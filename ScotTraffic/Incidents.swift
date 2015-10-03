//
//  Incidents.swift
//  ScotTraffic
//
//  Created by Neil Gall on 03/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import CoreLocation

public enum IncidentType {
    case Alert
    case Roadworks
}

public struct Incident {
    let type: IncidentType
    let title: String
    let text: String
    let latitude: CLLocationDegrees
    let longitude: CLLocationDegrees
    let date: NSDate
    let url: NSURL
}

extension IncidentType: JSONValueDecodable {
    public static func decodeJSON(json: JSONValue) throws -> IncidentType {
        guard let str = json as? String else {
            throw JSONError.ExpectedValue
        }
        switch str {
        case "incidents": return .Alert
        case "roadworks": return .Roadworks
        default: throw JSONError.ParseError
        }
    }
}

extension Incident: JSONObjectDecodable {
    public static func decodeJSON(json: JSONObject) throws -> Incident {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss z"
        guard let date = dateFormatter.dateFromString(try json <~ "date") else {
            throw JSONError.ParseError
        }
        guard let url = NSURL(string:try json <~ "orig_link") else {
            throw JSONError.ParseError
        }
        return try Incident(
            type: json <~ "type",
            title: json <~ "title",
            text: json <~ "desc",
            latitude: json <~ "lat",
            longitude: json <~ "lon",
            date: date,
            url: url)
    }
}