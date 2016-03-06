//
//  SearchViewModel.swift
//  ScotTraffic
//
//  Created by Neil Gall on 06/03/2016.
//  Copyright © 2016 Neil Gall. All rights reserved.
//

import Foundation

struct Search {
    enum ContentType: Equatable {
        case Favourites
        case SearchResults(majorAxis: GeographicAxis)
    }
    
    enum ContentItem: Equatable {
        case TrafficCameraItem(TrafficCameraLocation, TrafficCameraIndex)
        case OtherMapItem(MapItem)
        case SearchItem(String)
    }
    
    enum Selection {
        case None
        case Item(mapItem: MapItem, index: Int)
    }
    
    struct Content: Equatable {
        let type: ContentType
        let items: [ContentItem]
    }
}

func ~= (content: Search.Content, index: Int) -> Bool {
    return 0..<content.items.count ~= index
}

func == (lhs: Search.ContentType, rhs: Search.ContentType) -> Bool {
    switch (lhs, rhs) {
    case (.Favourites, .Favourites):
        return true
    case (.SearchResults(let lhsAxis), .SearchResults(let rhsAxis)):
        return lhsAxis == rhsAxis
    default:
        return false
    }
}

func == (lhs: Search.ContentItem, rhs: Search.ContentItem) -> Bool {
    switch (lhs, rhs) {
    case (.TrafficCameraItem(let lhsLoc, let lhsIndex), .TrafficCameraItem(let rhsLoc, let rhsIndex)):
        return lhsLoc.name == rhsLoc.name && lhsIndex == rhsIndex
    case (.OtherMapItem(let lhsItem), .OtherMapItem(let rhsItem)):
        return lhsItem == rhsItem
    case (.SearchItem(let lhsTerm), .SearchItem(let rhsTerm)):
        return lhsTerm == rhsTerm
    default:
        return false
    }
}

func == (lhs: Search.Content, rhs: Search.Content) -> Bool {
    return lhs.type == rhs.type && lhs.items == rhs.items
}

protocol SearchContentViewModel {
    var content: Signal<Search.Content> { get }
}

struct FavouritesViewModel: SearchContentViewModel {
    let content: Signal<Search.Content>
    
    init(scotTraffic: ScotTraffic) {
        content = combine(scotTraffic.favourites.items, scotTraffic.trafficCameraLocations, combine: { favourites, trafficCameraLocations in
            return Search.Content(
                type: .Favourites,
                items: contentItemsForFavourites(favourites, locations: trafficCameraLocations)
            )
        })
    }
}

struct SearchResultsViewModel: SearchContentViewModel {
    // Inputs
    let searchTerm: Input<String>
    let searchSelectionIndex: Input<Int?>
    
    // Outputs
    let content: Signal<Search.Content>
    let contentSelection: Signal<Search.Selection>
    
    init(scotTraffic: ScotTraffic, term: String = "") {
        searchTerm = Input(initial: term)
        searchSelectionIndex = Input(initial: nil)
        
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
        
        content = combinedResults.map({ (items: [MapItem]) -> Search.Content in
            Search.Content(
                type: .SearchResults(majorAxis: items.majorAxis),
                items: items.map({ .OtherMapItem($0) })
            )
        }).latest()

        contentSelection = searchSelectionIndex.mapWith(content, transform: { index, content in
            guard let index = index where content ~= index else {
                return .None
            }
            guard case .OtherMapItem(let mapItem) = content.items[index] else {
                return .None
            }
            return .Item(mapItem: mapItem, index: 0)
        }).event()
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

private func contentItemsForFavourites(favourites: [FavouriteItem], locations: [TrafficCameraLocation]) -> [Search.ContentItem] {
    return favourites.flatMap({ favourite in
        switch favourite {
        case .TrafficCamera(let identifier):
            return locations.findIdentifier(identifier).map({ .TrafficCameraItem($0, $1) })
            
        case .SavedSearch(let term):
            return .SearchItem(term)
        }
    })
}
