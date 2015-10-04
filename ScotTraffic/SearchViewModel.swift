//
//  SearchViewModel.swift
//  ScotTraffic
//
//  Created by Neil Gall on 03/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit

public class SearchViewModel: SearchViewDataSource {
    let appModel: AppModel
    let searchTerm: Input<String>
    let searchResults: Latest<[MapItem]>
    
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
        
        self.searchResults = combine(trafficCameras, safetyCameras, alerts, roadworks, combine:{
            return $0 + $1 + $2 + $3
        }).latest()
    }
    
    public var count: Int {
        return searchResults.value?.count ?? 0
    }
    
    public func configureCell(cell: UITableViewCell, forItemAtIndex index: Int) {
        let mapItem = searchResults.value?[index]
        cell.textLabel?.text = mapItem?.name
        cell.detailTextLabel?.text = mapItem?.road
    }
    
    public func onChange(fn: Void -> Void) -> Observation {
        return searchResults.output { _ in fn() }
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