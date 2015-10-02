//
//  TrafficCameras.swift
//  ScotTraffic
//
//  Created by Neil Gall on 30/09/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import CoreLocation

public enum TrafficCameraDirection {
    case North
    case South
    case East
    case West
}

public struct TrafficCameraLocation {
    let name: String
    let road: String
    let latitude: CLLocationDegrees
    let longitude: CLLocationDegrees
    let cameras: [TrafficCamera]
}

public struct TrafficCamera {
    let direction: TrafficCameraDirection?
    let identifier: String
}

extension TrafficCameraDirection: JSONValueDecodable {
    public static func decodeJSON(json: JSONValue) throws -> TrafficCameraDirection {
        guard let dir = json as? String else {
            throw JSONError.ExpectedValue
        }
        switch dir.lowercaseString {
        case "n": return .North
        case "s": return .South
        case "e":  return .East
        case "w":  return .West
        default:
            throw JSONError.ExpectedValue
        }
    }
}

extension TrafficCameraLocation: JSONObjectDecodable {
    public static func decodeJSON(json: JSONObject) throws -> TrafficCameraLocation {
        return try TrafficCameraLocation(
            name: json <~ "name",
            road: json <~ "road",
            latitude: json <~ "latitude",
            longitude: json <~ "longitude",
            cameras: json <~ "cameras")
    }
}

extension TrafficCamera: JSONObjectDecodable {
    public static func decodeJSON(json: JSONObject) throws -> TrafficCamera {
        return try TrafficCamera(
            direction: json <~ "direction",
            identifier: json <~ "image")
    }
}
