//
//  Throttle.swift
//  ScotTraffic
//
//  Created by Neil Gall on 04/01/2016.
//  Copyright © 2016 Neil Gall. All rights reserved.
//

import Foundation


class Throttle<ValueType> : Observable<ValueType> {
    private let timer: dispatch_source_t
    private let minimumInterval: NSTimeInterval
    private var lastPushTimestamp: CFAbsoluteTime = 0
    private var observer: Observation!
    private var transactionCount: Int = 0
    private var timerActive: Bool = false
    
    init(_ source: Observable<ValueType>, minimumInterval: NSTimeInterval, queue: dispatch_queue_t) {
        self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue)
        self.minimumInterval = minimumInterval
        
        super.init()
        
        self.observer = Observer(source) { transaction in
            switch transaction {
            case .Begin:
                if self.transactionCount == 0 {
                    self.pushTransaction(transaction)
                }
                self.transactionCount += 1
                
            case .End:
                dispatch_suspend(self.timer)
                if self.timerActive {
                    self.endTransaction(.Cancel)
                    self.timerActive = false
                }
                
                let now = CFAbsoluteTimeGetCurrent()
                if now - self.lastPushTimestamp > self.minimumInterval {
                    self.endTransaction(transaction)
                    self.lastPushTimestamp = now
                    
                } else {
                    self.deferEndTransaction(transaction)
                }
                
            case .Cancel:
                self.endTransaction(transaction)
            }
        }
    }
    
    deinit {
        dispatch_source_cancel(timer)
    }
    
    private func endTransaction(transaction: Transaction<ValueType>) {
        self.transactionCount -= 1
        if self.transactionCount == 0 {
            self.pushTransaction(transaction)
        }
    }
    
    private func deferEndTransaction(transaction: Transaction<ValueType>) {
        dispatch_source_set_event_handler(timer) {
            self.endTransaction(transaction)
            self.lastPushTimestamp = CFAbsoluteTimeGetCurrent()
            self.timerActive = false
        }
        
        dispatch_source_set_timer(timer,
            DISPATCH_TIME_NOW,
            nanosecondsFromSeconds(minimumInterval),
            nanosecondsFromSeconds(minimumInterval * 0.2))
        
        self.timerActive = true
        dispatch_resume(timer)
    }
}


extension Observable {
    public func throttle(minimumInterval: NSTimeInterval, queue: dispatch_queue_t) -> Observable<ValueType> {
        return Throttle(self, minimumInterval: minimumInterval, queue: queue)
    }
}
