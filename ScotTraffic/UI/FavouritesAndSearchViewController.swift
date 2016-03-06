//
//  FavouritesAndSearchViewController.swift
//  ScotTraffic
//
//  Created by Neil Gall on 03/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit
import MapKit

class FavouritesAndSearchViewController: UITableViewController {

    @IBOutlet var editingFavouritesButton: UIButton?
    @IBOutlet var saveSearchButton: UIButton? {
        didSet {
            saveSearchButton?.hidden = true
        }
    }
    var searchBar: UISearchBar? {
        return navigationItem.titleView as? UISearchBar
    }
    
    let editingFavourites: Input<Bool> = Input(initial: false)
    var viewModel: FavouritesAndSearchViewModel?
    var headerNib: Signal<String>?
    var dataSource: UITableViewDataSource?
    var receivers = [ReceiverType]()
    var modifyingTable: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let viewModel = viewModel else {
            return
        }

        let searchBar = UISearchBar(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 0, height: 44)))
        searchBar.translatesAutoresizingMaskIntoConstraints = true
        searchBar.autoresizingMask = .FlexibleWidth
        searchBar.delegate = self
        searchBar.autocapitalizationType = .Words
        searchBar.placeholder = "Place name or road"
        searchBar.showsCancelButton = false
        navigationItem.titleView = searchBar

        headerNib = headerNibSignal(viewModel.content)
        
        // YUCK: must remain above dataSource init due to dependency on observation order
        receivers.append(viewModel.content --> { [weak self] _ in
            self?.reloadTableIfNotModifying()
        })
        
        dataSource = viewModel.content.map({ $0.items }).tableViewDataSource(SearchResultCell.cellIdentifier)
        
        receivers.append(editingFavourites --> { [weak self] editing in
            self?.navigationItem.rightBarButtonItem?.enabled = !editing
            self?.tableView.setEditing(editing, animated: true)
            self?.editingFavouritesButton?.setTitle(editing ? "Done" : "Edit", forState: .Normal)
        })
        
        receivers.append(viewModel.searchSelection --> { [weak self] in
            guard let resultsModel = $0, searchResultViewController = self?.searchResultViewController() else {
                return
            }
            searchResultViewController.viewModel = resultsModel
            self?.navigationController?.pushViewController(searchResultViewController, animated: true)
        })
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if let viewModel = viewModel {
            viewModel.searchActive <-- true
        }
        
        if let searchBar = navigationItem.titleView as? UISearchBar, text = searchBar.text where !text.isEmpty {
            searchBar.becomeFirstResponder()
        }
            
        tableView.reloadData()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.editingFavourites <-- false
    }
    
    func cancelEditingFavourites() {
        editingFavourites <-- false
    }
    
    func reloadTableIfNotModifying() {
        guard !modifyingTable && !tableView.editing else {
            return
        }
        tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
    }
    
    func searchResultViewController() -> SearchResultViewController? {
        return storyboard?.instantiateViewControllerWithIdentifier("searchResultViewController") as? SearchResultViewController
    }

    // -- MARK: Actions
    
    @IBAction func editFavourites(sender: UIButton) {
        searchBar?.resignFirstResponder()
        editingFavourites.modify({ return !$0 })
    }
    
    @IBAction func cancelSearch() {
        if let viewModel = viewModel {
            viewModel.liveSearchTerm <-- ""
            viewModel.enteredSearchTerm <-- ""
        }
    }
}

extension FavouritesAndSearchViewController {
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
        guard let viewModel = viewModel where editingStyle == .Delete else {
            return
        }
        with(&modifyingTable) {
            viewModel.deleteFavouriteAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }
    }
    
    override func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        guard let viewModel = viewModel else {
            return
        }
        with(&modifyingTable) {
            viewModel.moveFavouriteAtIndex(sourceIndexPath.row, toIndex: destinationIndexPath.row)
        }
    }
}

extension FavouritesAndSearchViewController {
    // -- MARK: UITableViewDelegate
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let nibName = headerNib?.latestValue.get else {
            return nil
        }
        let nib = UINib(nibName: nibName, bundle: nil)
        return nib.instantiateWithOwner(self, options: nil).first as? UIView
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let nib = headerNib else {
            return 0
        }
        return nib.latestValue.has ? 44 : 0
    }
    
    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return .Delete
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let searchSelectionIndex = viewModel?.searchSelectionIndex {
            searchSelectionIndex <-- indexPath.row
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
    }
    
    override func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        if let searchSelectionIndex = viewModel?.searchSelectionIndex {
            searchSelectionIndex <-- nil
        }
    }
}

extension FavouritesAndSearchViewController: UISearchBarDelegate {
    // -- MARK: UISearchBarDelegate

    func searchBar(searchBar: UISearchBar, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        cancelEditingFavourites()
        return true
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        if let viewModel = viewModel {
            viewModel.liveSearchTerm <-- searchText
        }
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        if let viewModel = viewModel, text = searchBar.text {
            viewModel.liveSearchTerm <-- ""
            viewModel.enteredSearchTerm <-- text
        }
        searchBar.text = ""
        searchBar.resignFirstResponder()
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

extension Search.ContentItem: TableViewCellConfigurator {
    func configureCell(cell: UITableViewCell) {
        guard let resultCell = cell as? SearchResultCell else {
            return
        }
        switch self {
        case .TrafficCameraItem(let location, let index):
            resultCell.nameLabel?.text = location.nameAtIndex(index)
            resultCell.roadLabel?.text = location.road
            resultCell.iconImageView?.image = UIImage(named: location.iconName)
            resultCell.accessoryType = .None
        case .OtherMapItem(let mapItem):
            resultCell.nameLabel?.text = mapItem.name
            resultCell.roadLabel?.text = mapItem.road
            resultCell.iconImageView?.image = UIImage(named: mapItem.iconName)
            resultCell.accessoryType = .None
        case .SearchItem(let term):
            resultCell.nameLabel?.text = term
            resultCell.roadLabel?.text = nil
            resultCell.iconImageView?.image = UIImage(named: "708-search-gray")
            resultCell.accessoryType = .DisclosureIndicator
        }
    }
}


