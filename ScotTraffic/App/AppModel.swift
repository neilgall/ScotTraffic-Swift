//
//  AppModel.swift
//  ScotTraffic
//
//  Created by Neil Gall on 01/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import Foundation

class AppModel: ScotTraffic {
    
    // ScotTraffic interface
    let trafficCameraLocations: Signal<[TrafficCameraLocation]>
    let safetyCameras: Signal<[SafetyCamera]>
    let alerts: Signal<[Incident]>
    let roadworks: Signal<[Incident]>
    let bridges: Signal<[BridgeStatus]>
    let weather: Signal<WeatherFinder>
    let messageOfTheDay: Signal<MessageOfTheDay?>
    let settings: Settings
    let favourites: Favourites
    let remoteNotifications: RemoteNotifications
    
    let httpAccess: HTTPAccess

    private let diskCache: DiskCache
    private let fetchStarters: [PeriodicStarter]
    private var receivers = [ReceiverType]()
    
    init() {
        let userDefaults = Configuration.sharedUserDefaults()
        let diskCache = DiskCache(withPath: "scottraffic")
        let httpAccess = HTTPAccess(baseURL: scotTrafficBaseURL, indicator: AppNetworkActivityIndicator())
        
        let cachedDataSource = CachedHTTPDataSource.dataSourceWithHTTPAccess(httpAccess, cache: diskCache)
        let fiveMinuteCache = cachedDataSource(300)
        let fifteenMinuteCache = cachedDataSource(900)
        let dailyCache = cachedDataSource(86400)
        
        self.diskCache = diskCache
        self.httpAccess = httpAccess
        
        
        // -- Traffic Cameras --
        
        let trafficCamerasSource = fifteenMinuteCache("trafficcameras.json")
        let trafficCamerasContext = TrafficCameraDecodeContext(makeImageDataSource: fiveMinuteCache)
        let trafficCameraLocations = trafficCamerasSource.value.map {
            return $0.map(Array<TrafficCameraLocation>.decodeJSON(trafficCamerasContext) <== JSONArrayFromData)
        }
        self.trafficCameraLocations = trafficCameraLocations.map({ $0.value ?? [] }).latest()

        
        // -- Safety Cameras --
        
        let safetyCamerasSource = fifteenMinuteCache("safetycameras.json")
        let safetyCamerasContext = SafetyCameraDecodeContext(makeImageDataSource: dailyCache)
        let safetyCameras = safetyCamerasSource.value.map({
            $0.map(Array<SafetyCamera>.decodeJSON(safetyCamerasContext) <== JSONArrayFromData)
        })
        self.safetyCameras = safetyCameras.map({ $0.value ?? [] }).latest()
 
        
        // -- Incidents / Roadworks --
        
        let incidentsSource = fiveMinuteCache("incidents.json")
        let incidents = incidentsSource.value.map({
            $0.map(Array<Incident>.decodeJSON(Void) <== JSONArrayFromData)
        })
        let allIncidents = incidents.map({ $0.value ?? [] })
        self.alerts = allIncidents.map({ $0.filter({ $0.type == IncidentType.Alert }) }).latest()
        self.roadworks = allIncidents.map({ $0.filter({ $0.type == IncidentType.Roadworks }) }).latest()
        
        // -- Bridge Status --
        
        let bridgeStatusSource = fiveMinuteCache("bridges.json")
        let bridges = bridgeStatusSource.value.map({
            $0.map(Array<BridgeStatus>.decodeJSON(Void) <== JSONArrayFromData)
        })
        self.bridges = bridges.map({ $0.value ?? [] }).latest()
        
        
        // -- Weather --
        
        let weatherSource = fifteenMinuteCache("weather.json")
        let weather = weatherSource.value.map({
            $0.map(Array<Weather>.decodeJSON(Void) <== JSONArrayFromData)
        })
        self.weather = weather.map({ $0.value ?? [] }).latest().map() { (weather: [Weather]) -> WeatherFinder in
            return { (mapItem: MapItem) -> Weather? in
                let distanceSq = { (w: Weather) -> Double in w.mapPoint.distanceSqToMapPoint(mapItem.mapPoint) }
                return weather.minElement({ distanceSq($0) < distanceSq($1) })
            }
        }
        
        // -- Message of the day --
        
        let messageOfTheDaySource = HTTPDataSource(httpAccess: httpAccess, path: "message.json")
        let messageOfTheDay = messageOfTheDaySource.value.map({
            $0.map(MessageOfTheDay.decodeJSON(Void) <== JSONObjectFromData)
        })
        self.messageOfTheDay = messageOfTheDay
            .map({ $0.value })
            .filter({ $0 != nil && !userDefaults.messageOfTheDaySeenBefore($0!) })
            .latest()
        
        receivers.append(self.messageOfTheDay --> {
            if let message = $0 {
                userDefaults.noteMessageOfTheDaySeen(message)
            }
        })
        
        
        // -- Remote notifications
        
        self.remoteNotifications = RemoteNotifications(bridges: self.bridges)

        
        // -- Settings and Favourites --
        
        self.settings = Settings(userDefaults: userDefaults, bridges: self.bridges)
        self.favourites = Favourites(userDefaults: userDefaults)
        
        
        // -- Auto refresh --
        
        let fiveMinuteRefresh = PeriodicStarter(startables: [trafficCamerasSource, incidentsSource, bridgeStatusSource], period: 300)
        let halfHourlyRefresh = PeriodicStarter(startables: [safetyCamerasSource, weatherSource, messageOfTheDaySource], period: 1800)
        self.fetchStarters = [fiveMinuteRefresh, halfHourlyRefresh]
        
        
        // -- Refresh on restoring internet connection
        
        receivers.append(httpAccess.serverIsReachable.onRisingEdge({ [weak self] in
            self?.fetchStarters.forEach {
                $0.restart(fireImmediately: true)
            }
        }))
        
        // -- Error reporting
        
        let errors: Signal<AppError?> = union(
            trafficCameraLocations.map({ $0.error }),
            safetyCameras.map({ $0.error }),
            incidents.map({ $0.error }),
            weather.map({ $0.error }),
            bridges.map({ $0.error }),
            messageOfTheDay.map({ $0.error }))
        
        receivers.append(errors --> { error in
            if let error = error {
                analyticsError(error.name, error: error)
            }
        })
    }
}
