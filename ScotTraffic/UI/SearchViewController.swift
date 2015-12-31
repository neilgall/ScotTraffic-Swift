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

    @IBOutlet var editingFavouritesButton: UIButton?
    let editingFavourites: Input<Bool> = Input(initial: false)
    var searchBar: UISearchBar?
    var searchViewModel: SearchViewModel?
    var observations = [Observation]()

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
            observations.append(dataSource => { [weak self] adapter in
                self?.editingFavourites.value = false
                self?.tableView.reloadData()
                if let tableView = self?.tableView {
                    adapter.reloadTableViewOnChange(tableView)
                }
            })
        }
        
        observations.append(editingFavourites => { [weak self] editing in
            self?.navigationItem.rightBarButtonItem?.enabled = !editing
            self?.tableView.setEditing(editing, animated: true)
            self?.editingFavouritesButton?.setTitle(editing ? "Done" : "Edit", forState: .Normal)
        })
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        searchViewModel?.searchActive.value = true
        tableView.reloadData()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.editingFavourites.value = false
    }
    
    @IBAction func cancelSearch() {
        searchBar?.text = ""
        searchViewModel?.searchActive.value = false
    }

    // -- MARK: UITableViewDataSource
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return searchViewModel?.dataSource.value?.numberOfSectionsInTableView(tableView) ?? 0
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchViewModel?.dataSource.value?.tableView(tableView, numberOfRowsInSection: section) ?? 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return searchViewModel!.dataSource.value!.tableView(tableView, cellForRowAtIndexPath: indexPath)
    }
    
    // -- MARK: UITableViewDelegate
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let nibName = searchViewModel!.sectionHeader.value else {
            return nil
        }
        let nib = UINib(nibName: nibName, bundle: nil)
        return nib.instantiateWithOwner(self, options: nil).first as? UIView
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let title = searchViewModel?.sectionHeader.value where !title.isEmpty else {
            return 0
        }
        return 34
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return .Delete
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        guard let model = searchViewModel where editingStyle == .Delete else {
            return
        }
        model.deleteFavouriteAtIndex(indexPath.row)
        tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
    }
    
    override func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        guard let model = searchViewModel else {
            return
        }
        model.moveFavouriteAtIndex(sourceIndexPath.row, toIndex: destinationIndexPath.row)
//        tableView.moveRowAtIndexPath(sourceIndexPath, toIndexPath: destinationIndexPath)
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        searchViewModel?.searchSelectionIndex.value = indexPath.row
    }
    
    override func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        searchViewModel?.searchSelectionIndex.value = nil
    }

    // -- MARK: UISearchBarDelegate
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        searchViewModel?.searchTerm.value = searchText
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    // -- MARK: Actions
    
    @IBAction func editFavourites(sender: UIButton) {
        editingFavourites.value = !editingFavourites.value
    }
}


