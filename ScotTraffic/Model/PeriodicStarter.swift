//
//  PeriodicStarter.swift
//  ScotTraffic
//
//  Created by Neil Gall on 03/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import Foundation

public protocol Startable {
    func start()
}

public class PeriodicStarter {
    let timer: dispatch_source_t
    
    public init(startables: [Startable], period: NSTimeInterval) {
        self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue())
        
        dispatch_source_set_event_handler(self.timer) {
            startables.forEach { $0.start() }
        }
        
        dispatch_source_set_timer(self.timer,
            DISPATCH_TIME_NOW,
            nanosecondsFromSeconds(period),
            nanosecondsFromSeconds(period * 0.2))
        
        dispatch_resume(self.timer)
    }
    
    deinit {
        dispatch_source_cancel(self.timer)
    }
    
}

func nanosecondsFromSeconds(seconds: NSTimeInterval) -> UInt64 {
    let nanoseconds = seconds * Double(NSEC_PER_SEC)
    return UInt64(nanoseconds)
}