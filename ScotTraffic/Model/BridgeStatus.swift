//
//  BridgeStatus.swift
//  ScotTraffic
//
//  Created by ZBS on 06/12/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import MapKit

typealias KPH = Double

public final class BridgeStatus : MapItem {
    public let identifier: String
    public let name: String
    public let road: String
    public let message: String
    public let mapPoint: MKMapPoint
    public let iconName = "bridge"
    public let count = 1
    
    public init(identifier: String, name: String, road: String, message: String, mapPoint: MKMapPoint) {
        self.identifier = identifier
        self.name = name
        self.road = road
        self.message = message
        self.mapPoint = mapPoint
    }
}

extension BridgeStatus: JSONObjectDecodable {
    public static func decodeJSON(json: JSONObject, forKey key: JSONKey) throws -> BridgeStatus {
        return try BridgeStatus(
            identifier: json <~ "identifier",
            name: json <~ "name",
            road: json <~ "road",
            message: json <~ "message",
            mapPoint: MKMapPointForCoordinate(CLLocationCoordinate2D(latitude: json <~ "latitude", longitude: json <~ "longitude"))
        )
    }
}