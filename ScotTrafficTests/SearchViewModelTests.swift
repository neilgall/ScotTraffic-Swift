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
    
    
}
