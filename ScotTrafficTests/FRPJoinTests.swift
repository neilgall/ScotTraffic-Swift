//
//  FRPJoinTests.swift
//  ScotTraffic
//
//  Created by Neil Gall on 04/01/2016.
//  Copyright © 2016 Neil Gall. All rights reserved.
//

import XCTest
import ScotTraffic

// Must be a class so it can be mutated inside the observer closure
private class Capture<T> {
    var obs = [Observation]()
    var vals: [T] = []
    
    init(_ o: Observable<T>, previous: Capture<T>?) {
        if let previous = previous {
            vals.appendContentsOf(previous.vals)
        }
        self.obs.append(o => {
            self.vals.append($0)
        })
    }
}

class FRPJoinTests: XCTestCase {

    func testJoinOnInnerChange() {
        let inner = Input<Bool>(initial: false)
        let outer = Input<Observable<Bool>>(initial: inner)
        let c = Capture(outer.join(), previous: nil)
        
        inner.value = true
        inner.value = false
        XCTAssertEqual(c.vals, [true, false])
    }

    func testJoinOnOuterChange() {
        let outer = Input<Observable<Bool>?>(initial: nil)
        var c: Capture<Bool>? = nil
        let outerObs = outer => {
            if let inner = $0 {
                c = Capture(inner, previous: c)
            } else {
                c = nil
            }
        }
        
        let inner = Input<Bool>(initial: false)
        outer.value = inner
        
        let inner2 = Input<Bool>(initial: true)
        outer.value = inner2
        
        XCTAssertNotNil(c)
        XCTAssertEqual(c!.vals, [false, true])
        XCTAssertNotNil(outerObs)
    }
    
    func testJoinOnBothChange() {
        let outer = Input<Observable<Bool>?>(initial: nil)
        var c: Capture<Bool>? = nil
        let outerObs = outer => {
            if let inner = $0 {
                c = Capture(inner, previous: c)
            } else {
                c = nil
            }
        }
        
        let inner = Input<Bool>(initial: false)
        outer.value = inner
        inner.value = true
        
        XCTAssertNotNil(c)
        XCTAssertEqual(c!.vals, [false, true])
        XCTAssertNotNil(outerObs)
    }
}
