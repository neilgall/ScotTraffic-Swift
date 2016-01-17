//
//  MapItem.swift
//  ScotTraffic
//
//  Created by Neil Gall on 03/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import MapKit

protocol MapItem {
    var name: String { get }
    var road: String { get }
    var mapPoint: MKMapPoint { get }
    var count: Int { get }
    var iconName: String { get }
}

func == (a: MapItem, b: MapItem) -> Bool {
    return (a.name == b.name
        && a.road == b.road
        && MKMapPointEqualToPoint(a.mapPoint, b.mapPoint))
}

extension MKMapPoint {
    func distanceSqToMapPoint(other: MKMapPoint) -> Double {
        let xd = x - other.x
        let yd = y - other.y
        return xd * xd + yd * yd
    }
}

extension MKMapRect: Equatable {
    func addPoint(point: MKMapPoint) -> MKMapRect {
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
    
    var centrePoint: MKMapPoint {
        return MKMapPointMake(MKMapRectGetMidX(self), MKMapRectGetMidY(self))
    }
    
    func contains(point: MKMapPoint) -> Bool {
        return MKMapRectContainsPoint(self, point)
    }
}

public func == (lhs: MKMapRect, rhs: MKMapRect) -> Bool {
    let accuracy = 1e-3
    return fabs(lhs.origin.x - rhs.origin.x) < accuracy
        && fabs(lhs.origin.y - rhs.origin.y) < accuracy
        && fabs(lhs.size.width - rhs.size.width) < accuracy
        && fabs(lhs.size.height - rhs.size.height) < accuracy
}

enum GeographicAxis {
    case NorthSouth
    case EastWest
}

extension SequenceType where Generator.Element == MapItem {
    var boundingRect: MKMapRect {
        return reduce(MKMapRectNull) { rect, mapItem in
            rect.addPoint(mapItem.mapPoint)
        }
    }
    
    var centrePoint: MKMapPoint {
        return boundingRect.centrePoint
    }
    
    var majorAxis: GeographicAxis {
        let rect = boundingRect
        if rect.size.width > rect.size.height {
            return GeographicAxis.EastWest
        } else {
            return GeographicAxis.NorthSouth
        }
    }
    
    func sortGeographically() -> [Generator.Element] {
        if majorAxis == GeographicAxis.EastWest {
            return sort { item1, item2 in item1.mapPoint.x < item2.mapPoint.x }
        } else {
            return sort { item1, item2 in item1.mapPoint.y < item2.mapPoint.y }
        }
    }
    
    var flatCount: Int {
        return reduce(0) { $0 + $1.count }
    }
}