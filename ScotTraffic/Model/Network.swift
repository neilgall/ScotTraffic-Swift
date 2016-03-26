//
//  Network.swift
//  ScotTraffic
//
//  Created by Neil Gall on 30/09/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit

private let requestTimeout: NSTimeInterval = 30

enum NetworkError: ErrorType, CustomStringConvertible {
    case MalformedURL
    case FetchError(NSError)
    case HTTPError(Int)
    case CannotParseImage
    
    var description: String {
        switch self {
        case .MalformedURL: return "malformed URL"
        case .FetchError(let error): return "URL fetch error: \(error)"
        case .HTTPError(let code): return "HTTP status code \(code)"
        case .CannotParseImage: return "failed to parse image data"
        }
    }
}

class HTTPAccess: NSObject, NSURLSessionDelegate {
    private let indicator: NetworkActivityIndicator?
    private let baseURL: NSURL
    private let reachability: Reachability?
    private var session: NSURLSession!
    
    let serverIsReachable: Signal<Bool>
    
    enum HTTPMethod: String {
        case GET
        case PUT
        case POST
        case DELETE
        case HEAD
    }
    
    init(baseURL: NSURL, indicator: NetworkActivityIndicator?) {
        self.baseURL = baseURL
        self.indicator = indicator
        do {
            self.reachability = try Reachability.reachabilityForInternetConnection()
        } catch {
            self.reachability = nil
        }
        
        // assume reachable at first as the true->false transition is the important one
        let serverIsReachable = Input(initial: true)
        self.serverIsReachable = serverIsReachable
        
        super.init()
        
        let configuration = NSURLSessionConfiguration.ephemeralSessionConfiguration()
        session = NSURLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        
        reachability?.whenReachable = { _ in
            dispatch_async(dispatch_get_main_queue()) {
                serverIsReachable <-- true
            }
        }
        reachability?.whenUnreachable = { _ in
            dispatch_async(dispatch_get_main_queue()) {
                serverIsReachable <-- false
            }
        }
    }
    
    func startReachabilityNotifier() {
        do {
            try reachability?.startNotifier()
        } catch {
            analyticsError("startReachability", error: error)
        }

        if let reachability = self.reachability, flag = serverIsReachable as? Input<Bool> {
            flag <-- reachability.currentReachabilityStatus != .NotReachable
        }
    }

    func URLSession(session: NSURLSession, didBecomeInvalidWithError error: NSError?) {
    }
    
    func fetchDataAtPath(path: String, completion: DataSourceData -> Void) {
        return request(.GET, path: path, headers: nil, data: nil, completion: completion)
        
    }
    
    func request(method: HTTPMethod, path: String, headers: [String: String]?, data: NSData?, completion: DataSourceData -> Void) {
        guard let url = NSURL(string: path, relativeToURL: baseURL) else {
            completion(DataSourceValue.Error(.Network(.MalformedURL)))
            return
        }
        let request = NSMutableURLRequest(URL: url, cachePolicy: .ReloadIgnoringLocalCacheData, timeoutInterval: requestTimeout)
        request.HTTPMethod = method.rawValue
        request.HTTPBody = data
        headers?.forEach { (key, value) in
            request.addValue(value, forHTTPHeaderField: key)
        }
        
        runTaskForRequest(request, completion: completion)
    }
    
    private func runTaskForRequest(request: NSURLRequest, completion: DataSourceData -> Void) {
        let task = session.dataTaskWithRequest(request) { data, response, error in
            if let httpResponse = response as? NSHTTPURLResponse where httpResponse.statusCode != 200 {
                completion(DataSourceValue.Error(.Network(.HTTPError(httpResponse.statusCode))))
            
            } else if let error = error {
                completion(DataSourceValue.Error(.Network(.FetchError(error))))
                
            } else if let data = data {
                completion(DataSourceValue.Fresh(data))
            }
            
            self.indicator?.pop()
        }
        
        indicator?.push()
        task.resume()
    }
}

func JSONArrayFromData(data: NSData) throws -> ContextlessJSONArray {
    let json = try NSJSONSerialization.JSONObjectWithData(data, options: [])
    guard let array = json as? ContextlessJSONArray else {
        throw JSONError.ExpectedArray(key: "")
    }
    return array
}

func JSONObjectFromData(data: NSData) throws -> ContextlessJSONObject {
    let json = try NSJSONSerialization.JSONObjectWithData(data, options: [])
    guard let object = json as? ContextlessJSONObject else {
        throw JSONError.ExpectedDictionary(key: "")
    }
    return object
}

func UIImageFromData(data: NSData) throws -> UIImage {
    guard let image = UIImage(data: data) else {
        throw NetworkError.CannotParseImage
    }
    return image
}

protocol NetworkActivityIndicator {
    func push()
    func pop()
}

