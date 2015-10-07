//
//  SearchViewController.swift
//  ScotTraffic
//
//  Created by Neil Gall on 03/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit
import MapKit

enum TableSections : Int {
    case SearchBarSection = 0
    case TableTitleSection
    case ContentSection
    case NumberOfSections
}

enum DisplayContent {
    case Favourites
    case SearchResults
}

class SearchViewController: UITableViewController, UISearchBarDelegate {

    var favouritesViewModel: FavouritesViewModel?
    var coordinator: AppCoordinator?

    var searchBar: UISearchBar?
    var searchViewModel: SearchViewModel?
    var displayContent: Observable<DisplayContent>!
    var dataSource: Latest<TableViewDataSourceAdapter<[SearchResultItem]>>!
    var resultsMajorAxis: Latest<String>!
    var reloadObserver: Observation!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let searchBar = UISearchBar(frame: CGRectMake(0, 0, 0, 44))
        searchBar.translatesAutoresizingMaskIntoConstraints = true
        searchBar.autoresizingMask = .FlexibleWidth
        searchBar.delegate = self
        searchBar.autocapitalizationType = .Words
        searchBar.placeholder = "Place name or road"
        searchBar.showsCancelButton = false
        self.searchBar = searchBar
        
        displayContent = searchViewModel?.searchTerm.map { text in
            text.isEmpty ? .Favourites : .SearchResults
        }
        
        dataSource = displayContent.onChange().map({ contentType in
            switch contentType {
            case .Favourites:
                return self.favouritesViewModel!.favourites
                    .map(toSearchResultItems)
                    .tableViewDataSource(self.tableView, cellIdentifier: "searchCell")
            case .SearchResults:
                return self.searchViewModel!.searchResults
                    .map(toSearchResultItem)
                    .tableViewDataSource(self.tableView, cellIdentifier: "searchCell")
            }
        }).latest()

        resultsMajorAxis = combine(displayContent, searchViewModel!.searchResultsMajorAxis, combine: {
            if $0 == DisplayContent.Favourites {
                return ""
            } else {
                switch $1 {
                case .NorthSouth: return "North to South"
                case .EastWest: return "West to East"
                }
            }
        }).latest()
        

        // Must set this last as it will trigger a table reload
        reloadObserver = dataSource.output { _ in
            self.tableView.reloadData()
        }
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return TableSections.NumberOfSections.rawValue
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == TableSections.ContentSection.rawValue {
            return dataSource.value?.tableView(tableView, numberOfRowsInSection: 0) ?? 0
        } else {
            return 0
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == TableSections.ContentSection.rawValue {
            if let cell = dataSource.value?.tableView(tableView, cellForRowAtIndexPath: indexPath) {
                return cell
            }
        }
        return tableView.dequeueReusableCellWithIdentifier("dummy", forIndexPath: indexPath)
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == TableSections.TableTitleSection.rawValue {
            return resultsMajorAxis.value
        } else {
            return nil
        }
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == TableSections.SearchBarSection.rawValue {
            return searchBar
        } else {
            return nil
        }
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch TableSections(rawValue: section)! {
            
        case .SearchBarSection:
            return 44

        case .TableTitleSection:
            guard let title = resultsMajorAxis.value where !title.isEmpty else {
                return 0
            }
            return 20

        default:
            return 0
        }
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let mapItem = dataSource.value?.source.value?[indexPath.row] {
            coordinator?.zoomToMapItem(mapItem)
        }
    }

    // MARK - UISearchBarDelegate
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        searchViewModel?.searchTerm.value = searchText
    }
}

struct SearchResultItem: MapItem, TableViewCellConfigurator {
    let name: String
    let road: String
    let mapPoint: MKMapPoint
    
    init(item: MapItem) {
        self.name = item.name
        self.road = item.road
        self.mapPoint = item.mapPoint
    }
    
    func configureCell(cell: UITableViewCell) {
        cell.textLabel?.text = name
        cell.detailTextLabel?.text = road
    }
}

func toSearchResultItems(items: [FavouriteTrafficCamera]) -> [SearchResultItem] {
    return items.map { SearchResultItem(item: $0.location) }
}

func toSearchResultItem(items: [MapItem]) -> [SearchResultItem] {
    return items.map { SearchResultItem(item: $0) }
}

