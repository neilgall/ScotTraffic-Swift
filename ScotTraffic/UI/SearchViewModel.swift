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
    private enum DisplayContent {
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
    
    private var observations = [Observation]()

    
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
                    .tableViewDataSource(SearchResultCell.cellIdentifier)
            case .SearchResults:
                return searchResults
                    .map(toSearchResultItem)
                    .tableViewDataSource(SearchResultCell.cellIdentifier)
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
                return dataSource.source.value?[index].mapItem
            } else {
                return nil
            }
        }
        
        // cancel selection before search term changes
        observations.append(searchTerm.willOutput({
            self.searchSelectionIndex.value = nil
        }))
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

public struct SearchResultItem: TableViewCellConfigurator {
    public let mapItem: MapItem

    public init(item: MapItem) {
        self.mapItem = item
    }
    
    public func configureCell(cell: UITableViewCell) {
        if let resultCell = cell as? SearchResultCell {
            resultCell.nameLabel?.text = mapItem.name
            resultCell.roadLabel?.text = mapItem.road
            resultCell.iconImageView?.image = UIImage(named: mapItem.iconName)
        }
    }
}

public func toSearchResultItems(items: [FavouriteTrafficCamera]) -> [SearchResultItem] {
    return items.map { SearchResultItem(item: $0.location) }
}

public func toSearchResultItem(items: [MapItem]) -> [SearchResultItem] {
    return items.map { SearchResultItem(item: $0) }
}
