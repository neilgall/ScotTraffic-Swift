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
    public let showTrafficCamerasOnMap: Source<Bool>
    public let showSafetyCamerasOnMap: Source<Bool>
    public let showAlertsOnMap: Source<Bool>
    public let showRoadworksOnMap: Source<Bool>
    public let showBridgesOnMap: Source<Bool>
    public let temperatureUnit: Source<TemperatureUnit>
    
    public init(userDefaults: NSUserDefaults) {
        showTrafficCamerasOnMap = PersistentSetting(userDefaults, key: "showTrafficCamerasOnMap", defaultValue: true)
        showSafetyCamerasOnMap = PersistentSetting(userDefaults, key: "showSafetyCamerasOnMap", defaultValue: true)
        showAlertsOnMap = PersistentSetting(userDefaults, key: "showAlertsOnMap", defaultValue: true)
        showRoadworksOnMap = PersistentSetting(userDefaults, key: "showRoadworksOnMap", defaultValue: true)
        showBridgesOnMap = PersistentSetting(userDefaults, key: "showBridgesOnMap", defaultValue: true)
        temperatureUnit = PersistentSetting(userDefaults, key: "temperatureUnit", defaultValue: TemperatureUnit.Celcius)
    }
}


class PersistentSetting<T>: Source<T>, Startable {
    let userDefaults: NSUserDefaults
    let key: String
    let defaultValue: T
    
    init(_ userDefaults: NSUserDefaults, key: String, defaultValue: T) {
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

