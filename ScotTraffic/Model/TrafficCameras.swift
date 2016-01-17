//
//  TrafficCameras.swift
//  ScotTraffic
//
//  Created by Neil Gall on 30/09/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import CoreLocation
import MapKit

enum TrafficCameraDirection: String {
    case North
    case South
    case East
    case West
}

typealias TrafficCameraIndex = Int

final class TrafficCameraLocation: MapItem {
    let name: String
    let road: String
    let mapPoint: MKMapPoint
    let cameras: [TrafficCamera]
    let iconName = "camera"
    
    init(name: String, road: String, mapPoint: MKMapPoint, cameras: [TrafficCamera]) {
        self.name = name
        self.road = road
        self.mapPoint = mapPoint
        self.cameras = cameras
    }
    
    var count: Int {
        return cameras.count
    }
    
    var cameraIdentifiers: Set<String> {
        return Set(cameras.map({ $0.identifier }))
    }
    
    func indexOfCameraWithIdentifier(identifier: String) -> Int? {
        return cameras.indexOf({ $0.identifier == identifier })
    }
}

final class TrafficCamera: ImageDataSource {
    let identifier: String
    let direction: TrafficCameraDirection?
    let isAvailable: Bool
    let dataSource: DataSource
    
    init(identifier: String, direction: TrafficCameraDirection?, isAvailable: Bool, dataSourceFactory: String->DataSource) {
        self.identifier = identifier
        self.direction = direction
        self.isAvailable = isAvailable
        self.dataSource = dataSourceFactory(identifier)
    }
}

func == (a: TrafficCamera, b: TrafficCamera) -> Bool {
    return a.identifier == b.identifier
}

extension TrafficCameraLocation {
    func nameAtIndex(index: TrafficCameraIndex) -> String {
        if let direction = cameras[index].direction {
            return "\(name) \(direction.rawValue)"
        
        } else if cameras.count > 1 {
            return "\(name) Camera \(index+1)"

        } else {
            return name
        }
    }
}

extension SequenceType where Generator.Element: TrafficCameraLocation {
    func findIdentifier(identifier: String) -> (location: TrafficCameraLocation, cameraIndex: TrafficCameraIndex)? {
        return flatMap({ (location: TrafficCameraLocation) -> (location: TrafficCameraLocation, cameraIndex: TrafficCameraIndex)? in
            guard let cameraIndex = location.indexOfCameraWithIdentifier(identifier) else {
                return nil
            }
            return (location: location, cameraIndex: cameraIndex)
        }).first
    }
}

extension TrafficCameraDirection: JSONValueDecodable {
    static func decodeJSON(json: JSONValue, forKey key: JSONKey) throws -> TrafficCameraDirection {
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
    static func decodeJSON(json: JSONObject, forKey key: JSONKey) throws -> TrafficCameraLocation {
        return try TrafficCameraLocation(
            name: json <~ "name",
            road: json <~ "road",
            mapPoint: MKMapPointForCoordinate(CLLocationCoordinate2DMake(json <~ "latitude", json <~ "longitude")),
            cameras: json <~ "cameras"
        )
    }
}

struct TrafficCameraDecodeContext {
    let makeImageDataSource: String -> DataSource
    
    init(makeImageDataSource: String -> DataSource) {
        self.makeImageDataSource = makeImageDataSource
    }
}

extension TrafficCamera: JSONObjectDecodable {
    static func decodeJSON(json: JSONObject, forKey key: JSONKey) throws -> TrafficCamera {
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
