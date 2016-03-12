//
//  AppModelTests.swift
//  ScotTraffic
//
//  Created by Neil Gall on 12/03/2016.
//  Copyright © 2016 Neil Gall. All rights reserved.
//

import XCTest
@testable import ScotTraffic

class AppModelTests: XCTestCase {
    
    struct Fixture {
        let reachability: Input<Bool>
        let userDefaults: StubUserDefaults
        let appModel: AppModel
        
        init(reachable: Bool) {
            reachability = Input(initial: reachable)
            userDefaults = StubUserDefaults()
            appModel = AppModel(cacheSource: stubCacheSource, reachable: reachability, userDefaults: userDefaults)
        }
    }
    
    func testNoLatestValueUntilReachabilityBecomesTrue() {
        let f = Fixture(reachable: false)
        XCTAssertFalse(f.appModel.trafficCameraLocations.latestValue.has)
        XCTAssertFalse(f.appModel.safetyCameras.latestValue.has)
        XCTAssertFalse(f.appModel.alerts.latestValue.has)
        XCTAssertFalse(f.appModel.roadworks.latestValue.has)
        XCTAssertFalse(f.appModel.bridges.latestValue.has)
        XCTAssertFalse(f.appModel.weather.latestValue.has)
    }

    func testHasLatestValueAfterReachabilityBecomesTrue() {
        let f = Fixture(reachable: false)
        f.reachability <-- true
        XCTAssertTrue(f.appModel.trafficCameraLocations.latestValue.has)
        XCTAssertTrue(f.appModel.safetyCameras.latestValue.has)
        XCTAssertTrue(f.appModel.alerts.latestValue.has)
        XCTAssertTrue(f.appModel.roadworks.latestValue.has)
        XCTAssertTrue(f.appModel.bridges.latestValue.has)
        XCTAssertTrue(f.appModel.weather.latestValue.has)
    }
}

private func stubCacheSource(maxAge: NSTimeInterval) -> String -> DataSource {
    return { TestDataSource(maxAge: maxAge, filename: $0) }
}

private struct TestDataSource: DataSource {
    let maxAge: NSTimeInterval
    let filename: String
    let value = Signal<DataSourceData>()
    
    func start() {
        let data = loadTestData(filename)
        value.pushValue(.Fresh(data))
    }
}

private func loadTestData(filename: String) -> NSData {
    for bundle in NSBundle.allBundles() {
        if let path = bundle.pathForResource(filename, ofType: "", inDirectory: "Data"), let data = NSData(contentsOfFile: path) {
            return data
        }
    }
    fatalError("unable to find \(filename)")
}