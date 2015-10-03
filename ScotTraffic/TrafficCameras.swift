//
//  TrafficCameras.swift
//  ScotTraffic
//
//  Created by Neil Gall on 30/09/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import CoreLocation
import MapKit

public enum TrafficCameraDirection {
    case North
    case South
    case East
    case West
}

public final class TrafficCameraLocation : MapItem {
    public let name: String
    public let road: String
    public let mapPoint: MKMapPoint
    public let cameras: [TrafficCamera]
    
    public init(name: String, road: String, mapPoint: MKMapPoint, cameras: [TrafficCamera]) {
        self.name = name
        self.road = road
        self.mapPoint = mapPoint
        self.cameras = cameras
    }
}

public final class TrafficCamera {
    public let identifier: String
    public let direction: TrafficCameraDirection?
    
    public init(identifier: String, direction: TrafficCameraDirection?) {
        self.identifier = identifier
        self.direction = direction
    }
}

extension TrafficCameraDirection: JSONValueDecodable {
    public static func decodeJSON(json: JSONValue, forKey key: JSONKey) throws -> TrafficCameraDirection {
        guard let dir = json as? String else {
            throw JSONError.ExpectedValue(key: key, type: String.self)
        }
        switch dir.lowercaseString {
        case "n": return .North
        case "s": return .South
        case "e":  return .East
        case "w":  return .West
        default:
            throw JSONError.ParseError(key: key, value: dir, message: "should be one of N,S,E,W")
        }
    }
}

extension TrafficCameraLocation: JSONObjectDecodable {
    public static func decodeJSON(json: JSONObject, forKey key: JSONKey) throws -> TrafficCameraLocation {
        return try TrafficCameraLocation(
            name: json <~ "name",
            road: json <~ "road",
            mapPoint: MKMapPointForCoordinate(CLLocationCoordinate2DMake(json <~ "latitude", json <~ "longitude")),
            cameras: json <~ "cameras"
        )
    }
}

extension TrafficCamera: JSONObjectDecodable {
    public static func decodeJSON(json: JSONObject, forKey key: JSONKey) throws -> TrafficCamera {
        return try TrafficCamera(
            identifier: json <~ "image",
            direction: json <~ "direction"
        )
    }
}
