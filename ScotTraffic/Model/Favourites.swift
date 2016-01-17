//
//  Favourites.swift
//  ScotTraffic
//
//  Created by Neil Gall on 04/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import MapKit

let favouritesKey = "favouriteItems"

private typealias FavouriteIdentifier = String

struct FavouriteTrafficCamera {
    let location: TrafficCameraLocation
    let cameraIndex: Int
    
    init?(location: TrafficCameraLocation, camera: TrafficCamera) {
        guard let cameraIndex = location.cameras.indexOf({ $0.identifier == camera.identifier }) else {
            return nil
        }
        self.init(location: location, cameraIndex: cameraIndex)
    }
    
    init(location: TrafficCameraLocation, cameraIndex: Int) {
        self.location = location
        self.cameraIndex = cameraIndex
    }
    
    var identifier: String {
        return location.cameras[cameraIndex].identifier
    }
    
    var name: String {
        return trafficCameraName(location.cameras[cameraIndex], atLocation: location)
    }
}


class Favourites {
    private let userDefaults: UserDefaultsProtocol
    private let items: Input<[FavouriteIdentifier]>
    let trafficCameras: Signal<[FavouriteTrafficCamera]>
    
    private var receivers = [ReceiverType]()
    
    init(userDefaults: UserDefaultsProtocol, trafficCameraLocations: Signal<[TrafficCameraLocation]>) {
        self.userDefaults = userDefaults
        self.items = Input(initial: [])
        self.trafficCameras = combine(trafficCameraLocations, self.items, combine: favouriteTrafficCamerasFromLocations)
        
        reloadFromUserDefaults()
        
        receivers.append(items --> {
            userDefaults.setObject($0, forKey: favouritesKey)
        })
    }
    
    func toggleItem(item: FavouriteTrafficCamera) {
        let identifier = item.identifier
        
        var items = self.items.value
        if let index = items.indexOf({ $0 == identifier }) {
            items.removeAtIndex(index)
            analyticsEvent(.DeleteFavourite, ["identifier": identifier])
        } else {
            items.append(identifier)
            analyticsEvent(.AddFavourite, ["identifier": identifier])
        }
        self.items <-- items
    }
    
    func moveItemFromIndex(fromIndex: Int, toIndex: Int) {
        var items = self.items.value
        if fromIndex > toIndex {
            items.insert(items[fromIndex], atIndex: toIndex)
            items.removeAtIndex(fromIndex+1)
        } else if fromIndex < toIndex {
            items.insert(items[fromIndex], atIndex: toIndex+1)
            items.removeAtIndex(fromIndex)
        }
        analyticsEvent(.ReorderFavourites)
        self.items <-- items
    }
    
    func containsItem(item: FavouriteTrafficCamera) -> Bool {
        return self.items.value.contains(item.identifier)
    }
    
    func reloadFromUserDefaults() {
        let object = userDefaults.objectForKey(favouritesKey)
        guard let items = object as? [FavouriteIdentifier] else {
            return
        }
        self.items <-- items
    }
}

private func favouriteTrafficCamerasFromLocations(locations: [TrafficCameraLocation], favourites: [FavouriteIdentifier]) -> [FavouriteTrafficCamera] {
    return favourites.flatMap { identifier in
        let locations = locations.flatMap { (location: TrafficCameraLocation) -> FavouriteTrafficCamera? in
            guard let cameraIndex = location.indexOfCameraWithIdentifier(identifier) else {
                return nil
            }
            return FavouriteTrafficCamera(location: location, cameraIndex: cameraIndex)
        }
        return locations.first
    }
}
