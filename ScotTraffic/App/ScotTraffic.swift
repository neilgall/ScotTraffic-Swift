//
//  ScotTraffic.swift
//  ScotTraffic
//
//  Created by ZBS on 12/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import Foundation

public typealias WeatherFinder = MapItem -> Weather?

public protocol ScotTraffic {
    var trafficCameraLocations: Observable<[TrafficCameraLocation]> { get }
    var safetyCameras: Observable<[SafetyCamera]> { get }
    var alerts: Observable<[Incident]> { get }
    var roadworks: Observable<[Incident]> { get }
    var weather: Observable<WeatherFinder> { get }
    var settings: Settings { get }
    var favourites: Favourites { get }
}

