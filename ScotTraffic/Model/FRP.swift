//
//  FRP.swift
//  ScotTraffic
//
//  Created by Neil Gall on 30/09/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
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
    public var value: Value {
        didSet {
            pushValue(value)
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

public class Event : Input<Void> {
    public init() {
        super.init(initial: ())
    }
    
    public func send() {
        pushValue( () )
    }
}

class Observer<ValueType>: Observation {
    private let source: Observable<ValueType>
    private let id: Int
    
    init(_ source: Observable<ValueType>, _ closure: Transaction<ValueType> -> Void) {
        self.source = source
        self.id = source.addObserver(closure)
    }

    deinit {
        source.removeObserver(id)
    }
}

public class Output<ValueType>: Observer<ValueType> {
    public init(_ source: Observable<ValueType>, _ closure: ValueType -> Void) {
        super.init(source) { transaction in
            if case .End(let value) = transaction {
                closure(value)
            }
        }
    }
}

public class WillOutput<ValueType>: Observer<ValueType> {
    public init(_ source: Observable<ValueType>, _ closure: Void -> Void) {
        super.init(source) { transaction in
            if case .Begin = transaction {
                closure()
            }
        }
    }
}

public class Never<ValueType> : Observable<ValueType> {
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

class Throttle<ValueType> : Observable<ValueType> {
    private let timer: dispatch_source_t
    private let minimumInterval: NSTimeInterval
    private var lastPushTimestamp: CFAbsoluteTime = 0
    private var observer: Observer<ValueType>?
    private var transactionCount: Int = 0
    private var timerActive: Bool = false
    
    init(_ source: Observable<ValueType>, minimumInterval: NSTimeInterval, queue: dispatch_queue_t) {
        self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue)
        self.minimumInterval = minimumInterval

        super.init()
        
        self.observer = Observer(source) { transaction in
            switch transaction {
            case .Begin:
                if self.transactionCount == 0 {
                    self.pushTransaction(transaction)
                }
                self.transactionCount += 1

            case .End:
                dispatch_suspend(self.timer)
                if self.timerActive {
                    self.endTransaction(.Cancel)
                    self.timerActive = false
                }
                
                let now = CFAbsoluteTimeGetCurrent()
                if now - self.lastPushTimestamp > self.minimumInterval {
                    self.endTransaction(transaction)
                    self.lastPushTimestamp = now
                    
                } else {
                    self.deferEndTransaction(transaction)
                }
                
            case .Cancel:
                self.endTransaction(transaction)
            }
        }
    }
    
    deinit {
        dispatch_source_cancel(timer)
    }
    
    private func endTransaction(transaction: Transaction<ValueType>) {
        self.transactionCount -= 1
        if self.transactionCount == 0 {
            self.pushTransaction(transaction)
        }
    }
    
    private func deferEndTransaction(transaction: Transaction<ValueType>) {
        dispatch_source_set_event_handler(timer) {
            self.endTransaction(transaction)
            self.lastPushTimestamp = CFAbsoluteTimeGetCurrent()
            self.timerActive = false
        }
        
        dispatch_source_set_timer(timer,
            DISPATCH_TIME_NOW,
            nanosecondsFromSeconds(minimumInterval),
            nanosecondsFromSeconds(minimumInterval * 0.2))
        
        self.timerActive = true
        dispatch_resume(timer)
    }
}

class Combiner<Value>: Observable<Value> {
    private var transactionCount: Int = 0
    private var needsUpdate: Bool = false

    func update<S>(transaction: Transaction<S>) {
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
                if needsUpdate, let value = pullValue {
                    pushTransaction(.End(value))
                    needsUpdate = false
                } else {
                    pushTransaction(.Cancel)
                }
            }
        }
    }
}

class Combine2<SourceType1, SourceType2, CombinedType> : Combiner<CombinedType> {
    let combine: (SourceType1, SourceType2) -> CombinedType
    let latest1: Latest<SourceType1>
    let latest2: Latest<SourceType2>
    var sourceObservers: [Observation] = []
    
    init(_ s1: Observable<SourceType1>, _ s2: Observable<SourceType2>, combine: (SourceType1, SourceType2) -> CombinedType) {
        self.combine = combine
        latest1 = s1.latest()
        latest2 = s2.latest()
        super.init()
        sourceObservers.append(Observer(latest1) { t in self.update(t) })
        sourceObservers.append(Observer(latest2) { t in self.update(t) })
    }
    
    override var canPullValue: Bool {
        return latest1.canPullValue && latest2.canPullValue
    }
    
    override var pullValue: CombinedType? {
        guard let t1 = latest1.value, t2 = latest2.value else {
            return nil
        }
        return combine(t1, t2)
    }
}

class Combine3<SourceType1, SourceType2, SourceType3, CombinedType> : Combiner<CombinedType> {
    let combine: (SourceType1, SourceType2, SourceType3) -> CombinedType
    let latest1: Latest<SourceType1>
    let latest2: Latest<SourceType2>
    let latest3: Latest<SourceType3>
    var sourceObservers: [Observation] = []
    
    init(_ s1: Observable<SourceType1>, _ s2: Observable<SourceType2>, _ s3: Observable<SourceType3>,
        combine: (SourceType1, SourceType2, SourceType3) -> CombinedType)
    {
        self.combine = combine
        latest1 = s1.latest()
        latest2 = s2.latest()
        latest3 = s3.latest()
        super.init()
        sourceObservers.append(Observer(latest1) { t in self.update(t) })
        sourceObservers.append(Observer(latest2) { t in self.update(t) })
        sourceObservers.append(Observer(latest3) { t in self.update(t) })
    }
    
    override var canPullValue: Bool {
        return latest1.source.canPullValue && latest2.source.canPullValue && latest3.source.canPullValue
    }
    
    override var pullValue: CombinedType? {
        guard let t1 = latest1.value, t2 = latest2.value, t3 = latest3.value else {
            return nil
        }
        return combine(t1, t2, t3)
    }
}

class Combine4<SourceType1, SourceType2, SourceType3, SourceType4, CombinedType> : Combiner<CombinedType> {
    let combine: (SourceType1, SourceType2, SourceType3, SourceType4) -> CombinedType
    let latest1: Latest<SourceType1>
    let latest2: Latest<SourceType2>
    let latest3: Latest<SourceType3>
    let latest4: Latest<SourceType4>
    var sourceObservers: [Observation] = []
    
    init(_ s1: Observable<SourceType1>, _ s2: Observable<SourceType2>, _ s3: Observable<SourceType3>, _ s4: Observable<SourceType4>,
        combine: (SourceType1, SourceType2, SourceType3, SourceType4) -> CombinedType)
    {
        self.combine = combine
        latest1 = s1.latest()
        latest2 = s2.latest()
        latest3 = s3.latest()
        latest4 = s4.latest()
        super.init()
        sourceObservers.append(Observer(latest1) { t in self.update(t) })
        sourceObservers.append(Observer(latest2) { t in self.update(t) })
        sourceObservers.append(Observer(latest3) { t in self.update(t) })
        sourceObservers.append(Observer(latest4) { t in self.update(t) })
    }
    
    override var canPullValue: Bool {
        return latest1.source.canPullValue && latest2.source.canPullValue && latest3.source.canPullValue && latest4.source.canPullValue
    }
    
    override var pullValue: CombinedType? {
        guard let t1 = latest1.value, t2 = latest2.value, t3 = latest3.value, t4 = latest4.value else {
            return nil
        }
        return combine(t1, t2, t3, t4)
    }
}

class Combine5<SourceType1, SourceType2, SourceType3, SourceType4, SourceType5, CombinedType> : Combiner<CombinedType> {
    let combine: (SourceType1, SourceType2, SourceType3, SourceType4, SourceType5) -> CombinedType
    let latest1: Latest<SourceType1>
    let latest2: Latest<SourceType2>
    let latest3: Latest<SourceType3>
    let latest4: Latest<SourceType4>
    let latest5: Latest<SourceType5>
    var sourceObservers: [Observation] = []
    
    init(_ s1: Observable<SourceType1>, _ s2: Observable<SourceType2>, _ s3: Observable<SourceType3>,
        _ s4: Observable<SourceType4>, _ s5: Observable<SourceType5>,
        combine: (SourceType1, SourceType2, SourceType3, SourceType4, SourceType5) -> CombinedType)
    {
        self.combine = combine
        latest1 = s1.latest()
        latest2 = s2.latest()
        latest3 = s3.latest()
        latest4 = s4.latest()
        latest5 = s5.latest()
        super.init()
        sourceObservers.append(Observer(latest1) { t in self.update(t) })
        sourceObservers.append(Observer(latest2) { t in self.update(t) })
        sourceObservers.append(Observer(latest3) { t in self.update(t) })
        sourceObservers.append(Observer(latest4) { t in self.update(t) })
        sourceObservers.append(Observer(latest5) { t in self.update(t) })
    }
    
    override var canPullValue: Bool {
        return latest1.source.canPullValue && latest2.source.canPullValue && latest3.source.canPullValue && latest4.source.canPullValue && latest5.source.canPullValue
    }
    
    override var pullValue: CombinedType? {
        guard let t1 = latest1.value, t2 = latest2.value, t3 = latest3.value, t4 = latest4.value, t5 = latest5.value else {
            return nil
        }
        return combine(t1, t2, t3, t4, t5)
    }
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
    
    public func throttle(minimumInterval: NSTimeInterval, queue: dispatch_queue_t) -> Observable<ValueType> {
        return Throttle(self, minimumInterval: minimumInterval, queue: queue)
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

public func combine<SourceType1, SourceType2, CombinedType>
    (s1: Observable<SourceType1>,
    _ s2: Observable<SourceType2>,
    combine: (SourceType1, SourceType2) -> CombinedType) -> Observable<CombinedType>
{
    return Combine2(s1, s2, combine: combine)
}

public func combine<SourceType1, SourceType2, SourceType3, CombinedType>
    (s1: Observable<SourceType1>,
    _ s2: Observable<SourceType2>,
    _ s3: Observable<SourceType3>,
    combine: (SourceType1, SourceType2, SourceType3) -> CombinedType) -> Observable<CombinedType>
{
    return Combine3(s1, s2, s3, combine: combine)
}

public func combine<SourceType1, SourceType2, SourceType3, SourceType4, CombinedType>
    (s1: Observable<SourceType1>,
    _ s2: Observable<SourceType2>,
    _ s3: Observable<SourceType3>,
    _ s4: Observable<SourceType4>,
    combine: (SourceType1, SourceType2, SourceType3,SourceType4) -> CombinedType) -> Observable<CombinedType>
{
    return Combine4(s1, s2, s3, s4, combine: combine)
}

public func combine<SourceType1, SourceType2, SourceType3, SourceType4, SourceType5, CombinedType>
    (s1: Observable<SourceType1>,
    _ s2: Observable<SourceType2>,
    _ s3: Observable<SourceType3>,
    _ s4: Observable<SourceType4>,
    _ s5: Observable<SourceType5>,
    combine: (SourceType1, SourceType2, SourceType3, SourceType4, SourceType5) -> CombinedType) -> Observable<CombinedType>
{
    return Combine5(s1, s2, s3, s4, s5, combine: combine)
}
