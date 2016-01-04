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
    var trafficCameraLocations: Signal<[TrafficCameraLocation]> { get }
    var safetyCameras: Signal<[SafetyCamera]> { get }
    var alerts: Signal<[Incident]> { get }
    var roadworks: Signal<[Incident]> { get }
    var bridges: Signal<[BridgeStatus]> { get }
    var weather: Signal<WeatherFinder> { get }
    var settings: Settings { get }
    var favourites: Favourites { get }
}

