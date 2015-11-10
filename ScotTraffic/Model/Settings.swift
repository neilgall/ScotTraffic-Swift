//
//  Settings.swift
//  ScotTraffic
//
//  Created by Neil Gall on 03/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import MapKit

private let scotlandMapRect = MKMapRectMake(129244330.1, 79649811.3, 3762380.0, 6443076.1)

public enum TemperatureUnit: Int {
    case Celcius
    case Fahrenheit
}

public class Settings {
    public let showTrafficCamerasOnMap: PersistentSetting<Bool>
    public let showSafetyCamerasOnMap: PersistentSetting<Bool>
    public let showAlertsOnMap: PersistentSetting<Bool>
    public let showRoadworksOnMap: PersistentSetting<Bool>
    public let showBridgesOnMap: PersistentSetting<Bool>
    public let showCurrentLocationOnMap: PersistentSetting<Bool>
    public let temperatureUnit: PersistentSetting<TemperatureUnit>
    public let visibleMapRect: PersistentSetting<MKMapRect>
    
    public init(userDefaults: UserDefaultsProtocol) {
        showTrafficCamerasOnMap = userDefaults.boolSetting("showTrafficCamerasOnMap", true)
        showSafetyCamerasOnMap = userDefaults.boolSetting("showSafetyCamerasOnMap", true)
        showAlertsOnMap = userDefaults.boolSetting("showAlertsOnMap", true)
        showRoadworksOnMap = userDefaults.boolSetting("showRoadworksOnMap", true)
        showBridgesOnMap = userDefaults.boolSetting("showBridgesOnMap", true)
        showCurrentLocationOnMap = userDefaults.boolSetting("showCurrentLocationOnMap", false)
        temperatureUnit = userDefaults.enumSetting("temperatureUnit", TemperatureUnit.Celcius)
        visibleMapRect = userDefaults.setting("visibleMapRect", scotlandMapRect,
            to: { stringFromMapRect($0) }, from: { ($0 as? String).flatMap(mapRectFromString) })
        
        reload()
    }
    
    public func reload() {
        showTrafficCamerasOnMap.start()
        showSafetyCamerasOnMap.start()
        showAlertsOnMap.start()
        showRoadworksOnMap.start()
        showBridgesOnMap.start()
        showCurrentLocationOnMap.start()
        temperatureUnit.start()
        visibleMapRect.start()
    }
}

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

private func stringFromMapRect(rect: MKMapRect) -> String? {
    return "\(rect.origin.x),\(rect.origin.y),\(rect.size.width),\(rect.size.height)"
}

private func mapRectFromString(str: String) -> MKMapRect? {
    let components = str.componentsSeparatedByString(",").flatMap { Double($0) }
    guard components.count == 4 else {
        return nil
    }
    return MKMapRectMake(components[0], components[1], components[2], components[3])
}

