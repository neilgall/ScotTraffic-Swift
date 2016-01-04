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

class Filter<ValueType> : Observable<ValueType> {
    private var observer: Observer<ValueType>!
    
    init(_ source: Observable<ValueType>, _ predicate: ValueType -> Bool) {
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

class Mapped<SourceType, MappedType> : Observable<MappedType> {
    private let transform: SourceType -> MappedType
    private var observer: Observer<SourceType>!
    
    init(_ source: Observable<SourceType>, _ transform: SourceType -> MappedType) {
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
        return observer.source.canPullValue
    }
    
    override var pullValue: MappedType? {
        if canPullValue, let sourceValue = observer.source.pullValue {
            return transform(sourceValue)
        } else {
            return nil
        }
    }
}

class Union<ValueType> : Observable<ValueType> {
    private var sourceObservers: [Observer<ValueType>]!
    
    init(_ sources: [Observable<ValueType>]) {
        super.init()
        self.sourceObservers = sources.map {
            Observer($0) {
                self.pushTransaction($0)
            }
        }
    }
}

public class Latest<ValueType> : Observable<ValueType> {
    private var observer: Observer<ValueType>!
    var value: ValueType?
    
    init(_ source: Observable<ValueType>) {
        super.init()
        self.value = source.pullValue
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
    
    var source: Observable<ValueType> {
        return observer.source
    }
}

class OnChange<ValueType: Equatable> : Observable<ValueType> {
    private var observer: Observer<ValueType>?
    private var value: ValueType?
    
    init(_ source: Observable<ValueType>) {
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

public func => <ValueType> (observable: Observable<ValueType>, closure: ValueType -> Void) -> Observation {
    return Output(observable, closure)
}

extension Observable {
    public func output(closure: ValueType -> Void) -> Output<ValueType> {
        return Output(self, closure)
    }
    
    public func willOutput(closure: Void -> Void) -> WillOutput<ValueType> {
        return WillOutput(self, closure)
    }
    
    public func latest() -> Latest<ValueType> {
        if let latest = self as? Latest<ValueType> {
            // no point re-wrapping what is already a Latest
            return latest
        } else {
            return Latest(self)
        }
    }
    
    public func map<U>(transform: ValueType -> U) -> Observable<U> {
        return Mapped(self, transform)
    }
    
    public func filter(predicate: ValueType -> Bool) -> Observable<ValueType> {
        return Filter(self, predicate)
    }
}

extension Observable where Value: Equatable {
    public func onChange() -> Observable<ValueType> {
        return OnChange(self)
    }
}

public func union<ValueType>(sources: Observable<ValueType>...) -> Observable<ValueType> {
    return Union(sources)
}

