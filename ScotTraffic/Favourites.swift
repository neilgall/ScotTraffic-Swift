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

public struct FavouriteItem {
    let identifier: String
    let name: String
    let road: String
    
    init(identifier: String, name: String, road: String) {
        self.identifier = identifier
        self.name = name
        self.road = road
    }
    
    public init(trafficCamera: TrafficCamera, atLocation location: TrafficCameraLocation) {
        self.identifier = trafficCamera.identifier
        self.name = location.name
        self.road = location.road
    }
}

func == (a: FavouriteItem, b: FavouriteItem) -> Bool {
    return a.identifier == b.identifier
}

public struct FavouriteTrafficCamera {
    let location: TrafficCameraLocation
    let cameraIndex: Int
}


public class Favourites {
    private let userDefaults: NSUserDefaults
    private var userDefaultsNotification: AnyObject?
    private let items : Input<[FavouriteItem]>
    public let trafficCameras: Observable<[FavouriteTrafficCamera]>
    
    public init(userDefaults: NSUserDefaults, trafficCameraLocations: Observable<[TrafficCameraLocation]>) {
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
    
    public func toggleItem(item: FavouriteItem) {
        var items = self.items.value
        if let index = items.indexOf({ $0 == item }) {
            items.removeAtIndex(index)
        } else {
            items.append(item)
        }
        self.items.value = items
    }
    
    private func reloadFromUserDefaults() {
        guard let items = userDefaults.objectForKey(favouritesKey) as? [[String:String]] else {
            return
        }
        self.items.value = items.flatMap { item in
            guard let identifier = item["id"], name = item["name"], road = item["road"] else {
                return nil
            }
            return FavouriteItem(identifier: identifier, name: name, road: road)
        }
    }
    
    private func saveToUserDefaults() {
        let items = self.items.value.map { item in
            return [ "id": item.identifier, "name": item.name, "road": item.road ]
        }
        userDefaults.setObject(items, forKey: favouritesKey)
        userDefaults.synchronize()
    }
}

public func favouriteTrafficCamerasFromLocations(locations: [TrafficCameraLocation], favourites: [FavouriteItem]) -> [FavouriteTrafficCamera] {
    return favourites.flatMap { favourite in
        guard let locationIndex = locations.indexOf({ $0.name == favourite.name }) else {
            return nil
        }
        let location = locations[locationIndex]
        guard let cameraIndex = location.cameras.indexOf({ $0.identifier == favourite.identifier }) else {
            return nil
        }
        return FavouriteTrafficCamera(location: location, cameraIndex: cameraIndex)
    }
}
