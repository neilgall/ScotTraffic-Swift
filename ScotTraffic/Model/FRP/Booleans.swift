//
//  Booleans.swift
//  ScotTraffic
//
//  Created by Neil Gall on 04/01/2016.
//  Copyright © 2016 Neil Gall. All rights reserved.
//

import Foundation

class Gate<ValueType> : Observable<ValueType> {
    let valueLatest: Latest<ValueType>
    let gateLatest: Latest<Bool>
    var sourceObservers: [Observation] = []
    var transactionCount = 0
    var needsUpdate = false
    
    init(_ source: Observable<ValueType>, gate: Observable<Bool>) {
        valueLatest = source.latest()
        gateLatest = gate.latest()
        super.init()
        sourceObservers.append(Observer(valueLatest) { t in self.update(t) })
        sourceObservers.append(Observer(gateLatest) { t in self.update(t) })
    }
    
    private func update<S>(transaction: Transaction<S>) {
        switch transaction {
        case .Begin:
            if transactionCount == 0 {
                self.pushTransaction(.Begin)
                needsUpdate = false
            }
            transactionCount += 1
            
        case .End:
            needsUpdate = true
            fallthrough
            
        case .Cancel:
            transactionCount -= 1
            if transactionCount == 0 {
                if needsUpdate, let value = valueLatest.pullValue, let gate = gateLatest.pullValue where gate == true {
                    pushTransaction(.End(value))
                    needsUpdate = false
                } else {
                    pushTransaction(.Cancel)
                }
            }
        }
    }
}

extension Observable where Value: BooleanType, Value: Equatable {
    public func onRisingEdge(closure: Void -> Void) -> Observation {
        return onChange().filter({ $0.boolValue == true }) => { _ in closure() }
    }
    
    public func onFallingEdge(closure: Void -> Void) -> Observation {
        return onChange().filter({ $0.boolValue == false }) => { _ in closure() }
    }
    
    public func gate<SourceType>(source: Observable<SourceType>) -> Observable<SourceType> {
        return Gate(source, gate: self.map({ $0.boolValue }))
    }
}

public func not(observable: Observable<Bool>) -> Observable<Bool> {
    return observable.map { b in !b }
}

public func isNil<ValueType>(observable: Observable<ValueType?>) -> Observable<Bool> {
    return observable.map { $0 == nil }
}

public func && (lhs: Observable<Bool>, rhs: Observable<Bool>) -> Observable<Bool> {
    return combine(lhs, rhs) { $0 && $1 }
}

public func || (lhs: Observable<Bool>, rhs: Observable<Bool>) -> Observable<Bool> {
    return combine(lhs, rhs) { $0 || $1 }
}

