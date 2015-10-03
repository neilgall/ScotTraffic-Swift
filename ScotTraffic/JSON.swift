//
//  JSON.swift
//  ScotTraffic
//
//  Created by Neil Gall on 30/09/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import Foundation

public typealias JSONKey = String
public typealias JSONValue = AnyObject
public typealias JSONArray = [JSONValue]
public typealias JSONObject = [JSONKey : JSONValue]

public enum JSONError : ErrorType, CustomStringConvertible {
    case ExpectedDictionary(key: JSONKey)
    case ExpectedArray(key: JSONKey)
    case ExpectedValue(key: JSONKey, type: Any.Type)
    case ParseError(key: JSONKey, value: JSONValue, message: String)
    
    public var description: String {
        switch self {
        case .ExpectedDictionary(let key): return "expected a dictionary for key '\(key)'"
        case .ExpectedArray(let key): return "expected an array for key '\(key)'"
        case .ExpectedValue(let key, let type): return "expected \(type) for key '\(key)'"
        case .ParseError(let key, let value, let msg): return "cannot parse '\(value)' for key '\(key)': \(msg)"
        }
    }
}

public protocol JSONObjectDecodable {
    static func decodeJSON(json: JSONObject, forKey key: JSONKey) throws -> Self
}

public protocol JSONValueDecodable {
    static func decodeJSON(json: JSONValue, forKey key: JSONKey) throws -> Self
}

func genericDecodeJSON<T: JSONValueDecodable> (json: JSONValue?, forKey key: JSONKey, type: Any.Type) throws -> T {
    guard let value = json as? T else {
        throw JSONError.ExpectedValue(key: key, type: type)
    }
    return value
}

extension String: JSONValueDecodable {
    public static func decodeJSON(json: JSONValue, forKey key: JSONKey) throws -> String {
        return try genericDecodeJSON(json, forKey: key, type: String.self)
    }
}

extension Int: JSONValueDecodable {
    public static func decodeJSON(json: JSONValue, forKey key: JSONKey) throws -> Int {
        return try genericDecodeJSON(json, forKey: key, type: Int.self)
    }
}

extension Float: JSONValueDecodable {
    public static func decodeJSON(json: JSONValue, forKey key: JSONKey) throws -> Float {
        do {
            return try genericDecodeJSON(json, forKey: key, type: Float.self)
        } catch {
            // special handling of string -> float
            let str: String = try genericDecodeJSON(json, forKey: key, type: String.self)
            guard let f = Float(str) else {
                throw JSONError.ExpectedValue(key: key, type: Float.self)
            }
            return f
        }
    }
}

extension Double: JSONValueDecodable {
    public static func decodeJSON(json: JSONValue, forKey key: JSONKey) throws -> Double {
        do {
            return try genericDecodeJSON(json, forKey: key, type: Double.self)
        } catch {
            // special handling of string -> double
            let str: String = try genericDecodeJSON(json, forKey: key, type: String.self)
            guard let d = Double(str) else {
                throw JSONError.ExpectedValue(key: key, type: Double.self)
            }
            return d
        }
    }
}

extension Bool: JSONValueDecodable {
    public static func decodeJSON(json: JSONValue, forKey key: JSONKey) throws -> Bool {
        return try genericDecodeJSON(json, forKey: key, type: Bool.self)
    }
}

extension Array where Element: JSONValueDecodable {
    public static func decodeJSON(json: JSONArray, forKey key: JSONKey) throws -> [Element] {
        return try json.map { return try Element.decodeJSON($0, forKey: key) }
    }
    
    public static func decodeJSON(json: JSONArray) throws -> [Element] {
        return try decodeJSON(json, forKey: "")
    }
}

extension Array where Element: JSONObjectDecodable {
    public static func decodeJSON(json: JSONArray, forKey key: JSONKey) throws -> [Element] {
        return try json.map { item in
            guard let object = item as? JSONObject else {
                throw JSONError.ExpectedDictionary(key: key)
            }
            return try Element.decodeJSON(object, forKey: key)
        }
    }

    public static func decodeJSON(json: JSONArray) throws -> [Element] {
        return try decodeJSON(json, forKey: "")
    }
}

extension JSONValueDecodable {
    public static func decodeJSON(json: JSONValue?, forKey key: JSONKey) throws -> Self? {
        guard let value = json else {
            return nil
        }
        return try decodeJSON(value, forKey: key)
    }
}

extension JSONObjectDecodable {
    public static func decodeJSON(json: JSONObject?, forKey key: JSONKey) throws -> Self? {
        guard let value = json else {
            return nil
        }
        return try decodeJSON(value, forKey: key)
    }
}

infix operator <~ { associativity left precedence 150 }

public func <~ <T: JSONValueDecodable> (json: JSONObject, key: String) throws -> T {
    guard let value = json[key] else {
        throw JSONError.ExpectedValue(key: key, type: Any.self)
    }
    return try T.decodeJSON(value, forKey: key)
}

public func <~ <T: JSONValueDecodable>(json: JSONObject, key: String) throws -> [T] {
    guard let array = json[key] as? JSONArray else {
        throw JSONError.ExpectedArray(key: key)
    }
    return try [T].decodeJSON(array, forKey: key)
}

public func <~ <T: JSONValueDecodable>(json: JSONObject, key: String) throws -> T? {
    guard let value = json[key] else {
        return nil
    }
    return try T.decodeJSON(value, forKey: key)
}

public func <~ <T: JSONObjectDecodable>(json: JSONObject, key: String) throws -> T {
    guard let dict = json[key] as? JSONObject else {
        throw JSONError.ExpectedDictionary(key: key)
    }
    return try T.decodeJSON(dict, forKey: key)
}

public func <~ <T: JSONObjectDecodable>(json: JSONObject, key: String) throws -> [T] {
    guard let array = json[key] as? JSONArray else {
        throw JSONError.ExpectedArray(key: key)
    }
    return try [T].decodeJSON(array, forKey: key)
}

public func <~ <T: JSONObjectDecodable>(json: JSONObject, key: String) throws -> T? {
    guard let value = json[key] else {
        return nil
    }
    guard let dict = value as? JSONObject else {
        throw JSONError.ExpectedDictionary(key: key)
    }
    return try T.decodeJSON(dict, forKey: key)
}
