//
//  MapItemCollectionViewModel.swift
//  ScotTraffic
//
//  Created by ZBS on 11/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit

public class MapItemCollectionViewModel: NSObject, UICollectionViewDataSource, MapItemCollectionViewCellDelegate {

    // Sources
    let favourites: Favourites

    // Inputs
    let mapItems: Input<[MapItem]>
    
    // Outputs
    let weatherViewModel: WeatherViewModel
    let cellItems: Signal<[MapItemCollectionViewCell.Item]>
    let selectedItemIndex: Signal<Int?>
    let shareAction: Input<ShareAction?>
    
    public init(scotTraffic: ScotTraffic, selection: Signal<SearchViewModel.Selection?>) {
        self.favourites = scotTraffic.favourites

        mapItems = Input(initial: [])
        
        shareAction = Input(initial: nil)
        weatherViewModel = WeatherViewModel(
            weatherFinder: scotTraffic.weather,
            mapItem: mapItems.map({ $0.first }),
            temperatureUnit: scotTraffic.settings.temperatureUnit)
    
        // Each MapItem can have multiple items to show in the collection view. Flat map into a cell item list.
        cellItems = mapItems.map { mapItems in
            mapItems.flatMap {
                MapItemCollectionViewCell.Item.forMapItem($0)
            }
        }.latest()
        
        // Map the selected search result to a collection view cell
        selectedItemIndex = combine(cellItems, selection) { cellItems, selection in
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
        return cellItems.latestValue.get?.count ?? 0
    }
    
    public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cellItem = cellItems.latestValue.get![indexPath.item]
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(cellItem.type.reuseIdentifier, forIndexPath: indexPath)
        
        if let cell = cell as? MapItemCollectionViewCell {
            cell.delegate = self
            cell.configure(cellItem)
        }
        
        return cell
    }
    
    // -- MARK: MapItemCollectionViewCellDelegate --
    
    public func collectionViewCell(cell: MapItemCollectionViewCell, didRequestShareItem item: SharableItem, fromRect rect: CGRect) {
        shareAction.value = ShareAction(item: item, sourceView: cell, sourceRect: rect)
    }
    
    public func collectionViewCellDidToggleFavourite(item: FavouriteTrafficCamera) {
        favourites.toggleItem(item)
    }
    
    public func collectionViewItemIsFavourite(item: FavouriteTrafficCamera) -> Bool {
        return favourites.containsItem(item)
    }
}

public struct ShareAction {
    let item: SharableItem
    let sourceView: UIView
    let sourceRect: CGRect
}

