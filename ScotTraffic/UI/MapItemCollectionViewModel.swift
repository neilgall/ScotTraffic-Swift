//
//  MapItemCollectionViewModel.swift
//  ScotTraffic
//
//  Created by ZBS on 11/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit

protocol MapItemCollectionViewModelDelegate: class {
    func mapItemCollectionViewModel(model: MapItemCollectionViewModel, didRequestShareItem item: SharableItem)
}

public class MapItemCollectionViewModel: NSObject, UICollectionViewDataSource, MapItemCollectionViewCellDelegate {
    
    let cellItems: [MapItemCollectionViewCell.Item]
    let fetcher: HTTPFetcher
    weak var delegate: MapItemCollectionViewModelDelegate?
    
    public init(mapItems: [MapItem], fetcher: HTTPFetcher) {
        self.cellItems = mapItems.flatMap({ MapItemCollectionViewCell.Item.forMapItem($0) })
        self.fetcher = fetcher
    }

    // -- MARK: UICollectionViewDataSource --
    
    public func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return cellItems.count
    }
    
    public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cellItem = cellItems[indexPath.item]
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(cellItem.type.reuseIdentifier, forIndexPath: indexPath)
        
        if let cell = cell as? MapItemCollectionViewCell {
            cell.item = cellItem
            cell.delegate = self
            cell.configure(cellItem, usingHTTPFetcher: fetcher)
        }
        
        return cell
    }
    
    // -- MARK: MapItemCollectionViewCellDelegate --
    
    public func collectionViewCellDidRequestShare(item: SharableItem) {
        delegate?.mapItemCollectionViewModel(self, didRequestShareItem: item)
    }
    
    public func collectionViewCellDidToggleFavourite(item: MapItemCollectionViewCell.Item) {
    }
}