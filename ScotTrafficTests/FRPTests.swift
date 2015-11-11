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
    
    func testCombine2_independentInputs() {
        let s1 = Input<Int>(initial: 0)
        let s2 = Input<String>(initial: "")
        let m = combine(s1, s2) { i,s in "\(i):\(s)" }
        let c = Capture(m)

        s1.value = 123
        s2.value = "foo"

        XCTAssertEqual(c.vals, ["0:", "123:", "123:foo"])
    }
    
    func testCombine2_dependentInputs() {
        let s = Input<Int>(initial: 0)
        let t = s.map { $0 + 5 }
        let u = s.map { $0 + 3 }
        let m = combine(t, u) { $0 * $1 }
        let c = Capture(m)
        
        s.value = 6

        XCTAssertEqual(c.vals, [15, 99])
    }

    func testCombine3_independentInputs() {
        let s1 = Input<Int>(initial: 0)
        let s2 = Input<String>(initial: "")
        let s3 = Input<Bool>(initial: false)
        let m = combine(s1, s2, s3) { i,s,b in "\(i):\(s):\(b)" }
        let c = Capture(m)

        s1.value = 123
        s2.value = "foo"
        s3.value = true
        s1.value = 234
        s2.value = "bar"
        
        XCTAssertEqual(c.vals, ["0::false", "123::false", "123:foo:false", "123:foo:true", "234:foo:true", "234:bar:true"])
    }
    
    func testCombine3_dependentInputs() {
        let s = Input<Int>(initial: 0)
        let t = s.map { $0 + 5 }
        let u = s.map { $0 * -1 }
        let m = combine(s, t, u) { $0 * $1 + $2 }
        let c = Capture(m)
        
        s.value = 7
        s.value = 9
        
        XCTAssertEqual(c.vals, [0, 77, 117])
    }
    
    func testCombine4_independentInputs() {
        let s1 = Input<Int>(initial: 0)
        let s2 = Input<Int>(initial: 0)
        let s3 = Input<Int>(initial: 0)
        let s4 = Input<Int>(initial: 0)
        let m = combine(s1, s2, s3, s4) { $0 + $1 + $2 + $3 }
        let c = Capture(m)
        
        s1.value = 1
        s2.value = 4
        s3.value = 7
        s4.value = 9

        XCTAssertEqual(c.vals, [0, 1, 5, 12, 21])
    }
    
    func testCombine5_independentInputs() {
        let s1 = Input<Int>(initial: 1)
        let s2 = Input<Int>(initial: 3)
        let s3 = Input<Int>(initial: 5)
        let s4 = Input<Int>(initial: 7)
        let s5 = Input<Int>(initial: 9)
        let m = combine(s1, s2, s3, s4, s5) { ($0 * $1) + ($2 * $3) + $4 }
        let c = Capture(m)
        
        s1.value = 2
        s2.value = 4
        s3.value = 6
        s4.value = 8
        s5.value = 10
        
        XCTAssertEqual(c.vals, [47, 50, 52, 59, 65, 66])
    }
    
    func testLatest_mapped() {
        let s = Input<Int>(initial: 0)
        let t = s.map { $0 + 1 }
        let u = t.latest()

        XCTAssertTrue(t.canPullValue)
        XCTAssertTrue(u.canPullValue)
        XCTAssertEqual(u.pullValue, 1)

        s.value = 6
        
        XCTAssertEqual(u.pullValue, 7)
    }
    
    func testLatest_filtered() {
        let s = Input<Int>(initial: 0)
        let t = s.filter { $0 > 5 }
        let u = t.latest()

        XCTAssertFalse(t.canPullValue)
        XCTAssertFalse(u.canPullValue)
        XCTAssertNil(u.pullValue)
        
        s.value = 9
        
        XCTAssertFalse(t.canPullValue)
        XCTAssertTrue(u.canPullValue)
        XCTAssertEqual(u.pullValue, 9)
    }
    
    func testLatest_doesNotWrapLatest() {
        let s = Input<Int>(initial: 0)
        let l1 = s.latest()
        let l2 = l1.latest()
        XCTAssert(l1 === l2)
    }
    
    func testOnChange() {
        let s = Input<Int>(initial: 0)
        let t = Capture(s.latest())
        let u = Capture(s.onChange())

        s.value = 6
        s.value = 6
        s.value = 7

        XCTAssertEqual(t.vals, [0, 6, 6, 7])
        XCTAssertEqual(u.vals, [0, 6, 7])
    }
    
    func testGateDoesNotPushWhenGateIsFalse() {
        let s = Input<Int>(initial: 0)
        let g = Input<Bool>(initial: false)
        let t = g.gate(s)
        let c = Capture(t)
        
        s.value = 6
        XCTAssertEqual(c.vals, [])
    }

    func testGatePushesWhenGateIsTrue() {
        let s = Input<Int>(initial: 0)
        let g = Input<Bool>(initial: true)
        let t = g.gate(s)
        let c = Capture(t)
        
        s.value = 6
        XCTAssertEqual(c.vals, [6])
    }
    
    func testGatePushesDeferredOnRisingEdge() {
        let s = Input<Int>(initial: 0)
        let g = Input<Bool>(initial: false)
        let t = g.gate(s)
        let c = Capture(t)
        
        s.value = 6
        XCTAssertEqual(c.vals, [])

        g.value = true
        XCTAssertEqual(c.vals, [6])
    }
}
