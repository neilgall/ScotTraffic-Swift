//
//  JSON.swift
//  ScotTraffic
//
//  Created by Neil Gall on 30/09/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import Foundation

public enum JSONError : ErrorType {
    case ExpectedDictionary
    case ExpectedArray
    case ExpectedValue
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

public protocol JSONValueDecodable {
    static func decodeJSON(json: JSONValue) throws -> Self
}

func genericDecodeJSON<T: JSONValueDecodable> (json: JSONValue?) throws -> T {
    guard let value = json as? T else {
        throw JSONError.ExpectedValue
    }
    return value
}

extension String: JSONValueDecodable {
    public static func decodeJSON(json: JSONValue) throws -> String {
        return try genericDecodeJSON(json)
    }
}

extension Int: JSONValueDecodable {
    public static func decodeJSON(json: JSONValue) throws -> Int {
        return try genericDecodeJSON(json)
    }
}

extension Float: JSONValueDecodable {
    public static func decodeJSON(json: JSONValue) throws -> Float {
        return try genericDecodeJSON(json)
    }
}

extension Double: JSONValueDecodable {
    public static func decodeJSON(json: JSONValue) throws -> Double {
        return try genericDecodeJSON(json)
    }
}

extension Array where Element: JSONValueDecodable {
    public static func decodeJSON(json: JSONArray) throws -> [Element] {
        return try json.map(Element.decodeJSON)
    }
}

extension Array where Element: JSONObjectDecodable {
    public static func decodeJSON(json: JSONArray) throws -> [Element] {
        return try json.map { item in
            guard let object = item as? JSONObject else {
                throw JSONError.ExpectedDictionary
            }
            return try Element.decodeJSON(object)
        }
    }
}

extension Bool: JSONValueDecodable {
    public static func decodeJSON(json: JSONValue) throws -> Bool {
        return try genericDecodeJSON(json)
    }
}

extension JSONValueDecodable {
    public static func decodeJSON(json: JSONValue?) throws -> Self? {
        guard let value = json else {
            return nil
        }
        return try decodeJSON(value)
    }
}

extension JSONArrayDecodable {
    public static func decodeJSON(json: JSONArray?) throws -> [Self]? {
        guard let value = json else {
            return nil
        }
        return try decodeJSON(value)
    }
}

extension JSONObjectDecodable {
    public static func decodeJSON(json: JSONObject?) throws -> Self? {
        guard let value = json else {
            return nil
        }
        return try decodeJSON(value)
    }
}

infix operator <~ { associativity left precedence 150 }

public func <~ <T: JSONValueDecodable> (json: JSONObject, key: String) throws -> T {
    guard let value = json[key] else {
        throw JSONError.ExpectedValue
    }
    return try T.decodeJSON(value)
}

public func <~ <T: JSONValueDecodable>(json: JSONObject, key: String) throws -> [T] {
    guard let array = json[key] as? JSONArray else {
        throw JSONError.ExpectedArray
    }
    return try [T].decodeJSON(array)
}

public func <~ <T: JSONValueDecodable>(json: JSONObject, key: String) throws -> T? {
    guard let value = json[key] else {
        return nil
    }
    return try T.decodeJSON(value)
}

public func <~ <T: JSONObjectDecodable>(json: JSONObject, key: String) throws -> T {
    guard let dict = json[key] as? JSONObject else {
        throw JSONError.ExpectedDictionary
    }
    return try T.decodeJSON(dict)
}

public func <~ <T: JSONObjectDecodable>(json: JSONObject, key: String) throws -> [T] {
    guard let array = json[key] as? JSONArray else {
        throw JSONError.ExpectedArray
    }
    return try [T].decodeJSON(array)
}

public func <~ <T: JSONObjectDecodable>(json: JSONObject, key: String) throws -> T? {
    guard let value = json[key] else {
        return nil
    }
    guard let dict = value as? JSONObject else {
        throw JSONError.ExpectedDictionary
    }
    return try T.decodeJSON(dict)
}
