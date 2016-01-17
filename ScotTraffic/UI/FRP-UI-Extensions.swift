//
//  FRP-UI-Extensions.swift
//  ScotTraffic
//
//  Created by Neil Gall on 05/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit

protocol TableViewCellConfigurator {
    func configureCell(cell: UITableViewCell)
}

class TableViewDataSourceAdapter
    <Source: SignalType where Source.ValueType: CollectionType,
        Source.ValueType.Generator.Element: TableViewCellConfigurator,
        Source.ValueType.Index: IntegerType>
    : NSObject, UITableViewDataSource {

    let cellIdentifier: String
    let source: Signal<Source.ValueType>
    
    init(source: Source, cellIdentifier: String) {
        self.cellIdentifier = cellIdentifier
        self.source = source.latest()
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (source.latestValue.get?.count as? Int) ?? 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath)
        source.latestValue.get?[indexPath.row as! Source.ValueType.Index].configureCell(cell) // swiftlint:disable:this force_cast
        return cell
    }
}

extension SignalType where ValueType: CollectionType, ValueType.Generator.Element: TableViewCellConfigurator, ValueType.Index: IntegerType {
    
    // Where an Signal's value is a collection of TableViewCellConfigurators, we can automatically
    // create a table view data source drawing from this Signal, and refreshing the table when the
    // contents update
    
    func tableViewDataSource(cellIdentifier: String) -> TableViewDataSourceAdapter<Self> {
        return TableViewDataSourceAdapter(source: self, cellIdentifier: cellIdentifier)
    }
}
