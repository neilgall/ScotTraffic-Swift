//
//  TodaySettings.swift
//  ScotTraffic
//
//  Created by Neil Gall on 21/11/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import Foundation

class TodaySettings {
    
    var imageIndex: PersistentSetting<Int>
 
    init(userDefaults: UserDefaultsProtocol) {
        imageIndex = userDefaults.intSetting("currentTodayImage", 0)
        imageIndex.start()
    }
}