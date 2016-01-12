//
//  RemoteNotifications.swift
//  ScotTraffic
//
//  Created by Neil Gall on 11/01/2016.
//  Copyright © 2016 Neil Gall. All rights reserved.
//

import UIKit

public class RemoteNotifications {
    public typealias OptionsDict = [NSObject: AnyObject]

    private let bridgeIdentifier: Input<String?>
    
    // Outputs
    let zoomToBridge: Signal<BridgeStatus?>
    let showNotification: Input<String?>
    
    init(bridges: Signal<[BridgeStatus]>) {
        bridgeIdentifier = Input(initial: nil)
        
        zoomToBridge = combine(bridges, bridgeIdentifier) { bridges, identifier in
            return bridges.filter({ $0.identifier == identifier }).first
        }
        
        showNotification = Input(initial: nil)
    }
    
    public func parseLaunchOptions(options: OptionsDict?) {
        guard let options = options else {
            return
        }
        
        if let remoteNotificationOptions = options[UIApplicationLaunchOptionsRemoteNotificationKey] as? OptionsDict {
            parseRemoteNotificationOptions(remoteNotificationOptions, inApplicationState: .Inactive)
        }
    }
    
    public func parseRemoteNotificationOptions(options: OptionsDict, inApplicationState state: UIApplicationState) {
        switch state {
        case .Inactive:
            bridgeIdentifier <-- options["bridgeIdentifier"] as? String
        
        case .Active:
            if let aps = options["aps"] as? OptionsDict, message = aps["alert"] as? String {
                showNotification <-- message
            }
            
        case .Background:
            break
        }
    }
    
    public func clear() {
        bridgeIdentifier <-- nil
        showNotification <-- nil
    }
}