//
//  AppModel.swift
//  ScotTraffic
//
//  Created by Neil Gall on 01/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import Foundation

public class AppModel: ScotTraffic {
    
    // ScotTraffic interface
    public let trafficCameraLocations: Observable<[TrafficCameraLocation]>
    public let safetyCameras: Observable<[SafetyCamera]>
    public let alerts: Observable<[Incident]>
    public let roadworks: Observable<[Incident]>
    public let weather: Observable<[Weather]>
    public let settings: Settings
    public let favourites: Favourites
    
    public let fetcher: HTTPFetcher

    private let diskCache: DiskCache
    private let fetchStarters: [PeriodicStarter]
    private var observers = [Observation]()
    
    public init() {
        let diskCache = DiskCache(withPath: "scottraffic")
        let fetcher = HTTPFetcher(baseURL: NSURL(string: "http://dev.scottraffic.co.uk")!)
        
        let cachedDataSource = CachedHTTPDataSource.dataSourceWithFetcher(fetcher, cache: diskCache)
        
        let userDefaults = NSUserDefaults.standardUserDefaults()

        self.diskCache = diskCache
        self.fetcher = fetcher
        self.settings = Settings(userDefaults: userDefaults)
        
        
        // -- Traffic Cameras --
        
        let trafficCamerasSource = cachedDataSource(maximumCacheAge: 3600)(path: "trafficcameras.json")
        let trafficCamerasContext = TrafficCameraDecodeContext(makeImageDataSource: cachedDataSource(maximumCacheAge: 300))
        let trafficCameraLocations = trafficCamerasSource.value.map {
            return $0.map(Array<TrafficCameraLocation>.decodeJSON(trafficCamerasContext) <== JSONArrayFromData)
        }
        self.trafficCameraLocations = valueFromEither(trafficCameraLocations).latest()

        self.favourites = Favourites(userDefaults: userDefaults, trafficCameraLocations: self.trafficCameraLocations)

        
        // -- Safety Cameras --
        
        let safetyCamerasSource = cachedDataSource(maximumCacheAge: 86400)(path: "safetycameras.json")
        let safetyCamerasContext = SafetyCameraDecodeContext(makeImageDataSource: cachedDataSource(maximumCacheAge: 86400))
        let safetyCameras = safetyCamerasSource.value.map {
            $0.map(Array<SafetyCamera>.decodeJSON(safetyCamerasContext) <== JSONArrayFromData)
        }
        self.safetyCameras = valueFromEither(safetyCameras).latest()
 
        
        // -- Incidents / Roadworks --
        
        let incidentsSource = cachedDataSource(maximumCacheAge: 300)(path: "incidents.json")
        let incidents = incidentsSource.value.map {
            $0.map(Array<Incident>.decodeJSON(Void) <== JSONArrayFromData)
        }
        let allIncidents = valueFromEither(incidents)
        self.alerts = allIncidents.map { $0.filter { $0.type == IncidentType.Alert } }.latest()
        self.roadworks = allIncidents.map { $0.filter { $0.type == IncidentType.Roadworks } }.latest()
        
        
        // -- Weather --
        
        let weatherSource = cachedDataSource(maximumCacheAge: 900)(path: "weather.json")
        let weather = weatherSource.value.map {
            $0.map(Array<Weather>.decodeJSON(Void) <== JSONArrayFromData)
        }
        self.weather = valueFromEither(weather).latest()
        
        
        // -- Auto refresh --
        
        let fiveMinuteRefresh = PeriodicStarter(startables: [trafficCamerasSource, incidentsSource], period: 300)
        let halfHourlyRefresh = PeriodicStarter(startables: [safetyCamerasSource, weatherSource], period: 1800)
        self.fetchStarters = [fiveMinuteRefresh, halfHourlyRefresh]
        
        
        // -- Refresh on restoring internet connection
        
        self.observers.append(fetcher.serverIsReachable.onRisingEdge({
            for starter in self.fetchStarters {
                starter.restart(fireImmediately: true)
            }
        }))
    }
}
