//
//  SafetyCameras.swift
//  ScotTraffic
//
//  Created by Neil Gall on 03/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import CoreLocation
import MapKit

public enum SpeedLimit {
    case Unknown
    case MPH20
    case MPH30
    case MPH40
    case MPH50
    case MPH60
    case MPH70
    case National
}

public final class SafetyCamera : MapItem {
    public let name: String
    public let road: String
    public let mapPoint: MKMapPoint
    public let speedLimit: SpeedLimit
    public let weatherLocation: WeatherLocationCode
    public let images: [String]
    
    public init(name: String, road: String, speedLimit: SpeedLimit, mapPoint: MKMapPoint, weatherLocation: WeatherLocationCode, images: [String]) {
        self.name = name
        self.road = road
        self.speedLimit = speedLimit
        self.mapPoint = mapPoint
        self.weatherLocation = weatherLocation
        self.images = images
    }
}

extension SpeedLimit: JSONValueDecodable {
    public static func decodeJSON(json: JSONValue, forKey key: JSONKey) throws -> SpeedLimit {
        guard let str = json as? String else {
            throw JSONError.ExpectedValue(key: key, type: String.self)
        }
        switch str {
        case "20": return .MPH20
        case "30": return .MPH30
        case "40": return .MPH40
        case "50": return .MPH50
        case "60": return .MPH60
        case "70": return .MPH70
        case "nsl": return .National
        default: return .Unknown
        }
    }
}

extension SafetyCamera: JSONObjectDecodable {
    public static func decodeJSON(json: JSONObject, forKey key: JSONKey) throws -> SafetyCamera {
        return try SafetyCamera(
            name: json <~ "name",
            road: json <~ "road",
            speedLimit: json <~ "speedLimit",
            mapPoint: MKMapPointForCoordinate(CLLocationCoordinate2DMake(json <~ "latitude", json <~ "longitude")),
            weatherLocation: json <~ "weather",
            images: json <~ "images")
    }
}