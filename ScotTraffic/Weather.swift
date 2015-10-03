//
//  Weather.swift
//  ScotTraffic
//
//  Created by Neil Gall on 03/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import CoreLocation

public typealias WeatherLocationCode = Int
public typealias Celcius = Float
public typealias WindSpeedKPH = Float

public enum WindDirection {
    case North
    case NorthNorthEast
    case NorthEast
    case EastNorthEast
    case East
    case EastSouthEast
    case SouthEast
    case SouthSouthEast
    case South
    case SouthSouthWest
    case SouthWest
    case WestSouthWest
    case West
    case WestNorthWest
    case NorthWest
    case NorthNorthWest
}

public struct Weather {
    let identifier: Int
    let name: String
    let latitude: CLLocationDegrees
    let longitude: CLLocationDegrees
    let temperature: Celcius
    let windSpeed: WindSpeedKPH
    let windDirection: WindDirection
    let weatherType: String
}

extension WindDirection: JSONValueDecodable {
    public static func decodeJSON(json: JSONValue, forKey key: JSONKey) throws -> WindDirection {
        guard let str: String = json as? String else {
            throw JSONError.ExpectedValue(key: key, type: String.self)
        }
        switch str.lowercaseString {
        case "n"  : return .North
        case "nne": return .NorthNorthEast
        case "ne" : return .NorthEast
        case "ene": return .EastNorthEast
        case "e"  : return .East
        case "ese": return .EastSouthEast
        case "se" : return .SouthEast
        case "sse": return .SouthSouthEast
        case "s"  : return .South
        case "ssw": return .SouthSouthWest
        case "sw" : return .SouthWest
        case "wsw": return .WestSouthWest
        case "w"  : return .West
        case "wnw": return .WestNorthWest
        case "nw" : return .NorthWest
        case "nnw": return .NorthNorthWest
        default: throw JSONError.ParseError(key: key, value: str, message: "invalid wind direction")
        }
    }
}

extension Weather: JSONObjectDecodable {
    public static func decodeJSON(json: JSONObject, forKey key: JSONKey) throws -> Weather {
        return try Weather(
            identifier: json <~ "identifier",
            name: json <~ "name",
            latitude: json <~ "latitude",
            longitude: json <~ "longitude",
            temperature: json <~ "temp",
            windSpeed: json <~ "windSpeed",
            windDirection: json <~ "windDir",
            weatherType: json <~ "type"
        )
    }
}