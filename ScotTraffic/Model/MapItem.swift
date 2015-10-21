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
    var count: Int { get }
    var iconName: String { get }
}

public func == (a: MapItem, b: MapItem) -> Bool {
    return (a.name == b.name
        && a.road == b.road
        && MKMapPointEqualToPoint(a.mapPoint, b.mapPoint))
}

extension MKMapRect {
    public func addPoint(point: MKMapPoint) -> MKMapRect {
        if MKMapRectIsNull(self) {
            return MKMapRectMake(point.x, point.y, 0, 0)
        }
        
        if MKMapRectContainsPoint(self, point) {
            return self
        }
        
        var rect = self
        if point.x < MKMapRectGetMinX(rect) {
            rect.size.width = MKMapRectGetMaxX(rect) - point.x
            rect.origin.x = point.x
        }
        if point.y < MKMapRectGetMinY(rect) {
            rect.size.height = MKMapRectGetMaxY(rect) - point.y
            rect.origin.y = point.y
        }
        if MKMapRectGetMaxX(rect) < point.x {
            rect.size.width = point.x - MKMapRectGetMinX(rect)
        }
        if MKMapRectGetMaxY(rect) < point.y {
            rect.size.height = point.y - MKMapRectGetMinY(rect)
        }
        
        return rect
    }
    
    public var centrePoint: MKMapPoint {
        return MKMapPointMake(MKMapRectGetMidX(self), MKMapRectGetMidY(self))
    }
    
    public func contains(point: MKMapPoint) -> Bool {
        return MKMapRectContainsPoint(self, point)
    }
}

public enum GeographicAxis {
    case NorthSouth
    case EastWest
}

extension SequenceType where Generator.Element == MapItem {
    public var boundingRect: MKMapRect {
        return reduce(MKMapRectNull) { rect, mapItem in rect.addPoint(mapItem.mapPoint) }
    }
    
    public var majorAxis: GeographicAxis {
        let rect = boundingRect
        if rect.size.width > rect.size.height {
            return GeographicAxis.EastWest
        } else {
            return GeographicAxis.NorthSouth
        }
    }
    
    public func sortGeographically() -> [Generator.Element] {
        if majorAxis == GeographicAxis.EastWest {
            return sort { item1, item2 in item1.mapPoint.x < item2.mapPoint.x }
        } else {
            return sort { item1, item2 in item1.mapPoint.y < item2.mapPoint.y }
        }
    }
}