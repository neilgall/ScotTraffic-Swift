//
//  Join.swift
//  ScotTraffic
//
//  Created by Neil Gall on 04/01/2016.
//  Copyright © 2016 Neil Gall. All rights reserved.
//

import Foundation

class JoinedSignal<Value>: Signal<Value> {
    
    private var outerReceiver: ReceiverType!
    private var innerReceiver: ReceiverType?
    
    init<Outer: SignalType, Inner: SignalType where Outer.ValueType == Inner, Inner.ValueType == Value>(_ source: Outer) {
        super.init()
        outerReceiver = Receiver(source) { [weak self] transaction in
            if case .End(let inner) = transaction {
                self?.innerReceiver = Receiver(inner) { [weak self] transaction in
                    self?.pushTransaction(transaction)
                }
            }
        }
    }
}

public extension SignalType where ValueType: SignalType {
    public func join() -> Signal<ValueType.ValueType> {
        return JoinedSignal(self)
    }
}