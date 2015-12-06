//
//  Notifications.swift
//  ScotTraffic
//
//  Created by ZBS on 06/12/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit

public class Notifications {
    
    private var observations: [Observation] = []
    
    public init(settings: Settings) {
        let notificationsEnabled = settings.forthBridgeNotifications || settings.tayBridgeNotifications
        
        observations.append(notificationsEnabled.onRisingEdge(self.enableNotifications))
        observations.append(notificationsEnabled.onFallingEdge(self.disableNotifications))
    }
    
    private func enableNotifications() {
        let settings = UIUserNotificationSettings(forTypes: [.Badge, .Sound, .Alert], categories: Set())
        UIApplication.sharedApplication().registerUserNotificationSettings(settings)
    }
    
    private func disableNotifications() {
        UIApplication.sharedApplication().unregisterForRemoteNotifications()
    }
}