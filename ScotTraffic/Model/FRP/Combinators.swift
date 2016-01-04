//
//  Combinators.swift
//  ScotTraffic
//
//  Created by Neil Gall on 30/09/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import Foundation

public class Never<ValueType> : Observable<ValueType> {
}

public class Const<ValueType> : Observable<ValueType> {
    let value: ValueType

    public init(_ value: ValueType) {
        self.value = value
    }
    
    override public var canPullValue: Bool {
        return true
    }
    
    override public var pullValue: ValueType? {
        return value
    }
}

class Filter<Source: ObservableType> : Observable<Source.ValueType> {
    private var observer: Observation!
    
    init(_ source: Source, _ predicate: Source.ValueType -> Bool) {
        super.init()
        observer = Observer(source) { transaction in
            if case .End(let value) = transaction where !predicate(value) {
                self.pushTransaction(.Cancel)
            } else {
                self.pushTransaction(transaction)
            }
        }
    }
}

class Mapped<Source: ObservableType, MappedType> : Observable<MappedType> {
    private let source: Source
    private let transform: Source.ValueType -> MappedType
    private var observer: Observation!
    
    init(_ source: Source, _ transform: Source.ValueType -> MappedType) {
        self.source = source
        self.transform = transform
        super.init()
        self.observer = Observer(source) { transaction in
            switch transaction {
            case .Begin:
                self.pushTransaction(.Begin)
            case .End(let sourceValue):
                self.pushTransaction(.End(transform(sourceValue)))
            case .Cancel:
                self.pushTransaction(.Cancel)
            }
        }
    }
    
    override var canPullValue: Bool {
        return source.canPullValue
    }
    
    override var pullValue: MappedType? {
        if canPullValue, let sourceValue = source.pullValue {
            return transform(sourceValue)
        } else {
            return nil
        }
    }
}

class Union<Source: ObservableType> : Observable<Source.ValueType> {
    private var sourceObservers: [Observation]!
    
    init(_ sources: [Source]) {
        super.init()
        self.sourceObservers = sources.map {
            Observer($0) {
                self.pushTransaction($0)
            }
        }
    }
}

public class Latest<Source: ObservableType> : Observable<Source.ValueType> {
    let source: Source
    var value: Source.ValueType?
    private var observer: Observation!
    
    init(_ source: Source) {
        self.source = source
        self.value = source.pullValue
        
        super.init()

        self.observer = Observer(source) { transaction in
            if case .End(let value) = transaction {
                self.value = value
            }
            self.pushTransaction(transaction)
        }
    }
    
    override public var canPullValue: Bool {
        return value != nil
    }
    
    override public var pullValue: ValueType? {
        return value
    }
}

class OnChange<Source: ObservableType where Source.ValueType: Equatable> : Observable<Source.ValueType> {
    private var observer: Observation!
    private var value: Source.ValueType?
    
    init(_ source: Source) {
        super.init()
        self.value = source.pullValue
        self.observer = Observer(source) { transaction in
            if case .End(let newValue) = transaction {
                if newValue == self.value {
                    self.pushTransaction(.Cancel)
                } else {
                    self.value = newValue
                    self.pushTransaction(transaction)
                }
            } else {
                self.pushTransaction(transaction)
            }
        }
    }
    
    override var canPullValue: Bool {
        return value != nil
    }
    
    override var pullValue: ValueType? {
        return value
    }
}

infix operator => { associativity right precedence 100 }

public func => <Source: ObservableType> (source: Source, closure: Source.ValueType -> Void) -> Observation {
    return Output(source, closure)
}

extension ObservableType {
    public func output(closure: ValueType -> Void) -> Output<Self> {
        return Output(self, closure)
    }
    
    public func willOutput(closure: Void -> Void) -> WillOutput<Self> {
        return WillOutput(self, closure)
    }
    
    public func latest() -> Latest<Self> {
        if let latest = self as? Latest<Self> {
            // no point re-wrapping what is already a Latest
            return latest
        } else {
            return Latest(self)
        }
    }
    
    public func map<TargetType>(transform: ValueType -> TargetType) -> Observable<TargetType> {
        return Mapped(self, transform)
    }
    
    public func filter(predicate: ValueType -> Bool) -> Observable<ValueType> {
        return Filter(self, predicate)
    }
}

extension ObservableType where ValueType: Equatable {
    public func onChange() -> Observable<ValueType> {
        return OnChange(self)
    }
}

public func union<Source: ObservableType>(sources: Source...) -> Observable<Source.ValueType> {
    return Union(sources)
}

