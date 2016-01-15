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

func == (lhs: Registration, rhs: Registration) -> Bool {
    return lhs.deviceToken == rhs.deviceToken
        && lhs.identifier == rhs.identifier
        && lhs.enable == rhs.enable
}

public class AppNotifications {
    
    private let settings: Settings
    private let httpAccess: HTTPAccess
    private var receivers: [ReceiverType] = []
    private var notificationReceivers: [ReceiverType] = []
    private var deviceToken: Input<String?> = Input(initial: nil)
    
    public init(settings: Settings, httpAccess: HTTPAccess) {
        self.settings = settings
        self.httpAccess = httpAccess
        
        let notificationsEnabled = settings.bridgeNotifications.map({ pair in
            pair.map(second).reduce(Const(false), combine: ||)
        })
        receivers.append(notificationsEnabled.join() --> { [weak self] enabled in
            if enabled {
                self?.enableNotifications()
            } else {
                self?.disableNotifications()
            }
        })
        
        let deviceTokenWhenNotNil = not(isNil(deviceToken)).gate(deviceToken)

        receivers.append(settings.bridgeNotifications --> { [weak self] bridges in
            self?.notificationReceivers = bridges.flatMap({ [weak self] (bridge, setting) in
                guard self != nil else {
                    return nil
                }
                let registration = combine(deviceTokenWhenNotNil, setting) {
                    return Registration(identifier: bridge.identifier, deviceToken: $0!, enable: $1)
                }
                return registration.onChange() --> self!.updateRegistration
            })
        })
    }

    private func enableNotifications() {
        let settings = UIUserNotificationSettings(forTypes: [.Badge, .Sound, .Alert], categories: nil)
        UIApplication.sharedApplication().registerUserNotificationSettings(settings)
        UIApplication.sharedApplication().registerForRemoteNotifications()
    }
    
    private func disableNotifications() {
        UIApplication.sharedApplication().unregisterForRemoteNotifications()
        deviceToken <-- nil
    }
    
    private func updateRegistration(registration: Registration) {
        let method: HTTPAccess.HTTPMethod = registration.enable ? .PUT : .DELETE
        let path = "/notifications/\(registration.identifier)/\(registration.deviceToken)"
        httpAccess.request(method, data: nil, path: path) {
            if case .Error(let error) = $0 {
                analyticsError(path, error: error)
            }
        }
        
        analyticsEvent(registration.enable ? .EnableNotifications : .DisableNotifications, ["identifier": registration.identifier])
    }
    
    public func didFailToRegisterWithError(error: NSError) {
        deviceToken <-- nil
    }
    
    public func didRegisterWithDeviceToken(token: NSData) {
        deviceToken <-- hexStringFromData(token)
    }
}

private func hexStringFromData(data: NSData) -> String {
    let nibble: [Character] = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F" ]
    
    var bytes = [UInt8](count: data.length, repeatedValue: 0)
    data.getBytes(&bytes, length: data.length)
    
    var str = [Character]()
    for byte in bytes {
        str.append(nibble[Int(byte >> 4)])
        str.append(nibble[Int(byte & 0xF)])
    }
    
    return String(str)
}

