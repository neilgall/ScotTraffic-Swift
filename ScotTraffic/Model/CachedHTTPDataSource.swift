//
//  CachedHTTPDataSource.swift
//  ScotTraffic
//
//  Created by Neil Gall on 01/11/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import Foundation

class CachedHTTPDataSource: Observable<Either<NSData,NetworkError>>, Startable {
    
    private let httpSource: HTTPDataSource
    private let cacheSource: CacheDataSource
    private var observations = [Observation]()
    
    init(fetcher: HTTPFetcher, cache: DiskCache, path: String) {
        httpSource = HTTPDataSource(fetcher: fetcher, path: path)
        cacheSource = CacheDataSource(cache: cache, key: path)
        
        super.init()
        
        observations.append(httpSource.output({ dataOrError in
            self.pushValue(dataOrError)
            if case .Value(let data) = dataOrError {
                self.cacheSource.update(data)
            }
        }))
    
        observations.append(cacheSource.output({ data in
            if let data = data {
                self.pushValue(.Value(data))
            }
        }))
    }
    
    func start() {
        cacheSource.start()
        httpSource.start()
    }
}

private class CacheDataSource: Observable<NSData?>, Startable {
    let cache: DiskCache
    let key: String
    
    init(cache: DiskCache, key: String) {
        self.cache = cache
        self.key = key
    }
    
    func start() {
        cache.dataForKey(key, completion: pushValue)
    }
    
    func update(data: NSData) {
        cache.storeData(data, forKey: key)
    }
}