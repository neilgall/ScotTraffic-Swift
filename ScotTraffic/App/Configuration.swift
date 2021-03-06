//
//  Configuration.swift
//  ScotTraffic
//
//  Created by Neil Gall on 21/11/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import Foundation

#if DEBUG
    public let scotTrafficBaseURL = NSURL(string: "https://dev.scottraffic.co.uk")!
#else
    public let scotTrafficBaseURL = NSURL(string: "https://scottraffic.co.uk")!
#endif

public let scotTrafficAppGroup = "group.uk.co.scottraffic.ios.favourites"
public let todayExtensionBundleIdentifier = "uk.co.ScotTraffic.iOS.TodayExtension"
