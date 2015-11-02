//
//  TestAppModel.swift
//  ScotTraffic
//
//  Created by ZBS on 12/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import Foundation
import ScotTraffic

public class TestAppModel: ScotTraffic {
    
    public let trafficCameraLocations: Observable<[TrafficCameraLocation]>
    public let safetyCameras: Observable<[SafetyCamera]>
    public let alerts: Observable<[Incident]>
    public let roadworks: Observable<[Incident]>
    public let weather: Observable<[Weather]>
    public let settings: Settings
    public let favourites: Favourites
    public let userDefaults: UserDefaultsProtocol

    public init() {
        trafficCameraLocations = Input<[TrafficCameraLocation]>(initial: loadTestData("trafficcameras"))
        safetyCameras = Input<[SafetyCamera]>(initial: loadTestData("safetycameras"))
        weather = Input<[Weather]>(initial: loadTestData("weather"))
        
        let incidents = Input<[Incident]>(initial: loadTestData("incidents"))
        alerts = incidents.map { $0.filter { $0.type == .Alert } }
        roadworks = incidents.map { $0.filter { $0.type == .Roadworks } }
        
        userDefaults = TestUserDefaults()
        settings = Settings(userDefaults: userDefaults)
        favourites = Favourites(userDefaults: userDefaults, trafficCameraLocations: trafficCameraLocations)
    }    
}
    
private func loadTestData<T where T: JSONObjectDecodable>(filename: String) -> [T] {
    for bundle in NSBundle.allBundles() {
        if let path = bundle.pathForResource(filename, ofType: "json", inDirectory: "Data"), let data = NSData(contentsOfFile: path) {
            do {
                let array = try JSONArrayFromData(data)
                let context: String->DataSource = { _ in DummyDataSource() }
                return try [T].decodeJSON(JSONArray(value: array, context: context ))
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

public class TestUserDefaults: UserDefaultsProtocol {
    var userDefaults = [String:AnyObject]()

    public func objectForKey(key: String) -> AnyObject? {
        return userDefaults[key]
    }
    
    public func setObject(object: AnyObject?, forKey key: String) {
        userDefaults[key] = object
    }
    
    public func removeObjectForKey(key: String) {
        userDefaults.removeValueForKey(key)
    }
    
    public func synchronize() -> Bool {
        return true
    }
}
