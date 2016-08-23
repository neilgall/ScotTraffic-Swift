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

let hasMigratedToiCloudKey = "hasMigratedToiCloud"

func migrateUserDefaultsToAppGroup() {
    let appGroupUserDefaults = Configuration.sharedUserDefaults
    guard appGroupUserDefaults.integerForKey(hasMigratedKey) < hasMigratedValue else {
        return
    }
    
    let standardUserDefaults = NSUserDefaults.standardUserDefaults()
    for (key, value) in standardUserDefaults.dictionaryRepresentation() {
        appGroupUserDefaults.setObject(value, forKey: key)
    }
    
    appGroupUserDefaults.setInteger(hasMigratedValue, forKey: hasMigratedKey)
}

func migrateUserDefaultsToiCloud() {
    let localUserDefaults = Configuration.sharedUserDefaults
    let iCloudUserDefaults = Configuration.iCloudUserDefaults

    // if this device has already migrated to icloud, stop
    guard localUserDefaults.boolForKey(hasMigratedToiCloudKey) == false else {
        return
    }
    
    // if another device has migrated to icloud already, merge the favourites
    if iCloudUserDefaults.boolForKey(hasMigratedToiCloudKey) {
        mergeFavouritesFromUserDefaults(iCloudUserDefaults, toUserDefaults: localUserDefaults)
    }

    localUserDefaults.setBool(true, forKey: hasMigratedToiCloudKey)

    // copy everything from the local user defaults to iCloud, including merged favourites
    // (other settings are overwritten by the last device to do this)
    for (key, value) in localUserDefaults.dictionaryRepresentation() {
        iCloudUserDefaults.setObject(value, forKey: key)
    }
}

private func mergeFavouritesFromUserDefaults(fromUserDefaults: UserDefaultsProtocol, toUserDefaults: UserDefaultsProtocol) {
    let fromFavourites = Favourites(userDefaults: fromUserDefaults)
    let toFavourites = Favourites(userDefaults: toUserDefaults)
    
    fromFavourites.items --> { items in
        items.forEach { item in
            if !toFavourites.containsItem(item) {
                toFavourites.addItem(item)
            }
        }
    }
}
