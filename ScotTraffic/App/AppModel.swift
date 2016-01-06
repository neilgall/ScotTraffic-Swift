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
    public let trafficCameraLocations: Signal<[TrafficCameraLocation]>
    public let safetyCameras: Signal<[SafetyCamera]>
    public let alerts: Signal<[Incident]>
    public let roadworks: Signal<[Incident]>
    public let bridges: Signal<[BridgeStatus]>
    public let weather: Signal<WeatherFinder>
    public let settings: Settings
    public let favourites: Favourites
    
    public let httpAccess: HTTPAccess

    private let diskCache: DiskCache
    private let fetchStarters: [PeriodicStarter]
    private var receivers = [ReceiverType]()
    
    public init() {
        let diskCache = DiskCache(withPath: "scottraffic")
        let httpAccess = HTTPAccess(baseURL: scotTrafficBaseURL, indicator: AppNetworkActivityIndicator())
        
        let cachedDataSource = CachedHTTPDataSource.dataSourceWithHTTPAccess(httpAccess, cache: diskCache)
        
        guard let userDefaults = NSUserDefaults(suiteName: scotTrafficAppGroup) else {
            fatalError("unable to create NSUserDefaults with suite name \(scotTrafficAppGroup)")
        }

        self.diskCache = diskCache
        self.httpAccess = httpAccess
        
        
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
        
        let bridgeStatusSource = cachedDataSource(maximumCacheAge: 1)(path: "bridges.json")
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
                return weather.minElement({ distanceSq($0) < distanceSq($1) })
            }
        }
        
        // -- Settings
        
        self.settings = Settings(userDefaults: userDefaults, bridges: self.bridges)
        
        
        // -- Auto refresh --
        
        let fiveMinuteRefresh = PeriodicStarter(startables: [trafficCamerasSource, incidentsSource, bridgeStatusSource], period: 300)
        let halfHourlyRefresh = PeriodicStarter(startables: [safetyCamerasSource, weatherSource], period: 1800)
        self.fetchStarters = [fiveMinuteRefresh, halfHourlyRefresh]
        
        
        // -- Refresh on restoring internet connection
        
        self.receivers.append(httpAccess.serverIsReachable.onRisingEdge({ [weak self] in
            self?.fetchStarters.forEach {
                $0.restart(fireImmediately: true)
            }
        }))
    }
}
