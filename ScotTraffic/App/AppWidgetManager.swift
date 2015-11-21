//
//  AppWidgetManager.swift
//  ScotTraffic
//
//  Created by Neil Gall on 21/11/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import NotificationCenter

class AppWidgetManager {
    
    let observation: Observation
    
    init(favourites: Favourites) {
        observation = favourites.trafficCameras => {
            let hasContent = $0.count > 0
            NCWidgetController.widgetController().setHasContent(hasContent, forWidgetWithBundleIdentifier: TodayExtensionBundleIdentifier)
        }
    }
}