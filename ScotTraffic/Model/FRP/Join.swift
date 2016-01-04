//
//  Join.swift
//  ScotTraffic
//
//  Created by Neil Gall on 04/01/2016.
//  Copyright © 2016 Neil Gall. All rights reserved.
//

import Foundation

class JoinedObservable<Value>: Observable<Value> {
    
    private var outerObservation: Observation!
    private var innerObservation: Observation?
    
    init<Inner: ObservableType where Inner.ValueType == Value>(_ source: Observable<Inner>) {
        super.init()
        outerObservation = Observer(source) { [weak self] transaction in
            if case .End(let inner) = transaction {
                self?.innerObservation = Observer(inner) { [weak self] transaction in
                    self?.pushTransaction(transaction)
                }
            }
        }
    }
}

public extension Observable where Value: ObservableType {
    public func join() -> Observable<Value.ValueType> {
        return JoinedObservable(self)
    }
}