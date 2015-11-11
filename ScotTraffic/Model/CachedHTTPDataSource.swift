//
//  CachedHTTPDataSource.swift
//  ScotTraffic
//
//  Created by Neil Gall on 01/11/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import Foundation

public class CachedHTTPDataSource: DataSource {

    // Output
    public let value = Observable<Either<NSData, NetworkError>>()
    
    private let diskCache: DiskCache
    private let fetcher: HTTPFetcher
    private let maximumCacheAge: NSTimeInterval
    private let key: String

    private var httpSource: HTTPDataSource?
    private var httpObservation: Observation?
    private var inFlight = false
    
    init(fetcher: HTTPFetcher, cache: DiskCache, maximumCacheAge: NSTimeInterval, path: String) {
        self.fetcher = fetcher
        self.diskCache = cache
        self.maximumCacheAge = maximumCacheAge
        self.key = path
    }
    
    public func start() {
        guard !inFlight else {
            // already in-flight
            return
        }
        
        inFlight = true
        diskCache.dataForKey(key) { result in
            switch result {
                
            case .Hit(let data, let date):
                let age = NSDate().timeIntervalSinceDate(date)
                print ("cache hit \(self.key) age \(age)")
                self.cacheHit(data, age: age)
                
            case .Miss:
                print ("cache miss \(self.key)")
                self.startHTTPSource(false)
            }
        }
    }
    
    private func cacheHit(data: NSData, age: NSTimeInterval) {
        value.pushValue(.Value(data))
        if age < maximumCacheAge {
            inFlight = false
        } else {
            // cache hit but old, so follow up with network fetch
            startHTTPSource(true)
        }
    }
    
    private func startHTTPSource(afterCacheHit: Bool) {
        let httpSource = HTTPDataSource(fetcher: self.fetcher, path: self.key)
        
        httpObservation = httpSource.value.output { dataOrError in
            switch dataOrError {
            case .Value(let data):
                self.diskCache.storeData(data, forKey: self.key)
                self.value.pushValue(dataOrError)

            case .Error:
                if !afterCacheHit {
                    self.value.pushValue(dataOrError)
                }
            }
            
            self.endHTTPSource()
        }
        
        self.httpSource = httpSource
        httpSource.start()
    }
    
    private func endHTTPSource() {
        httpSource = nil
        httpObservation = nil
        inFlight = false
    }

    public static func dataSourceWithFetcher(fetcher: HTTPFetcher, cache: DiskCache)(maximumCacheAge: NSTimeInterval)(path: String) -> DataSource {
        return CachedHTTPDataSource(fetcher: fetcher, cache: cache, maximumCacheAge: maximumCacheAge, path: path)
    }
}
