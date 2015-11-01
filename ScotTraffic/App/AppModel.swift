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
    private let errorSources: Observable<AppError>
    private let fetchStarters: [PeriodicStarter]
    private var internalObservers = [Observation]()
    
    public init() {
        let diskCache = DiskCache(withPath: "scottraffic")
        let fetcher = HTTPFetcher(baseURL: NSURL(string: "http://dev.scottraffic.co.uk")!)
        
        let dataSourceForPath : String -> CachedHTTPDataSource = { path in
            return CachedHTTPDataSource(fetcher: fetcher, cache: diskCache, path: path)
        }
        
        let userDefaults = NSUserDefaults.standardUserDefaults()

        self.diskCache = diskCache
        self.fetcher = fetcher
        self.settings = Settings(userDefaults: userDefaults)
        
        // -- Traffic Cameras --
        
        let trafficCamerasSource = dataSourceForPath("trafficcameras.json")
        let trafficCameraLocations = trafficCamerasSource.map {
            $0.map(Array<TrafficCameraLocation>.decodeJSON <== JSONArrayFromData)
        }
        self.trafficCameraLocations = valueFromEither(trafficCameraLocations).latest()
        self.favourites = Favourites(userDefaults: userDefaults, trafficCameraLocations: self.trafficCameraLocations)

        
        // -- Safety Cameras --
        
        let safetyCamerasSource = dataSourceForPath("safetycameras.json")
        let safetyCameras = safetyCamerasSource.map {
            $0.map(Array<SafetyCamera>.decodeJSON <== JSONArrayFromData)
        }
        self.safetyCameras = valueFromEither(safetyCameras).latest()
 
        
        // -- Incidents / Roadworks --
        
        let incidentsSource = dataSourceForPath("incidents.json")
        let incidents = incidentsSource.map {
            $0.map(Array<Incident>.decodeJSON <== JSONArrayFromData)
        }
        let allIncidents = valueFromEither(incidents)
        self.alerts = allIncidents.map { $0.filter { $0.type == IncidentType.Alert } }.latest()
        self.roadworks = allIncidents.map { $0.filter { $0.type == IncidentType.Roadworks } }.latest()
        
        
        // -- Weather --
        
        let weatherSource = dataSourceForPath("weather.json")
        let weather = weatherSource.map {
            $0.map(Array<Weather>.decodeJSON <== JSONArrayFromData)
        }
        self.weather = valueFromEither(weather).latest()
        
        
        // -- Merge errors from all sources
        
        self.errorSources = union(
            errorFromEither(trafficCameraLocations),
            errorFromEither(safetyCameras),
            errorFromEither(incidents),
            errorFromEither(weather)
        )
        
        internalObservers.append(self.errorSources.output({
            print($0)
        }))
        
        // -- Auto refresh --
        
        let fiveMinuteRefresh = PeriodicStarter(startables: [trafficCamerasSource, incidentsSource], period: 300)
        let halfHourlyRefresh = PeriodicStarter(startables: [safetyCamerasSource, weatherSource], period: 1800)
        self.fetchStarters = [fiveMinuteRefresh, halfHourlyRefresh]
        
        // -- Refresh on restoring internet connection
        
        internalObservers.append(fetcher.serverIsReachable.onRisingEdge({
            for starter in self.fetchStarters {
                starter.restart(fireImmediately: true)
            }
        }))
    }
    
}
