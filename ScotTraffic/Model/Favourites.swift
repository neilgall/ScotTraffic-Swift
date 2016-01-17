//
//  Favourites.swift
//  ScotTraffic
//
//  Created by Neil Gall on 04/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import MapKit

private let favouritesKey = "favouriteItems"
private let typeKey = "type"
private let typeSavedSearch = "savedSearch"
private let typeTrafficCamera = "trafficCamera"
private let termKey = "term"
private let identifierKey = "identifier"

typealias FavouriteIdentifier = String

enum FavouriteItem {
    case SavedSearch(term: String)
    case TrafficCamera(identifier: FavouriteIdentifier)
}

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
    let items: Input<[FavouriteItem]>
    let trafficCameras: Signal<[FavouriteTrafficCamera]>
    
    private var receivers = [ReceiverType]()
    
    init(userDefaults: UserDefaultsProtocol, trafficCameraLocations: Signal<[TrafficCameraLocation]>) {
        self.userDefaults = userDefaults
        self.items = Input(initial: [])
        self.trafficCameras = combine(trafficCameraLocations, self.items, combine: favouriteTrafficCamerasFromLocations)
        
        reloadFromUserDefaults()
        
        receivers.append(items --> {
            userDefaults.setObject($0.map(dictionaryFromFavouriteItem), forKey: favouritesKey)
        })
    }
    
    func addTrafficCamera(item: FavouriteTrafficCamera) {
        items.modify {
            return $0 + [.TrafficCamera(identifier: item.identifier)]
        }
        analyticsEvent(.AddFavourite, ["identifier": item.identifier])
    }
    
    func deleteTrafficCamera(item: FavouriteTrafficCamera) {
        items.modify {
            return $0.filter(not(itemIsTrafficCameraIdentifier(item.identifier)))
        }
        analyticsEvent(.DeleteFavourite, ["identifier": item.identifier])
    }

    func containsTrafficCamera(item: FavouriteTrafficCamera) -> Bool {
        return self.items.value.contains(itemIsTrafficCameraIdentifier(item.identifier))
    }
    
    func deleteItemAtIndex(index: Int) {
        items.modify { items in
            let item = items[index]
            return items.filter({ $0 != item })
        }
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
    
    func reloadFromUserDefaults() {
        let object = userDefaults.objectForKey(favouritesKey)
        guard let items = object as? [AnyObject] else {
            return
        }
        self.items <-- items.flatMap(favouriteItemFromObject)
    }
}

private func favouriteItemFromObject(object: AnyObject) -> FavouriteItem? {
    if let identifier = object as? String {
        // pre-1.2 favourite which is always a traffic camera
        return .TrafficCamera(identifier: identifier)
    }
    
    guard let dictionary = object as? [String: String] else {
        return nil
    }
    
    if let term = dictionary[termKey] where dictionary[typeKey] == typeSavedSearch {
        return .SavedSearch(term: term)
        
    } else if let identifier = dictionary[identifierKey] where dictionary[typeKey] == typeTrafficCamera {
        return .TrafficCamera(identifier: identifier)
        
    } else {
        return nil
    }
}

private func itemIsTrafficCameraIdentifier(identifier: FavouriteIdentifier) -> FavouriteItem -> Bool {
    return { favourite in
        switch favourite {
        case .SavedSearch:
            return false
        case .TrafficCamera(let tcIdentifier):
            return tcIdentifier == identifier
        }
    }
}

private func dictionaryFromFavouriteItem(favourite: FavouriteItem) -> [String:String] {
    switch favourite {
    case .SavedSearch(let term):
        return [ typeKey: typeSavedSearch, termKey: term ]
    case .TrafficCamera(let identifier):
        return [ typeKey: typeTrafficCamera, identifierKey: identifier ]
    }
}

private func favouriteTrafficCamerasFromLocations(locations: [TrafficCameraLocation], favourites: [FavouriteItem]) -> [FavouriteTrafficCamera] {
    return favourites.flatMap { favourite in
        switch favourite {
        case .SavedSearch:
            return nil
        case .TrafficCamera(let identifier):
            let locations = locations.flatMap { (location: TrafficCameraLocation) -> FavouriteTrafficCamera? in
                guard let cameraIndex = location.indexOfCameraWithIdentifier(identifier) else {
                    return nil
                }
                return FavouriteTrafficCamera(location: location, cameraIndex: cameraIndex)
            }
            return locations.first
        }
    }
}

extension FavouriteItem: Equatable {}

func == (lhs: FavouriteItem, rhs: FavouriteItem) -> Bool {
    switch (lhs, rhs) {
    case (.SavedSearch(let lhsTerm), .SavedSearch(let rhsTerm)):
        return lhsTerm == rhsTerm
    case (.TrafficCamera(let lhsId), .TrafficCamera(let rhsId)):
        return lhsId == rhsId
    default:
        return false
    }
}
