//
//  MapItemCollectionViewModel.swift
//  ScotTraffic
//
//  Created by ZBS on 11/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import Foundation

public class MapItemCollectionViewModel {
    
    let mapItems: [MapItem]
    
    public init(mapItems: [MapItem]) {
        self.mapItems = mapItems
    }
}