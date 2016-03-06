//
//  Incidents.swift
//  ScotTraffic
//
//  Created by Neil Gall on 03/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import CoreLocation
import MapKit

enum IncidentType {
    case Alert
    case Roadworks
}

struct Incident: MapItem {
    let type: IncidentType
    let name: String
    let road: String = ""
    let text: String
    let mapPoint: MKMapPoint
    let date: NSDate
    let url: NSURL
    let count: Int = 1
    
    var iconName: String {
        switch type {
        case .Alert: return "incident"
        case .Roadworks: return "roadworks"
        }
    }
}

extension IncidentType: JSONValueDecodable {
    static func decodeJSON(json: JSONValue, forKey key: JSONKey) throws -> IncidentType {
        guard let str = json.value as? String else {
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
    static func decodeJSON(json: JSONObject, forKey key: JSONKey) throws -> Incident {
        let dateFormatter = NSDateFormatter()
        dateFormatter.locale = NSLocale(localeIdentifier: "en_GB")
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
            name: json <~ "title" ?? "",
            text: json <~ "desc" ?? "",
            mapPoint: MKMapPointForCoordinate(CLLocationCoordinate2DMake(json <~ "lat", json <~ "lon")),
            date: date,
            url: url)
    }
}
