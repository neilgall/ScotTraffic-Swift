//
//  Booleans.swift
//  ScotTraffic
//
//  Created by Neil Gall on 04/01/2016.
//  Copyright © 2016 Neil Gall. All rights reserved.
//

import Foundation

// Gate is a form of controllable filter. Values from the source signal are not
// propagated when the gate is "closed" (false). When the gate opens, the last
// value frm the source signal is then propagated.
//
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

    // An output on boolean signals which only fire when the value goes from false to true
    //
    public func onRisingEdge(closure: Void -> Void) -> ReceiverType {
        return onChange().filter({ $0.boolValue == true }) --> { _ in closure() }
    }
    
    // An output on boolean signals which only fire when the value goes from true to false
    //
    public func onFallingEdge(closure: Void -> Void) -> ReceiverType {
        return onChange().filter({ $0.boolValue == false }) --> { _ in closure() }
    }
    
    // Convenience Gate creation
    //
    public func gate<SourceType>(source: Signal<SourceType>) -> Signal<SourceType> {
        return Gate(source, gate: self.map({ $0.boolValue }))
    }
}

// Invert the sense of a boolean signal
//
public func not<S: SignalType where S.ValueType: BooleanType>(signal: S) -> Signal<Bool> {
    return signal.map { b in !b.boolValue }
}

// Given a signal where the value type is optional, create a signal that indicates whether
// the source value is nil
//
public func isNil<S: SignalType, T where S.ValueType == T?>(signal: S) -> Signal<Bool> {
    return signal.map { $0 == nil }
}

// Logical AND of boolean signals. Note that there is no shortcutting as this is based on
// Combiners, so both sides are evaluated on each change.
//
public func && <LHS: SignalType, RHS: SignalType where LHS.ValueType: BooleanType, RHS.ValueType: BooleanType>(lhs: LHS, rhs: RHS) -> Signal<Bool> {
    return combine(lhs, rhs) { $0.boolValue && $1.boolValue }
}

// Logical OR of boolean signals. Note that there is no shortcutting as this is based on
// Combiners, so both sides are evaluated on each change.
//
public func || <LHS: SignalType, RHS: SignalType where LHS.ValueType: BooleanType, RHS.ValueType: BooleanType>(lhs: LHS, rhs: RHS) -> Signal<Bool> {
    return combine(lhs, rhs) { $0.boolValue || $1.boolValue }
}

