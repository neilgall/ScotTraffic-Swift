//
//  CachedHTTPDataSource.swift
//  ScotTraffic
//
//  Created by Neil Gall on 01/11/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import Foundation

class CachedHTTPDataSource: DataSource {
    
    private let httpSource: HTTPDataSource
    private let cacheSource: CacheDataSource
    private var observations = [Observation]()
    
    let value = Observable<Either<NSData, NetworkError>>()

    init(fetcher: HTTPFetcher, cache: DiskCache, path: String) {
        httpSource = HTTPDataSource(fetcher: fetcher, path: path)
        cacheSource = CacheDataSource(cache: cache, key: path)
        
        observations.append(httpSource.value.output({ dataOrError in
            self.value.pushValue(dataOrError)
            if case .Value(let data) = dataOrError {
                self.cacheSource.update(data)
            }
        }))
    
        observations.append(cacheSource.value.output({ dataOrError in
            if case .Value(let data) = dataOrError {
                self.value.pushValue(.Value(data))
            }
        }))
    }
    
    func start() {
        cacheSource.start()
        httpSource.start()
    }

    static func dataSourceWithFetcher(fetcher: HTTPFetcher, cache: DiskCache) -> String -> DataSource {
        return { path in
            CachedHTTPDataSource(fetcher: fetcher, cache: cache, path: path)
        }
    }
}

private class CacheDataSource: DataSource {
    let cache: DiskCache
    let key: String
    let value = Observable<Either<NSData,NetworkError>>()
    
    init(cache: DiskCache, key: String) {
        self.cache = cache
        self.key = key
    }
    
    func start() {
        cache.dataForKey(key) { data in
            if let data = data {
                self.value.pushValue(.Value(data))
            }
        }
    }
    
    func update(data: NSData) {
        cache.storeData(data, forKey: key)
    }
}