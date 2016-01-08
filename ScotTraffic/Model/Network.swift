//
//  Network.swift
//  ScotTraffic
//
//  Created by Neil Gall on 30/09/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit

private let requestTimeout: NSTimeInterval = 30

public enum NetworkError: ErrorType {
    case MalformedURL
    case FetchError(NSError)
    case HTTPError(Int)
    case CannotParseImage
    
    public var description: String {
        switch self {
        case .MalformedURL: return "malformed URL"
        case .FetchError(let error): return "URL fetch error: \(error)"
        case .HTTPError(let code): return "HTTP status code \(code)"
        case .CannotParseImage: return "failed to parse image data"
        }
    }
}

public class HTTPAccess: NSObject, NSURLSessionDelegate {
    private let indicator: NetworkActivityIndicator?
    private let baseURL: NSURL
    private let reachability: Reachability?
    private var session: NSURLSession!
    
    public let serverIsReachable: Signal<Bool>
    
    public enum HTTPMethod: String {
        case GET
        case PUT
        case POST
        case DELETE
        case HEAD
    }
    
    public init(baseURL: NSURL, indicator: NetworkActivityIndicator?) {
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
    
    public func startReachabilityNotifier() {
        do {
            try reachability?.startNotifier()
        } catch {
            print("Unable to start notifier")
        }

        if let reachability = self.reachability, flag = serverIsReachable as? Input<Bool> {
            flag <-- reachability.currentReachabilityStatus != .NotReachable
        }
    }

    public func URLSession(session: NSURLSession, didBecomeInvalidWithError error: NSError?) {
    }
    
    public func fetchDataAtPath(path: String, completion: DataSourceData -> Void) {
        return request(.GET, data: nil, path: path, completion: completion)
        
    }
    
    public func request(method: HTTPMethod, data: NSData?, path: String, completion: DataSourceData -> Void) {
        guard let url = NSURL(string: path, relativeToURL: baseURL) else {
            completion(DataSourceValue.Error(.Network(.MalformedURL)))
            return
        }
        let request = NSMutableURLRequest(URL: url, cachePolicy: .ReloadIgnoringLocalCacheData, timeoutInterval: requestTimeout)
        request.HTTPMethod = method.rawValue
        request.HTTPBody = data
        
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

class HTTPDataSource: DataSource {
    let httpAccess: HTTPAccess
    let path: String
    let value = Signal<DataSourceData>()
    
    init(httpAccess: HTTPAccess, path: String) {
        self.httpAccess = httpAccess
        self.path = path
    }
    
    func start() {
        print ("GET \(path)")
        self.httpAccess.fetchDataAtPath(path) { data in
            dispatch_async(dispatch_get_main_queue()) {
                self.value.pushValue(data)
            }
        }
    }
}


public func JSONArrayFromData(data: NSData) throws -> ContextlessJSONArray {
    let json = try NSJSONSerialization.JSONObjectWithData(data, options: [])
    guard let array = json as? ContextlessJSONArray else {
        throw JSONError.ExpectedArray(key: "")
    }
    return array
}

public func JSONObjectFromData(data: NSData) throws -> ContextlessJSONObject {
    let json = try NSJSONSerialization.JSONObjectWithData(data, options: [])
    guard let object = json as? ContextlessJSONObject else {
        throw JSONError.ExpectedDictionary(key: "")
    }
    return object
}

public func UIImageFromData(data: NSData) throws -> UIImage {
    guard let image = UIImage(data: data) else {
        throw NetworkError.CannotParseImage
    }
    return image
}

public protocol NetworkActivityIndicator {
    func push()
    func pop()
}

