//
//  TestAppModel.swift
//  ScotTraffic
//
//  Created by ZBS on 12/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import Foundation
import ScotTraffic

class TestAppModel: ScotTraffic {
    
    let trafficCameraLocations: Observable<[TrafficCameraLocation]>
    let safetyCameras: Observable<[SafetyCamera]>
    let alerts: Observable<[Incident]>
    let roadworks: Observable<[Incident]>
    let weather: Observable<WeatherFinder>
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
        
        let incidents = Input<[Incident]>(initial: loadTestData("incidents", context: ()))
        alerts = incidents.map { $0.filter { $0.type == .Alert } }
        roadworks = incidents.map { $0.filter { $0.type == .Roadworks } }
        
        userDefaults = TestUserDefaults()
        settings = Settings(userDefaults: userDefaults)
        favourites = Favourites(userDefaults: userDefaults, trafficCameraLocations: trafficCameraLocations)
    }
    
    func trafficCameraLocationNamed(name: String) -> TrafficCameraLocation? {
        return trafficCameraLocations.pullValue?.filter({ $0.name == name }).first
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
    var value: Observable<Either<NSData, NetworkError>> = Input(initial: .Value(NSData()))
    
    func start() {
    }
}

class TestUserDefaults: UserDefaultsProtocol {
    var userDefaults = [String:AnyObject]()

    func objectForKey(key: String) -> AnyObject? {
        return userDefaults[key]
    }
    
    func setObject(object: AnyObject?, forKey key: String) {
        userDefaults[key] = object
    }
    
    func removeObjectForKey(key: String) {
        userDefaults.removeValueForKey(key)
    }
    
    func synchronize() -> Bool {
        return true
    }
}
