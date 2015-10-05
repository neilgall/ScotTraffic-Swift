//
//  FavouritesViewModel.swift
//  ScotTraffic
//
//  Created by Neil Gall on 05/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit

public class FavouritesViewModel {
    
    let favourites: Latest<[FavouriteTrafficCamera]>
    
    public init(favourites: Favourites) {
        self.favourites = favourites.trafficCameras.latest()
    }
}
