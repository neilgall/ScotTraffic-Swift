//
//  SearchViewModel.swift
//  ScotTraffic
//
//  Created by Neil Gall on 03/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit
import MapKit

public class SearchViewModel {
    enum DisplayContent {
        case Favourites
        case SearchResults
    }

    // Inputs
    public let searchTerm: Input<String>
    public let searchSelectionIndex: Input<Int?>
    
    // Outputs
    public var dataSource: Latest<TableViewDataSourceAdapter<[SearchResultItem]>>
    public var resultsMajorAxisLabel: Latest<String>
    public var searchSelection: Observable<MapItem?>
    

    public init(scotTraffic: ScotTraffic) {
        searchTerm = Input(initial: "")
        searchSelectionIndex = Input(initial: nil)
        
        let favourites = scotTraffic.favourites.trafficCameras.latest()

        let trafficCameras = combine(
            scotTraffic.trafficCameraLocations, scotTraffic.settings.showTrafficCamerasOnMap, self.searchTerm,
            combine: applyFilterToMapItems)
        
        let safetyCameras = combine(
            scotTraffic.safetyCameras, scotTraffic.settings.showSafetyCamerasOnMap, self.searchTerm,
            combine: applyFilterToMapItems)
        
        let alerts = combine(
            scotTraffic.alerts, scotTraffic.settings.showAlertsOnMap, self.searchTerm,
            combine: applyFilterToMapItems)
        
        let roadworks = combine(
            scotTraffic.roadworks, scotTraffic.settings.showRoadworksOnMap, self.searchTerm,
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
        searchSelectionIndex.value = nil
        searchTerm.value = ""
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

public struct SearchResultItem: MapItem, TableViewCellConfigurator {
    public let name: String
    public let road: String
    public let mapPoint: MKMapPoint
    
    public init(item: MapItem) {
        self.name = item.name
        self.road = item.road
        self.mapPoint = item.mapPoint
    
    }
    public func configureCell(cell: UITableViewCell) {
        cell.textLabel?.text = name
        cell.detailTextLabel?.text = road
    }
}

public func toSearchResultItems(items: [FavouriteTrafficCamera]) -> [SearchResultItem] {
    return items.map { SearchResultItem(item: $0.location) }
}

public func toSearchResultItem(items: [MapItem]) -> [SearchResultItem] {
    return items.map { SearchResultItem(item: $0) }
}
