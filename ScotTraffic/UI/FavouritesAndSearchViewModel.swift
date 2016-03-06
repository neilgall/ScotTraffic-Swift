//
//  SearchViewModel.swift
//  ScotTraffic
//
//  Created by Neil Gall on 03/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit
import MapKit

struct FavouritesAndSearchViewModel {
    private let favourites: Favourites
    private let favouritesViewModel: FavouritesViewModel
    private let searchResultsViewModel: SearchResultsViewModel
    
    // Inputs
    let liveSearchTerm: Input<String>
    let enteredSearchTerm: Input<String>
    let searchSelectionIndex: Input<Int?>
    
    // Outputs
    let searchActive = Input(initial: false)
    let content: Signal<Search.Content>
    let contentSelection: Signal<Search.Selection>
    let searchSelection: Signal<SearchResultsViewModel?>
    
    init(scotTraffic: ScotTraffic) {
        self.favourites = scotTraffic.favourites
        
        let favouritesViewModel = FavouritesViewModel(scotTraffic: scotTraffic)
        let liveSearchResultsViewModel = SearchResultsViewModel(scotTraffic: scotTraffic)
        
        liveSearchTerm = liveSearchResultsViewModel.searchTerm
        enteredSearchTerm = Input(initial: "")
        searchSelectionIndex = Input(initial: nil)
        
        content = liveSearchTerm.map({ (text: String) -> Signal<Search.Content> in
            let model: SearchContentViewModel = text.isEmpty ? favouritesViewModel : liveSearchResultsViewModel
            return model.content
        }).join()
        
        let currentSearchSelection: Signal<SearchResultsViewModel?> = enteredSearchTerm.event().mapWith(content, transform: { term, content in
            return SearchResultsViewModel(scotTraffic: scotTraffic, term: term)
        })
        
        let savedSearchSelection: Signal<SearchResultsViewModel?> = searchSelectionIndex.event().mapWith(content, transform: { index, content in
            guard let index = index where content ~= index else {
                return nil
            }
            guard case .SearchItem(let term) = content.items[index] else {
                return nil
            }
            return SearchResultsViewModel(scotTraffic: scotTraffic, term: term)
        })
        
        let localItemSelection: Signal<Search.Selection> = searchSelectionIndex.mapWith(content, transform: { index, content in
            guard let index = index where content ~= index else {
                return .None
            }
            switch content.items[index] {
            case .TrafficCameraItem(let location, let index):
                return .Item(mapItem: location, index: index)
            case .OtherMapItem(let mapItem):
                return .Item(mapItem: mapItem, index: 0)
            case .SearchItem:
                return .None
            }
        }).event()
        
        searchSelection = union(currentSearchSelection, savedSearchSelection)

        let savedSearchItemSelection = searchSelection.map({
            return $0?.contentSelection ?? Const(.None)
        }).join()
        
        contentSelection = union(localItemSelection, savedSearchItemSelection)
        
        self.favouritesViewModel = favouritesViewModel
        self.searchResultsViewModel = liveSearchResultsViewModel
    }
    
    func deleteFavouriteAtIndex(index: Int) {
        favourites.deleteItemAtIndex(index)
    }
    
    func moveFavouriteAtIndex(sourceIndex: Int, toIndex destinationIndex: Int) {
        favourites.moveItemFromIndex(sourceIndex, toIndex: destinationIndex)
    }
}

