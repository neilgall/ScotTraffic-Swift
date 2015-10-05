//
//  MapViewModel.swift
//  ScotTraffic
//
//  Created by Neil Gall on 05/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import Foundation

public class MapViewModel {
    
    let mapItems : Observable<[MapItem]>
    let annotations: Latest<[MapAnnotation]>
 
    public init(appModel: AppModel) {
        
        let trafficCameras = combine(appModel.trafficCameraLocations, appModel.settings.showTrafficCamerasOnMap, appModel.favourites.trafficCameras) {
            (locations, enabled, favourites) -> [MapItem] in
            
            if !enabled {
                return favourites.map { $0.location as MapItem }
            } else {
                return locations.map { $0 as MapItem }
            }
        }
        
        let safetyCameras = combine(appModel.safetyCameras, appModel.settings.showSafetyCamerasOnMap, combine: includeMapItemsIfEnabled)
        let alerts = combine(appModel.alerts, appModel.settings.showAlertsOnMap, combine: includeMapItemsIfEnabled)
        let roadworks = combine(appModel.roadworks, appModel.settings.showRoadworksOnMap, combine: includeMapItemsIfEnabled)
        
        mapItems = combine(trafficCameras, safetyCameras, alerts, roadworks) {
            $0 + $1 + $2 + $3
        }
        
        let annotations = mapItems.map { items in
            items.map { item in MapAnnotation(mapItems: [item]) }
        }
        
        self.annotations = annotations.latest()
    }
}

func includeMapItemsIfEnabled<T: MapItem>(mapItems: [T], enabled: Bool) -> [MapItem] {
    if enabled {
        return mapItems.map { $0 as MapItem }
    } else {
        return []
    }
}