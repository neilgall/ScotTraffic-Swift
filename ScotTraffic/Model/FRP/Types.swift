//
//  Types.swift
//  ScotTraffic
//
//  Created by Neil Gall on 04/01/2016.
//  Copyright © 2016 Neil Gall. All rights reserved.
//

import Foundation

public protocol Observation {}

public enum Transaction<ValueType> {
    case Begin
    case End(ValueType)
    case Cancel
}

public protocol ObservableType {
    typealias ValueType
    
    func addObserver(observer: Transaction<ValueType> -> Void) -> Int
    func removeObserver(id: Int)
    
    func pushTransaction(transaction: Transaction<ValueType>)
    func pushValue(value: ValueType)
    
    var canPullValue: Bool { get }
    var pullValue: ValueType? { get }
}

public class Observable<Value> : ObservableType {
    public typealias ValueType = Value
    
    private var observers: [Int : Transaction<ValueType> -> Void] = [:]
    private var nextObserverId: Int = 0
    
    public init() {
    }
    
    public func addObserver(observer: Transaction<ValueType> -> Void) -> Int {
        if canPullValue, let value = pullValue {
            observer(.Begin)
            observer(.End(value))
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
    
    // Pull - by default pull is not enabled
    public var canPullValue: Bool {
        return false
    }
    public var pullValue: ValueType? {
        return nil
    }
}

public class Input<Value> : Observable<Value> {
    private var inTransaction: Bool = false
    
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
    
    public init(initial: Value) {
        value = initial
    }
    
    override public var canPullValue: Bool {
        return true
    }
    
    override public var pullValue: Value? {
        return value
    }
}

class Observer<Source: ObservableType>: Observation {
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

public class Output<Source: ObservableType>: Observer<Source> {
    public init(_ source: Source, _ closure: Source.ValueType -> Void) {
        super.init(source) { transaction in
            if case .End(let value) = transaction {
                closure(value)
            }
        }
    }
}

public class WillOutput<Source: ObservableType>: Observer<Source> {
    public init(_ source: Source, _ closure: Void -> Void) {
        super.init(source) { transaction in
            if case .Begin = transaction {
                closure()
            }
        }
    }
}
