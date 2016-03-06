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
    let searchTerm: Input<String>
    let searchSelectionIndex: Input<Int?>
    
    // Outputs
    let searchActive = Input(initial: false)
    let content: Signal<Search.Content>
    let canSaveSearch: Signal<Bool>
    let contentSelection: Signal<Search.Selection>
    let savedSearchSelection: Signal<SearchResultsViewModel?>
    
    init(scotTraffic: ScotTraffic) {
        self.favourites = scotTraffic.favourites
        
        let favouritesViewModel = FavouritesViewModel(scotTraffic: scotTraffic)
        let searchResultsViewModel = SearchResultsViewModel(scotTraffic: scotTraffic)
        
        searchTerm = searchResultsViewModel.searchTerm
        searchSelectionIndex = Input(initial: nil)
        
        content = searchTerm.map({ (text: String) -> Signal<Search.Content> in
            let model: SearchContentViewModel = text.isEmpty ? favouritesViewModel : searchResultsViewModel
            return model.content
        }).join()
        
        savedSearchSelection = searchSelectionIndex.mapWith(content, transform: { index, content in
            guard let index = index where content ~= index else {
                return nil
            }
            guard case .SearchItem(let term) = content.items[index] else {
                return nil
            }
            return SearchResultsViewModel(scotTraffic: scotTraffic, term: term)
        }).event()
        
        let savedSearchItemSelection = savedSearchSelection.map({
            return $0?.contentSelection ?? Const(.None)
        }).join()
        
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
        
        contentSelection = union(localItemSelection, savedSearchItemSelection)
        
        canSaveSearch = combine(scotTraffic.favourites.items, searchTerm, combine: { favourites, searchTerm in
            !favourites.containsSavedSearch(searchTerm)
        })
        
        self.favouritesViewModel = favouritesViewModel
        self.searchResultsViewModel = searchResultsViewModel
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

