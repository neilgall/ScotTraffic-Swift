//
//  StubAppModel.swift
//  ScotTraffic
//
//  Created by ZBS on 12/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import Foundation
@testable import ScotTraffic

class StubAppModel: ScotTraffic {
    
    let trafficCameraLocations: Signal<[TrafficCameraLocation]>
    let safetyCameras: Signal<[SafetyCamera]>
    let alerts: Signal<[Incident]>
    let roadworks: Signal<[Incident]>
    let bridges: Signal<[BridgeStatus]>
    let weather: Signal<WeatherFinder>
    let settings: Settings
    let favourites: Favourites
    let userDefaults: UserDefaultsProtocol

    init() {
        let trafficCameraDummyContext = TrafficCameraDecodeContext(makeImageDataSource: { _ in DummyDataSource() })
        let safetyCameraDummyContext = SafetyCameraDecodeContext(makeImageDataSource: { _ in DummyDataSource() })
        
        trafficCameraLocations = Input<[TrafficCameraLocation]>(initial: loadTestData("trafficcameras", context: trafficCameraDummyContext))
        safetyCameras = Input<[SafetyCamera]>(initial: loadTestData("safetycameras", context: safetyCameraDummyContext))

        let weatherItems = Input<[Weather]>(initial: loadTestData("weather", context: ()))
        weather = weatherItems.map { weather in
            return { mapItems in nil }
        }
        
        alerts = Input<[Alert]>(initial: loadTestData("alerts", context: IncidentType.Alert))
        roadworks = Input<[Roadwork]>(initial: loadTestData("roadworks", context: IncidentType.Roadworks))
        bridges = Input<[BridgeStatus]>(initial: loadTestData("bridges", context: ()))
        
        userDefaults = StubUserDefaults()
        settings = Settings(userDefaults: userDefaults, bridges: bridges)
        favourites = Favourites(userDefaults: userDefaults)
    }
    
    func trafficCameraLocationNamed(name: String) -> TrafficCameraLocation? {
        return trafficCameraLocations.latestValue.get?.filter({ $0.name == name }).first
    }
}
    
private func loadTestData<T, C where T: JSONObjectDecodable>(filename: String, context: C) -> [T] {
    for bundle in NSBundle.allBundles() {
        if let path = bundle.pathForResource(filename, ofType: "json", inDirectory: "Data"), let data = NSData(contentsOfFile: path) {
            do {
                let array = try JSONArrayFromData(data)
                return try [T].decodeJSON(JSONArray(value: array, context: context))
            } catch {
            }
        }
    }
    fatalError("unable to find \(filename).json")
}

private class DummyDataSource: DataSource {
    var value: Signal<DataSourceData> = Input(initial: .Empty)
    
    func start() {
    }
}

