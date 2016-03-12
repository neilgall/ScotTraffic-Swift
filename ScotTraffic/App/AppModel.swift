//
//  AppModel.swift
//  ScotTraffic
//
//  Created by Neil Gall on 01/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import Foundation

class AppModel: ScotTraffic {
    
    typealias CacheSource = (maximumAge: NSTimeInterval) -> (filename: String) -> DataSource
    
    // ScotTraffic interface
    let trafficCameraLocations: Signal<[TrafficCameraLocation]>
    let safetyCameras: Signal<[SafetyCamera]>
    let alerts: Signal<[Alert]>
    let roadworks: Signal<[Roadwork]>
    let bridges: Signal<[BridgeStatus]>
    let weather: Signal<WeatherFinder>
    let messageOfTheDay: Signal<MessageOfTheDay?>
    let settings: Settings
    let favourites: Favourites
    let remoteNotifications: RemoteNotifications

    private let fetchStarters: [PeriodicStarter]
    private var receivers = [ReceiverType]()
    
    init(cacheSource: CacheSource, reachable: Signal<Bool>, userDefaults: UserDefaultsProtocol) {
        let fiveMinuteCache = cacheSource(maximumAge: 300)
        let fifteenMinuteCache = cacheSource(maximumAge: 900)
        let dailyCache = cacheSource(maximumAge: 86400)
        
        // -- Traffic Cameras --
        
        let trafficCamerasSource = fiveMinuteCache(filename: "trafficcameras.json")
        let trafficCamerasContext = TrafficCameraDecodeContext(makeImageDataSource: fiveMinuteCache)
        let trafficCameraLocations = trafficCamerasSource.value.map {
            return $0.map(Array<TrafficCameraLocation>.decodeJSON(trafficCamerasContext) <== JSONArrayFromData)
        }
        self.trafficCameraLocations = trafficCameraLocations.map({ $0.value ?? [] }).latest()

        
        // -- Safety Cameras --
        
        let safetyCamerasSource = fifteenMinuteCache(filename: "safetycameras.json")
        let safetyCamerasContext = SafetyCameraDecodeContext(makeImageDataSource: dailyCache)
        let safetyCameras = safetyCamerasSource.value.map({
            $0.map(Array<SafetyCamera>.decodeJSON(safetyCamerasContext) <== JSONArrayFromData)
        })
        self.safetyCameras = safetyCameras.map({ $0.value ?? [] }).latest()
 
        
        // -- Alerts --
        
        let alertsSource = fiveMinuteCache(filename: "alerts.json")
        let alerts = alertsSource.value.map({
            $0.map(Array<Alert>.decodeJSON(IncidentType.Alert) <== JSONArrayFromData)
        })
        self.alerts = alerts.map({ $0.value ?? [] }).latest()
        
        
        // -- Roadworks --
        
        let roadworksSource = fiveMinuteCache(filename: "roadworks.json")
        let roadworks = roadworksSource.value.map({
            $0.map(Array<Roadwork>.decodeJSON(IncidentType.Roadworks) <== JSONArrayFromData)
        })
        self.roadworks = roadworks.map({ $0.value ?? [] }).latest()
        
        
        // -- Bridge Status --
        
        let bridgeStatusSource = fiveMinuteCache(filename: "bridges.json")
        let bridges = bridgeStatusSource.value.map({
            $0.map(Array<BridgeStatus>.decodeJSON(Void) <== JSONArrayFromData)
        })
        self.bridges = bridges.map({ $0.value ?? [] }).latest()
        
        
        // -- Weather --
        
        let weatherSource = fifteenMinuteCache(filename: "weather.json")
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
        
        let messageOfTheDaySource = cacheSource(maximumAge: 60)(filename: "message.json")
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
        
        let fiveMinuteRefresh = PeriodicStarter(startables: [trafficCamerasSource, alertsSource, roadworksSource, bridgeStatusSource], period: 300)
        let halfHourlyRefresh = PeriodicStarter(startables: [safetyCamerasSource, weatherSource, messageOfTheDaySource], period: 1800)
        self.fetchStarters = [fiveMinuteRefresh, halfHourlyRefresh]
        
        
        // -- Refresh on restoring internet connection
        
        receivers.append(reachable.onRisingEdge({ [weak self] in
            self?.fetchStarters.forEach {
                $0.restart(fireImmediately: true)
            }
        }))
        
        
        // -- Error reporting
        
        let errors: Signal<AppError?> = union(
            trafficCameraLocations.map({ $0.error }),
            safetyCameras.map({ $0.error }),
            alerts.map({ $0.error }),
            roadworks.map({ $0.error }),
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
