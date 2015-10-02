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
    let trafficCameraLocations: Observable<Either<[TrafficCameraLocation], NSError>>
    var observations = Observations()
    
    public init() {
        self.fetcher = HTTPFetcher(baseURL: NSURL(string: "http://dev.scottraffic.co.uk")!)
        
        let trafficCamerasSource = HTTPJSONArraySource(fetcher: self.fetcher, path: "trafficcameras.json")
        self.trafficCameraLocations = trafficCamerasSource.map { $0.map(Array.decodeJSON) }

        observations.sink(self.trafficCameraLocations) {
            print($0)
        }
        
        trafficCamerasSource.start()
    }
    
}
