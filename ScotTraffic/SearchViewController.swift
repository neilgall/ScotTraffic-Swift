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

protocol SearchViewDataSource: class {
    var count: Int { get }
    func configureCell(cell: UITableViewCell, forItemAtIndex index: Int)
    func onChange(fn: Void->Void) -> Observation
}

class SearchViewController: UITableViewController, UISearchBarDelegate {

    var searchBar: UISearchBar?
    var favouritesViewModel: FavouritesViewModel?
    var searchViewModel: SearchViewModel?

    var dataSourceObserver: Observation?
    var dataSource: SearchViewDataSource? {
        didSet {
            dataSourceObserver = dataSource?.onChange { self.tableView.reloadData() }
        }
    }
    
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
        
        self.dataSource = self.favouritesViewModel
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return TableSections.NumberOfSections.rawValue
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == TableSections.ContentSection.rawValue {
            return dataSource?.count ?? 0
        } else {
            return 0
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("searchCell", forIndexPath: indexPath)
        dataSource?.configureCell(cell, forItemAtIndex: indexPath.row)
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
        let newDataSource: SearchViewDataSource?
        if searchText.isEmpty {
            newDataSource = favouritesViewModel
        } else  {
            searchViewModel?.searchTerm.value = searchText
            newDataSource = searchViewModel
        }
        
        if newDataSource !== dataSource {
            dataSource = newDataSource
            tableView.reloadData()
        }
    }
}
