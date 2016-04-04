//
//  CachedHTTPDataSource.swift
//  ScotTraffic
//
//  Created by Neil Gall on 01/11/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import Foundation

class CachedHTTPDataSource: DataSource {

    // Output
    let value = Signal<DataSourceData>()
    
    private let diskCache: DiskCache
    private let httpAccess: HTTPAccess
    private let maximumCacheAge: NSTimeInterval
    private let key: String
    private var inFlight = false
    
    init(httpAccess: HTTPAccess, cache: DiskCache, maximumCacheAge: NSTimeInterval, path: String) {
        self.httpAccess = httpAccess
        self.diskCache = cache
        self.maximumCacheAge = maximumCacheAge
        self.key = path
    }
    
    func start() {
        guard !inFlight else {
            // already in-flight
            return
        }
        
        inFlight = true
        diskCache.dataForKey(key) { result in
            switch result {
                
            case .Hit(let data, let date):
                let age = NSDate().timeIntervalSinceDate(date)
                self.cacheHit(data, age: age)
                
            case .Miss:
                self.startHTTPSource(nil)
            }
        }
    }
    
    private func cacheHit(data: NSData, age: NSTimeInterval) {
        let expired = age > maximumCacheAge
        value.pushValue(.Cached(data, expired: expired))
        
        if !expired {
            inFlight = false
        } else {
            // cache hit but old, so follow up with network fetch
            startHTTPSource(age)
        }
    }
    
    private func startHTTPSource(cacheAge: NSTimeInterval?) {
        let headers: [String: String]? = cacheAge.map({ age in
            let date = NSDate().dateByAddingTimeInterval(-age)
            return ["If-Modified-Since": NSDateFormatter.RFC2822.stringFromDate(date)]
        })
        let key = self.key
        
        httpAccess.request(.GET, path: key, headers: headers, data: nil) { [weak self] dataOrError in
            switch dataOrError {
            case .Fresh(let data):
                self?.diskCache.storeData(data, forKey: key)
                onMainQueue {
                    self?.value.pushValue(dataOrError)
                }

            case .Error(let error):
                if cacheAge == nil || !error.isHTTP(304) {
                    onMainQueue {
                        self?.value.pushValue(dataOrError)
                    }
                }
                
            case .Cached, .Empty:
                break
            }
            
            onMainQueue {
                self?.inFlight = false
            }
        }
    }
    
    static func dataSourceWithHTTPAccess(httpAccess: HTTPAccess, cache: DiskCache) -> NSTimeInterval -> String -> DataSource {
        return { maximumCacheAge in
            return { path in
                CachedHTTPDataSource(httpAccess: httpAccess, cache: cache, maximumCacheAge: maximumCacheAge, path: path)
            }
        }
    }
}

private extension AppError {
    func isHTTP(httpErrorCode: Int) -> Bool {
        guard case .Network(let network) = self, case .HTTPError(let code) = network else {
            return false
        }
        return code == httpErrorCode
    }
}
