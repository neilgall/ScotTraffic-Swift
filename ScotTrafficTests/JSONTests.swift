//
//  JSONTests.swift
//  ScotTraffic
//
//  Created by Neil Gall on 30/09/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import XCTest
@testable import ScotTraffic

struct TestType {
    let a: String
    let b: Int
}

extension TestType: JSONObjectDecodable {
    static func decodeJSON(json: JSONObject) throws -> TestType {
        return try TestType(
            a: json <~ "a",
            b: json <~ "b")
    }
}

class JSONTests: XCTestCase {

    func testStringOk() {
        do {
            let json = [ "key": "value" ] as JSONObject
            let str: String = try json <~ "key"
            XCTAssertEqual(str, "value")
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testStringMissing() {
        do {
            let json = JSONObject()
            let str: String = try json <~ "key"
            XCTFail("unexpected parse: \(str)")
        } catch (error: JSONError.ExpectedValue) {
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testStringNotString() {
        do {
            let json = [ "key": 123 ]
            let str: String = try json <~ "key"
            XCTFail("unexpected parse: \(str)")
        } catch (error: JSONError.ExpectedValue) {
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testOptionalStringOk() {
        do {
            let json = [ "key": "value" ]
            let str: String? = try json <~ "key"
            XCTAssertEqual(str, "value")
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testOptionalStringMissing() {
        do {
            let json = JSONObject()
            let str: String? = try json <~ "key"
            XCTAssertNil(str)
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testOptionalStringNotString() {
        do {
            let json = [ "key": 123 ]
            let str: String? = try json <~ "key"
            XCTFail("unexpected parse: \(str)")
        } catch (error: JSONError.ExpectedValue) {
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testTopLevelStringArray() {
        do {
            let json = [ "abc", "def", "ghi" ]
            let strings = try Array<String>.decodeJSON(json)
            XCTAssertEqual(strings, [ "abc", "def", "ghi" ])
        } catch {
            XCTFail("\(error)")
        }
    }

    func testIntegerOk() {
        do {
            let json = [ "key": 123 ] as JSONObject
            let num: Int = try json <~ "key"
            XCTAssertEqual(num, 123)
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testIntegerMissing() {
        do {
            let json = JSONObject()
            let str: Int = try json <~ "key"
            XCTFail("unexpected parse: \(str)")
        } catch (error: JSONError.ExpectedValue) {
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testIntegerNotInteger() {
        do {
            let json = [ "key": "123" ]
            let num: Int = try json <~ "key"
            XCTFail("unexpected parse: \(num)")
        } catch (error: JSONError.ExpectedValue) {
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testOptionalIntegerOk() {
        do {
            let json = [ "key": 123 ]
            let num: Int? = try json <~ "key"
            XCTAssertEqual(num, 123)
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testOptionalIntegerMissing() {
        do {
            let json = JSONObject()
            let num: Int? = try json <~ "key"
            XCTAssertNil(num)
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testOptionalIntegerNotInteger() {
        do {
            let json = [ "key": "123" ]
            let num: Int? = try json <~ "key"
            XCTFail("unexpected parse: \(num)")
        } catch (error: JSONError.ExpectedValue) {
        } catch {
            XCTFail("\(error)")
        }
    }

    func testBoolFalse() {
        do {
            let json = [ "bool": false ] as JSONObject
            let bool: Bool = try json <~ "bool"
            XCTAssertEqual(bool, false)
        } catch {
            XCTFail("\(error)")
        }
    }

    func testBoolTrue() {
        do {
            let json = [ "bool": true ] as JSONObject
            let bool: Bool = try json <~ "bool"
            XCTAssertEqual(bool, true)
        } catch {
            XCTFail("\(error)")
        }
    }

    func testBoolZero() {
        do {
            let json = [ "bool": 0 ] as JSONObject
            let bool: Bool = try json <~ "bool"
            XCTAssertEqual(bool, false)
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testBoolOne() {
        do {
            let json = [ "bool": 1 ] as JSONObject
            let bool: Bool = try json <~ "bool"
            XCTAssertEqual(bool, true)
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testBoolMissing() {
        do {
            let json = JSONObject()
            let bool: Bool = try json <~ "bool"
            XCTFail("unexpected parse: \(bool)")
        } catch (error: JSONError.ExpectedValue) {
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testBoolNotBool() {
        do {
            let json = [ "bool" : "gah" ]
            let bool: Bool = try json <~ "bool"
            XCTFail("unexpected parse: \(bool)")
        } catch (error: JSONError.ExpectedValue) {
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testOptionalBoolOk() {
        do {
            let json = [ "bool": true ] as JSONObject
            let bool: Bool? = try json <~ "bool"
            XCTAssertEqual(bool, true)
        } catch {
            XCTFail("\(error)")
        }
    }

    func testOptionalBoolMissing() {
        do {
            let json = JSONObject()
            let bool: Bool? = try json <~ "bool"
            XCTAssertNil(bool)
        } catch {
            XCTFail("\(error)")
        }
    }

    func testOptionalBoolNotBool() {
        do {
            let json = [ "bool" : "bleh" ]
            let bool: Bool? = try json <~ "bool"
            XCTFail("unexpected parse: \(bool)")
        } catch (error: JSONError.ExpectedValue) {
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testTestTypeOk() {
        do {
            let json = [ "foo": [ "a": "string", "b": 213 ]]
            let test: TestType = try json <~ "foo"
            XCTAssertEqual(test.a, "string")
            XCTAssertEqual(test.b, 213)
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testTestTypeMissing() {
        do {
            let json = JSONObject()
            let test: TestType = try json <~ "foo"
            XCTFail("unexpected parse: \(test)")
        } catch (error: JSONError.ExpectedDictionary) {
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testTestTypeNotDictionary() {
        do {
            let json = [ "foo": "bar" ]
            let test: TestType = try json <~ "foo"
            XCTFail("unexpected parse: \(test)")
        } catch (error: JSONError.ExpectedDictionary) {
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testOptionalTestTypeOk() {
        do {
            let json: JSONObject = [ "foo": [ "a": "string", "b": 213 ]]
            let test: TestType? = try json <~ "foo"
            XCTAssertNotNil(test)
            XCTAssertEqual(test!.a, "string")
            XCTAssertEqual(test!.b, 213)
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testOptionalTestTypeMissing() {
        do {
            let json = JSONObject()
            let test: TestType? = try json <~ "foo"
            XCTAssertNil(test)
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testOptionalTestTypeNotDictionary() {
        do {
            let json: JSONObject = [ "foo": "bar" ]
            let test: TestType? = try json <~ "foo"
            XCTFail("unexpected parse: \(test)")
        } catch (error: JSONError.ExpectedDictionary) {
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testStringArrayOk() {
        do {
            let json = [ "strings": ["a","b","c"]]
            let strings: [String] = try json <~ "strings"
            XCTAssertEqual(strings, ["a","b","c"])
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testStringArrayMissing() {
        do {
            let json = JSONObject()
            let strings: [String] = try json <~ "strings"
            XCTFail("unexpected parse: \(strings)")
        } catch (error: JSONError.ExpectedArray) {
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testStringArrayNotArray() {
        do {
            let json = [ "strings": "foo" ]
            let strings: [String] = try json <~ "strings"
            XCTFail("unexpected parse: \(strings)")
        } catch (error: JSONError.ExpectedArray) {
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testStringArrayNotStringsInArray() {
        do {
            let json = [ "strings": [ 123, 456 ] ]
            let strings: [String] = try json <~ "strings"
            XCTFail("unexpected parse: \(strings)")
        } catch (error:JSONError.ExpectedValue) {
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testIntegerArrayOk() {
        do {
            let json = [ "ints": [1,2,3,4] ]
            let ints: [Int] = try json <~ "ints"
            XCTAssertEqual(ints, [1,2,3,4])
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testIntegerArrayMissing() {
        do {
            let json = JSONObject()
            let ints: [Int] = try json <~ "ints"
            XCTFail("unexpected parse: \(ints)")
        } catch (error: JSONError.ExpectedArray) {
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testIntegerArrayNotArray() {
        do {
            let json = [ "ints" : "foo" ]
            let ints: [Int] = try json <~ "ints"
            XCTFail("unexpected parse: \(ints)")
        } catch (error: JSONError.ExpectedArray) {
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testIntegerArrayNotArrayOfInts() {
        do {
            let json = [ "ints" : [ "foo", "bar" ] ]
            let ints: [Int] = try json <~ "ints"
            XCTFail("unexpected parse: \(ints)")
        } catch (error: JSONError.ExpectedValue) {
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testTestTypeKeyedArrayOk() {
        do {
            let json = [ "objs" : [ [ "a": "abc", "b": 123 ], [ "a": "def", "b": 234] ] ]
            let test: [TestType] = try json <~ "objs"
            XCTAssertEqual(test.count, 2)
            XCTAssertEqual(test[0].a, "abc")
            XCTAssertEqual(test[0].b, 123)
            XCTAssertEqual(test[1].a, "def")
            XCTAssertEqual(test[1].b, 234)
        } catch {
            XCTFail("\(error)")
        }
    }

    func testTestTypeBareArrayOk() {
        do {
            let json = [ [ "a": "abc", "b": 123 ], [ "a": "def", "b": 234] ]
            let test: [TestType] = try Array<TestType>.decodeJSON(json)
            XCTAssertEqual(test.count, 2)
            XCTAssertEqual(test[0].a, "abc")
            XCTAssertEqual(test[0].b, 123)
            XCTAssertEqual(test[1].a, "def")
            XCTAssertEqual(test[1].b, 234)
        } catch {
            XCTFail("\(error)")
        }
    }
}
