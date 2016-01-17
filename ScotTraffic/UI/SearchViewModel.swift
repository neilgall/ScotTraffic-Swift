//
//  SearchViewModel.swift
//  ScotTraffic
//
//  Created by Neil Gall on 03/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit
import MapKit

class SearchViewModel {
    private enum DisplayContent {
        case Favourites
        case SearchResults
    }
    
    // A selected search result is a MapItem and an index into its sub-items
    typealias Selection = (mapItem: MapItem, index: Int)
    
    // Inputs
    let searchActive: Input<Bool>
    let searchTerm: Input<String>
    let searchSelectionIndex: Input<Int?>
    
    // Outputs
    var dataSource: Signal<TableViewDataSourceAdapter<Signal<[SearchResultItem]>>>
    var sectionHeader: Signal<String>
    var searchSelection: Signal<Selection?>
    
    private var favourites: Favourites
    private var receivers = [ReceiverType]()

    
    init(scotTraffic: ScotTraffic) {
        searchActive = Input(initial: false)
        searchTerm = Input(initial: "")
        searchSelectionIndex = Input(initial: nil)
        
        favourites = scotTraffic.favourites
        let latestFavourites = favourites.trafficCameras.latest()

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
        
        let bridges = combine(
            scotTraffic.bridges,
            scotTraffic.settings.showBridgesOnMap,
            searchTerm,
            combine: applyFilterToMapItems)
        
        let combinedResults: Signal<[MapItem]> = combine(trafficCameras, safetyCameras, alerts, roadworks, bridges) {
            return Array([$0, $1, $2, $3, $4].flatten())
        }
            
        let searchResults = combinedResults.map { $0.sortGeographically() }.latest()
        let searchResultsMajorAxis = combinedResults.map { $0.majorAxis }

        let displayContent: Signal<DisplayContent> = searchTerm.map { text in
            text.isEmpty ? .Favourites : .SearchResults
        }
        
        dataSource = displayContent.onChange().map { contentType in
            switch contentType {
            case .Favourites:
                return latestFavourites
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
                return "FavouritesHeadingView"
            } else {
                switch $1 {
                case .NorthSouth: return "NorthToSouthHeadingView"
                case .EastWest: return "WestToEastHeadingView"
                }
            }
        }.latest()
        
        searchSelection = combine(searchSelectionIndex, dataSource) { index, dataSource in
            if let index = index, let searchResult = dataSource.source.latestValue.get?[index] {
                return (mapItem: searchResult.mapItem, index: searchResult.index)
            } else {
                return nil
            }
        }
        
        // cancel selection before search term changes
        receivers.append(searchTerm.willOutput({
            self.searchSelectionIndex <-- nil
        }))
        
        // clear search term and selection on deactivating search
        receivers.append(searchActive.onFallingEdge {
            self.searchTerm <-- ""
            self.searchSelectionIndex <-- nil
        })
    }
    
    func setSearchActive(active: Bool) {
        self.searchActive <-- active
    }
    
    func deleteFavouriteAtIndex(index: Int) {
        favourites.trafficCameras.map({ $0[index] }) --> { favouriteToDelete in
            self.favourites.toggleItem(favouriteToDelete)
        }
    }
    
    func moveFavouriteAtIndex(sourceIndex: Int, toIndex destinationIndex: Int) {
        favourites.moveItemFromIndex(sourceIndex, toIndex: destinationIndex)
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

struct SearchResultItem: TableViewCellConfigurator {
    let name: String
    let mapItem: MapItem
    let index: Int

    func configureCell(cell: UITableViewCell) {
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
