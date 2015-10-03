//
//  Network.swift
//  ScotTraffic
//
//  Created by Neil Gall on 30/09/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit

let HTTPFetcherErrorDomain = "HTTPFetcherErrorDomain"

public enum NetworkError : ErrorType {
    case CannotParseImage
}

public class HTTPFetcher: NSObject, NSURLSessionDelegate {
    let baseURL: NSURL
    var session: NSURLSession!
    
    public init(baseURL: NSURL) {
        self.baseURL = baseURL
        super.init()
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        session = NSURLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }

    public func URLSession(session: NSURLSession, didBecomeInvalidWithError error: NSError?) {
    }
    
    public func fetchDataAtPath(path: String, completion: Either<NSData,NSError> -> Void) {
        guard let url = NSURL(string: path, relativeToURL: baseURL) else {
            completion(Either.Error(HTTPFetcher.errorWithCode(1)))
            return
        }
        
        let task = session.dataTaskWithURL(url) { data, _, error in
            if let error = error {
                completion(Either.Error(error))
                
            } else if let data = data {
                completion(Either.Value(data))
            }
        }
        task.resume()
    }
    
    private static func errorWithCode(code: Int) -> NSError {
        return NSError(domain: HTTPFetcherErrorDomain, code: code, userInfo: nil)
    }
}

class HTTPDataSource: Source<Either<NSData,NSError>> {
    let fetcher: HTTPFetcher
    let path: String
    
    init(fetcher: HTTPFetcher, path: String) {
        self.fetcher = fetcher
        self.path = path
        super.init(initial: Either.Value(NSData()))
    }
    
    func start() {
        self.fetcher.fetchDataAtPath(path) { self.value = $0 }
    }
}

public func JSONArrayFromData(data: NSData) throws -> JSONArray {
    let json = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions())
    guard let array = json as? JSONArray else {
        throw JSONError.ExpectedArray
    }
    return array
}

public func UIImageFromData(data: NSData) throws -> UIImage {
    guard let image = UIImage(data: data) else {
        throw NetworkError.CannotParseImage
    }
    return image
}
