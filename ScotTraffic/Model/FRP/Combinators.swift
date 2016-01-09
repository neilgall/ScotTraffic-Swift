//
//  Combinators.swift
//  ScotTraffic
//
//  Created by Neil Gall on 30/09/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import Foundation

public class Never<Value> : Signal<Value> {
}

public class Const<Value> : Signal<Value> {
    public let value: Value

    public init(_ value: Value) {
        self.value = value
    }
    
    override public var latestValue: LatestValue<Value> {
        return .Stored(value)
    }
}

class Filter<Source: SignalType> : Signal<Source.ValueType> {
    private var receiver: ReceiverType!
    
    init(_ source: Source, _ predicate: Source.ValueType -> Bool) {
        super.init()
        receiver = Receiver(source) { [weak self] transaction in
            if case .End(let value) = transaction where !predicate(value) {
                self?.pushTransaction(.Cancel)
            } else {
                self?.pushTransaction(transaction)
            }
        }
    }
}

class Mapped<Source: SignalType, MappedType> : Signal<MappedType> {
    private let source: Source
    private let transform: Source.ValueType -> MappedType
    private var receiver: ReceiverType!
    
    init(_ source: Source, _ transform: Source.ValueType -> MappedType) {
        self.source = source
        self.transform = transform
        
        super.init()
        
        self.receiver = Receiver(source) { [weak self] transaction in
            switch transaction {
            case .Begin:
                self?.pushTransaction(.Begin)
            case .End(let sourceValue):
                self?.pushTransaction(.End(transform(sourceValue)))
            case .Cancel:
                self?.pushTransaction(.Cancel)
            }
        }
    }
    
    override var latestValue: LatestValue<MappedType> {
        switch source.latestValue {
        case .None:
            return .None
        case .Stored(let sourceValue):
            return .Computed({ self.transform(sourceValue) })
        case .Computed(let getSourceValue):
            return .Computed({ self.transform(getSourceValue()) })
        }
    }
}

class Union<Source: SignalType> : Signal<Source.ValueType> {
    private var receivers: [ReceiverType]!
    
    init(_ sources: [Source]) {
        super.init()
        self.receivers = sources.map { [weak self] in
            Receiver($0) {
                self?.pushTransaction($0)
            }
        }
    }
}

// Basic signal wrapper for when we only have a SignalType
//
class WrappedSignal<Source: SignalType>: Signal<Source.ValueType> {
    private let source: Source
    private var receiver: ReceiverType!
    
    init(_ source: Source) {
        self.source = source
        
        super.init()
        
        self.receiver = Receiver(source) { [weak self] in
            self?.pushTransaction($0)
        }
    }
    
    override var latestValue: LatestValue<Source.ValueType> {
        return source.latestValue
    }
}

public class Latest<Source: SignalType>: Signal<Source.ValueType> {
    let source: Source
    var value: Source.ValueType?
    private var receiver: ReceiverType!
    
    init(_ source: Source) {
        self.source = source
        self.value = source.latestValue.get
        
        super.init()

        self.receiver = Receiver(source) { [weak self] transaction in
            if case .End(let value) = transaction {
                self?.value = value
            }
            self?.pushTransaction(transaction)
        }
    }
    
    override public var latestValue: LatestValue<Source.ValueType> {
        if let value = value {
            return .Stored(value)
        } else {
            return .None
        }
    }
}

class OnChange<Source: SignalType where Source.ValueType: Equatable> : Signal<Source.ValueType> {
    private var receiver: ReceiverType!
    private var value: Source.ValueType?
    
    init(_ source: Source) {
        super.init()
        value = source.latestValue.get
        receiver = Receiver(source) { [weak self] transaction in
            if case .End(let newValue) = transaction {
                if newValue == self?.value {
                    self?.pushTransaction(.Cancel)
                } else {
                    self?.value = newValue
                    self?.pushTransaction(transaction)
                }
            } else {
                self?.pushTransaction(transaction)
            }
        }
    }
    
    override var latestValue: LatestValue<Source.ValueType> {
        guard let value = value else {
            return .None
        }
        return .Stored(value)
    }
}

infix operator --> { associativity right precedence 100 }

public func --> <Source: SignalType> (source: Source, closure: Source.ValueType -> Void) -> ReceiverType {
    return Output(source, closure)
}

infix operator <-- { associativity left precedence 100 }

public func <-- <Input: InputType, ValueType where Input.ValueType == ValueType> (var input: Input, value: ValueType) {
    input.value = value
}

extension SignalType {
    public func willOutput(closure: Void -> Void) -> WillOutput<Self> {
        return WillOutput(self, closure)
    }
    
    public func signal() -> Signal<ValueType> {
        return WrappedSignal(self)
    }
    
    public func latest() -> Signal<ValueType> {
        if let signal = self as? Signal<ValueType>, case .Stored = signal.latestValue {
            return signal
        }
        
        return Latest(self)
    }
    
    public func map<TargetType>(transform: ValueType -> TargetType) -> Signal<TargetType> {
        return Mapped(self, transform)
    }
    
    public func filter(predicate: ValueType -> Bool) -> Signal<ValueType> {
        return Filter(self, predicate)
    }
}

extension SignalType where ValueType: Equatable {
    public func onChange() -> Signal<ValueType> {
        return OnChange(self)
    }
}

public func union<Source: SignalType>(sources: Source...) -> Signal<Source.ValueType> {
    return Union(sources)
}

