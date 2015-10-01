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

public typealias JSON = [String : AnyObject]

public protocol JSONObjectDecodable {
    static func decodeJSON(json: JSON) throws -> Self
}

public protocol JSONValueDecodable {}

extension String: JSONValueDecodable {}
extension Int: JSONValueDecodable {}
extension Float: JSONValueDecodable {}
extension Double: JSONValueDecodable {}
extension Bool: JSONValueDecodable {}

infix operator <~ { associativity left precedence 150 }

public func <~ <T: JSONValueDecodable> (json: JSON, key: String) throws -> T {
    guard let value = json[key] as? T else {
        throw JSONError.ExpectedValue
    }
    return value
}

public func <~ <T: JSONValueDecodable> (json: JSON, key: String) throws -> T? {
    guard let object = json[key] else {
        return nil
    }
    guard let value = object as? T else {
        throw JSONError.ExpectedValue
    }
    return value
}

public func <~ <T: JSONValueDecodable> (json: JSON, key: String) throws -> [T] {
    guard let values = json[key] as? [T] else {
        throw JSONError.ExpectedArray
    }
    return values
}

public func <~ <T: JSONValueDecodable> (json: JSON, key: String) throws -> [T]? {
    guard let object = json[key] else {
        return nil
    }
    guard let values = object as? [T] else {
        throw JSONError.ExpectedArray
    }
    return values
}

public func <~ <T: JSONObjectDecodable> (json: JSON, key: String) throws -> T {
    guard let dict = json[key] as? JSON else {
        throw JSONError.ExpectedDictionary
    }
    return try T.decodeJSON(dict)
}

public func <~ <T: JSONObjectDecodable> (json: JSON, key: String) throws -> T? {
    guard let object = json[key] else {
        return nil
    }
    guard let dict = object as? JSON else {
        throw JSONError.ExpectedDictionary
    }
    return try T.decodeJSON(dict)
}

public func <~ <T: JSONObjectDecodable> (json: JSON, key: String) throws -> [T] {
    guard let array = json[key] as? [JSON] else {
        throw JSONError.ExpectedArray
    }
    return try array.map(T.decodeJSON)
}

public func <~ <T: JSONObjectDecodable> (json: JSON, key: String) throws -> [T]? {
    guard let object = json[key] else {
        return nil
    }
    guard let array = object as? [JSON] else {
        throw JSONError.ExpectedArray
    }
    return try array.map(T.decodeJSON)
}
