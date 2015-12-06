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
    public let bridges: Observable<[BridgeStatus]>
    public let weather: Observable<WeatherFinder>
    public let settings: Settings
    public let favourites: Favourites
    
    public let fetcher: HTTPFetcher

    private let diskCache: DiskCache
    private let fetchStarters: [PeriodicStarter]
    private var observers = [Observation]()
    
    public init() {
        let diskCache = DiskCache(withPath: "scottraffic")
        let fetcher = HTTPFetcher(baseURL: ScotTrafficBaseURL, indicator: AppNetworkActivityIndicator())
        
        let cachedDataSource = CachedHTTPDataSource.dataSourceWithFetcher(fetcher, cache: diskCache)
        
        guard let userDefaults = NSUserDefaults(suiteName: ScotTrafficAppGroup) else {
            fatalError("unable to create NSUserDefaults with suite name \(ScotTrafficAppGroup)")
        }

        self.diskCache = diskCache
        self.fetcher = fetcher
        self.settings = Settings(userDefaults: userDefaults)
        
        
        // -- Traffic Cameras --
        
        let trafficCamerasSource = cachedDataSource(maximumCacheAge: 900)(path: "trafficcameras.json")
        let trafficCamerasContext = TrafficCameraDecodeContext(makeImageDataSource: cachedDataSource(maximumCacheAge: 300))
        let trafficCameraLocations = trafficCamerasSource.value.map {
            return $0.map(Array<TrafficCameraLocation>.decodeJSON(trafficCamerasContext) <== JSONArrayFromData)
        }
        self.trafficCameraLocations = trafficCameraLocations.map({ $0.value ?? [] }).latest()

        self.favourites = Favourites(userDefaults: userDefaults, trafficCameraLocations: self.trafficCameraLocations)

        
        // -- Safety Cameras --
        
        let safetyCamerasSource = cachedDataSource(maximumCacheAge: 900)(path: "safetycameras.json")
        let safetyCamerasContext = SafetyCameraDecodeContext(makeImageDataSource: cachedDataSource(maximumCacheAge: 86400))
        let safetyCameras = safetyCamerasSource.value.map {
            $0.map(Array<SafetyCamera>.decodeJSON(safetyCamerasContext) <== JSONArrayFromData)
        }
        self.safetyCameras = safetyCameras.map({ $0.value ?? [] }).latest()
 
        
        // -- Incidents / Roadworks --
        
        let incidentsSource = cachedDataSource(maximumCacheAge: 300)(path: "incidents.json")
        let incidents = incidentsSource.value.map {
            $0.map(Array<Incident>.decodeJSON(Void) <== JSONArrayFromData)
        }
        let allIncidents = incidents.map({ $0.value ?? [] })
        self.alerts = allIncidents.map({ $0.filter({ $0.type == IncidentType.Alert }) }).latest()
        self.roadworks = allIncidents.map({ $0.filter({ $0.type == IncidentType.Roadworks }) }).latest()
        
        // -- Bridge Status --
        
        let bridgeStatusSource = cachedDataSource(maximumCacheAge: 600)(path: "bridges.json")
        let bridges = bridgeStatusSource.value.map {
            $0.map(Array<BridgeStatus>.decodeJSON(Void) <== JSONArrayFromData)
        }
        self.bridges = bridges.map({ $0.value ?? [] }).latest()
        
        
        // -- Weather --
        
        let weatherSource = cachedDataSource(maximumCacheAge: 900)(path: "weather.json")
        let weather = weatherSource.value.map {
            $0.map(Array<Weather>.decodeJSON(Void) <== JSONArrayFromData)
        }
        self.weather = weather.map({ $0.value ?? [] }).latest().map() { (weather: [Weather]) -> WeatherFinder in
            return { (mapItem: MapItem) -> Weather? in
                let distanceSq = { (w: Weather) -> Double in w.mapPoint.distanceSqToMapPoint(mapItem.mapPoint) }
                return weather.minElement( { distanceSq($0) < distanceSq($1) })
            }
        }
        
        
        // -- Auto refresh --
        
        let fiveMinuteRefresh = PeriodicStarter(startables: [trafficCamerasSource, incidentsSource, bridgeStatusSource], period: 300)
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

