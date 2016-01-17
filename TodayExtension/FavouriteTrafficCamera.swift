//
//  FavouriteTrafficCamera.swift
//  ScotTraffic
//
//  Created by Neil Gall on 17/01/2016.
//  Copyright © 2016 Neil Gall. All rights reserved.
//

import Foundation

struct FavouriteTrafficCamera {
    let location: TrafficCameraLocation
    let cameraIndex: Int
    
    var identifier: String {
        return location.cameras[cameraIndex].identifier
    }
    
    var name: String {
        return location.nameAtIndex(cameraIndex)
    }
}

extension Favourites {
    func trafficCamerasFromLocations(locations: Signal<[TrafficCameraLocation]>) -> Signal<[FavouriteTrafficCamera]> {
        return combine(locations, items, combine: { locations, favourites in
            favourites.flatMap { favourite in
                switch favourite {
                case .SavedSearch:
                    return nil
                case .TrafficCamera(let identifier):
                    return locations.findIdentifier(identifier).map({ location, cameraIndex in
                        return FavouriteTrafficCamera(location: location, cameraIndex: cameraIndex)
                    })
                }
            }
        })
    }
}
