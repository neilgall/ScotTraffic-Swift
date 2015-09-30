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
    case ExpectedRawRepresentable
    case ExpectedString
}

public typealias JSON = [String : AnyObject]

public protocol JSONDecodable {
    static func decode(json: JSON) throws -> Self
}

infix operator <~ { associativity left precedence 150 }
infix operator <~? { associativity left precedence 150 }

/** RawRepresentable */
public func <~ <T> (json: JSON, key: String) throws -> T {
    guard let value = json[key] as? T else {
        throw JSONError.ExpectedRawRepresentable
    }
    return value
}

/** Optional Bool */
public func <~? (json: JSON, key: String) throws -> Bool? {
    if let value = json[key] as? Int {
        return value != 0
    }
    guard let value = json[key] as? Bool? else {
        throw JSONError.ExpectedRawRepresentable
    }
    return value
}

/** Optional primitive */
public func <~? <T> (json: JSON, key: String) throws -> T? {
    guard let object = json[key] else {
        return nil
    }
    guard let value = object as? T else {
        throw JSONError.ExpectedRawRepresentable
    }
    return value
}

/** Primitive array */
public func <~ <T: RawRepresentable> (json: JSON, key: String) throws -> [T] {
    guard let values = json[key] as? [T] else {
        throw JSONError.ExpectedArray
    }
    return values
}

/** JSONDecodable */
public func <~ <T: JSONDecodable> (json: JSON, key: String) throws -> T {
    guard let dict = json[key] as? JSON else {
        throw JSONError.ExpectedDictionary
    }
    return try T.decode(dict)
}

/** Optional JSONDecodable */
public func <~? <T: JSONDecodable> (json: JSON, key: String) throws -> T? {
    guard let object = json[key] else {
        return nil
    }
    guard let dict = object as? JSON else {
        throw JSONError.ExpectedDictionary
    }
    return try T.decode(dict)
}

/** Decodable array */
public func <~ <T: JSONDecodable> (json: JSON, key: String) throws -> [T] {
    guard let array = json[key] as? [JSON] else {
        throw JSONError.ExpectedArray
    }
    return try array.map(T.decode)
}
