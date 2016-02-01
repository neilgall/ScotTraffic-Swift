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

let scotTrafficAppGroup = "group.uk.co.scottraffic.ios.favourites"
let todayExtensionBundleIdentifier = "uk.co.ScotTraffic.iOS.TodayExtension"

let runningOnSimulator = (TARGET_OS_SIMULATOR != 0)
let runningUnitTests = (NSClassFromString("XCTestCase") != nil)
