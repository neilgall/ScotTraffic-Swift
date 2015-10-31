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
    
    // A selected search result is a MapItem and an index into its sub-items
    public typealias Selection = (mapItem: MapItem, index: Int)
    
    // Inputs
    public let searchActive: Input<Bool>
    public let searchTerm: Input<String>
    public let searchSelectionIndex: Input<Int?>
    
    // Outputs
    public var dataSource: Latest<TableViewDataSourceAdapter<[SearchResultItem]>>
    public var sectionHeader: Latest<String>
    public var searchSelection: Observable<Selection?>
    
    private var observations = [Observation]()

    
    public init(scotTraffic: ScotTraffic) {
        searchActive = Input(initial: false)
        searchTerm = Input(initial: "")
        searchSelectionIndex = Input(initial: nil)
        
        let favourites = scotTraffic.favourites.trafficCameras.latest()

        let trafficCameras = combine(
            scotTraffic.trafficCameraLocations,
            scotTraffic.settings.showTrafficCamerasOnMap,
            searchTerm,
            combine: applyFilterToMapItems)
        
        let safetyCameras = combine(
            scotTraffic.safetyCameras,
            scotTraffic.settings.showSafetyCamerasOnMap,
            searchTerm,
            combine: applyFilterToMapItems)
        
        let alerts = combine(
            scotTraffic.alerts,
            scotTraffic.settings.showAlertsOnMap,
            searchTerm,
            combine: applyFilterToMapItems)
        
        let roadworks = combine(
            scotTraffic.roadworks,
            scotTraffic.settings.showRoadworksOnMap,
            searchTerm,
            combine: applyFilterToMapItems)
        
        let combinedResults: Observable<[MapItem]> = combine(trafficCameras, safetyCameras, alerts, roadworks) {
            return $0 + $1 + $2 + $3
        }
            
        let searchResults = combinedResults.map { $0.sortGeographically() }.latest()
        let searchResultsMajorAxis = combinedResults.map { $0.majorAxis }

        let displayContent: Observable<DisplayContent> = searchTerm.map { text in
            text.isEmpty ? .Favourites : .SearchResults
        }
        
        dataSource = displayContent.onChange().map { contentType in
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
        }.latest()
        
        sectionHeader = combine(displayContent, searchResultsMajorAxis) {
            if $0 == DisplayContent.Favourites {
                return "Favourites"
            } else {
                switch $1 {
                case .NorthSouth: return "North to South"
                case .EastWest: return "West to East"
                }
            }
        }.latest()
        
        searchSelection = combine(searchSelectionIndex, dataSource) { index, dataSource in
            if let index = index, let searchResult = dataSource.source.value?[index] {
                return (mapItem: searchResult.mapItem, index: searchResult.index)
            } else {
                return nil
            }
        }
        
        // cancel selection before search term changes
        observations.append(searchTerm.willOutput({
            self.searchSelectionIndex.value = nil
        }))
        
        // clear search term and selection on deactivating search
        observations.append(searchActive.filter({ $0 == false }).output({ _ in
            self.searchTerm.value = ""
            self.searchSelectionIndex.value = nil
        }))
    }
    
    public func setSearchActive(active: Bool) {
        self.searchActive.value = active
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
    public let name: String
    public let mapItem: MapItem
    public let index: Int

    public func configureCell(cell: UITableViewCell) {
        if let resultCell = cell as? SearchResultCell {
            resultCell.nameLabel?.text = name
            resultCell.roadLabel?.text = mapItem.road
            resultCell.iconImageView?.image = UIImage(named: mapItem.iconName)
        }
    }
}

func toSearchResultItems(items: [FavouriteTrafficCamera]) -> [SearchResultItem] {
    return items.map { favourite in
        SearchResultItem(name: favourite.name, mapItem: favourite.location, index: favourite.cameraIndex)
    }
}

func toSearchResultItem(items: [MapItem]) -> [SearchResultItem] {
    return items.map { item in
        SearchResultItem(name: item.name, mapItem: item, index: 0)
    }
}
