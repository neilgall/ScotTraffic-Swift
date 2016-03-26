//
//  DateFormatters.swift
//  ScotTraffic
//
//  Created by Neil Gall on 08/01/2016.
//  Copyright © 2016 Neil Gall. All rights reserved.
//

import Foundation

extension NSDateFormatter {
    private static let iso8601DateFormatter = NSDateFormatter()
    private static var iso8601Initialised = dispatch_once_t()

    static var ISO8601: NSDateFormatter {
        dispatch_once(&iso8601Initialised) {
            iso8601DateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
            iso8601DateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        }
        return iso8601DateFormatter
    }
}

extension NSDateFormatter {
    private static let rfc2822DateFormatter = NSDateFormatter()
    private static var rfc2822Initialised = dispatch_once_t()
    
    static var RFC2822: NSDateFormatter {
        dispatch_once(&rfc2822Initialised) {
            rfc2822DateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
            rfc2822DateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        }
        return rfc2822DateFormatter
    }
}