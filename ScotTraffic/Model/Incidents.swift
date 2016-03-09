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
    let road: String
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

typealias Alert = Incident
typealias Roadwork = Incident

extension Incident: JSONObjectDecodable {
    static func decodeJSON(json: JSONObject, forKey key: JSONKey) throws -> Incident {
        guard let type = json.context as? IncidentType else {
            fatalError("invalid JSON context")
        }
    
        let dateStr: String = try json <~ "date"
        guard let date = NSDateFormatter.ISO8601.dateFromString(dateStr) else {
            throw JSONError.ParseError(key: key, value: dateStr, message: "cannot parse date")
        }

        let urlStr: String = try json <~ "link"
        guard let url = NSURL(string:urlStr) else {
            throw JSONError.ParseError(key: key, value: urlStr, message: "cannot parse URL")
        }
        
        return try Incident(
            type: type,
            name: json <~ "title" ?? "",
            road: json <~ "road" ?? "",
            text: json <~ "description" ?? "",
            mapPoint: MKMapPointForCoordinate(CLLocationCoordinate2DMake(json <~ "latitude", json <~ "longitude")),
            date: date,
            url: url)
    }
}
