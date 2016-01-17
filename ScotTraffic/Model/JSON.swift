//
//  JSON.swift
//  ScotTraffic
//
//  Created by Neil Gall on 30/09/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import Foundation

typealias JSONKey = String
typealias JSONContext = Any?
typealias ContextlessJSONValue = AnyObject
typealias ContextlessJSONArray = [ContextlessJSONValue]
typealias ContextlessJSONObject = [JSONKey : ContextlessJSONValue]

struct JSONValue {
    let value: ContextlessJSONValue
    let context: JSONContext

    init(value: ContextlessJSONValue, context: JSONContext) {
        self.value = value
        self.context = context
    }
}

struct JSONArray {
    let value: ContextlessJSONArray
    let context: JSONContext
    
    init(value: ContextlessJSONArray, context: JSONContext) {
        self.value = value
        self.context = context
    }
}

struct JSONObject {
    let value: ContextlessJSONObject
    let context: JSONContext

    init(value: ContextlessJSONObject, context: JSONContext) {
        self.value = value
        self.context = context
    }
}

enum JSONError: ErrorType, CustomStringConvertible {
    case ExpectedDictionary(key: JSONKey)
    case ExpectedArray(key: JSONKey)
    case ExpectedValue(key: JSONKey, type: Any.Type)
    case ParseError(key: JSONKey, value: ContextlessJSONValue, message: String)
    
    var description: String {
        switch self {
        case .ExpectedDictionary(let key): return "expected a dictionary for key '\(key)'"
        case .ExpectedArray(let key): return "expected an array for key '\(key)'"
        case .ExpectedValue(let key, let type): return "expected \(type) for key '\(key)'"
        case .ParseError(let key, let value, let msg): return "cannot parse '\(value)' for key '\(key)': \(msg)"
        }
    }
}

protocol JSONObjectDecodable {
    static func decodeJSON(json: JSONObject, forKey key: JSONKey) throws -> Self
}

protocol JSONValueDecodable {
    static func decodeJSON(json: JSONValue, forKey key: JSONKey) throws -> Self
}

private func genericDecodeJSON<TargetType: JSONValueDecodable> (json: JSONValue?, forKey key: JSONKey, type: Any.Type) throws -> TargetType {
    guard let value = json?.value as? TargetType else {
        throw JSONError.ExpectedValue(key: key, type: type)
    }
    return value
}

extension String: JSONValueDecodable {
    static func decodeJSON(json: JSONValue, forKey key: JSONKey) throws -> String {
        return try genericDecodeJSON(json, forKey: key, type: String.self)
    }
}

extension Int: JSONValueDecodable {
    static func decodeJSON(json: JSONValue, forKey key: JSONKey) throws -> Int {
        return try genericDecodeJSON(json, forKey: key, type: Int.self)
    }
}

extension Float: JSONValueDecodable {
    static func decodeJSON(json: JSONValue, forKey key: JSONKey) throws -> Float {
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
    static func decodeJSON(json: JSONValue, forKey key: JSONKey) throws -> Double {
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
    static func decodeJSON(json: JSONValue, forKey key: JSONKey) throws -> Bool {
        return try genericDecodeJSON(json, forKey: key, type: Bool.self)
    }
}

extension Array where Element: JSONValueDecodable {
    static func decodeJSON(json: JSONArray, forKey key: JSONKey) throws -> [Element] {
        return try json.value.map {
            return try Element.decodeJSON(JSONValue(value: $0, context: json.context), forKey: key)
        }
    }
    
    static func decodeJSON(json: JSONArray) throws -> [Element] {
        return try decodeJSON(json, forKey: "")
    }
    
    static func decodeJSON(context: JSONContext)(json: ContextlessJSONArray) throws -> [Element] {
        return try decodeJSON(JSONArray(value: json, context: context), forKey: "")
    }
}

extension Array where Element: JSONObjectDecodable {
    static func decodeJSON(json: JSONArray, forKey key: JSONKey) throws -> [Element] {
        return try json.value.map { item in
            guard let object = item as? ContextlessJSONObject else {
                throw JSONError.ExpectedDictionary(key: key)
            }
            return try Element.decodeJSON(JSONObject(value: object, context: json.context), forKey: key)
        }
    }

    static func decodeJSON(json: JSONArray) throws -> [Element] {
        return try decodeJSON(json, forKey: "")
    }
    
    static func decodeJSON(context: JSONContext)(json: ContextlessJSONArray) throws -> [Element] {
        return try decodeJSON(JSONArray(value: json, context: context), forKey: "")
    }
}

extension JSONValueDecodable {
    static func decodeJSON(json: JSONValue?, forKey key: JSONKey) throws -> Self? {
        guard let value = json else {
            return nil
        }
        return try decodeJSON(value, forKey: key)
    }
}

extension JSONObjectDecodable {
    static func decodeJSON(json: JSONObject?, forKey key: JSONKey) throws -> Self? {
        guard let value = json else {
            return nil
        }
        return try decodeJSON(value, forKey: key)
    }
    
    static func decodeJSON(context: JSONContext)(json: ContextlessJSONObject) throws -> Self {
        return try decodeJSON(JSONObject(value: json, context: context), forKey: "")
    }
}

infix operator <~ { associativity left precedence 150 }

func <~ <TargetType: JSONValueDecodable> (json: JSONObject, key: String) throws -> TargetType {
    guard let value = json.value[key] else {
        throw JSONError.ExpectedValue(key: key, type: Any.self)
    }
    return try TargetType.decodeJSON(JSONValue(value: value, context: json.context), forKey: key)
}

func <~ <TargetType: JSONValueDecodable> (json: JSONObject, key: String) throws -> [TargetType] {
    guard let array = json.value[key] as? ContextlessJSONArray else {
        throw JSONError.ExpectedArray(key: key)
    }
    return try [TargetType].decodeJSON(JSONArray(value: array, context: json.context), forKey: key)
}

func <~ <TargetType: JSONValueDecodable>(json: JSONObject, key: String) throws -> TargetType? {
    guard let value = json.value[key] else {
        return nil
    }
    return try TargetType.decodeJSON(JSONValue(value: value, context: json.context), forKey: key)
}

func <~ <TargetType: JSONObjectDecodable>(json: JSONObject, key: String) throws -> TargetType {
    guard let object = json.value[key] as? ContextlessJSONObject else {
        throw JSONError.ExpectedDictionary(key: key)
    }
    return try TargetType.decodeJSON(JSONObject(value: object, context: json.context), forKey: key)
}

func <~ <TargetType: JSONObjectDecodable>(json: JSONObject, key: String) throws -> [TargetType] {
    guard let array = json.value[key] as? ContextlessJSONArray else {
        throw JSONError.ExpectedArray(key: key)
    }
    return try [TargetType].decodeJSON(JSONArray(value: array, context: json.context), forKey: key)
}

func <~ <TargetType: JSONObjectDecodable>(json: JSONObject, key: String) throws -> TargetType? {
    guard let value = json.value[key] else {
        return nil
    }
    guard let object = value as? ContextlessJSONObject else {
        throw JSONError.ExpectedDictionary(key: key)
    }
    return try TargetType.decodeJSON(JSONObject(value: object, context: json.context), forKey: key)
}
