//
//  SearchViewModel.swift
//  ScotTraffic
//
//  Created by Neil Gall on 03/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import Foundation

public class SearchViewModel {
    let appModel: AppModel
    let searchTerm: Input<String>
    let searchResults: Observable<[MapItem]>
    
    public init(appModel: AppModel) {
        self.appModel = appModel
        self.searchTerm = Input(initial: "")
        
        let trafficCameras = filteredMapItems(
            sourceList: appModel.trafficCameraLocations,
            enabled:    appModel.settings.showTrafficCamerasOnMap,
            searchTerm: self.searchTerm)
        
        let safetyCameras = filteredMapItems(
            sourceList: appModel.safetyCameras,
            enabled:    appModel.settings.showSafetyCamerasOnMap,
            searchTerm: self.searchTerm)
        
        let alerts = filteredMapItems(
            sourceList: appModel.alerts,
            enabled:    appModel.settings.showAlertsOnMap,
            searchTerm: self.searchTerm)
        
        let roadworks = filteredMapItems(
            sourceList: appModel.roadworks,
            enabled:    appModel.settings.showRoadworksOnMap,
            searchTerm: self.searchTerm)
        
        self.searchResults = combine(trafficCameras, safetyCameras, alerts, roadworks) {
            return $0 + $1 + $2 + $3
        }
    }
}

func filteredMapItems<T: MapItem>(
    sourceList sourceList: Observable<[T]>,
    enabled: Observable<Bool>,
    searchTerm: Observable<String>) -> Observable<[MapItem]>
{
    return combine(sourceList, enabled, searchTerm) { sourceList, enabled, searchTerm in
        if !enabled {
            return []
        } else {
            return sourceList
                .filter { $0.name.containsString(searchTerm) || $0.road.containsString(searchTerm) }
                .map { $0 as MapItem }
        }
    }
}