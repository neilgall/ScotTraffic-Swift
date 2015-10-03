//
//  FRP.swift
//  ScotTraffic
//
//  Created by Neil Gall on 30/09/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import Foundation

public class Observable<T> {
    private var observers: [Int:T->Void] = [:]
    private var nextObserverId: Int = 0
    
    func addObserver(observer: T->Void) -> Int {
        let id = nextObserverId++
        observers[id] = observer
        return id
    }
    
    func removeObserver(id: Int) {
        observers.removeValueForKey(id)
    }
    
    func notify(value: T) {
        for observer in observers.values {
            observer(value)
        }
    }
}

public protocol Observation {}

public class Sink<T>: Observation {
    private var source: Observable<T>
    private var id: Int
    
    init(_ source: Observable<T>, _ closure: T->Void) {
        self.source = source
        self.id = source.addObserver(closure)
    }
    
    deinit {
        source.removeObserver(id)
    }
}

public class Source<T> : Observable<T> {
    public var value: T {
        didSet {
            notify(value)
        }
    }
    
    public init(initial: T) {
        value = initial
    }
}

class Filter<T> : Observable<T> {
    var sink: Sink<T>?
    
    init(_ source: Observable<T>, _ predicate: T->Bool) {
        super.init()
        self.sink = Sink<T>(source) { t in
            if predicate(t) {
                self.notify(t)
            }
        }
    }
}

class Mapped<T,U> : Observable<U> {
    var sink: Sink<T>?
    
    init(_ source: Observable<T>, _ transform: T->U) {
        super.init()
        self.sink = Sink<T>(source) { t in
            let u = transform(t)
            self.notify(u)
        }
    }
}

class Union<T> : Observable<T> {
    var sinks: [Sink<T>]?
    
    init(_ sources: [Observable<T>]) {
        super.init()
        self.sinks = sources.map {
            Sink<T>($0) { t in
                self.notify(t)
            }
        }
    }
}

class Latest<T> : Observable<T> {
    var sink: Sink<T>?
    var value: T?
    
    init(_ source: Observable<T>) {
        super.init()
        self.sink = Sink<T>(source) { value in
            self.value = value
            self.notify(value)
        }
    }
}

class Combine2<T1,T2,U> : Observable<U> {
    let combine: (T1,T2)->U
    let latest1: Latest<T1>
    let latest2: Latest<T2>
    var sinks: [Observation] = []
    
    init(_ s1: Observable<T1>, _ s2: Observable<T2>, combine: (T1,T2)->U) {
        self.combine = combine
        latest1 = Latest(s1)
        latest2 = Latest(s2)
        super.init()
        sinks.append(latest1.sink { _ in self.update() })
        sinks.append(latest2.sink { _ in self.update() })
    }
    
    func update() {
        guard let t1 = latest1.value, t2 = latest2.value else {
            return
        }
        notify(combine(t1, t2))
    }
}

class Combine3<T1,T2,T3,U> : Observable<U> {
    let combine: (T1,T2,T3)->U
    let latest1: Latest<T1>
    let latest2: Latest<T2>
    let latest3: Latest<T3>
    var sinks: [Observation] = []
    
    init(_ s1: Observable<T1>, _ s2: Observable<T2>, _ s3: Observable<T3>, combine: (T1,T2,T3)->U) {
        self.combine = combine
        latest1 = Latest(s1)
        latest2 = Latest(s2)
        latest3 = Latest(s3)
        super.init()
        sinks.append(latest1.sink { _ in self.update() })
        sinks.append(latest2.sink { _ in self.update() })
        sinks.append(latest3.sink { _ in self.update() })
    }
    
    func update() {
        guard let t1 = latest1.value, t2 = latest2.value, t3 = latest3.value else {
            return
        }
        notify(combine(t1, t2, t3))
    }
}

class Combine4<T1,T2,T3,T4,U> : Observable<U> {
    let combine: (T1,T2,T3,T4)->U
    let latest1: Latest<T1>
    let latest2: Latest<T2>
    let latest3: Latest<T3>
    let latest4: Latest<T4>
    var sinks: [Observation] = []
    
    init(_ s1: Observable<T1>, _ s2: Observable<T2>, _ s3: Observable<T3>, _ s4: Observable<T4>, combine: (T1,T2,T3,T4)->U) {
        self.combine = combine
        latest1 = Latest(s1)
        latest2 = Latest(s2)
        latest3 = Latest(s3)
        latest4 = Latest(s4)
        super.init()
        sinks.append(latest1.sink { _ in self.update() })
        sinks.append(latest2.sink { _ in self.update() })
        sinks.append(latest3.sink { _ in self.update() })
        sinks.append(latest4.sink { _ in self.update() })
    }
    
    func update() {
        guard let t1 = latest1.value, t2 = latest2.value, t3 = latest3.value, t4 = latest4.value else {
            return
        }
        notify(combine(t1, t2, t3, t4))
    }
}

class Combine5<T1,T2,T3,T4,T5,U> : Observable<U> {
    let combine: (T1,T2,T3,T4,T5)->U
    let latest1: Latest<T1>
    let latest2: Latest<T2>
    let latest3: Latest<T3>
    let latest4: Latest<T4>
    let latest5: Latest<T5>
    var sinks: [Observation] = []
    
    init(_ s1: Observable<T1>, _ s2: Observable<T2>, _ s3: Observable<T3>, _ s4: Observable<T4>, _ s5: Observable<T5>, combine: (T1,T2,T3,T4,T5)->U) {
        self.combine = combine
        latest1 = Latest(s1)
        latest2 = Latest(s2)
        latest3 = Latest(s3)
        latest4 = Latest(s4)
        latest5 = Latest(s5)
        super.init()
        sinks.append(latest1.sink { _ in self.update() })
        sinks.append(latest2.sink { _ in self.update() })
        sinks.append(latest3.sink { _ in self.update() })
        sinks.append(latest4.sink { _ in self.update() })
        sinks.append(latest5.sink { _ in self.update() })
    }
    
    func update() {
        guard let t1 = latest1.value, t2 = latest2.value, t3 = latest3.value, t4 = latest4.value, t5 = latest5.value else {
            return
        }
        notify(combine(t1, t2, t3, t4, t5))
    }
}

// Convenience wrapper for an array of Observation
public struct Observations {
    private var observations: [Observation]
    
    public init() {
        self.observations = []
    }
    
    public mutating func add<T>(source: Observable<T>, closure: T->Void) {
        observations.append(source.sink(closure))
    }
    
    public mutating func clear() {
        observations.removeAll()
    }
}

public extension Observable {
    public func sink(sink: T->Void) -> Sink<T> {
        return Sink(self, sink)
    }
    
    public func latest() -> Observable<T> {
        return Latest(self)
    }
    
    public func map<U>(transform: T->U) -> Observable<U> {
        return Mapped(self, transform)
    }
    
    public func filter(predicate: T->Bool) -> Observable<T> {
        return Filter(self, predicate)
    }
}

public func union<T>(sources: Observable<T>...) -> Observable<T> {
    return Union<T>(sources)
}

public func combine<T1, T2, U>(s1: Observable<T1>, _ s2: Observable<T2>, combine: (T1,T2)->U) -> Observable<U> {
    return Combine2(s1, s2, combine: combine)
}

public func combine<T1, T2, T3, U>(s1: Observable<T1>, _ s2: Observable<T2>, _ s3: Observable<T3>, combine: (T1,T2,T3)->U) -> Observable<U> {
    return Combine3(s1, s2, s3, combine: combine)
}

public func combine<T1, T2, T3, T4, U>(s1: Observable<T1>, _ s2: Observable<T2>, _ s3: Observable<T3>, _ s4: Observable<T4>, combine: (T1,T2,T3,T4)->U) -> Observable<U> {
    return Combine4(s1, s2, s3, s4, combine: combine)
}

public func combine<T1, T2, T3, T4, T5, U>(s1: Observable<T1>, _ s2: Observable<T2>, _ s3: Observable<T3>, _ s4: Observable<T4>, _ s5: Observable<T5>, combine: (T1,T2,T3,T4,T5)->U) -> Observable<U> {
    return Combine5(s1, s2, s3, s4, s5, combine: combine)
}
