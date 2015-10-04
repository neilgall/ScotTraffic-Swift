//
//  FavouritesViewModel.swift
//  ScotTraffic
//
//  Created by Neil Gall on 05/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit

public class FavouritesViewModel: SearchViewDataSource {
    
    let favourites: Latest<[FavouriteTrafficCamera]>
    
    public init(favourites: Favourites) {
        self.favourites = favourites.trafficCameras.latest()
    }
    
    public var count: Int {
        return self.favourites.value?.count ?? 0
    }
    
    public func configureCell(cell: UITableViewCell, forItemAtIndex index: Int) {
        let item = self.favourites.value?[index]
        cell.textLabel?.text = item?.location.name
        cell.detailTextLabel?.text = item?.location.road
    }
    
    public func onChange(fn: Void -> Void) -> Observation {
        return favourites.output { _ in fn() }
    }
}
