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
    var obs = [Observation]()
    var vals: [T] = []
    
    init(_ o: Observable<T>) {
        self.obs.append(o.output {
            self.vals.append($0)
        })
    }
}

class FRPTests: XCTestCase {

    func testInputCanOutput() {
        let s = Input<Int>(initial: 0)
        let c = Capture(s)
        
        s.value = 123
        s.value = 234
        XCTAssertEqual(c.vals, [0, 123, 234])
    }
    
    func testDiscardingObservationCancelsOutput() {
        let s = Input<Int>(initial: 66)
        let c = Capture(s)
        
        s.value = 123
        XCTAssertEqual(c.vals, [66, 123])
        
        c.obs.removeAll()
        s.value = 234
        XCTAssertEqual(c.vals, [66, 123])
    }
    
    func testMap_pushable() {
        let s = Input<Int>(initial: 7)
        let m = s.map { $0 + 1 }
        let c = Capture(m)
        
        s.value = 123
        XCTAssertEqual(c.vals, [8, 124])
    }
    
    func testMap_notPushable() {
        let s = Observable<Int>()
        let m = s.map { $0 * 2 }
        let c = Capture(m)
        
        s.pushValue(18)
        XCTAssertEqual(c.vals, [36])
    }
    
    func testFilter_pushable() {
        let s = Input<Int>(initial: 0)
        let f = s.filter { $0 > 5 }
        let c = Capture(f)
        
        s.value = 2
        s.value = 9
        s.value = 6
        s.value = 4
        XCTAssertEqual(c.vals, [9, 6])
    }
    
    func testFilter_notPushable() {
        let s = Observable<Int>()
        let f = s.filter { $0 < 5 }
        let c = Capture(f)
        
        s.pushValue(7)
        s.pushValue(2)
        XCTAssertEqual(c.vals, [2])
    }
    
    func testUnion_pushable() {
        let s1 = Input<Int>(initial: 0)
        let s2 = Input<Int>(initial: 0)
        let u = union(s1, s2)
        let c = Capture(u)
        
        s1.value = 6
        s2.value = 3
        s1.value = 10
        s1.value = 7
        s2.value = 14
        XCTAssertEqual(c.vals, [6,3,10,7,14])
    }
    
    func tetsUnion_notPushable() {
        let s1 = Observable<Int>()
        let s2 = Observable<Int>()
        let u = union(s1, s2)
        let c = Capture(u)
        
        s1.pushValue(6)
        s2.pushValue(3)
        s1.pushValue(10)
        s1.pushValue(7)
        s2.pushValue(14)
        XCTAssertEqual(c.vals, [6,3,10,7,14])
    }
    
    func testCombine2_async() {
        let s1 = Input<Int>(initial: 0)
        let s2 = Input<String>(initial: "")
        let m = combine(s1, s2) { i,s in "\(i):\(s)" }
        let c = Capture(m)

        let expectation = expectationWithDescription("wait")
        c.obs.append(m.output { _ in
            if c.vals.count == 5 {
                expectation.fulfill()
            }
        })
        
        s1.value = 123
        dispatch_async(dispatch_get_main_queue()) {
            s2.value = "foo"
            dispatch_async(dispatch_get_main_queue()) {
                s1.value = 234
                dispatch_async(dispatch_get_main_queue()) {
                    s2.value = "bar"
                }
            }
        }
        
        waitForExpectationsWithTimeout(1.0, handler: nil)
        
        XCTAssertEqual(c.vals, ["0:", "123:", "123:foo", "234:foo", "234:bar"])
    }
    
    func testCombine2_sync() {
        
    }

    func testCombine3_async() {
        let s1 = Input<Int>(initial: 0)
        let s2 = Input<String>(initial: "")
        let s3 = Input<Bool>(initial: false)
        let m = combine(s1, s2, s3) { i,s,b in "\(i):\(s):\(b)" }
        let c = Capture(m)
        
        let expectation = expectationWithDescription("wait")
        c.obs.append(m.output { _ in
            if c.vals.count == 6 {
                expectation.fulfill()
            }
        })

        s1.value = 123
        dispatch_async(dispatch_get_main_queue()) {
            s2.value = "foo"
            dispatch_async(dispatch_get_main_queue()) {
                s3.value = true
                dispatch_async(dispatch_get_main_queue()) {
                    s1.value = 234
                    dispatch_async(dispatch_get_main_queue()) {
                        s2.value = "bar"
                    }
                }
            }
        }
        
        waitForExpectationsWithTimeout(1.0, handler: nil)

        XCTAssertEqual(c.vals, ["0::false", "123::false", "123:foo:false", "123:foo:true", "234:foo:true", "234:bar:true"])
    }

    func testCombine3_sync() {
        
    }
    
    func testCombine4_async() {
        let s1 = Input<Int>(initial: 0)
        let s2 = Input<Int>(initial: 0)
        let s3 = Input<Int>(initial: 0)
        let s4 = Input<Int>(initial: 0)
        let m = combine(s1, s2, s3, s4) { $0 + $1 + $2 + $3 }
        let c = Capture(m)
        
        let expectation = expectationWithDescription("wait")
        c.obs.append(m.output { _ in
            if c.vals.count == 5 {
                expectation.fulfill()
            }
        })

        s1.value = 1
        dispatch_async(dispatch_get_main_queue()) {
            s2.value = 4
            dispatch_async(dispatch_get_main_queue()) {
                s3.value = 7
                dispatch_async(dispatch_get_main_queue()) {
                    s4.value = 9
                }
            }
        }
        
        waitForExpectationsWithTimeout(1.0, handler: nil)

        XCTAssertEqual(c.vals, [0, 1, 5, 12, 21])
    }
    
    func testCombine4_sync() {
    }
    
    func testCombine5() {
        let s1 = Input<Int>(initial: 1)
        let s2 = Input<Int>(initial: 3)
        let s3 = Input<Int>(initial: 5)
        let s4 = Input<Int>(initial: 7)
        let s5 = Input<Int>(initial: 9)
        let m = combine(s1, s2, s3, s4, s5) { ($0 * $1) + ($2 * $3) + $4 }
        let c = Capture(m)
        
        let expectation = expectationWithDescription("wait")
        c.obs.append(m.output { _ in
            if c.vals.count == 6 {
                expectation.fulfill()
            }
        })

        s1.value = 2
        dispatch_async(dispatch_get_main_queue()) {
            s2.value = 4
            dispatch_async(dispatch_get_main_queue()) {
                s3.value = 6
                dispatch_async(dispatch_get_main_queue()) {
                    s4.value = 8
                    dispatch_async(dispatch_get_main_queue()) {
                        s5.value = 10
                    }
                }
            }
        }
        
        waitForExpectationsWithTimeout(3.0, handler: nil)

        XCTAssertEqual(c.vals, [47, 50, 52, 59, 65, 66])
    }
    
    func testCombine5_sync() {
        
    }
}
