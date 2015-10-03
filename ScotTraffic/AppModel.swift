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
    let incidents: Observable<[Incident]>
    let weather: Observable<[Weather]>
    let errorSources: Observable<AppError>
    var observations = Observations()
    
    public init() {
        self.fetcher = HTTPFetcher(baseURL: NSURL(string: "http://dev.scottraffic.co.uk")!)

        // -- Traffic Cameras --
        
        let trafficCamerasSource = HTTPDataSource(fetcher: self.fetcher, path: "trafficcameras.json")
        let trafficCameraLocations = trafficCamerasSource.map {
            $0.map(Array<TrafficCameraLocation>.decodeJSON <== JSONArrayFromData)
        }
        self.trafficCameraLocations = valueFromEither(trafficCameraLocations)
        
        
        // -- Safety Cameras --
        
        let safetyCamerasSource = HTTPDataSource(fetcher: self.fetcher, path: "safetycameras.json")
        let safetyCameras = safetyCamerasSource.map {
            $0.map(Array<SafetyCamera>.decodeJSON <== JSONArrayFromData)
        }
        self.safetyCameras = valueFromEither(safetyCameras)
 
        
        // -- Incidents / Roadworks --
        
        let incidentsSource = HTTPDataSource(fetcher: self.fetcher, path: "incidents.json")
        let incidents = incidentsSource.map {
            $0.map(Array<Incident>.decodeJSON <== JSONArrayFromData)
        }
        self.incidents = valueFromEither(incidents)
        
        
        // -- Weather --
        
        let weatherSource = HTTPDataSource(fetcher: self.fetcher, path: "weather.json")
        let weather = weatherSource.map {
            $0.map(Array<Weather>.decodeJSON <== JSONArrayFromData)
        }
        self.weather = valueFromEither(weather)
        
        
        // -- Merge errors from all sources
        
        self.errorSources = union(
            errorFromEither(trafficCameraLocations),
            errorFromEither(safetyCameras),
            errorFromEither(incidents),
            errorFromEither(weather)
        )
        
        
        // --

        observations.add(self.trafficCameraLocations) { _ in
        }
        observations.add(self.safetyCameras) { _ in
        }
        observations.add(self.incidents) { _ in
        }
        observations.add(self.weather) {
            print($0)
        }
        observations.add(self.errorSources) {
            print($0)
        }

        trafficCamerasSource.start()
        safetyCamerasSource.start()
        incidentsSource.start()
        weatherSource.start()
    }
}
