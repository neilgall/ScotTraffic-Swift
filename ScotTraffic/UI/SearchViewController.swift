//
//  SearchViewController.swift
//  ScotTraffic
//
//  Created by Neil Gall on 03/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit
import MapKit

class SearchViewController: UITableViewController {

    @IBOutlet var editingFavouritesButton: UIButton?
    @IBOutlet var saveSearchButton: UIButton? {
        didSet {
            saveSearchButtonSignal <-- saveSearchButton
        }
    }
    
    let editingFavourites: Input<Bool> = Input(initial: false)
    var searchViewModel: SearchViewModel?
    var dataSource: UITableViewDataSource?
    var saveSearchButtonSignal: Input<UIButton?> = Input(initial: nil)
    var receivers = [ReceiverType]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let searchBar = UISearchBar(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 0, height: 44)))
        searchBar.translatesAutoresizingMaskIntoConstraints = true
        searchBar.autoresizingMask = .FlexibleWidth
        searchBar.delegate = self
        searchBar.autocapitalizationType = .Words
        searchBar.placeholder = "Place name or road"
        searchBar.showsCancelButton = false
        navigationItem.titleView = searchBar

        if let searchViewModel = searchViewModel {
            receivers.append(searchViewModel.contentType --> { [weak self] _ in
                if let editingFavourites = self?.editingFavourites {
                    editingFavourites <-- false
                }
            })
            
            receivers.append(searchViewModel.savedSearchSelection --> { searchTerm in
                if let searchTerm = searchTerm {
                    dispatch_async(dispatch_get_main_queue()) {
                        searchBar.text = searchTerm
                        searchViewModel.searchTerm <-- searchTerm
                    }
                }
            })
            
            receivers.append(combine(saveSearchButtonSignal, searchViewModel.canSaveSearch, combine: { ($0, $1) }) --> { button, canSave in
                button?.enabled = canSave
            })
            
            receivers.append(searchViewModel.content --> { [weak self] _ in
                dispatch_async(dispatch_get_main_queue()) {
                    if let tableView = self?.tableView where !tableView.editing {
                        tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
                    }
                }
            })

            dataSource = searchViewModel.content.tableViewDataSource(SearchResultCell.cellIdentifier)
        }

        receivers.append(editingFavourites --> { [weak self] editing in
            self?.navigationItem.rightBarButtonItem?.enabled = !editing
            self?.tableView.setEditing(editing, animated: true)
            self?.editingFavouritesButton?.setTitle(editing ? "Done" : "Edit", forState: .Normal)
        })
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if let searchActive = searchViewModel?.searchActive {
            searchActive <-- true
        }
        tableView.reloadData()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.editingFavourites <-- false
    }
    
    func searchBarResignFirstResponder() {
        (navigationItem.titleView as? UISearchBar)?.resignFirstResponder()
    }
    
    // -- MARK: Actions
    
    @IBAction func editFavourites(sender: UIButton) {
        editingFavourites <-- !(editingFavourites.latestValue.get!)
    }
    
    @IBAction func saveSearch(sender: UIButton) {
        searchViewModel?.saveSearch()
        searchBarResignFirstResponder()
    }

    @IBAction func cancelSearch() {
        if let searchActive = searchViewModel?.searchActive {
            searchActive <-- false
        }
    }
}

extension SearchViewController {
    // -- MARK: UITableViewDataSource
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return dataSource?.numberOfSectionsInTableView?(tableView) ?? 0
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource!.tableView(tableView, numberOfRowsInSection: section)
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return dataSource!.tableView(tableView, cellForRowAtIndexPath: indexPath)
    }

    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        guard editingStyle == .Delete else {
            return
        }
        searchViewModel?.deleteFavouriteAtIndex(indexPath.row)
        tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
    }
    
    override func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        guard let model = searchViewModel else {
            return
        }
        model.moveFavouriteAtIndex(sourceIndexPath.row, toIndex: destinationIndexPath.row)
    }
}

extension SearchViewController {
    // -- MARK: UITableViewDelegate
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let nibName = searchViewModel!.sectionHeader.latestValue.get else {
            return nil
        }
        let nib = UINib(nibName: nibName, bundle: nil)
        return nib.instantiateWithOwner(self, options: nil).first as? UIView
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let title = searchViewModel?.sectionHeader.latestValue.get where !title.isEmpty else {
            return 0
        }
        return 34
    }
    
    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return .Delete
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let searchSelectionIndex = searchViewModel?.searchSelectionIndex {
            searchSelectionIndex <-- indexPath.row
        }
    }
    
    override func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        if let searchSelectionIndex = searchViewModel?.searchSelectionIndex {
            searchSelectionIndex <-- nil
        }
    }
}

extension SearchViewController {
    // -- MARK: UIScrollViewDelegate
    
    override func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        searchBarResignFirstResponder()
    }
}

extension SearchViewController: UISearchBarDelegate {
    // -- MARK: UISearchBarDelegate
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        if let searchTerm = searchViewModel?.searchTerm {
            searchTerm <-- searchText
        }
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}


