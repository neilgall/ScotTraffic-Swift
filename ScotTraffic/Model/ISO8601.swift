//
//  ISO8601.swift
//  ScotTraffic
//
//  Created by Neil Gall on 08/01/2016.
//  Copyright © 2016 Neil Gall. All rights reserved.
//

import Foundation

public extension NSDateFormatter {
    private static let iso8601DateFormatter = NSDateFormatter()
    private static var initialised = dispatch_once_t()

    public static var ISO8601: NSDateFormatter {
        dispatch_once(&initialised) {
            iso8601DateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
            iso8601DateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        }
        return iso8601DateFormatter
    }
}