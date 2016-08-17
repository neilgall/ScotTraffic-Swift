//  AppWidgetManager.swift
//  ScotTraffic
//
//  Created by Neil Gall on 21/11/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import NotificationCenter

struct AppWidgetManager {
    
    let observation: ReceiverType
    
    init(favourites: Favourites) {
        observation = favourites.items --> { items in
            let hasContent = items.filter(isTrafficCamera).count > 0
            NCWidgetController.widgetController().setHasContent(hasContent, forWidgetWithBundleIdentifier: Configuration.todayExtensionBundleIdentifier)
        }
    }
}

private func isTrafficCamera(item: FavouriteItem) -> Bool {
    if case .TrafficCamera = item {
        return true
    } else {
        return false
    }
}
