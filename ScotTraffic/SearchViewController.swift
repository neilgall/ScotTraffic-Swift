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

class SearchViewController: UITableViewController, UISearchBarDelegate {

    var searchBar: UISearchBar?
    var viewModel: SearchViewModel?
    var tableData: Latest<[MapItem]>?
    var tableDataObserver: Observation?
    
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

        tableData = viewModel?.searchResults.latest()
        tableDataObserver = tableData?.sink { _ in
            self.tableView.reloadData()
        }
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return TableSections.NumberOfSections.rawValue
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == TableSections.ContentSection.rawValue {
            return tableData?.value?.count ?? 0
        } else {
            return 0
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("searchCell", forIndexPath: indexPath)

        let mapItem = tableData?.value?[indexPath.row]
        cell.textLabel?.text = mapItem?.name
        cell.detailTextLabel?.text = mapItem?.road

        return cell
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == TableSections.TableTitleSection.rawValue {
            return "Title"
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
        viewModel?.searchTerm.value = searchText
    }
}
