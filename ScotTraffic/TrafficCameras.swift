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
    
    public static func parse(d: String) -> TrafficCameraDirection? {
        switch d.lowercaseString {
        case "north": return .North
        case "south": return .South
        case "east":  return .East
        case "west":  return .West
        default: return nil
        }
    }
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

extension TrafficCameraLocation: JSONObjectDecodable {
    public static func decodeJSON(json: JSON) throws -> TrafficCameraLocation {
        return try TrafficCameraLocation(
            name: json <~ "name",
            road: json <~ "road",
            latitude: json <~ "latitude",
            longitude: json <~ "longitude",
            cameras: json <~ "cameras")
    }
}

extension TrafficCamera: JSONObjectDecodable {
    public static func decodeJSON(json: JSON) throws -> TrafficCamera {
        let direction: String? = try json <~ "direction"
        return try TrafficCamera(
            direction: direction != nil ? TrafficCameraDirection.parse(direction!) : nil,
            identifier: json <~ "identifier")
    }
}