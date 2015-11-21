//
//  PersistentSetting.swift
//  ScotTraffic
//
//  Created by Neil Gall on 21/11/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import Foundation

public class PersistentSetting<Value>: Input<Value>, Startable {
    let userDefaults: UserDefaultsProtocol
    let key: String
    let marshallTo: Value -> AnyObject?
    let marshallFrom: AnyObject -> Value?
    var updating: Bool
    
    init(_ userDefaults: UserDefaultsProtocol, key: String, defaultValue: Value, to: Value -> AnyObject?, from: AnyObject -> Value?) {
        self.userDefaults = userDefaults
        self.key = key
        self.marshallTo = to
        self.marshallFrom = from
        self.updating = false
        super.init(initial: defaultValue)
    }
    
    public func start() {
        if let value = userDefaults.objectForKey(key).flatMap(marshallFrom) {
            with(&updating) {
                self.value = value
            }
        }
    }
    
    override public func pushValue(value: Value) {
        super.pushValue(value)
        if !updating, let object = marshallTo(value) {
            userDefaults.setObject(object, forKey: key)
        }
    }
}

extension UserDefaultsProtocol {
    func boolSetting(key: String, _ defaultValue: Bool) -> PersistentSetting<Bool> {
        return PersistentSetting(self,
            key: key,
            defaultValue: defaultValue,
            to: { $0 },
            from: { $0 as? Bool }
        )
    }
    
    func intSetting(key: String, _ defaultValue: Int) -> PersistentSetting<Int> {
        return PersistentSetting(self,
            key: key,
            defaultValue: defaultValue,
            to: { $0 },
            from: { $0 as? Int }
        )
    }
    
    func enumSetting<T where T:RawRepresentable, T.RawValue == Int>(key: String, _ defaultValue: T) -> PersistentSetting<T> {
        return PersistentSetting(self,
            key: key,
            defaultValue: defaultValue,
            to: { $0.rawValue },
            from: { ($0 as? T.RawValue).flatMap { T(rawValue: $0) } }
        )
    }
    
    func setting<T>(key: String, _ defaultValue: T, to:(T -> AnyObject?), from:(AnyObject -> T?)) -> PersistentSetting<T> {
        return PersistentSetting(self, key: key, defaultValue: defaultValue, to: to, from: from)
    }
}
