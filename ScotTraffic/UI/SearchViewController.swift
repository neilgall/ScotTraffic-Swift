//
//  SearchViewController.swift
//  ScotTraffic
//
//  Created by Neil Gall on 03/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit
import MapKit

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
        navigationItem.titleView = searchBar

        if let dataSource = searchViewModel?.dataSource {
            // Reload on data source change or adapter updates
            dataSourceChangeObserver = dataSource.output { adapter in
                self.tableView.reloadData()
                adapter.reloadTableViewOnChange(self.tableView)
            }
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        searchViewModel?.searchActive.value = true
        tableView.reloadData()
    }
    
    @IBAction func cancelSearch() {
        searchBar?.text = ""
        searchViewModel?.searchActive.value = false
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return searchViewModel?.dataSource.value?.numberOfSectionsInTableView(tableView) ?? 0
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchViewModel?.dataSource.value?.tableView(tableView, numberOfRowsInSection: section) ?? 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return searchViewModel!.dataSource.value!.tableView(tableView, cellForRowAtIndexPath: indexPath)
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return searchViewModel!.sectionHeader.value
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let title = searchViewModel?.sectionHeader.value where !title.isEmpty else {
            return 0
        }
        return 30
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


