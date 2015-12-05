//
//  TrafficCameras.swift
//  ScotTraffic
//
//  Created by Neil Gall on 30/09/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import CoreLocation
import MapKit

public enum TrafficCameraDirection: String {
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
    public let iconName = "camera"
    
    public init(name: String, road: String, mapPoint: MKMapPoint, cameras: [TrafficCamera]) {
        self.name = name
        self.road = road
        self.mapPoint = mapPoint
        self.cameras = cameras
    }
    
    public var count: Int {
        return cameras.count
    }
    
    public func indexOfCameraWithIdentifier(identifier: String) -> Int? {
        return cameras.indexOf { $0.identifier == identifier }
    }
}

public final class TrafficCamera : ImageDataSource {
    public let identifier: String
    public let direction: TrafficCameraDirection?
    public let isAvailable: Bool
    public let dataSource: DataSource
    
    public init(identifier: String, direction: TrafficCameraDirection?, isAvailable: Bool, dataSourceFactory: String->DataSource) {
        self.identifier = identifier
        self.direction = direction
        self.isAvailable = isAvailable
        self.dataSource = dataSourceFactory(identifier)
    }
}

public func == (a: TrafficCamera, b: TrafficCamera) -> Bool {
    return a.identifier == b.identifier
}

func trafficCameraName(camera: TrafficCamera, atLocation location: TrafficCameraLocation) -> String {
    if let direction = camera.direction {
        return "\(location.name) \(direction.rawValue)"
    
    } else if let index = location.cameras.indexOf({ $0 === camera }) where location.cameras.count > 1 {
        return "\(location.name) Camera \(index+1)"

    } else {
        return location.name
    }
}

extension TrafficCameraDirection: JSONValueDecodable {
    public static func decodeJSON(json: JSONValue, forKey key: JSONKey) throws -> TrafficCameraDirection {
        guard let dir = json.value as? String else {
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

public struct TrafficCameraDecodeContext {
    let makeImageDataSource: String -> DataSource
    
    public init(makeImageDataSource: String -> DataSource) {
        self.makeImageDataSource = makeImageDataSource
    }
}

extension TrafficCamera: JSONObjectDecodable {
    public static func decodeJSON(json: JSONObject, forKey key: JSONKey) throws -> TrafficCamera {
        guard let context = json.context as? TrafficCameraDecodeContext else {
            fatalError("invalid JSON decode context")
        }
        return try TrafficCamera(
            identifier: json <~ "image",
            direction: json <~ "direction",
            isAvailable: json <~ "available",
            dataSourceFactory: context.makeImageDataSource
        )
    }
}
