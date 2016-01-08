//
//  MessageOfTheDay.swift
//  ScotTraffic
//
//  Created by Neil Gall on 08/01/2016.
//  Copyright © 2016 Neil Gall. All rights reserved.
//

import Foundation

private let messageOfTheDaySHAKey = "messageOfTheDaySHA"

public struct MessageOfTheDay {
    let title: String
    let body: String
    let date: NSDate
    let url: NSURL?
    
    var sha1: NSData {
        let str = "\(title).\(body).\(date).\(url)"
        let cstr = str.cStringUsingEncoding(NSUTF8StringEncoding)
        let cstrLen = CC_LONG(str.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
        let digestLen = Int(CC_SHA1_DIGEST_LENGTH)
        let result = UnsafeMutablePointer<CUnsignedChar>.alloc(digestLen)
        CC_SHA1(cstr!, cstrLen, result)
        let data = NSData(bytes: result, length: digestLen)
        result.dealloc(digestLen)
        return data
    }
}

extension MessageOfTheDay: JSONObjectDecodable {
    public static func decodeJSON(json: JSONObject, forKey key: JSONKey) throws -> MessageOfTheDay {
        return try MessageOfTheDay(
            title: json <~ "title",
            body: json <~ "body",
            date: parseDate(json),
            url: parseURL(json))
    }
}

private func parseDate(json: JSONObject) throws -> NSDate {
    guard let date = (try json <~ "date").flatMap({ NSDateFormatter.ISO8601.dateFromString($0) }) else {
        throw JSONError.ExpectedValue(key: "date", type: NSDate.self)
    }
    return date
}

private func parseURL(json: JSONObject) throws -> NSURL? {
    return (try json <~ "url").flatMap({ NSURL(string: $0) })
}

extension UserDefaultsProtocol {
    public func messageOfTheDaySeenBefore(message: MessageOfTheDay) -> Bool {
        guard let lastMessageSHA = objectForKey(messageOfTheDaySHAKey) as? NSData else {
            return false
        }
        return lastMessageSHA == message.sha1
    }
    
    public func noteMessageOfTheDaySeen(message: MessageOfTheDay) {
        setObject(message.sha1, forKey: messageOfTheDaySHAKey)
    }
}
