//
//  Notifications.swift
//  ScotTraffic
//
//  Created by ZBS on 06/12/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit

public class AppNotifications {
    
    private let settings: Settings
    private let httpAccess: HTTPAccess
    private var observations: [Observation] = []
    
    public init(settings: Settings, httpAccess: HTTPAccess) {
        self.settings = settings
        self.httpAccess = httpAccess
        
        let notificationsEnabled = settings.forthBridgeNotifications || settings.tayBridgeNotifications
        observations.append(notificationsEnabled => { [weak self] enabled in
            if enabled {
                self?.enableNotifications()
            } else {
                self?.disableNotifications()
            }
        })
    }
    
    private func enableNotifications() {
        let settings = UIUserNotificationSettings(forTypes: [.Badge, .Sound, .Alert], categories: Set())
        UIApplication.sharedApplication().registerUserNotificationSettings(settings)
    }
    
    private func disableNotifications() {
        UIApplication.sharedApplication().unregisterForRemoteNotifications()
    }
    
    public func didFailToRegisterWithError(error: NSError) {
        settings.forthBridgeNotifications.value = false
        settings.tayBridgeNotifications.value = false
    }
    
    public func didRegisterWithDeviceToken(token: NSData) {
        
    }
}