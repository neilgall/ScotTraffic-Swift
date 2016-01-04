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
    <Source: ObservableType where Source.ValueType: CollectionType,
        Source.ValueType.Generator.Element: TableViewCellConfigurator,
        Source.ValueType.Index: IntegerType>
    : NSObject, UITableViewDataSource
{
    public let cellIdentifier: String
    public let source: Observable<Source.ValueType>
    private var observation: Observation!
    
    init(source: Source, cellIdentifier: String) {
        self.cellIdentifier = cellIdentifier
        self.source = source.latest()
    }
    
    public func reloadTableViewOnChange(tableView: UITableView) {
        observation = source => { [weak tableView] _ in
            if let tableView = tableView where !tableView.editing {
                tableView.reloadData()
            }
        }
    }
    
    public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (source.pullValue?.count as? Int) ?? 0
    }
    
    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath)
        source.pullValue?[indexPath.row as! Source.ValueType.Index].configureCell(cell)
        return cell
    }
}

extension ObservableType where ValueType: CollectionType, ValueType.Generator.Element: TableViewCellConfigurator, ValueType.Index: IntegerType {
    
    // Where an Observable's value is a collection of TableViewCellConfigurators, we can automatically
    // create a table view data source drawing from this observable, and refreshing the table when the
    // contents update
    
    public func tableViewDataSource(cellIdentifier: String) -> TableViewDataSourceAdapter<Self> {
        return TableViewDataSourceAdapter(source: self, cellIdentifier: cellIdentifier)
    }
}
