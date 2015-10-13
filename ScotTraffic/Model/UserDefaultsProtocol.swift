//
//  UserDefaultsProtocol.swift
//  ScotTraffic
//
//  Created by ZBS on 12/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import Foundation

public protocol UserDefaultsProtocol: class {
    func synchronize() -> Bool
    
    func objectForKey(key: String) -> AnyObject?
    
    func setObject(object: AnyObject?, forKey key: String)
    
    func removeObjectForKey(key: String)
}

extension NSUserDefaults: UserDefaultsProtocol {
}
