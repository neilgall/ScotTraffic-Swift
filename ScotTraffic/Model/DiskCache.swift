//
//  DiskCache.swift
//  ScotTraffic
//
//  Created by Neil Gall on 25/08/2015.
//  Copyright (c) 2015 ZBS Mobile. All rights reserved.
//

import UIKit

public class DiskCache {
   
    public enum Result {
        case Hit(data: NSData, date: NSDate)
        case Miss
    }
    
    private let directoryURL: NSURL
    private let readQueue: NSOperationQueue
    private let writeQueue: NSOperationQueue
    private let fileManager: NSFileManager
    
    public init(withPath path: String) {
        readQueue = NSOperationQueue()
        writeQueue = NSOperationQueue()
        fileManager = NSFileManager()

        let cacheURLs = NSFileManager.defaultManager().URLsForDirectory(.CachesDirectory, inDomains:.UserDomainMask)
        guard cacheURLs.count > 0 else {
            fatalError("cannot find CachesDirectory")
        }
        
        let pathWithSuffix = path.hasSuffix("/") ? path : path + "/"
        directoryURL = NSURL(string: pathWithSuffix, relativeToURL: cacheURLs[0])!
        
        do {
            try NSFileManager.defaultManager().createDirectoryAtURL(directoryURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            NSLog("failed to create directory \(directoryURL): \(error)")
        }
        
        NSLog("using cache at \(directoryURL)")
    }
    
    public func dataForKey(key: String, completion: Result -> ()) {
        let operation = NSBlockOperation() {
            let result = self.readCacheDataForKey(key)
            dispatch_async(dispatch_get_main_queue()) {
                completion(result)
            }
        }
        
        addReadOperation(operation)
    }
    
    public func storeData(data: NSData, forKey key: String) {
        let operation = NSBlockOperation() {
            self.writeCacheData(data, forKey: key)
        }
        
        addWriteOperation(operation)
    }
    
    public func removeDataForKey(key: String) {
        let operation = NSBlockOperation() {
            self.deleteCacheDataForKey(key)
        }
        
        addWriteOperation(operation)
    }
    
    private func addReadOperation(operation: NSOperation) {
        writeQueue.operations.forEach { operation.addDependency($0) }
        readQueue.addOperation(operation)
    }
    
    private func addWriteOperation(operation: NSOperation) {
        readQueue.operations.forEach { operation.addDependency($0) }
        writeQueue.operations.forEach { operation.addDependency($0) }
        writeQueue.addOperation(operation)
    }
    
    private func readCacheDataForKey(key: String) -> Result {
        if let url = NSURL(string: key, relativeToURL: self.directoryURL) {
            do {
                let attrs = try url.path.map { try self.fileManager.attributesOfItemAtPath($0) }
                if let modificationDate = attrs?[NSFileModificationDate] as? NSDate {
                    let data = try NSData(contentsOfURL: url, options: .DataReadingMapped)
                    return .Hit(data: data, date: modificationDate)
                }
            } catch {
                // ignore errors and send a cache miss
            }
        }
        return .Miss
    }
    
    private func writeCacheData(data: NSData, forKey key: String) {
        guard let url = NSURL(string: key, relativeToURL: self.directoryURL) else {
            return
        }
        
        do {
            try self.ensureParentDirectoryExistsAtURL(url)
            try data.writeToURL(url, options: .DataWritingAtomic)
        } catch {
            NSLog("failed to write \(url): \(error)")
        }
    }
    
    private func deleteCacheDataForKey(key: String) {
        guard let url = NSURL(string: key, relativeToURL: self.directoryURL) else {
            return
        }
        
        do {
            try fileManager.removeItemAtURL(url)
        } catch {
            NSLog("failed to remove \(url): \(error)")
        }
    }

    private func ensureParentDirectoryExistsAtURL(url: NSURL) throws {
        if var components = url.pathComponents {
            components.removeLast()
            let directoryPath = NSString.pathWithComponents(components)
            if !fileManager.fileExistsAtPath(directoryPath) {
                try fileManager.createDirectoryAtPath(directoryPath, withIntermediateDirectories: true, attributes: nil)
            }
        }
    }
}
