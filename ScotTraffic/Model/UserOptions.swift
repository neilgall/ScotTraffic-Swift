//
//  UserOptions.swift
//  ScotTraffic
//
//  Created by Neil Gall on 11/01/2016.
//  Copyright © 2016 Neil Gall. All rights reserved.
//

import UIKit

public struct UserOptions {
    public typealias OptionsDict = [NSObject: AnyObject]

    let bridgeIdentifier: Input<String?> = Input(initial: nil)
    
    public func parseLaunchOptions(options: OptionsDict?) {
        guard let options = options else {
            return
        }
        
        if let remoteNotificationOptions = options[UIApplicationLaunchOptionsRemoteNotificationKey] as? OptionsDict {
            parseRemoteNotificationOptions(remoteNotificationOptions)
        }
    }
    
    public func parseRemoteNotificationOptions(options: OptionsDict) {
        bridgeIdentifier <-- options["bridgeIdentifier"] as? String
    }
}