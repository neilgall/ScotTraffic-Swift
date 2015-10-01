//
//  JSON.swift
//  ScotTraffic
//
//  Created by Neil Gall on 30/09/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import Foundation

public enum JSONError : ErrorType {
    case ExpectedDictionary(String)
    case ExpectedArray(String)
    case ExpectedValue(String)
}

public typealias JSONValue = AnyObject
public typealias JSONArray = [JSONValue]
public typealias JSONObject = [String : AnyObject]
public let emptyJSON: JSONArray = []

public protocol JSONObjectDecodable {
    static func decodeJSON(json: JSONObject) throws -> Self
}

public protocol JSONArrayDecodable {
    static func decodeJSON(json: JSONArray) throws -> [Self]
}

public protocol JSONValueDecodable {}

extension String: JSONValueDecodable {}
extension Int:    JSONValueDecodable {}
extension Float:  JSONValueDecodable {}
extension Double: JSONValueDecodable {}
extension Bool:   JSONValueDecodable {}

infix operator <~ { associativity left precedence 150 }

public func <~ <T: JSONValueDecodable> (json: JSONObject, key: String) throws -> T {
    guard let value = json[key] as? T else {
        throw JSONError.ExpectedValue(key)
    }
    return value
}

public func <~ <T: JSONValueDecodable> (json: JSONObject, key: String) throws -> T? {
    guard let object = json[key] else {
        return nil
    }
    guard let value = object as? T else {
        throw JSONError.ExpectedValue(key)
    }
    return value
}

public func <~ <T: JSONValueDecodable> (json: JSONObject, key: String) throws -> [T] {
    guard let values = json[key] as? [T] else {
        throw JSONError.ExpectedArray(key)
    }
    return values
}

public func <~ <T: JSONValueDecodable> (json: JSONObject, key: String) throws -> [T]? {
    guard let object = json[key] else {
        return nil
    }
    guard let values = object as? [T] else {
        throw JSONError.ExpectedArray(key)
    }
    return values
}

public func <~ <T: JSONObjectDecodable> (json: JSONObject, key: String) throws -> T {
    guard let dict = json[key] as? JSONObject else {
        throw JSONError.ExpectedDictionary(key)
    }
    return try T.decodeJSON(dict)
}

public func <~ <T: JSONObjectDecodable> (json: JSONObject, key: String) throws -> T? {
    guard let object = json[key] else {
        return nil
    }
    guard let dict = object as? JSONObject else {
        throw JSONError.ExpectedDictionary(key)
    }
    return try T.decodeJSON(dict)
}

public func <~ <T: JSONObjectDecodable> (json: JSONObject, key: String) throws -> [T] {
    guard let array = json[key] as? [JSONObject] else {
        throw JSONError.ExpectedArray(key)
    }
    return try array.map(T.decodeJSON)
}

public func <~ <T: JSONObjectDecodable> (json: JSONObject, key: String) throws -> [T]? {
    guard let object = json[key] else {
        return nil
    }
    guard let array = object as? [JSONObject] else {
        throw JSONError.ExpectedArray(key)
    }
    return try array.map(T.decodeJSON)
}

public func decodeJSONArray<T: JSONValueDecodable>(array: JSONArray) throws -> [T] {
    let wrapped = [ "array": array ] as JSONObject
    return try wrapped <~ "array"
}

public func decodeJSONArray<T: JSONObjectDecodable>(array: JSONArray) throws -> [T] {
    let wrapped = [ "array": array ] as JSONObject
    return try wrapped <~ "array"
}
