//
//  SearchViewModelTests.swift
//  ScotTraffic
//
//  Created by ZBS on 12/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import XCTest
import ScotTraffic

class SearchViewModelTests: XCTestCase {
    
    func testDataSourceIsFavouritesWhenSearchTermIsEmpty() {
        let testData = TestAppModel()
        
        testData.userDefaults.setObject(["7_1005.jpg","7_608.jpg"], forKey: "favouriteItems")
        testData.notifyUserDefaultsChange()

        let viewModel = SearchViewModel(scotTraffic: testData)
        viewModel.searchTerm.value = ""
        
        guard let searchResults = viewModel.dataSource.pullValue?.source.pullValue else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(searchResults.count, 2)
        XCTAssertEqual(searchResults[0].name, "Aldclune")
        XCTAssertEqual(searchResults[1].name, "Auchengeich")
    }
    
    func testHeadingLabelIsEmptyWhenSearchTermIsEmpty() {
        let testData = TestAppModel()
        let viewModel = SearchViewModel(scotTraffic: testData)
        viewModel.searchTerm.value = ""

        guard let heading = viewModel.resultsMajorAxisLabel.pullValue else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(heading, "")
    }
    
    func testDataSourceIsSearchResultsWhenSearchTermIsNonEmpty() {
        let testData = TestAppModel()
        let viewModel = SearchViewModel(scotTraffic: testData)
        viewModel.searchTerm.value = "M80"
        
        guard let searchResults = viewModel.dataSource.pullValue?.source.pullValue else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(searchResults.count, 19)
    }
    
    func testHeadingIsNorthToSouthForA90Search() {
        let testData = TestAppModel()
        let viewModel = SearchViewModel(scotTraffic: testData)
        viewModel.searchTerm.value = "A90"
        
        guard let heading = viewModel.resultsMajorAxisLabel.pullValue else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(heading, "North to South")
    }

    func testHeadingIsWestToEastForM8Search() {
        let testData = TestAppModel()
        let viewModel = SearchViewModel(scotTraffic: testData)
        viewModel.searchTerm.value = "M8"
        
        guard let heading = viewModel.resultsMajorAxisLabel.pullValue else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(heading, "West to East")
    }
    
    func testDefaultSearchSelectionIsNil() {
        let testData = TestAppModel()
        let viewModel = SearchViewModel(scotTraffic: testData)
        viewModel.searchTerm.value = ""

        guard let selection = viewModel.searchSelection.pullValue else {
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
        
        guard let selection = viewModel.searchSelection.pullValue else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(selection?.name, "Glasgow Airport")
    }
    
    func testSearchSelectionClearedByCancellingSearch() {
        let testData = TestAppModel()
        let viewModel = SearchViewModel(scotTraffic: testData)
        viewModel.searchTerm.value = "M8"
        viewModel.searchSelectionIndex.value = 3
        viewModel.searchTerm.value = ""
        
        guard let selection = viewModel.searchSelection.pullValue else {
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

        guard let selection = viewModel.searchSelection.pullValue else {
            XCTFail()
            return
        }
        
        XCTAssertNil(selection)
    }
}
