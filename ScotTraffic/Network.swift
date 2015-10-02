//
//  Network.swift
//  ScotTraffic
//
//  Created by Neil Gall on 30/09/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import Foundation

let HTTPFetcherErrorDomain = "HTTPFetcherErrorDomain"

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
    
    public func fetchJSONAtPath(path: String, completion: Either<JSONValue,NSError> -> Void) {
        guard let url = NSURL(string: path, relativeToURL: baseURL) else {
            completion(Either.Error(self.errorWithCode(1)))
            return
        }
        
        let task = session.dataTaskWithURL(url) { data, _, error in
            if let error = error {
                completion(Either.Error(error))
                
            } else if let data = data {
                do {
                    let json = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions())
                    completion(Either.Value(json))
                } catch {
                    completion(Either.Error(error as NSError))
                }
            }
        }
        task.resume()
    }
    
    public func fetchJSONArrayAtPath(path: String, completion: Either<JSONArray,NSError> -> Void) {
        fetchJSONAtPath(path) { completion($0.map { ($0 as? JSONArray)! }) }
    }
        
    private func errorWithCode(code: Int) -> NSError {
        return NSError(domain: HTTPFetcherErrorDomain, code: code, userInfo: nil)
    }
}

public class HTTPJSONArraySource: Source<Either<JSONArray,NSError>> {
    let fetcher: HTTPFetcher
    let path: String
    
    public init(fetcher: HTTPFetcher, path: String) {
        self.fetcher = fetcher
        self.path = path
        super.init(initial: Either.Value(emptyJSON))
    }
    
    public func start() {
        self.fetcher.fetchJSONArrayAtPath(path) { self.value = $0 }
    }
}