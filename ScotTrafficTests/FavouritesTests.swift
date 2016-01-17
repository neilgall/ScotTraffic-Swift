//
//  FavouritesTests.swift
//  ScotTraffic
//
//  Created by Neil Gall on 30/12/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import XCTest
@testable import ScotTraffic

class FavouritesTests: XCTestCase {

    var userDefaults: TestUserDefaults!
    var favourites: Favourites!
    
    override func setUp() {
        super.setUp()
        
        userDefaults = TestUserDefaults()
        favourites = Favourites(userDefaults: userDefaults)
    }
    
    override func tearDown() {
        userDefaults = nil
        favourites = nil
        
        super.tearDown()
    }
    
    func testIsEmptyOnInit() {
        XCTAssertTrue(favourites.items.value.isEmpty)
    }
    
    func testAdd() {
        favourites.addItem(.SavedSearch(term: "Foo"))
        XCTAssertEqual(favourites.items.value, [.SavedSearch(term: "Foo")])
    }
    
    func testDeleteSavedSearch() {
        favourites.addItem(.SavedSearch(term: "Foo"))
        favourites.addItem(.SavedSearch(term: "Bar"))
        favourites.deleteItem(.SavedSearch(term: "Foo"))
        XCTAssertEqual(favourites.items.value, [.SavedSearch(term: "Bar")])
    }
    
    func testDeleteTrafficCamera() {
        favourites.addItem(.TrafficCamera(identifier: "Foo"))
        favourites.addItem(.SavedSearch(term: "Bar"))
        favourites.deleteItem(.TrafficCamera(identifier: "Foo"))
        XCTAssertEqual(favourites.items.value, [.SavedSearch(term: "Bar")])
    }
    
    func testDeleteAtIndex() {
        favourites.addItem(.SavedSearch(term: "Foo"))
        favourites.addItem(.SavedSearch(term: "Bar"))
        favourites.deleteItemAtIndex(1)
        XCTAssertEqual(favourites.items.value, [.SavedSearch(term: "Foo")])
    }
    
    func testLoadFromUserDefaults_Pre1_2() {
        userDefaults.setObject(["4_1181_cam1.jpg", "4_1193_cam1.jpg"], forKey: "favouriteItems")
        favourites.reloadFromUserDefaults()
        
        XCTAssertEqual(favourites.items.value, [
            .TrafficCamera(identifier: "4_1181_cam1.jpg"),
            .TrafficCamera(identifier: "4_1193_cam1.jpg")
        ])
    }
    
    func testLoadFromDefaults_Current() {
        userDefaults.setObject([
            ["type": "trafficCamera", "identifier": "4_1181_cam1.jpg"],
            ["type": "savedSearch", "term": "M80"] ], forKey: "favouriteItems")
        favourites.reloadFromUserDefaults()
        
        XCTAssertEqual(favourites.items.value, [
            .TrafficCamera(identifier: "4_1181_cam1.jpg"),
            .SavedSearch(term: "M80")
        ])
    }
    
    func testSaveToDefaults() {
        favourites.addItem(.SavedSearch(term: "M9"))
        favourites.addItem(.TrafficCamera(identifier: "4_1193_cam1.jpg"))
        
        let savedValue = userDefaults.objectForKey("favouriteItems") as? [[String: String]]
        XCTAssertNotNil(savedValue)
        XCTAssertEqual(savedValue!, [
            [ "type": "savedSearch", "term": "M9"],
            [ "type": "trafficCamera", "identifier": "4_1193_cam1.jpg"]
        ])
    }
    
    func testMoveDown() {
        let (a,b,c,d,e) = ("4_1181_cam1.jpg", "4_1193_cam1.jpg", "4_1193_cam2.jpg", "4_6020_cam1.jpg", "4_6020_cam2.jpg")
        userDefaults.setObject([a,b,c,d,e], forKey: "favouriteItems")
        favourites.reloadFromUserDefaults()
        
        favourites.moveItemFromIndex(1, toIndex: 3)
        
        XCTAssertEqual(favourites.items.value, [a,c,d,b,e].map({ .TrafficCamera(identifier: $0) }))
    }

    func testMoveUp() {
        let (a,b,c,d,e) = ("4_1181_cam1.jpg", "4_1193_cam1.jpg", "4_1193_cam2.jpg", "4_6020_cam1.jpg", "4_6020_cam2.jpg")
        userDefaults.setObject([a,b,c,d,e], forKey: "favouriteItems")
        favourites.reloadFromUserDefaults()
        
        favourites.moveItemFromIndex(4, toIndex: 0)
        
        XCTAssertEqual(favourites.items.value, [e, a, b, c, d].map({ .TrafficCamera(identifier: $0) }))
    }

    func testMoveSame() {
        let (a,b,c,d,e) = ("4_1181_cam1.jpg", "4_1193_cam1.jpg", "4_1193_cam2.jpg", "4_6020_cam1.jpg", "4_6020_cam2.jpg")
        userDefaults.setObject([a,b,c,d,e], forKey: "favouriteItems")
        favourites.reloadFromUserDefaults()
        
        favourites.moveItemFromIndex(2, toIndex: 2)
        
        XCTAssertEqual(favourites.items.value, [a, b, c, d, e].map({ .TrafficCamera(identifier: $0) }))
        
    }
}
