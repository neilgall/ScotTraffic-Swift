//
//  PeriodicStarter.swift
//  ScotTraffic
//
//  Created by Neil Gall on 03/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import Foundation

protocol Startable {
    func start()
}

class PeriodicStarter {
    let timer: dispatch_source_t
    let period: NSTimeInterval
    let startables: [Startable]
    
    init(startables: [Startable], period: NSTimeInterval) {
        self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue())
        self.period = period
        self.startables = startables
        
        dispatch_source_set_event_handler(self.timer) {
            self.fire()
        }
        
        self.start()
    }
    
    deinit {
        dispatch_source_cancel(self.timer)
    }
    
    func restart(fireImmediately fireImmediately: Bool) {
        stop()
        if fireImmediately {
            fire()
        }
        start()
    }
    
    private func start() {
        dispatch_source_set_timer(self.timer,
            DISPATCH_TIME_NOW,
            nanosecondsFromSeconds(period),
            nanosecondsFromSeconds(period * 0.2))
        
        dispatch_resume(self.timer)
    }
    
    private func stop() {
        dispatch_suspend(self.timer)
    }
    
    private func fire() {
        for startable in startables {
            startable.start()
        }
    }
}

func nanosecondsFromSeconds(seconds: NSTimeInterval) -> UInt64 {
    let nanoseconds = seconds * Double(NSEC_PER_SEC)
    return UInt64(nanoseconds)
}