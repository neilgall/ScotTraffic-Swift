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

class SearchViewController: UITableViewController, UISearchBarDelegate {

    var searchBar: UISearchBar?
    
    var searchViewModel: SearchViewModel?
    var dataSourceChangeObserver: Observation!

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

        if let dataSource = searchViewModel?.dataSource {
            // Reload on data source change or adapter updates
            dataSourceChangeObserver = dataSource.output { adapter in
                self.tableView.reloadData()
                adapter.reloadTableViewOnChange(self.tableView)
            }
        }
    }
    
    @IBAction func cancelSearch() {
        searchBar?.text = ""
        searchViewModel?.clearSearch()
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return TableSections.NumberOfSections.rawValue
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == TableSections.ContentSection.rawValue {
            return searchViewModel?.dataSource.value?.tableView(tableView, numberOfRowsInSection: 0) ?? 0
        } else {
            return 0
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == TableSections.ContentSection.rawValue {
            if let cell = searchViewModel?.dataSource.value?.tableView(tableView, cellForRowAtIndexPath: indexPath) {
                return cell
            }
        }
        return tableView.dequeueReusableCellWithIdentifier("dummy", forIndexPath: indexPath)
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == TableSections.TableTitleSection.rawValue {
            return searchViewModel?.resultsMajorAxisLabel.value ?? nil
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
            guard let title = searchViewModel?.resultsMajorAxisLabel.value where !title.isEmpty else {
                return 0
            }
            return 20

        default:
            return 0
        }
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        searchViewModel?.searchSelectionIndex.value = indexPath.row
    }
    
    override func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        searchViewModel?.searchSelectionIndex.value = nil
    }

    // MARK - UISearchBarDelegate
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        searchViewModel?.searchTerm.value = searchText
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}


