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
    public static func decodeJSON(json: JSONValue, forKey key: JSONKey) throws -> IncidentType {
        guard let str = json as? String else {
            throw JSONError.ExpectedValue(key: key, type: String.self)
        }
        switch str {
        case "incidents": return .Alert
        case "roadworks": return .Roadworks
        default: throw JSONError.ParseError(key: key, value: str, message: "should be 'incidents' or 'roadworks'")
        }
    }
}

extension Incident: JSONObjectDecodable {
    public static func decodeJSON(json: JSONObject, forKey key: JSONKey) throws -> Incident {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss z"

        let dateStr: String = try json <~ "date"
        guard let date = dateFormatter.dateFromString(dateStr) else {
            throw JSONError.ParseError(key: key, value: dateStr, message: "cannot parse date")
        }

        let urlStr: String = try json <~ "orig_link"
        guard let url = NSURL(string:urlStr) else {
            throw JSONError.ParseError(key: key, value: urlStr, message: "cannot parse URL")
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