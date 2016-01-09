//
//  BridgeStatus.swift
//  ScotTraffic
//
//  Created by ZBS on 06/12/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import MapKit

typealias KPH = Double

public final class BridgeStatus: MapItem, Hashable {
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
    
    public var hashValue: Int {
        return identifier.hashValue
    }
}

public func == (lhs: BridgeStatus, rhs: BridgeStatus) -> Bool {
    return lhs.identifier == rhs.identifier
}

extension BridgeStatus {
    func notificationSettingSignalFromSettings(settings: Settings) -> Signal<Input<Bool>>? {
        let pair = settings.bridgeNotifications.filterSeq({ $0.0 == self })
        return pair.map({ $0.first!.1 })
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