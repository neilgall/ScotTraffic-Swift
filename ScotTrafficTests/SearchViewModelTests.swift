//
//  SearchViewModelTests.swift
//  ScotTraffic
//
//  Created by ZBS on 12/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import XCTest
@testable import ScotTraffic

extension Search.ContentItem {
    var name: String {
        switch self {
        case .TrafficCameraItem(let location, let index):
            return location.nameAtIndex(index)
        case .OtherMapItem(let mapItem):
            return mapItem.name
        case .SearchItem(let term):
            return term
        }
    }
}

class FavouritesAndSearchViewModelTests: XCTestCase {
    
    func testContentIsFavouritesWhenSearchTermIsEmpty() {
        let testData = TestAppModel()
        
        testData.userDefaults.setObject(["7_1005.jpg","7_608.jpg"], forKey: "favouriteItems")
        testData.favourites.reloadFromUserDefaults()

        let viewModel = FavouritesAndSearchViewModel(scotTraffic: testData)
        viewModel.liveSearchTerm.value = ""
        
        guard let content = viewModel.content.latestValue.get else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(content.type, Search.ContentType.Favourites)
        XCTAssertEqual(content.items.count, 2)
        XCTAssertEqual(content.items[0].name, "Aldclune")
        XCTAssertEqual(content.items[1].name, "Auchengeich")
    }
    
    func testContentIsSearchResultsWhenSearchTermIsNonEmpty() {
        let testData = TestAppModel()
        let viewModel = FavouritesAndSearchViewModel(scotTraffic: testData)
        viewModel.liveSearchTerm.value = "M80"
        
        guard let content = viewModel.content.latestValue.get else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(content.type, Search.ContentType.SearchResults(majorAxis: .EastWest))
        XCTAssertEqual(content.items.count, 19)
    }
    
    func testResultsAxisIsNorthToSouthForA90Search() {
        let testData = TestAppModel()
        let viewModel = FavouritesAndSearchViewModel(scotTraffic: testData)
        viewModel.liveSearchTerm.value = "A90"
        
        guard let content = viewModel.content.latestValue.get else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(content.type, Search.ContentType.SearchResults(majorAxis: .NorthSouth))
    }

    func testResultsAxisIsWestToEastForM8Search() {
        let testData = TestAppModel()
        let viewModel = FavouritesAndSearchViewModel(scotTraffic: testData)
        viewModel.liveSearchTerm.value = "M8"
        
        guard let content = viewModel.content.latestValue.get else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(content.type, Search.ContentType.SearchResults(majorAxis: .EastWest))
    }
    
    func testDefaultSearchSelectionIsNone() {
        let testData = TestAppModel()
        let viewModel = FavouritesAndSearchViewModel(scotTraffic: testData)
        viewModel.liveSearchTerm.value = ""

        let selection = viewModel.contentSelection.latestValue
        guard case .None = selection else {
            XCTFail()
            return
        }
    }
    
    func testSearchSelectionSetBySelectionIndex() {
        let testData = TestAppModel()
        let viewModel = FavouritesAndSearchViewModel(scotTraffic: testData)
        let selection = viewModel.contentSelection.latest()
        
        viewModel.liveSearchTerm.value = "M8"
        viewModel.selectionIndex.value = 3
        
        guard case .Some(let selectionValue) = selection.latestValue.get, case .Item(let selectionItem, _) = selectionValue else {
            XCTFail()
            return
        }
        
        // the exact value here depends on the test data
        XCTAssertEqual(selectionItem.name, "Erskine Br (M8)")
    }
    
    func testSearchSelectionIsEvent() {
        let testData = TestAppModel()
        let viewModel = FavouritesAndSearchViewModel(scotTraffic: testData)
        viewModel.liveSearchTerm.value = "M8"
        viewModel.selectionIndex.value = 3
        
        let selection = viewModel.contentSelection.latestValue
        guard case .None = selection else {
            XCTFail()
            return
        }
    }    
}
