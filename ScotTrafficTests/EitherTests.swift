//
//  EitherTests.swift
//  ScotTraffic
//
//  Created by Neil Gall on 13/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import XCTest
import ScotTraffic

enum TestError : ErrorType {
    case Error1
    case Error2
}

class EitherTests: XCTestCase {
    
    func testEitherValue() {
        let s = Either<Int, TestError>.Value(22)
        switch s {
        case .Value(let v):
            XCTAssertEqual(v, 22)
        case .Error:
            XCTFail()
        }
    }

    func testEitherError() {
        let s = Either<Int, TestError>.Error(.Error1)
        switch s {
        case .Value:
            XCTFail()
        case .Error(let e):
            XCTAssertEqual(e, TestError.Error1)
        }
    }
    
    func testEitherValueMap() {
        let s = Either<Int, TestError>.Value(22)
        let t = s.map { "\($0)" }
        switch t {
        case .Error:
            XCTFail()
        case .Value(let v):
            XCTAssertEqual(v, "22")
        }
    }

    func testEitherErrorMap() {
        let s = Either<Int, TestError>.Error(.Error1)
        let t = s.map { "\($0)" }
        switch t {
        case .Value:
            XCTFail()
        case .Error(let e):
            switch e {
            case .Unknown(let f):
                XCTAssertEqual(f as? TestError, TestError.Error1)
            default:
                XCTFail()
            }
        }
    }
    
    func testEitherValueMapWithThrow() {
        let s = Either<Int, TestError>.Value(22)
        let t: Either<String, AppError> = s.map { (_:Int)->String in throw TestError.Error2 }
        switch t {
        case .Error(let e):
            switch e {
            case .Unknown(let f):
                XCTAssertEqual(f as? TestError, TestError.Error2)
            default:
                XCTFail()
            }
        case .Value:
            XCTFail()
        }
    }

    func testEitherErrorMapWithThrow() {
        let s = Either<Int, TestError>.Error(.Error1)
        let t: Either<String, AppError> = s.map { (_:Int)->String in throw TestError.Error2 }
        switch t {
        case .Value:
            XCTFail()
        case .Error(let e):
            switch e {
            case .Unknown(let f):
                XCTAssertEqual(f as? TestError, TestError.Error1)
            default:
                XCTFail()
            }
        }
    }
    
    func testValueFromEither() {
        let s = Input<Either<Int, TestError>>(initial: Either.Value(1))
        let t = valueFromEither(s)
        let c = Capture(t)
        
        XCTAssertEqual(c.vals, [1])
        s.value = Either.Value(3)
        XCTAssertEqual(c.vals, [1, 3])
        
        s.value = Either.Error(TestError.Error1)
        XCTAssertEqual(c.vals, [1, 3])
    }
    
    func testErrorFromEither() {
        let s = Input<Either<Int, TestError>>(initial: Either.Value(1))
        let e = errorFromEither(s)
        let c = Capture(e)
        
        XCTAssertEqual(c.vals, [])
        s.value = Either.Value(3)
        XCTAssertEqual(c.vals, [])
        
        s.value = Either.Error(TestError.Error1)
        XCTAssertEqual(c.vals, [TestError.Error1])
        
    }
}
