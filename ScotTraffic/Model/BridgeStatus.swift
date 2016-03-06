//
//  BridgeStatus.swift
//  ScotTraffic
//
//  Created by ZBS on 06/12/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import MapKit

typealias KPH = Double

struct BridgeStatus: MapItem {
    let identifier: String
    let name: String
    let road: String
    let message: String
    let mapPoint: MKMapPoint
    let iconName = "bridge"
    let count = 1
}

extension BridgeStatus: Hashable {
    var hashValue: Int {
        return identifier.hashValue
    }
}

func == (lhs: BridgeStatus, rhs: BridgeStatus) -> Bool {
    return lhs.identifier == rhs.identifier
}

extension BridgeStatus {
    func notificationSettingSignalFromSettings(settings: Settings) -> Signal<Input<Bool>>? {
        let pair = settings.bridgeNotifications.filterSeq({ $0.0 == self })
        return pair.map({ $0.first!.1 })
    }
}

extension BridgeStatus: JSONObjectDecodable {
    static func decodeJSON(json: JSONObject, forKey key: JSONKey) throws -> BridgeStatus {
        return try BridgeStatus(
            identifier: json <~ "identifier",
            name: json <~ "name",
            road: json <~ "road",
            message: json <~ "message",
            mapPoint: MKMapPointForCoordinate(CLLocationCoordinate2D(latitude: json <~ "latitude", longitude: json <~ "longitude"))
        )
    }
}