//
//  SafetyCameras.swift
//  ScotTraffic
//
//  Created by Neil Gall on 03/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import CoreLocation
import MapKit

enum SpeedLimit {
    case Unknown
    case MPH20
    case MPH30
    case MPH40
    case MPH50
    case MPH60
    case MPH70
    case National
}

struct SafetyCamera: MapItem, ImageDataSource {
    let name: String
    let road: String
    let url: NSURL?
    let mapPoint: MKMapPoint
    let speedLimit: SpeedLimit
    let images: [String]
    let count: Int = 1
    let iconName = "safetycamera"
    let dataSource: DataSource
}

extension SpeedLimit: JSONValueDecodable {
    static func decodeJSON(json: JSONValue, forKey key: JSONKey) throws -> SpeedLimit {
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

struct SafetyCameraDecodeContext {
    let makeImageDataSource: String -> DataSource
    
    init(makeImageDataSource: String -> DataSource) {
        self.makeImageDataSource = makeImageDataSource
    }
}

extension SafetyCamera: JSONObjectDecodable {
    static func decodeJSON(json: JSONObject, forKey key: JSONKey) throws -> SafetyCamera {
        guard let context = json.context as? SafetyCameraDecodeContext else {
            fatalError("invalid JSON decode context")
        }
        let images: [String] = try json <~ "images"
        let dataSource = dataSourceForImages(images, factory: context.makeImageDataSource)
        
        return try SafetyCamera(
            name: json <~ "name",
            road: json <~ "road",
            url: (json <~ "url").flatMap { NSURL(string: $0) },
            mapPoint: MKMapPointForCoordinate(CLLocationCoordinate2DMake(json <~ "latitude", json <~ "longitude")),
            speedLimit: json <~ "speedLimit",
            images: images,
            dataSource: dataSource
        )
    }
}

func dataSourceForImages(images: [String], factory: String -> DataSource) -> DataSource {
    if let image = images.first {
        return factory(image)
    } else {
        return EmptyDataSource()
    }
}
