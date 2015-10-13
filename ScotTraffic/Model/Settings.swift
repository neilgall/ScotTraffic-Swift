//
//  Settings.swift
//  ScotTraffic
//
//  Created by Neil Gall on 03/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import Foundation

public enum TemperatureUnit: String {
    case Celcius
    case Fahrenheit
}

public class Settings {
    public let showTrafficCamerasOnMap: Input<Bool>
    public let showSafetyCamerasOnMap: Input<Bool>
    public let showAlertsOnMap: Input<Bool>
    public let showRoadworksOnMap: Input<Bool>
    public let showBridgesOnMap: Input<Bool>
    public let temperatureUnit: Input<TemperatureUnit>
    
    public init(userDefaults: UserDefaultsProtocol) {
        showTrafficCamerasOnMap = PersistentSetting(userDefaults, key: "showTrafficCamerasOnMap", defaultValue: true)
        showSafetyCamerasOnMap = PersistentSetting(userDefaults, key: "showSafetyCamerasOnMap", defaultValue: true)
        showAlertsOnMap = PersistentSetting(userDefaults, key: "showAlertsOnMap", defaultValue: true)
        showRoadworksOnMap = PersistentSetting(userDefaults, key: "showRoadworksOnMap", defaultValue: true)
        showBridgesOnMap = PersistentSetting(userDefaults, key: "showBridgesOnMap", defaultValue: true)
        temperatureUnit = PersistentSetting(userDefaults, key: "temperatureUnit", defaultValue: TemperatureUnit.Celcius)
    }
}


class PersistentSetting<T>: Input<T>, Startable {
    let userDefaults: UserDefaultsProtocol
    let key: String
    let defaultValue: T
    
    init(_ userDefaults: UserDefaultsProtocol, key: String, defaultValue: T) {
        self.userDefaults = userDefaults
        self.key = key
        self.defaultValue = defaultValue
        super.init(initial: defaultValue)
    }
    
    func start() {
        // TODO: load from userDefaults
    }
    
    // TODO: persistence
}

