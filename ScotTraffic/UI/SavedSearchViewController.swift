//
//  SavedSearchViewController.swift
//  ScotTraffic
//
//  Created by Neil Gall on 03/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit
import MapKit

class SavedSearchViewController: UITableViewController {

    @IBOutlet var saveSearchButton: UIButton? {
        didSet {
            saveSearchButton?.hidden = true
        }
    }

    var viewModel: SearchResultsViewModel?
    var headerNib: Signal<String>?
    var dataSource: UITableViewDataSource?
    var receivers = [ReceiverType]()

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let viewModel = viewModel else {
            return
        }
        
        receivers.append(viewModel.searchTerm --> { [weak self] in
            self?.title = $0
        })

        receivers.append(viewModel.content --> { [weak self] _ in
            self?.tableView.reloadData()
        })
        
        headerNib = headerNibSignal(viewModel.content)
        
        dataSource = viewModel.content.map({ $0.items }).tableViewDataSource(SearchResultCell.cellIdentifier)
    }
}

extension SavedSearchViewController {
    // -- MARK: UITableViewDataSource
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return dataSource?.numberOfSectionsInTableView?(tableView) ?? 0
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource?.tableView(tableView, numberOfRowsInSection: section) ?? 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return dataSource?.tableView(tableView, cellForRowAtIndexPath: indexPath) ?? UITableViewCell()
    }
}

extension SavedSearchViewController {
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
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let viewModel = viewModel {
            viewModel.searchSelectionIndex <-- indexPath.row
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
    }
}



