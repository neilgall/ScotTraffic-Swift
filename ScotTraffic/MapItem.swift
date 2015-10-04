//
//  MapItem.swift
//  ScotTraffic
//
//  Created by Neil Gall on 03/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import MapKit

public protocol MapItem {
    var name: String { get }
    var road: String { get }
    var mapPoint: MKMapPoint { get }
}

public func == (a: MapItem, b: MapItem) -> Bool {
    return (a.name == b.name
        && a.road == b.road
        && MKMapPointEqualToPoint(a.mapPoint, b.mapPoint))
}