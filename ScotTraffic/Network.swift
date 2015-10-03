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
    case MalformedURL
    case FetchError(NSError)
    case CannotParseImage
    
    public var description: String {
        switch self {
        case .MalformedURL: return "malformed URL"
        case .FetchError(let error): return "URL fetch error: \(error)"
        case .CannotParseImage: return "failed to parse image data"
        }
    }
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
    
    public func fetchDataAtPath(path: String, completion: Either<NSData,NetworkError> -> Void) {
        guard let url = NSURL(string: path, relativeToURL: baseURL) else {
            completion(Either.Error(NetworkError.MalformedURL))
            return
        }
        
        let task = session.dataTaskWithURL(url) { data, _, error in
            if let error = error {
                completion(Either.Error(NetworkError.FetchError(error)))
                
            } else if let data = data {
                completion(Either.Value(data))
            }
        }
        task.resume()
    }
}

class HTTPDataSource: Source<Either<NSData,NetworkError>> {
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
        throw JSONError.ExpectedArray(key: "")
    }
    return array
}

public func UIImageFromData(data: NSData) throws -> UIImage {
    guard let image = UIImage(data: data) else {
        throw NetworkError.CannotParseImage
    }
    return image
}
