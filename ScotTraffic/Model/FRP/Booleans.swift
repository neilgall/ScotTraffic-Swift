//
//  Booleans.swift
//  ScotTraffic
//
//  Created by Neil Gall on 04/01/2016.
//  Copyright © 2016 Neil Gall. All rights reserved.
//

import Foundation

class Gate<Source: SignalType, Gate: SignalType where Gate.ValueType: BooleanType> : Signal<Source.ValueType> {
    let valueLatest: Signal<Source.ValueType>
    let gateLatest: Signal<Gate.ValueType>
    var receivers: [ReceiverType] = []
    var transactionCount = 0
    var needsUpdate = false
    
    init(_ source: Source, gate: Gate) {
        valueLatest = source.latest()
        gateLatest = gate.latest()
        super.init()
        receivers.append(Receiver(valueLatest) { [weak self] t in self?.update(t) })
        receivers.append(Receiver(gateLatest) { [weak self] t in self?.update(t) })
    }
    
    private func update<S>(transaction: Transaction<S>) {
        switch transaction {
        case .Begin:
            if transactionCount == 0 {
                pushTransaction(.Begin)
                needsUpdate = false
            }
            transactionCount += 1
            
        case .End:
            needsUpdate = true
            fallthrough
            
        case .Cancel:
            transactionCount -= 1
            if transactionCount == 0 {
                if needsUpdate, let value = valueLatest.latestValue.get, let gate = gateLatest.latestValue.get where gate.boolValue == true {
                    pushTransaction(.End(value))
                    needsUpdate = false
                } else {
                    pushTransaction(.Cancel)
                }
            }
        }
    }
}

extension Signal where Value: BooleanType, Value: Equatable {
    public func onRisingEdge(closure: Void -> Void) -> ReceiverType {
        return onChange().filter({ $0.boolValue == true }) --> { _ in closure() }
    }
    
    public func onFallingEdge(closure: Void -> Void) -> ReceiverType {
        return onChange().filter({ $0.boolValue == false }) --> { _ in closure() }
    }
    
    public func gate<SourceType>(source: Signal<SourceType>) -> Signal<SourceType> {
        return Gate(source, gate: self.map({ $0.boolValue }))
    }
}

public func not<S: SignalType where S.ValueType: BooleanType>(signal: S) -> Signal<Bool> {
    return signal.map { b in !b.boolValue }
}

public func isNil<S: SignalType, T where S.ValueType == T?>(signal: S) -> Signal<Bool> {
    return signal.map { $0 == nil }
}

public func && <LHS: SignalType, RHS: SignalType where LHS.ValueType: BooleanType, RHS.ValueType: BooleanType>(lhs: LHS, rhs: RHS) -> Signal<Bool> {
    return combine(lhs, rhs) { $0.boolValue && $1.boolValue }
}

public func || <LHS: SignalType, RHS: SignalType where LHS.ValueType: BooleanType, RHS.ValueType: BooleanType>(lhs: LHS, rhs: RHS) -> Signal<Bool> {
    return combine(lhs, rhs) { $0.boolValue || $1.boolValue }
}

