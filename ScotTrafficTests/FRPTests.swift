//
//  FRPTests.swift
//  ScotTraffic
//
//  Created by Neil Gall on 30/09/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import XCTest
import ScotTraffic

// Must be a class so it can be mutated inside the observer closure
class Capture<T> {
    var obs = Observations()
    var vals: [T] = []
    
    init(_ o: Observable<T>) {
        self.obs.add(o) {
            self.vals.append($0)
        }
    }
}

class FRPTests: XCTestCase {

    func testSourceCanSink() {
        let s = Source<Int>(initial: 0)
        let c = Capture(s)
        
        s.value = 123
        s.value = 234
        XCTAssertEqual(c.vals, [123, 234])
    }
    
    func testDiscardingObservationCancelsSink() {
        let s = Source<Int>(initial: 0)
        let c = Capture(s)
        
        s.value = 123
        XCTAssertEqual(c.vals, [123])
        
        c.obs.clear()
        s.value = 234
        XCTAssertEqual(c.vals, [123])
    }
    
    func testMap() {
        let s = Source<Int>(initial: 0)
        let m = s.map { $0 + 1 }
        let c = Capture(m)
        
        s.value = 123
        XCTAssertEqual(c.vals, [124])
    }
    
    func testFilter() {
        let s = Source<Int>(initial: 0)
        let f = s.filter { $0 > 5 }
        let c = Capture(f)
        
        s.value = 2
        s.value = 9
        s.value = 6
        s.value = 4
        XCTAssertEqual(c.vals, [9, 6])
    }
    
    func testUnion() {
        let s1 = Source<Int>(initial: 0)
        let s2 = Source<Int>(initial: 0)
        let u = union(s1, s2)
        let c = Capture(u)
        
        s1.value = 6
        s2.value = 3
        s1.value = 10
        s1.value = 7
        s2.value = 14
        XCTAssertEqual(c.vals, [6,3,10,7,14])
    }
    
    func testCombine2() {
        let s1 = Source<Int>(initial: 0)
        let s2 = Source<String>(initial: "")
        let m = combine(s1, s2) { i,s in "\(i):\(s)" }
        let c = Capture(m)
        
        s1.value = 123
        s2.value = "foo"
        s1.value = 234
        s2.value = "bar"
        XCTAssertEqual(c.vals, ["123:foo", "234:foo", "234:bar"])
    }
}
