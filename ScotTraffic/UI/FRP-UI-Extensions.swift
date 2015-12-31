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
    <ValueType: CollectionType where ValueType.Generator.Element: TableViewCellConfigurator, ValueType.Index: IntegerType>
    : NSObject, UITableViewDataSource
{
    public let cellIdentifier: String
    public let source: Latest<ValueType>
    var output: Output<ValueType>?
    
    init(source: Observable<ValueType>, cellIdentifier: String) {
        self.cellIdentifier = cellIdentifier
        self.source = source.latest()
    }
    
    public func reloadTableViewOnChange(tableView: UITableView) {
        self.output = source.output { [weak tableView] _ in
            if let tableView = tableView where !tableView.editing {
                tableView.reloadData()
            }
        }
    }
    
    public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (source.value?.count as? Int) ?? 0
    }
    
    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath)
        source.value?[indexPath.row as! ValueType.Index].configureCell(cell)
        return cell
    }
}

extension Observable where Value: CollectionType, Value.Generator.Element: TableViewCellConfigurator, Value.Index: IntegerType {
    
    // Where an Observable's value is a collection of TableViewCellConfigurators, we can automatically
    // create a table view data source drawing from this observable, and refreshing the table when the
    // contents update
    
    public func tableViewDataSource(cellIdentifier: String) -> TableViewDataSourceAdapter<ValueType> {
        return TableViewDataSourceAdapter(source: self, cellIdentifier: cellIdentifier)
    }
}
