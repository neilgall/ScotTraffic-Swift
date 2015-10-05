//
//  FRP-UI-Extensions.swift
//  ScotTraffic
//
//  Created by Neil Gall on 05/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit

public protocol TableViewCellConfigurator {
    func configureCell(cell: UITableViewCell)
}

public class TableViewDataSourceAdapter
    <ValueType: CollectionType where ValueType.Generator.Element: TableViewCellConfigurator>
    : NSObject, UITableViewDataSource
{
    let cellIdentifier: String
    let source: Latest<ValueType>
    var output: Output<ValueType>
    
    init(source: Observable<ValueType>, tableView: UITableView, cellIdentifier: String) {
        self.cellIdentifier = cellIdentifier
        self.source = source.latest()
        self.output = source.output { [weak tableView] _ in
            tableView?.reloadData()
        }
    }
    
    public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let count = source.value?.count as? Int else {
            return 0
        }
        return count
    }
    
    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath)
        if let data = source.value {
            data[indexPath.row as! ValueType.Index].configureCell(cell)
        }
        return cell
    }
}

extension Observable where T: CollectionType, T.Generator.Element: TableViewCellConfigurator {
    
    // Where an Observable's value is a collection of TableViewCellConfigurators, we can automatically
    // create a table view data source drawing from this observable, and refreshing the table when the
    // contents update
    
    public func tableViewDataSource(tableView: UITableView, cellIdentifier: String) -> TableViewDataSourceAdapter<ValueType> {
        return TableViewDataSourceAdapter(source: self, tableView: tableView, cellIdentifier: cellIdentifier)
    }
}
