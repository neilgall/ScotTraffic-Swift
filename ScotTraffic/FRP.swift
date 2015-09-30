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
    private let source: Observable<T>
    private var id: Int?
    
    init(source: Observable<T>) {
        self.source = source
    }
    
    func start(closure: T->Void) -> Sink<T> {
        id = source.addObserver(closure)
        return self
    }
    
    deinit {
        if let id = self.id {
            self.source.removeObserver(id)
        }
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
    let sink: Sink<T>
    
    init(source: Observable<T>, predicate: T->Bool) {
        self.sink = Sink<T>(source: source)
        super.init()
        self.sink.start() { t in
            if predicate(t) {
                self.notify(t)
            }
        }
    }
}

class Mapped<T,U> : Observable<U> {
    let sink: Sink<T>
    
    init(source: Observable<T>, function: T->U) {
        self.sink = Sink<T>(source: source)
        super.init()
        self.sink.start() { t in
            let u = function(t)
            self.notify(u)
        }
    }
}

class Union<T> : Observable<T> {
    let sinks: [Sink<T>]
    
    init(sources: [Observable<T>]) {
        self.sinks = sources.map { Sink<T>(source: $0) }
        super.init()
        for sink in self.sinks {
            sink.start() { t in
                self.notify(t)
            }
        }
    }
}

protocol Combiner {
    func update()
}

class Latest<T> {
    let sink: Sink<T>
    var value: T?
    
    init(source: Observable<T>, combiner: Combiner) {
        self.sink = Sink<T>(source: source)
        self.sink.start() {
            self.value = $0
            combiner.update()
        }
    }
}

class Combine2<T1,T2,U> : Observable<U>, Combiner {
    let combine: (T1,T2)->U
    var latest1: Latest<T1>?
    var latest2: Latest<T2>?
    
    init(s1: Observable<T1>, s2: Observable<T2>, combine: (T1,T2)->U) {
        self.combine = combine
        super.init()
        self.latest1 = Latest(source: s1, combiner: self)
        self.latest2 = Latest(source: s2, combiner: self)
    }
    
    func update() {
        guard let t1 = latest1?.value, t2 = latest2?.value else {
            return
        }
        notify(combine(t1, t2))
    }
}

class Combine3<T1,T2,T3,U> : Observable<U>, Combiner {
    let combine: (T1,T2,T3)->U
    var latest1: Latest<T1>?
    var latest2: Latest<T2>?
    var latest3: Latest<T3>?
    
    init(s1: Observable<T1>, s2: Observable<T2>, s3: Observable<T3>, combine: (T1,T2,T3)->U) {
        self.combine = combine
        super.init()
        self.latest1 = Latest(source: s1, combiner: self)
        self.latest2 = Latest(source: s2, combiner: self)
        self.latest3 = Latest(source: s3, combiner: self)
    }
    
    func update() {
        guard let t1 = latest1?.value, t2 = latest2?.value, t3 = latest3?.value else {
            return
        }
        notify(combine(t1, t2, t3))
    }
}

class Combine4<T1,T2,T3,T4,U> : Observable<U>, Combiner {
    let combine: (T1,T2,T3,T4)->U
    var latest1: Latest<T1>?
    var latest2: Latest<T2>?
    var latest3: Latest<T3>?
    var latest4: Latest<T4>?
    
    init(s1: Observable<T1>, s2: Observable<T2>, s3: Observable<T3>, s4: Observable<T4>, combine: (T1,T2,T3,T4)->U) {
        self.combine = combine
        super.init()
        self.latest1 = Latest(source: s1, combiner: self)
        self.latest2 = Latest(source: s2, combiner: self)
        self.latest3 = Latest(source: s3, combiner: self)
        self.latest4 = Latest(source: s4, combiner: self)
    }
    
    func update() {
        guard let t1 = latest1?.value, t2 = latest2?.value, t3 = latest3?.value, t4 = latest4?.value else {
            return
        }
        notify(combine(t1, t2, t3, t4))
    }
}

class Combine5<T1,T2,T3,T4,T5,U> : Observable<U>, Combiner {
    let combine: (T1,T2,T3,T4,T5)->U
    var latest1: Latest<T1>?
    var latest2: Latest<T2>?
    var latest3: Latest<T3>?
    var latest4: Latest<T4>?
    var latest5: Latest<T5>?
    
    init(s1: Observable<T1>, s2: Observable<T2>, s3: Observable<T3>, s4: Observable<T4>, s5: Observable<T5>, combine: (T1,T2,T3,T4,T5)->U) {
        self.combine = combine
        super.init()
        self.latest1 = Latest(source: s1, combiner: self)
        self.latest2 = Latest(source: s2, combiner: self)
        self.latest3 = Latest(source: s3, combiner: self)
        self.latest4 = Latest(source: s4, combiner: self)
        self.latest5 = Latest(source: s5, combiner: self)
    }
    
    func update() {
        guard let t1 = latest1?.value, t2 = latest2?.value, t3 = latest3?.value, t4 = latest4?.value, t5 = latest5?.value else {
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
    
    public mutating func sink<T>(source: Observable<T>, closure: T->Void) {
        observations.append(source.sink(closure))
    }
    
    public mutating func clear() {
        observations.removeAll()
    }
}

public extension Observable {
    public func sink(sink: T->Void) -> Sink<T> {
        return Sink(source: self).start(sink)
    }
    
    public func map<U>(function: T->U) -> Observable<U> {
        return Mapped(source: self, function: function)
    }
    
    public func filter(predicate: T->Bool) -> Observable<T> {
        return Filter(source: self, predicate: predicate)
    }
}

public func union<T>(sources: Observable<T>...) -> Observable<T> {
    return Union<T>(sources: sources)
}

public func combine<T1, T2, U>(s1: Observable<T1>, _ s2: Observable<T2>, combine: (T1,T2)->U) -> Observable<U> {
    return Combine2(s1: s1, s2: s2, combine: combine)
}

public func combine<T1, T2, T3, U>(s1: Observable<T1>, _ s2: Observable<T2>, _ s3: Observable<T3>, combine: (T1,T2,T3)->U) -> Observable<U> {
    return Combine3(s1: s1, s2: s2, s3: s3, combine: combine)
}

public func combine<T1, T2, T3, T4, U>(s1: Observable<T1>, _ s2: Observable<T2>, _ s3: Observable<T3>, _ s4: Observable<T4>, combine: (T1,T2,T3,T4)->U) -> Observable<U> {
    return Combine4(s1: s1, s2: s2, s3: s3, s4: s4, combine: combine)
}

public func combine<T1, T2, T3, T4, T5, U>(s1: Observable<T1>, _ s2: Observable<T2>, _ s3: Observable<T3>, _ s4: Observable<T4>, _ s5: Observable<T5>, combine: (T1,T2,T3,T4,T5)->U) -> Observable<U> {
    return Combine5(s1: s1, s2: s2, s3: s3, s4: s4, s5: s5, combine: combine)
}
