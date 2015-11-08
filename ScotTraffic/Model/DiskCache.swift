//
//  DiskCache.swift
//  ScotTraffic
//
//  Created by Neil Gall on 25/08/2015.
//  Copyright (c) 2015 ZBS Mobile. All rights reserved.
//

import UIKit

public class DiskCache: NSObject {
   
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
    
    public func dataForKey(key: String, completion: NSData? -> ()) {
        let operation = NSBlockOperation() {
            guard let url = NSURL(string: key, relativeToURL: self.directoryURL) else {
                dispatch_async(dispatch_get_main_queue()) {
                    completion(nil)
                }
                return
            }
            
            do {
                let data = try NSData(contentsOfURL: url, options: .DataReadingMapped)
                dispatch_async(dispatch_get_main_queue()) {
                    completion(data)
                }
            } catch {
                dispatch_async(dispatch_get_main_queue()) {
                    completion(nil)
                }
            }
        }
        
        addReadOperation(operation)
    }
    
    public func storeData(data: NSData, forKey key: String) {
        let operation = NSBlockOperation() {
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
        
        addWriteOperation(operation)
    }
    
    public func removeDataForKey(key: String) {
        let operation = NSBlockOperation() {
            guard let url = NSURL(string: key, relativeToURL: self.directoryURL) else {
                return
            }

            do {
                let fileManager = NSFileManager.defaultManager()
                try fileManager.removeItemAtURL(url)
            } catch {
                NSLog("failed to remove \(url): \(error)")
            }
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
