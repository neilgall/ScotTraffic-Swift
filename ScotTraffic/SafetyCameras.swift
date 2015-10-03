//
//  SafetyCameras.swift
//  ScotTraffic
//
//  Created by Neil Gall on 03/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import CoreLocation

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

public struct SafetyCamera {
    let speedLimit: SpeedLimit
    let latitude: CLLocationDegrees
    let longitude: CLLocationDegrees
    let weatherLocation: WeatherLocationCode
    let images: [String]
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
            speedLimit: json <~ "speedLimit",
            latitude: json <~ "latitude",
            longitude: json <~ "longitude",
            weatherLocation: json <~ "weather",
            images: json <~ "images")
    }
}