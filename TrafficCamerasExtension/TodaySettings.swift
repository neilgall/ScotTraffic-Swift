//
//  TodaySettings.swift
//  ScotTraffic
//
//  Created by Neil Gall on 21/11/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import Foundation

class TodaySettings {
    
    let imageIndex: PersistentSetting<Int>
    let temperatureUnit: PersistentSetting<TemperatureUnit>

    init(userDefaults: UserDefaultsProtocol) {
        imageIndex = userDefaults.intSetting("currentTodayImage", 0)
        temperatureUnit = userDefaults.enumSetting("temperatureUnit", TemperatureUnit.Celcius)
        reload()
    }
    
    func reload() {
        imageIndex.start()
        temperatureUnit.start()
    }
}