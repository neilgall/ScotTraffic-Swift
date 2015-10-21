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
    func mapItemCollectionViewModel(model: MapItemCollectionViewModel, didToggleFavouriteItem item: FavouriteTrafficCamera)
}

public class MapItemCollectionViewModel: NSObject, UICollectionViewDataSource, MapItemCollectionViewCellDelegate {
    
    weak var delegate: MapItemCollectionViewModelDelegate?
    let cellItems: Latest<[MapItemCollectionViewCell.Item]>
    let selectedItemIndex: Observable<Int?>
    let fetcher: HTTPFetcher
    
    public init(mapItems: Observable<[MapItem]>, selection: Observable<MapItem?>, fetcher: HTTPFetcher) {
        self.fetcher = fetcher

        self.cellItems = mapItems.map({
            $0.flatMap({
                MapItemCollectionViewCell.Item.forMapItem($0)
            })
        }).latest()
        
        self.selectedItemIndex = combine(mapItems, selection) { items, selection in
            selection.flatMap {
                selection in items.indexOf {
                    $0 == selection
                }
            }
        }
    }

    // -- MARK: UICollectionViewDataSource --
    
    public func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return cellItems.value?.count ?? 0
    }
    
    public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cellItem = cellItems.value![indexPath.item]
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(cellItem.type.reuseIdentifier, forIndexPath: indexPath)
        
        if let cell = cell as? MapItemCollectionViewCell {
            cell.delegate = self
            cell.configure(cellItem, usingHTTPFetcher: fetcher)
        }
        
        return cell
    }
    
    // -- MARK: MapItemCollectionViewCellDelegate --
    
    public func collectionViewCellDidRequestShare(item: SharableItem) {
        delegate?.mapItemCollectionViewModel(self, didRequestShareItem: item)
    }
    
    public func collectionViewCellDidToggleFavourite(item: FavouriteTrafficCamera) {
        delegate?.mapItemCollectionViewModel(self, didToggleFavouriteItem: item)
    }
}