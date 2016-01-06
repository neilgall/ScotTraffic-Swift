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

public final class SafetyCamera: MapItem, ImageDataSource {
    public let name: String
    public let road: String
    public let url: NSURL?
    public let mapPoint: MKMapPoint
    public let speedLimit: SpeedLimit
    public let images: [String]
    public let count: Int = 1
    public let iconName = "safetycamera"
    public let dataSource: DataSource
    
    public init(name: String, road: String, url: NSURL?, speedLimit: SpeedLimit, mapPoint: MKMapPoint, images: [String], dataSourceFactory: String->DataSource) {
        self.name = name
        self.road = road
        self.url = url
        self.speedLimit = speedLimit
        self.mapPoint = mapPoint
        self.images = images
        
        if let image = images.first {
            self.dataSource = dataSourceFactory(image)
        } else {
            self.dataSource = EmptyDataSource()
        }
    }
}

extension SpeedLimit: JSONValueDecodable {
    public static func decodeJSON(json: JSONValue, forKey key: JSONKey) throws -> SpeedLimit {
        guard let str = json.value as? String else {
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

public struct SafetyCameraDecodeContext {
    let makeImageDataSource: String -> DataSource
    
    public init(makeImageDataSource: String -> DataSource) {
        self.makeImageDataSource = makeImageDataSource
    }
}

extension SafetyCamera: JSONObjectDecodable {
    public static func decodeJSON(json: JSONObject, forKey key: JSONKey) throws -> SafetyCamera {
        guard let context = json.context as? SafetyCameraDecodeContext else {
            fatalError("invalid JSON decode context")
        }
        return try SafetyCamera(
            name: json <~ "name",
            road: json <~ "road",
            url: (json <~ "url").flatMap { NSURL(string: $0) },
            speedLimit: json <~ "speedLimit",
            mapPoint: MKMapPointForCoordinate(CLLocationCoordinate2DMake(json <~ "latitude", json <~ "longitude")),
            images: json <~ "images",
            dataSourceFactory: context.makeImageDataSource
        )
    }
}