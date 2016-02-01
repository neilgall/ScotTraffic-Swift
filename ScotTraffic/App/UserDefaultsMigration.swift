//
//  UserDefaultsMigration.swift
//  ScotTraffic
//
//  Created by Neil Gall on 21/11/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import Foundation

let hasMigratedKey = "userDefaultsMigration"
let hasMigratedValue = 1

func migrateUserDefaultsToAppGroup() {
    let appGroupUserDefaults = Configuration.sharedUserDefaults()
    guard appGroupUserDefaults.integerForKey(hasMigratedKey) < hasMigratedValue else {
        return
    }
    
    let standardUserDefaults = NSUserDefaults.standardUserDefaults()
    for (key, value) in standardUserDefaults.dictionaryRepresentation() {
        appGroupUserDefaults.setObject(value, forKey: key)
    }
    
    appGroupUserDefaults.setInteger(hasMigratedValue, forKey: hasMigratedKey)
}
