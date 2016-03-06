//
//  Weather.swift
//  ScotTraffic
//
//  Created by Neil Gall on 03/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import MapKit

typealias Celcius = Float
typealias WindSpeedKPH = Float

enum TemperatureUnit: Int {
    case Celcius
    case Fahrenheit
}

enum WindDirection {
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

enum WeatherType: String {
    case Clear = "clear"
    case PartCloudy = "part-cloudy"
    case Mist = "mist"
    case Fog = "fog"
    case Cloudy = "cloudy"
    case Overcast = "overcast"
    case LightRainShower = "light-rain-shower"
    case Drizzle = "drizzle"
    case LightRain = "light-rain"
    case HeavyRainShower = "heavy-rain-shower"
    case HeavyRain = "heavy-rain"
    case SleetShower = "sleet-shower"
    case Sleet = "sleet"
    case HailShower = "hail-shower"
    case Hail = "hail"
    case LightSnowShower = "light-snow-shower"
    case LightSnow = "light-snow"
    case HeavySnowShower = "heavy-snow-shower"
    case HeavySnow = "heavy-snow"
    case ThunderShower = "thunder-shower"
    case Thunder = "thunder"
    case Unknown = "unknown"
}

struct Weather {
    let name: String
    let mapPoint: MKMapPoint
    let temperature: Celcius
    let windSpeed: WindSpeedKPH
    let windDirection: WindDirection
    let weatherType: WeatherType
    
    var temperatureFahrenheit: Float {
        return temperature * 1.8 + 32
    }
}

extension WindDirection: JSONValueDecodable {
    static func decodeJSON(json: JSONValue, forKey key: JSONKey) throws -> WindDirection {
        guard let str: String = json.value as? String else {
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
    static func decodeJSON(json: JSONObject, forKey key: JSONKey) throws -> Weather {
        return try Weather(
            name: json <~ "name",
            mapPoint: MKMapPointForCoordinate(CLLocationCoordinate2D(latitude: json <~ "latitude", longitude: json <~ "longitude")),
            temperature: json <~ "temp",
            windSpeed: json <~ "windSpeed",
            windDirection: json <~ "windDir",
            weatherType: WeatherType(rawValue: json <~ "type") ?? .Unknown
        )
    }
}