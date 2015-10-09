//
//  AppModel.swift
//  ScotTraffic
//
//  Created by Neil Gall on 01/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import Foundation

public class AppModel {
    let fetcher: HTTPFetcher
    
    let trafficCameraLocations: Observable<[TrafficCameraLocation]>
    let safetyCameras: Observable<[SafetyCamera]>
    let alerts: Observable<[Incident]>
    let roadworks: Observable<[Incident]>
    let weather: Observable<[Weather]>
    let settings: Settings
    let favourites: Favourites
    
    let errorSources: Observable<AppError>
    let fetchStarters: [PeriodicStarter]
    var internalObservers = Observations()
    
    public init() {
        self.fetcher = HTTPFetcher(baseURL: NSURL(string: "http://dev.scottraffic.co.uk")!)
        
        let userDefaults = NSUserDefaults.standardUserDefaults()
        self.settings = Settings(userDefaults: userDefaults)

        
        // -- Traffic Cameras --
        
        let trafficCamerasSource = HTTPDataSource(fetcher: self.fetcher, path: "trafficcameras.json")
        let trafficCameraLocations = trafficCamerasSource.map {
            $0.map(Array<TrafficCameraLocation>.decodeJSON <== JSONArrayFromData)
        }
        self.trafficCameraLocations = valueFromEither(trafficCameraLocations).latest()
        self.favourites = Favourites(userDefaults: userDefaults, trafficCameraLocations: self.trafficCameraLocations)

        
        // -- Safety Cameras --
        
        let safetyCamerasSource = HTTPDataSource(fetcher: self.fetcher, path: "safetycameras.json")
        let safetyCameras = safetyCamerasSource.map {
            $0.map(Array<SafetyCamera>.decodeJSON <== JSONArrayFromData)
        }
        self.safetyCameras = valueFromEither(safetyCameras).latest()
 
        
        // -- Incidents / Roadworks --
        
        let incidentsSource = HTTPDataSource(fetcher: self.fetcher, path: "incidents.json")
        let incidents = incidentsSource.map {
            $0.map(Array<Incident>.decodeJSON <== JSONArrayFromData)
        }
        let allIncidents = valueFromEither(incidents)
        self.alerts = allIncidents.map { $0.filter { $0.type == IncidentType.Alert } }.latest()
        self.roadworks = allIncidents.map { $0.filter { $0.type == IncidentType.Roadworks } }.latest()
        
        
        // -- Weather --
        
        let weatherSource = HTTPDataSource(fetcher: self.fetcher, path: "weather.json")
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
        
        internalObservers.add(self.errorSources) {
            print($0)
        }
        
        // -- Auto refresh --
        
        let fiveMinuteRefresh = PeriodicStarter(startables: [trafficCamerasSource, incidentsSource], period: 300)
        let halfHourlyRefresh = PeriodicStarter(startables: [safetyCamerasSource, weatherSource], period: 1800)
        self.fetchStarters = [fiveMinuteRefresh, halfHourlyRefresh]
    }
}