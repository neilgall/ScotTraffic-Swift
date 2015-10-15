//
//  Favourites.swift
//  ScotTraffic
//
//  Created by Neil Gall on 04/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import MapKit

let favouritesKey = "favouriteItems"
let lastViewedKey = "lastViewedIdentifier"

public typealias FavouriteIdentifier = String

public struct FavouriteTrafficCamera {
    let location: TrafficCameraLocation
    let cameraIndex: Int
    
    public init?(location: TrafficCameraLocation, camera: TrafficCamera) {
        guard let cameraIndex = location.cameras.indexOf({ $0.identifier == camera.identifier }) else {
            return nil
        }
        self.init(location: location, cameraIndex: cameraIndex)
    }
    
    public init(location: TrafficCameraLocation, cameraIndex: Int) {
        self.location = location
        self.cameraIndex = cameraIndex
    }
}


public class Favourites {
    private let userDefaults: UserDefaultsProtocol
    private var userDefaultsNotification: AnyObject?
    private let items : Input<[FavouriteIdentifier]>
    public let trafficCameras: Observable<[FavouriteTrafficCamera]>
    
    public init(userDefaults: UserDefaultsProtocol, trafficCameraLocations: Observable<[TrafficCameraLocation]>) {
        self.userDefaults = userDefaults
        self.items = Input(initial: [])
        self.trafficCameras = combine(trafficCameraLocations, self.items, combine: favouriteTrafficCamerasFromLocations)
        
        self.userDefaultsNotification = NSNotificationCenter.defaultCenter()
            .addObserverForName(NSUserDefaultsDidChangeNotification, object: nil, queue: nil) { _ in
                self.reloadFromUserDefaults()
        }
        
        reloadFromUserDefaults()
    }
    
    deinit {
        if let userDefaultsNotification = self.userDefaultsNotification {
            NSNotificationCenter.defaultCenter().removeObserver(userDefaultsNotification)
        }
    }
    
    public func toggleItem(identifier: FavouriteIdentifier) {
        var items = self.items.value
        if let index = items.indexOf({ $0 == identifier }) {
            items.removeAtIndex(index)
        } else {
            items.append(identifier)
        }
        self.items.value = items
    }
    
    private func reloadFromUserDefaults() {
        guard let items = userDefaults.objectForKey(favouritesKey) as? [FavouriteIdentifier] else {
            return
        }
        self.items.value = items
    }
    
    private func saveToUserDefaults() {
        userDefaults.setObject(self.items.value, forKey: favouritesKey)
        userDefaults.synchronize()
    }
}

public func favouriteTrafficCamerasFromLocations(locations: [TrafficCameraLocation], favourites: [FavouriteIdentifier]) -> [FavouriteTrafficCamera] {
    return locations.flatMap { location in
        guard let cameraIndex = location.cameras.indexOf({ favourites.contains($0.identifier) }) else {
            return nil
        }
        return FavouriteTrafficCamera(location: location, cameraIndex: cameraIndex)
    }
}
