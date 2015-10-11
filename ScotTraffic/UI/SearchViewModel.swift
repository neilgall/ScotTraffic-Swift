//
//  SearchViewModel.swift
//  ScotTraffic
//
//  Created by Neil Gall on 03/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit

public class SearchViewModel {
    let searchTerm: Input<String>
    let searchResults: Latest<[MapItem]>
    let searchResultsMajorAxis: Observable<GeographicAxis>
    
    public init(appModel: AppModel) {
        self.searchTerm = Input(initial: "")
        
        let trafficCameras = combine(
            appModel.trafficCameraLocations, appModel.settings.showTrafficCamerasOnMap, self.searchTerm,
            combine: applyFilterToMapItems)
        
        let safetyCameras = combine(
            appModel.safetyCameras, appModel.settings.showSafetyCamerasOnMap, self.searchTerm,
            combine: applyFilterToMapItems)
        
        let alerts = combine(
            appModel.alerts, appModel.settings.showAlertsOnMap, self.searchTerm,
            combine: applyFilterToMapItems)
        
        let roadworks = combine(
            appModel.roadworks, appModel.settings.showRoadworksOnMap, self.searchTerm,
            combine: applyFilterToMapItems)
        
        let combinedResults: Observable<[MapItem]> = combine(trafficCameras, safetyCameras, alerts, roadworks) {
            return $0 + $1 + $2 + $3
        }
            
        self.searchResults = combinedResults.map({ $0.sortGeographically() }).latest()
        self.searchResultsMajorAxis = combinedResults.map { $0.majorAxis }
    }
}

func applyFilterToMapItems<T: MapItem> (sourceList: [T], enabled: Bool, searchTerm: String) -> [MapItem] {
    if !enabled {
        return []
    } else {
        let term = searchTerm.lowercaseString
        return sourceList
            .filter { $0.name.lowercaseString.containsString(term) || $0.road.lowercaseString == term }
            .map { $0 as MapItem }
    }
}