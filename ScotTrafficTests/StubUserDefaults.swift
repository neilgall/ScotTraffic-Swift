//
//  StubUserDefaults.swift
//  ScotTraffic
//
//  Created by Neil Gall on 12/03/2016.
//  Copyright © 2016 Neil Gall. All rights reserved.
//

import Foundation
@testable import ScotTraffic

class StubUserDefaults: UserDefaultsProtocol {
    var userDefaults = [String:AnyObject]()
    
    func objectForKey(key: String) -> AnyObject? {
        return userDefaults[key]
    }
    
    func setObject(object: AnyObject?, forKey key: String) {
        userDefaults[key] = object
    }
    
    func removeObjectForKey(key: String) {
        userDefaults.removeValueForKey(key)
    }
    
    func synchronize() -> Bool {
        return true
    }
}
