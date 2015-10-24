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
    
    weak var delegate: MapItemCollectionViewModelDelegate?
    let cellItems: Latest<[MapItemCollectionViewCell.Item]>
    let selectedItemIndex: Observable<Int?>
    let fetcher: HTTPFetcher
    let favourites: Favourites
    
    public init(mapItems: Observable<[MapItem]>, selection: Observable<SearchViewModel.Selection?>, fetcher: HTTPFetcher, favourites: Favourites) {
        self.fetcher = fetcher
        self.favourites = favourites

        // Each MapItem can have multiple items to show in the collection view. Flat map into a cell item list.
        self.cellItems = mapItems.map { mapItems in
            mapItems.flatMap {
                MapItemCollectionViewCell.Item.forMapItem($0)
            }
        }.latest()
        
        // Map the selected search result to a collection view cell
        self.selectedItemIndex = combine(cellItems, selection) { cellItems, selection in
            selection.flatMap { selection in
                cellItems.indexOf { item in
                    item.matchesSelection(selection)
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
        favourites.toggleItem(item)
    }
    
    public func collectionViewItemIsFavourite(item: FavouriteTrafficCamera) -> Bool {
        return favourites.containsItem(item)
    }
}