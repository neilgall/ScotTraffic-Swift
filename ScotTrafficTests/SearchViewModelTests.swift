//
//  SearchViewModelTests.swift
//  ScotTraffic
//
//  Created by ZBS on 12/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import XCTest
@testable import ScotTraffic

extension SearchViewModel.ContentItem {
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

class SearchViewModelTests: XCTestCase {
    
    func testContentTypeIsFavouritesWhenSearchTermIsEmpty() {
        let testData = TestAppModel()
        
        testData.userDefaults.setObject(["7_1005.jpg","7_608.jpg"], forKey: "favouriteItems")
        testData.favourites.reloadFromUserDefaults()

        let viewModel = SearchViewModel(scotTraffic: testData)
        viewModel.searchTerm.value = ""
        
        guard let searchResults = viewModel.content.latestValue.get else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(searchResults.count, 2)
        XCTAssertEqual(searchResults[0].name, "Aldclune")
        XCTAssertEqual(searchResults[1].name, "Auchengeich")
    }
    
    func testHeaderIsFavouritesWhenSearchTermIsEmpty() {
        let testData = TestAppModel()
        let viewModel = SearchViewModel(scotTraffic: testData)
        viewModel.searchTerm.value = ""

        guard let header = viewModel.sectionHeader.latestValue.get else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(header, "FavouritesHeadingView")
    }
    
    func testDataSourceIsSearchResultsWhenSearchTermIsNonEmpty() {
        let testData = TestAppModel()
        let viewModel = SearchViewModel(scotTraffic: testData)
        viewModel.searchTerm.value = "M80"
        
        guard let searchResults = viewModel.content.latestValue.get else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(searchResults.count, 19)
    }
    
    func testHeaderIsNorthToSouthForA90Search() {
        let testData = TestAppModel()
        let viewModel = SearchViewModel(scotTraffic: testData)
        viewModel.searchTerm.value = "A90"
        
        guard let header = viewModel.sectionHeader.latestValue.get else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(header, "NorthToSouthHeadingView")
    }

    func testHeaderIsWestToEastForM8Search() {
        let testData = TestAppModel()
        let viewModel = SearchViewModel(scotTraffic: testData)
        viewModel.searchTerm.value = "M8"
        
        guard let header = viewModel.sectionHeader.latestValue.get else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(header, "WestToEastHeadingView")
    }
    
    func testDefaultSearchSelectionIsNil() {
        let testData = TestAppModel()
        let viewModel = SearchViewModel(scotTraffic: testData)
        viewModel.searchTerm.value = ""

        guard let selection = viewModel.contentSelection.latestValue.get else {
            XCTFail()
            return
        }
        
        XCTAssertNil(selection)
    }
    
    func testSearchSelectionSetBySelectionIndex() {
        let testData = TestAppModel()
        let viewModel = SearchViewModel(scotTraffic: testData)
        viewModel.searchTerm.value = "M8"
        viewModel.searchSelectionIndex.value = 3
        
        guard let selection = viewModel.contentSelection.latestValue.get else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(selection?.mapItem.name, "Glasgow Airport")
    }
    
    func testSearchSelectionClearedByCancellingSearch() {
        let testData = TestAppModel()
        let viewModel = SearchViewModel(scotTraffic: testData)
        viewModel.searchTerm.value = "M8"
        viewModel.searchSelectionIndex.value = 3
        viewModel.searchTerm.value = ""
        
        guard let selection = viewModel.contentSelection.latestValue.get else {
            XCTFail()
            return
        }
        
        XCTAssertNil(selection)
    }
    
    func testSearchSelectionClearedByChangingSearchTerm() {
        let testData = TestAppModel()
        let viewModel = SearchViewModel(scotTraffic: testData)
        viewModel.searchTerm.value = "M8"
        viewModel.searchSelectionIndex.value = 3
        viewModel.searchTerm.value = "M80"

        guard let selection = viewModel.contentSelection.latestValue.get else {
            XCTFail()
            return
        }
        
        XCTAssertNil(selection)
    }
    
    func testDeactivatingSearchClearsSearchTermAndSelection() {
        let viewModel = SearchViewModel(scotTraffic: TestAppModel())
        viewModel.searchActive.value = true
        viewModel.searchTerm.value = "M80"
        viewModel.searchSelectionIndex.value = 3
        
        viewModel.searchActive.value = false
        
        guard let term = viewModel.searchTerm.latestValue.get, selection = viewModel.contentSelection.latestValue.get else {
            XCTFail()
            return
        }
        
        XCTAssertTrue(term.isEmpty)
        XCTAssertNil(selection)
    }
}
