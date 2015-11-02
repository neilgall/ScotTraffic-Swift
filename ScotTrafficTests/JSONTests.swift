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
    static func decodeJSON(json: JSONObject, forKey key: JSONKey) throws -> TestType {
        return try TestType(
            a: json <~ "a",
            b: json <~ "b")
    }
}

class JSONTests: XCTestCase {

    func testStringOk() {
        do {
            let json = JSONObject(value: [ "key": "value" ], context: nil)
            let str: String = try json <~ "key"
            XCTAssertEqual(str, "value")
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testStringMissing() {
        do {
            let json = JSONObject(value: [:], context: nil)
            let str: String = try json <~ "key"
            XCTFail("unexpected parse: \(str)")
        } catch (error: JSONError.ExpectedValue) {
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testStringNotString() {
        do {
            let json = JSONObject(value: [ "key": 123 ], context: nil)
            let str: String = try json <~ "key"
            XCTFail("unexpected parse: \(str)")
        } catch (error: JSONError.ExpectedValue) {
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testOptionalStringOk() {
        do {
            let json = JSONObject(value: [ "key": "value" ], context: nil)
            let str: String? = try json <~ "key"
            XCTAssertEqual(str, "value")
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testOptionalStringMissing() {
        do {
            let json = JSONObject(value: [:], context: nil)
            let str: String? = try json <~ "key"
            XCTAssertNil(str)
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testOptionalStringNotString() {
        do {
            let json = JSONObject(value: [ "key": 123 ], context: nil)
            let str: String? = try json <~ "key"
            XCTFail("unexpected parse: \(str)")
        } catch (error: JSONError.ExpectedValue) {
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testTopLevelStringArray() {
        do {
            let json = JSONArray(value: [ "abc", "def", "ghi" ], context: nil)
            let strings = try Array<String>.decodeJSON(json)
            XCTAssertEqual(strings, [ "abc", "def", "ghi" ])
        } catch {
            XCTFail("\(error)")
        }
    }

    func testIntegerOk() {
        do {
            let json = JSONObject(value: [ "key": 123 ], context: nil)
            let num: Int = try json <~ "key"
            XCTAssertEqual(num, 123)
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testIntegerMissing() {
        do {
            let json = JSONObject(value: [:], context: nil)
            let str: Int = try json <~ "key"
            XCTFail("unexpected parse: \(str)")
        } catch (error: JSONError.ExpectedValue) {
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testIntegerNotInteger() {
        do {
            let json = JSONObject(value: [ "key": "123" ], context: nil)
            let num: Int = try json <~ "key"
            XCTFail("unexpected parse: \(num)")
        } catch (error: JSONError.ExpectedValue) {
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testOptionalIntegerOk() {
        do {
            let json = JSONObject(value: [ "key": 123 ], context: nil)
            let num: Int? = try json <~ "key"
            XCTAssertEqual(num, 123)
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testOptionalIntegerMissing() {
        do {
            let json = JSONObject(value: [:], context: nil)
            let num: Int? = try json <~ "key"
            XCTAssertNil(num)
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testOptionalIntegerNotInteger() {
        do {
            let json = JSONObject(value: [ "key": "123" ], context: nil)
            let num: Int? = try json <~ "key"
            XCTFail("unexpected parse: \(num)")
        } catch (error: JSONError.ExpectedValue) {
        } catch {
            XCTFail("\(error)")
        }
    }

    func testBoolFalse() {
        do {
            let json = JSONObject(value: [ "bool": false ], context: nil)
            let bool: Bool = try json <~ "bool"
            XCTAssertEqual(bool, false)
        } catch {
            XCTFail("\(error)")
        }
    }

    func testBoolTrue() {
        do {
            let json = JSONObject(value: [ "bool": true ], context: nil)
            let bool: Bool = try json <~ "bool"
            XCTAssertEqual(bool, true)
        } catch {
            XCTFail("\(error)")
        }
    }

    func testBoolZero() {
        do {
            let json = JSONObject(value: [ "bool": 0 ], context: nil)
            let bool: Bool = try json <~ "bool"
            XCTAssertEqual(bool, false)
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testBoolOne() {
        do {
            let json = JSONObject(value: [ "bool": 1 ], context: nil)
            let bool: Bool = try json <~ "bool"
            XCTAssertEqual(bool, true)
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testBoolMissing() {
        do {
            let json = JSONObject(value: [:], context:  nil)
            let bool: Bool = try json <~ "bool"
            XCTFail("unexpected parse: \(bool)")
        } catch (error: JSONError.ExpectedValue) {
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testBoolNotBool() {
        do {
            let json = JSONObject(value: [ "bool" : "gah" ], context: nil)
            let bool: Bool = try json <~ "bool"
            XCTFail("unexpected parse: \(bool)")
        } catch (error: JSONError.ExpectedValue) {
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testOptionalBoolOk() {
        do {
            let json = JSONObject(value: [ "bool": true ], context: nil)
            let bool: Bool? = try json <~ "bool"
            XCTAssertEqual(bool, true)
        } catch {
            XCTFail("\(error)")
        }
    }

    func testOptionalBoolMissing() {
        do {
            let json = JSONObject(value: [:], context: nil)
            let bool: Bool? = try json <~ "bool"
            XCTAssertNil(bool)
        } catch {
            XCTFail("\(error)")
        }
    }

    func testOptionalBoolNotBool() {
        do {
            let json = JSONObject(value: [ "bool" : "bleh" ], context: nil)
            let bool: Bool? = try json <~ "bool"
            XCTFail("unexpected parse: \(bool)")
        } catch (error: JSONError.ExpectedValue) {
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testTestTypeOk() {
        do {
            let json = JSONObject(value: [ "foo": [ "a": "string", "b": 213 ]], context: nil)
            let test: TestType = try json <~ "foo"
            XCTAssertEqual(test.a, "string")
            XCTAssertEqual(test.b, 213)
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testTestTypeMissing() {
        do {
            let json = JSONObject(value: [:], context: nil)
            let test: TestType = try json <~ "foo"
            XCTFail("unexpected parse: \(test)")
        } catch (error: JSONError.ExpectedDictionary) {
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testTestTypeNotDictionary() {
        do {
            let json = JSONObject(value: [ "foo": "bar" ], context: nil)
            let test: TestType = try json <~ "foo"
            XCTFail("unexpected parse: \(test)")
        } catch (error: JSONError.ExpectedDictionary) {
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testOptionalTestTypeOk() {
        do {
            let json = JSONObject(value: [ "foo": [ "a": "string", "b": 213 ]], context: nil)
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
            let json = JSONObject(value: [:], context: nil)
            let test: TestType? = try json <~ "foo"
            XCTAssertNil(test)
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testOptionalTestTypeNotDictionary() {
        do {
            let json = JSONObject(value: [ "foo": "bar" ], context: nil)
            let test: TestType? = try json <~ "foo"
            XCTFail("unexpected parse: \(test)")
        } catch (error: JSONError.ExpectedDictionary) {
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testStringArrayOk() {
        do {
            let json = JSONObject(value: [ "strings": ["a","b","c"]], context: nil)
            let strings: [String] = try json <~ "strings"
            XCTAssertEqual(strings, ["a","b","c"])
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testStringArrayMissing() {
        do {
            let json = JSONObject(value: [:], context: nil)
            let strings: [String] = try json <~ "strings"
            XCTFail("unexpected parse: \(strings)")
        } catch (error: JSONError.ExpectedArray) {
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testStringArrayNotArray() {
        do {
            let json = JSONObject(value: [ "strings": "foo" ], context: nil)
            let strings: [String] = try json <~ "strings"
            XCTFail("unexpected parse: \(strings)")
        } catch (error: JSONError.ExpectedArray) {
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testStringArrayNotStringsInArray() {
        do {
            let json = JSONObject(value: [ "strings": [ 123, 456 ] ], context: nil)
            let strings: [String] = try json <~ "strings"
            XCTFail("unexpected parse: \(strings)")
        } catch (error:JSONError.ExpectedValue) {
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testIntegerArrayOk() {
        do {
            let json = JSONObject(value: [ "ints": [1,2,3,4] ], context: nil)
            let ints: [Int] = try json <~ "ints"
            XCTAssertEqual(ints, [1,2,3,4])
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testIntegerArrayMissing() {
        do {
            let json = JSONObject(value: [:], context: nil)
            let ints: [Int] = try json <~ "ints"
            XCTFail("unexpected parse: \(ints)")
        } catch (error: JSONError.ExpectedArray) {
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testIntegerArrayNotArray() {
        do {
            let json = JSONObject(value: [ "ints" : "foo" ], context: nil)
            let ints: [Int] = try json <~ "ints"
            XCTFail("unexpected parse: \(ints)")
        } catch (error: JSONError.ExpectedArray) {
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testIntegerArrayNotArrayOfInts() {
        do {
            let json = JSONObject(value: [ "ints" : [ "foo", "bar" ] ], context: nil)
            let ints: [Int] = try json <~ "ints"
            XCTFail("unexpected parse: \(ints)")
        } catch (error: JSONError.ExpectedValue) {
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testTestTypeKeyedArrayOk() {
        do {
            let json = JSONObject(value: [ "objs" : [ [ "a": "abc", "b": 123 ], [ "a": "def", "b": 234] ] ], context: nil)
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
            let json = JSONArray(value: [ [ "a": "abc", "b": 123 ], [ "a": "def", "b": 234] ], context: nil)
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
