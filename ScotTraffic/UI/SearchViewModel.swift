//
//  SearchViewModel.swift
//  ScotTraffic
//
//  Created by Neil Gall on 03/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit

public class SearchViewModel {
    enum DisplayContent {
        case Favourites
        case SearchResults
    }

    // Inputs
    let searchTerm: Input<String>
    let searchSelectionIndex: Input<Int?>
    
    // Outputs
    var dataSource: Latest<TableViewDataSourceAdapter<[SearchResultItem]>>
    var resultsMajorAxisLabel: Latest<String>
    var searchSelection: Observable<MapItem?>
    

    public init(appModel: AppModel) {
        searchTerm = Input(initial: "")
        searchSelectionIndex = Input(initial: nil)
        
        let favourites = appModel.favourites.trafficCameras.latest()

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
            
        let searchResults = combinedResults.map({ $0.sortGeographically() }).latest()
        let searchResultsMajorAxis = combinedResults.map { $0.majorAxis }

        let displayContent: Observable<DisplayContent> = searchTerm.map { text in
            text.isEmpty ? .Favourites : .SearchResults
        }
        
        dataSource = displayContent.onChange().map({ contentType in
            switch contentType {
            case .Favourites:
                return favourites
                    .map(toSearchResultItems)
                    .tableViewDataSource("searchCell")
            case .SearchResults:
                return searchResults
                    .map(toSearchResultItem)
                    .tableViewDataSource("searchCell")
            }
        }).latest()
        
        resultsMajorAxisLabel = combine(displayContent, searchResultsMajorAxis, combine: {
            if $0 == DisplayContent.Favourites {
                return ""
            } else {
                switch $1 {
                case .NorthSouth: return "North to South"
                case .EastWest: return "West to East"
                }
            }
        }).latest()
        
        searchSelection = combine(searchSelectionIndex, dataSource) { index, dataSource in
            if let index = index {
                return dataSource.source.value?[index]
            } else {
                return nil
            }
        }
    }
    
    func clearSearch() {
        searchTerm.value = ""
        searchSelectionIndex.value = nil
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