//
//  Analytics.swift
//  ScotTraffic
//
//  Created by Neil Gall on 13/01/2016.
//  Copyright © 2016 Neil Gall. All rights reserved.
//

import Foundation

enum AnalyticsEvent: String {
    case EnableNotifications
    case DisableNotifications
    case OpenFromRemoteNotification
    case Search
    case Settings
    case AddFavourite
    case DeleteFavourite
    case ReorderFavourites
    case ViewTrafficCamera
    case ViewSafetyCamera
    case ViewIncident
    case ViewBridgeStatus
    case ShareItem
}

func analyticsStart() {
    Flurry.setCrashReportingEnabled(true)
    Flurry.startSession("8BC7J7RSGRNCVYDB2TTV")
}

func analyticsEvent(event: AnalyticsEvent) {
    Flurry.logEvent(event.rawValue)
}

func analyticsEvent(event: AnalyticsEvent, _ parameters: [String:String]) {
    Flurry.logEvent(event.rawValue, withParameters: parameters)
}

func analyticsError(name: String, error: ErrorType) {
    if let appError = error as? AppError {
        Flurry.logError(name, message: "", error: appError.toNSError)
    } else {
        Flurry.logError(name, message: "", error: error as NSError)
    }
}


