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

public class Observable<T> : ObservableType {
    public typealias ValueType = T
    
    private var observers: [Int : Transaction<ValueType> -> Void] = [:]
    private var nextObserverId: Int = 0
    
    public init() {
    }
    
    public func addObserver(observer: Transaction<ValueType> -> Void) -> Int {
        if canPullValue, let value = pullValue {
            observer(Transaction.Begin)
            observer(Transaction.End(value))
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
        pushTransaction(Transaction.Begin)
        pushTransaction(Transaction.End(value))
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
    public var pullValue: T? {
        return nil
    }
}

public class Input<T> : Observable<T> {
    public var value: T {
        didSet {
            pushValue(value)
        }
    }
    
    public init(initial: T) {
        value = initial
    }
    
    override public var canPullValue: Bool {
        return true
    }
    
    override public var pullValue: T? {
        return value
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
            switch transaction {
            case .Begin:
                break
            case .End(let value):
                closure(value)
            }
        }
    }
}

public class WillOutput<ValueType>: Observer<ValueType> {
    public init(_ source: Observable<ValueType>, _ closure: Void -> Void) {
        super.init(source) { transaction in
            switch transaction {
            case .Begin:
                closure()
            case .End:
                break
            }
        }
    }
}

class Filter<ValueType> : Observable<ValueType> {
    private var observer: Observer<ValueType>!
    
    init(_ source: Observable<ValueType>, _ predicate: ValueType -> Bool) {
        super.init()
        observer = Observer(source) { transaction in
            switch transaction {
            case .Begin:
                break
            case .End(let value):
                if predicate(value) {
                    self.pushValue(value)
                }
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
                self.pushTransaction(Transaction.Begin)
            case .End(let sourceValue):
                self.pushTransaction(Transaction.End(transform(sourceValue)))
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
            switch transaction {
            case .Begin:
                self.pushTransaction(transaction)
            case .End(let value):
                self.value = value
                self.pushTransaction(transaction)
            }
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
            switch transaction {
            case .Begin:
                break
            case .End(let newValue):
                if newValue != self.value {
                    self.value = newValue
                    self.pushValue(newValue)
                }
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

//class Throttle<ValueType> : Observable<ValueType> {
//    let timer: dispatch_source_t
//    let minimumInterval: NSTimeInterval
//    var lastPushTimestamp: CFAbsoluteTime = 0
//    var sink: Output<ValueType>?
//    
//    init(_ source: Observable<ValueType>, minimumInterval: NSTimeInterval, queue: dispatch_queue_t) {
//        self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue)
//        self.minimumInterval = minimumInterval
//
//        super.init()
//        
//        self.sink = Output(source) { t in
//            dispatch_async(queue) {
//                dispatch_suspend(self.timer)
//                
//                let now = CFAbsoluteTimeGetCurrent()
//                if now - self.lastPushTimestamp > self.minimumInterval {
//                    self.pushValue(t)
//                    self.lastPushTimestamp = now
//                    
//                } else {
//                    self.deferPushValue(t)
//                }
//            }
//        }
//    }
//    
//    deinit {
//        dispatch_source_cancel(timer)
//    }
//    
//    private func deferPushValue(t: ValueType) {
//        dispatch_source_set_event_handler(timer) {
//            self.pushValue(t)
//            self.lastPushTimestamp = CFAbsoluteTimeGetCurrent()
//        }
//        
//        dispatch_source_set_timer(timer,
//            DISPATCH_TIME_NOW,
//            nanosecondsFromSeconds(minimumInterval),
//            nanosecondsFromSeconds(minimumInterval * 0.2))
//        
//        dispatch_resume(timer)
//    }
//}

class Combiner<T>: Observable<T> {
    private let maxTransactionCount: Int
    private var transactionCount: Int = 0

    init(maxTransactionCount: Int) {
        self.maxTransactionCount = maxTransactionCount
    }

    func update<S>(transaction: Transaction<S>) {
        switch transaction {
        case .Begin:
            transactionCount += 1
            if transactionCount > maxTransactionCount {
                print("BUG! transactionCount=\(transactionCount) too high in \(self)")
            }
            
        case .End:
            if transactionCount == 0 {
                print("BUG! transactionCount=0 too low in \(self)")
            }
            transactionCount -= 1
            if transactionCount == 0, let value = pullValue {
                pushValue(value)
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
        super.init(maxTransactionCount: 2)
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
        super.init(maxTransactionCount: 3)
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
        super.init(maxTransactionCount: 4)
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
        super.init(maxTransactionCount: 5)
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
    
//    public func throttle(minimumInterval: NSTimeInterval, queue: dispatch_queue_t) -> Observable<ValueType> {
//        return Throttle(self, minimumInterval: minimumInterval, queue: queue)
//    }
}

extension Observable where T: Equatable {
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

public func sort
    <ValueType: SequenceType where ValueType.Generator.Element: Comparable>
    (obs: Observable<ValueType>) -> Observable<[ValueType.Generator.Element]>
{
    return obs.map { $0.sort() }
}
