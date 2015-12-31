//
//  Notifications.swift
//  ScotTraffic
//
//  Created by ZBS on 06/12/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit

struct Registration: Equatable {
    let identifier: String
    let deviceToken: String
    let enable: Bool
}

public class AppNotifications {
    
    private let settings: Settings
    private let httpAccess: HTTPAccess
    private var observations: [Observation] = []
    private var deviceToken: Input<String?> = Input(initial: nil)
    
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
        
        observations.append(registrationForSetting(settings.forthBridgeNotifications, identifier: "forthRoadBridge") => updateRegistration)
        observations.append(registrationForSetting(settings.tayBridgeNotifications, identifier: "tayBridge") => updateRegistration)
        
    }

    private func registrationForSetting(setting: Observable<Bool>, identifier: String) -> Observable<Registration> {
        let registration = combine(not(isNil(deviceToken)).gate(deviceToken), setting) {
            return Registration(identifier: identifier, deviceToken: $0!, enable: $1)
        }
        return registration.onChange()
    }
    
    private func enableNotifications() {
        let settings = UIUserNotificationSettings(forTypes: [.Badge, .Sound, .Alert], categories: nil)
        UIApplication.sharedApplication().registerUserNotificationSettings(settings)
        UIApplication.sharedApplication().registerForRemoteNotifications()
    }
    
    private func disableNotifications() {
        UIApplication.sharedApplication().unregisterForRemoteNotifications()
    }
    
    private func updateRegistration(registration: Registration) {
        let enable = registration.enable ? "on" : "off"
        let path = "/notifications/\(registration.identifier)/\(registration.deviceToken)/\(enable)"
        httpAccess.fetchDataAtPath(path) {
            switch $0 {
            case .Error(let error):
                NSLog("registration failed for \(path): \(error)")
            case .Fresh:
                NSLog("registration success for \(path): \(registration.identifier)")
            default:
                NSLog("unexpected result from \(path)")
            }
        }
    }
    
    public func didFailToRegisterWithError(error: NSError) {
        deviceToken.value = nil
        settings.forthBridgeNotifications.value = false
        settings.tayBridgeNotifications.value = false
    }
    
    public func didRegisterWithDeviceToken(token: NSData) {
        let nibble : [Character] = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F" ]
        
        var bytes = [UInt8](count: token.length, repeatedValue: 0)
        token.getBytes(&bytes, length: token.length)

        var str = [Character]()
        for byte in bytes {
            str.append(nibble[Int(byte >> 4)])
            str.append(nibble[Int(byte & 0xF)])
        }
        
        deviceToken.value = String(str)
    }
}

func == (lhs: Registration, rhs: Registration) -> Bool {
    return lhs.deviceToken == rhs.deviceToken
        && lhs.identifier == rhs.identifier
        && lhs.enable == rhs.enable
}