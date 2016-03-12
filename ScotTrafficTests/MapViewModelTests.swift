//
//  MapViewModelTests.swift
//  ScotTraffic
//
//  Created by Neil Gall on 17/11/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import XCTest
import MapKit
@testable import ScotTraffic

private let scotlandMapRect = MKMapRectMake(129244330.1, 79649811.3, 3762380.0, 6443076.1)

private class Capture<T> {
    var value: T?
    var observation: ReceiverType!
    
    init(_ obs: Signal<T>) {
        observation = (obs --> { self.value = $0 })
    }
}

private extension MKMapPoint {
    func rectAround(size: Double) -> MKMapRect {
        return MKMapRect(origin: MKMapPoint(x: self.x - size/2, y: self.y - size/2), size: MKMapSize(width: size, height: size))
    }
}

class MapViewModelTests: XCTestCase {
 
//    func testSelectMapItem() {
//        let appData = StubAppModel()
//        let viewModel = MapViewModel(scotTraffic: appData)
//        
//        let selectedAnnotation = Capture(viewModel.selectedAnnotation)
//        let newInn = appData.trafficCameraLocationNamed("New Inn")!
//        let baberton = appData.trafficCameraLocationNamed("Baberton")!
//
//        viewModel.visibleMapRect.value = scotlandMapRect
//        viewModel.selectedMapItem.value = newInn
//        XCTAssertNil(selectedAnnotation.value?.flatMap({$0}))
//        
//        viewModel.animatingMapRect.value = true
//        XCTAssertNil(selectedAnnotation.value?.flatMap({$0}))
//        
//        viewModel.visibleMapRect.value = newInn.mapPoint.rectAround(4000)
//        viewModel.animatingMapRect.value = false
//        XCTAssertNotNil(selectedAnnotation.value?.flatMap({$0}))
//    }
}
