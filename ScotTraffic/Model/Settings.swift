//
//  Settings.swift
//  ScotTraffic
//
//  Created by Neil Gall on 03/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import MapKit

private let scotlandMapRect = MKMapRectMake(129244330.1, 79649811.3, 3762380.0, 6443076.1)

class Settings {
    let showTrafficOnMap: PersistentSetting<Bool>
    let showTrafficCamerasOnMap: PersistentSetting<Bool>
    let showSafetyCamerasOnMap: PersistentSetting<Bool>
    let showAlertsOnMap: PersistentSetting<Bool>
    let showRoadworksOnMap: PersistentSetting<Bool>
    let showBridgesOnMap: PersistentSetting<Bool>
    let showCurrentLocationOnMap: PersistentSetting<Bool>
    let temperatureUnit: PersistentSetting<TemperatureUnit>
    let visibleMapRect: PersistentSetting<MKMapRect>
    let bridgeNotifications: Signal<[(BridgeStatus, PersistentSetting<Bool>)]>
    
    private var receivers: [ReceiverType] = []

    init(userDefaults: UserDefaultsProtocol, bridges: Signal<[BridgeStatus]>) {
        showTrafficOnMap = userDefaults.boolSetting("showTrafficOnMap", false)
        showTrafficCamerasOnMap = userDefaults.boolSetting("showTrafficCamerasOnMap", true)
        showSafetyCamerasOnMap = userDefaults.boolSetting("showSafetyCamerasOnMap", true)
        showAlertsOnMap = userDefaults.boolSetting("showAlertsOnMap", true)
        showRoadworksOnMap = userDefaults.boolSetting("showRoadworksOnMap", true)
        showBridgesOnMap = userDefaults.boolSetting("showBridgesOnMap", true)
        showCurrentLocationOnMap = userDefaults.boolSetting("showCurrentLocationOnMap", false)
        temperatureUnit = userDefaults.enumSetting("temperatureUnit", TemperatureUnit.Celcius)
        
        visibleMapRect = userDefaults.setting("visibleMapRect", scotlandMapRect,
            to: { stringFromMapRect($0) }, from: { ($0 as? String).flatMap(mapRectFromString) })

        bridgeNotifications = bridges.mapSeq({ bridge in
            (bridge, userDefaults.boolSetting("bridgeNotifications-\(bridge.identifier)", false))
        }).latest()
        
        receivers.append(bridgeNotifications --> {
            for (_, setting) in $0 {
                setting.start()
            }
        })
        
        reload()
    }
    
    func reload() {
        showTrafficOnMap.start()
        showTrafficCamerasOnMap.start()
        showSafetyCamerasOnMap.start()
        showAlertsOnMap.start()
        showRoadworksOnMap.start()
        showBridgesOnMap.start()
        showCurrentLocationOnMap.start()
        temperatureUnit.start()
        visibleMapRect.start()
    }
}

private func stringFromMapRect(rect: MKMapRect) -> String? {
    return "\(rect.origin.x),\(rect.origin.y),\(rect.size.width),\(rect.size.height)"
}

private func mapRectFromString(str: String) -> MKMapRect? {
    let components = str.componentsSeparatedByString(",").flatMap { Double($0) }
    guard components.count == 4 else {
        return nil
    }
    return MKMapRectMake(components[0], components[1], components[2], components[3])
}

