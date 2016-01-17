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
    enum ContentType {
        case Favourites
        case SearchResults
    }

    enum ContentItem {
        case TrafficCameraItem(TrafficCameraLocation, TrafficCameraIndex)
        case OtherMapItem(MapItem)
        case SearchItem(String)
    }

    // A selected search result is a MapItem and an index into its sub-items
    typealias Selection = (mapItem: MapItem, index: Int)
    
    // Inputs
    let searchActive: Input<Bool>
    let searchTerm: Input<String>
    let searchSelectionIndex: Input<Int?>
    
    // Outputs
    let contentType: Signal<ContentType>
    let content: Signal<[ContentItem]>
    let sectionHeader: Signal<String>
    let canSaveSearch: Signal<Bool>
    let contentSelection: Signal<Selection?>
    let savedSearchSelection: Signal<String?>
    
    private var favourites: Favourites
    private var receivers = [ReceiverType]()

    
    init(scotTraffic: ScotTraffic) {
        searchActive = Input(initial: false)
        searchTerm = Input(initial: "")
        searchSelectionIndex = Input(initial: nil)
        
        favourites = scotTraffic.favourites

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

        contentType = searchTerm.map { text in
            text.isEmpty ? .Favourites : .SearchResults
        }
        
        content = combine(contentType, searchResults, scotTraffic.favourites.items, scotTraffic.trafficCameraLocations, combine: {
            contentType, searchResults, favourites, trafficCameraLocations in

            switch contentType {
            case .Favourites:
                return searchResultsForFavourites(favourites, locations: trafficCameraLocations)
                
            case .SearchResults:
                return searchResults.map({ .OtherMapItem($0) })
            }
        }).latest()
                
        sectionHeader = combine(contentType, searchResultsMajorAxis) {
            if case .Favourites = $0 {
                return "FavouritesHeadingView"
            } else {
                switch $1 {
                case .NorthSouth: return "NorthToSouthHeadingView"
                case .EastWest: return "WestToEastHeadingView"
                }
            }
        }.latest()
        
        contentSelection = combine(searchSelectionIndex, content, combine: { index, content in
            guard let index = index else {
                return nil
            }
            switch content[index] {
            case .TrafficCameraItem(let location, let index):
                return (mapItem: location, index: index)
            case .OtherMapItem(let mapItem):
                return (mapItem: mapItem, index: 0)
            case .SearchItem:
                return nil
            }
        })
        
        canSaveSearch = combine(favourites.items, searchTerm, combine: { favourites, searchTerm in
            !favourites.savedSearches.contains(searchTerm)
        })
        
        savedSearchSelection = combine(searchSelectionIndex, content, combine: { index, content in
            guard let index = index, case .SearchItem(let term) = content[index] else {
                return nil
            }
            return term
        })
        
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
        searchActive <-- active
    }
    
    func deleteFavouriteAtIndex(index: Int) {
        favourites.deleteItemAtIndex(index)
    }
    
    func moveFavouriteAtIndex(sourceIndex: Int, toIndex destinationIndex: Int) {
        favourites.moveItemFromIndex(sourceIndex, toIndex: destinationIndex)
    }
    
    func saveSearch() {
        if let searchTerm = searchTerm.latestValue.get {
            favourites.addItem(.SavedSearch(term: searchTerm))
        }
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

extension SearchViewModel.ContentItem: TableViewCellConfigurator {
    func configureCell(cell: UITableViewCell) {
        guard let resultCell = cell as? SearchResultCell else {
            return
        }
        switch self {
        case .TrafficCameraItem(let location, let index):
            resultCell.nameLabel?.text = location.nameAtIndex(index)
            resultCell.roadLabel?.text = location.road
            resultCell.iconImageView?.image = UIImage(named: location.iconName)
        case .OtherMapItem(let mapItem):
            resultCell.nameLabel?.text = mapItem.name
            resultCell.roadLabel?.text = mapItem.road
            resultCell.iconImageView?.image = UIImage(named: mapItem.iconName)
        case .SearchItem(let term):
            resultCell.nameLabel?.text = term
            resultCell.roadLabel?.text = nil
            resultCell.iconImageView?.image = UIImage(named: "708-search-gray")
        }
    }
}

private func searchResultsForFavourites(favourites: [FavouriteItem], locations: [TrafficCameraLocation]) -> [SearchViewModel.ContentItem] {
    return favourites.flatMap({ favourite in
        switch favourite {
        case .TrafficCamera(let identifier):
            return locations.findIdentifier(identifier).map({ .TrafficCameraItem($0, $1) })
            
        case .SavedSearch(let term):
            return .SearchItem(term)
        }
    })
}
