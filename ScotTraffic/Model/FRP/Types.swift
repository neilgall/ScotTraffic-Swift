//
//  Types.swift
//  ScotTraffic
//
//  Created by Neil Gall on 04/01/2016.
//  Copyright © 2016 Neil Gall. All rights reserved.
//

import Foundation

public protocol ReceiverType {}

public enum Transaction<ValueType> {
    case Begin
    case End(ValueType)
    case Cancel
}

public enum LatestValue<Value> {
    case None
    case Computed(Void -> Value)
    case Stored(Value)
    
    public var has: Bool {
        switch self {
        case .None: return false
        case .Stored: return true
        case .Computed: return true
        }
    }
    
    public var get: Value? {
        switch self {
        case .None:
            return nil
        case .Stored(let value):
            return value
        case .Computed(let getValue):
            return getValue()
        }
    }
}

public protocol SignalType {
    typealias ValueType
    
    func addObserver(observer: Transaction<ValueType> -> Void) -> Int
    func removeObserver(id: Int)
    
    func pushTransaction(transaction: Transaction<ValueType>)
    func pushValue(value: ValueType)
    
    var latestValue: LatestValue<ValueType> { get }
}

public protocol InputType {
    typealias ValueType
    
    var value: ValueType { get set }
}

public class Signal<Value> : SignalType {
    public typealias ValueType = Value
    
    private var observers: [Int : Transaction<ValueType> -> Void] = [:]
    private var nextObserverId: Int = 0
    
    public init() {
    }
    
    public func addObserver(observer: Transaction<ValueType> -> Void) -> Int {
        switch latestValue {
        case .Stored(let value):
            observer(.Begin)
            observer(.End(value))
        case .Computed(let getValue):
            observer(.Begin)
            observer(.End(getValue()))
        case .None:
            break
        }
        let id = nextObserverId++
        observers[id] = observer
        return id
    }
    
    public func removeObserver(id: Int) {
        observers.removeValueForKey(id)
    }
    
    // Push
    public func pushValue(value: ValueType) {
        pushTransaction(.Begin)
        pushTransaction(.End(value))
    }
    
    public func pushTransaction(transaction: Transaction<ValueType>) {
        for observer in observers.values {
            observer(transaction)
        }
    }
    
    public var latestValue: LatestValue<Value> {
        return .None
    }
}

public class Input<Value> : Signal<Value>, InputType {
    public typealias ValueType = Value
    
    public var value: Value {
        willSet {
            assert(!inTransaction)
        }
        didSet {
            inTransaction = true
            pushValue(value)
            inTransaction = false
        }
    }

    override public var latestValue: LatestValue<Value> {
        return .Stored(value)
    }
    
    private var inTransaction: Bool = false
    
    public init(initial: Value) {
        value = initial
    }
}

class Receiver<Source: SignalType>: ReceiverType {
    let source: Source
    private let id: Int
    
    init(_ source: Source, _ closure: Transaction<Source.ValueType> -> Void) {
        self.source = source
        self.id = source.addObserver(closure)
    }
    
    deinit {
        source.removeObserver(id)
    }
}

public class Output<Source: SignalType>: Receiver<Source> {
    public init(_ source: Source, _ closure: Source.ValueType -> Void) {
        super.init(source) { transaction in
            if case .End(let value) = transaction {
                closure(value)
            }
        }
    }
}

public class WillOutput<Source: SignalType>: Receiver<Source> {
    public init(_ source: Source, _ closure: Void -> Void) {
        super.init(source) { transaction in
            if case .Begin = transaction {
                closure()
            }
        }
    }
}
