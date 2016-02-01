//
//  Configuration.swift
//  ScotTraffic
//
//  Created by Neil Gall on 21/11/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import Foundation

#if DEBUG
    let scotTrafficBaseURL = NSURL(string: "https://dev.scottraffic.co.uk")!
#else
    let scotTrafficBaseURL = NSURL(string: "https://scottraffic.co.uk")!
#endif

struct Configuration {
    static let scotTrafficAppGroup = "group.uk.co.scottraffic.ios.favourites"
    static let todayExtensionBundleIdentifier = "uk.co.ScotTraffic.iOS.TodayExtension"
    static let sharedUserDefaults: Void -> NSUserDefaults = {
        guard let userDefaults = NSUserDefaults(suiteName: scotTrafficAppGroup) else {
            fatalError("cannot create NSUserDefaults for app Group \(scotTrafficAppGroup)")
        }
        return userDefaults
    }
    static let iCloudUserDefaults = NSUbiquitousKeyValueStore.defaultStore()

    static let runningOnSimulator = (TARGET_OS_SIMULATOR != 0)
    static let runningUnitTests = (NSClassFromString("XCTestCase") != nil)
}
