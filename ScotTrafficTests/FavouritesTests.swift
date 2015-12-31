//
//  FavouritesTests.swift
//  ScotTraffic
//
//  Created by Neil Gall on 30/12/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import XCTest
import ScotTraffic

class FavouritesTests: XCTestCase {

    var appModel: TestAppModel!
    var userDefaults: TestUserDefaults!
    var favourites: Favourites!
    
    override func setUp() {
        super.setUp()
        
        appModel = TestAppModel()
        userDefaults = TestUserDefaults()
        favourites = Favourites(userDefaults: userDefaults, trafficCameraLocations: appModel.trafficCameraLocations)
    }
    
    override func tearDown() {
        appModel = nil
        userDefaults = nil
        favourites = nil
        
        super.tearDown()
    }
    
    func testMoveDown() {
        let (a,b,c,d,e) = ("4_1181_cam1.jpg", "4_1193_cam1.jpg", "4_1193_cam2.jpg", "4_6020_cam1.jpg", "4_6020_cam2.jpg")
        userDefaults.setObject([a,b,c,d,e], forKey: "favouriteItems")
        favourites.reloadFromUserDefaults()
        
        let identifiers = favourites.trafficCameras.map({ $0.map({ $0.identifier }) }).latest()
        
        favourites.moveItemFromIndex(1, toIndex: 3)
        
        XCTAssertEqual(identifiers.pullValue!, [a, c, d, b, e])
    }

    func testMoveUp() {
        let (a,b,c,d,e) = ("4_1181_cam1.jpg", "4_1193_cam1.jpg", "4_1193_cam2.jpg", "4_6020_cam1.jpg", "4_6020_cam2.jpg")
        userDefaults.setObject([a,b,c,d,e], forKey: "favouriteItems")
        favourites.reloadFromUserDefaults()
        
        let identifiers = favourites.trafficCameras.map({ $0.map({ $0.identifier }) }).latest()
        
        favourites.moveItemFromIndex(4, toIndex: 0)
        
        XCTAssertEqual(identifiers.pullValue!, [e, a, b, c, d])
    }

    func testMoveSame() {
        let (a,b,c,d,e) = ("4_1181_cam1.jpg", "4_1193_cam1.jpg", "4_1193_cam2.jpg", "4_6020_cam1.jpg", "4_6020_cam2.jpg")
        userDefaults.setObject([a,b,c,d,e], forKey: "favouriteItems")
        favourites.reloadFromUserDefaults()
        
        let identifiers = favourites.trafficCameras.map({ $0.map({ $0.identifier }) }).latest()
        
        favourites.moveItemFromIndex(2, toIndex: 2)
        
        XCTAssertEqual(identifiers.pullValue!, [a, b, c, d, e])
        
    }
}
