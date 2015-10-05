//
//  SearchViewController.swift
//  ScotTraffic
//
//  Created by Neil Gall on 03/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit

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

    var searchBar: UISearchBar?
    var favouritesViewModel: FavouritesViewModel?
    var searchViewModel: SearchViewModel?
    var displayContent: Observable<DisplayContent>?
    var dataSource: Latest<UITableViewDataSource>?
    var resultsMajorAxis: Latest<String>?
    var reloadObserver: Observation?
    
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
        
        dataSource = displayContent!.onChange().map({
            switch $0 {
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

        resultsMajorAxis = combine(displayContent!, searchViewModel!.searchResultsMajorAxis, combine: {
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
        reloadObserver = dataSource!.output { _ in
            self.tableView.reloadData()
        }
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return TableSections.NumberOfSections.rawValue
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == TableSections.ContentSection.rawValue {
            return dataSource?.value?.tableView(tableView, numberOfRowsInSection: 0) ?? 0
        } else {
            return 0
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == TableSections.ContentSection.rawValue {
            if let cell = dataSource?.value?.tableView(tableView, cellForRowAtIndexPath: indexPath) {
                return cell
            }
        }
        return tableView.dequeueReusableCellWithIdentifier("dummy", forIndexPath: indexPath)
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == TableSections.TableTitleSection.rawValue {
            return resultsMajorAxis?.value
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
            guard let title = resultsMajorAxis?.value where !title.isEmpty else {
                return 0
            }
            return 20

        default:
            return 0
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    // MARK - UISearchBarDelegate
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        searchViewModel?.searchTerm.value = searchText
    }
}

struct SearchResultItem: TableViewCellConfigurator {
    let name: String
    let road: String
    
    func configureCell(cell: UITableViewCell) {
        cell.textLabel?.text = name
        cell.detailTextLabel?.text = road
    }
}

func toSearchResultItems(items: [FavouriteTrafficCamera]) -> [SearchResultItem] {
    return items.map { item in SearchResultItem(name: item.location.name, road: item.location.road) }
}

func toSearchResultItem(items: [MapItem]) -> [SearchResultItem] {
    return items.map { item in SearchResultItem(name: item.name, road: item.road) }
}

