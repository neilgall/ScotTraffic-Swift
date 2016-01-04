//
//  Combine.swift
//  ScotTraffic
//
//  Created by Neil Gall on 04/01/2016.
//  Copyright © 2016 Neil Gall. All rights reserved.
//

import Foundation

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

class Combine2<Source1: ObservableType, Source2: ObservableType, CombinedType> : Combiner<CombinedType> {
    typealias CombineFunction = (Source1.ValueType, Source2.ValueType) -> CombinedType
    
    let combine: CombineFunction
    let latest1: Latest<Source1>
    let latest2: Latest<Source2>
    var sourceObservers: [Observation] = []
    
    init(_ s1: Source1, _ s2: Source2, combine: CombineFunction) {
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

class Combine3<Source1: ObservableType, Source2: ObservableType, Source3: ObservableType, CombinedType> : Combiner<CombinedType> {
    typealias CombineFunction = (Source1.ValueType, Source2.ValueType, Source3.ValueType) -> CombinedType

    let combine: CombineFunction
    let latest1: Latest<Source1>
    let latest2: Latest<Source2>
    let latest3: Latest<Source3>
    var sourceObservers: [Observation] = []
    
    init(_ s1: Source1, _ s2: Source2, _ s3: Source3, combine: CombineFunction) {
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

class Combine4<Source1: ObservableType, Source2: ObservableType, Source3: ObservableType, Source4: ObservableType, CombinedType> : Combiner<CombinedType> {
    typealias CombineFunction = (Source1.ValueType, Source2.ValueType, Source3.ValueType, Source4.ValueType) -> CombinedType

    let combine: CombineFunction
    let latest1: Latest<Source1>
    let latest2: Latest<Source2>
    let latest3: Latest<Source3>
    let latest4: Latest<Source4>
    var sourceObservers: [Observation] = []
    
    init(_ s1: Source1, _ s2: Source2, _ s3: Source3, _ s4: Source4, combine: CombineFunction) {
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

class Combine5<Source1: ObservableType, Source2: ObservableType, Source3: ObservableType, Source4: ObservableType, Source5: ObservableType, CombinedType> : Combiner<CombinedType> {
    typealias CombineFunction = (Source1.ValueType, Source2.ValueType, Source3.ValueType, Source4.ValueType, Source5.ValueType) -> CombinedType

    let combine: CombineFunction
    let latest1: Latest<Source1>
    let latest2: Latest<Source2>
    let latest3: Latest<Source3>
    let latest4: Latest<Source4>
    let latest5: Latest<Source5>
    var sourceObservers: [Observation] = []
    
    init(_ s1: Source1, _ s2: Source2, _ s3: Source3, _ s4: Source4, _ s5: Source5, combine: CombineFunction) {
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

class Combine6<Source1: ObservableType, Source2: ObservableType, Source3: ObservableType, Source4: ObservableType, Source5: ObservableType, Source6: ObservableType, CombinedType> : Combiner<CombinedType> {
    typealias CombineFunction = (Source1.ValueType, Source2.ValueType, Source3.ValueType, Source4.ValueType, Source5.ValueType, Source6.ValueType) -> CombinedType
    let combine: CombineFunction
    let latest1: Latest<Source1>
    let latest2: Latest<Source2>
    let latest3: Latest<Source3>
    let latest4: Latest<Source4>
    let latest5: Latest<Source5>
    let latest6: Latest<Source6>
    var sourceObservers: [Observation] = []
    
    init(_ s1: Source1, _ s2: Source2, _ s3: Source3, _ s4: Source4, _ s5: Source5, _ s6: Source6, combine: CombineFunction) {
        self.combine = combine
        latest1 = s1.latest()
        latest2 = s2.latest()
        latest3 = s3.latest()
        latest4 = s4.latest()
        latest5 = s5.latest()
        latest6 = s6.latest()
        super.init()
        sourceObservers.append(Observer(latest1) { t in self.update(t) })
        sourceObservers.append(Observer(latest2) { t in self.update(t) })
        sourceObservers.append(Observer(latest3) { t in self.update(t) })
        sourceObservers.append(Observer(latest4) { t in self.update(t) })
        sourceObservers.append(Observer(latest5) { t in self.update(t) })
        sourceObservers.append(Observer(latest6) { t in self.update(t) })
    }
    
    override var canPullValue: Bool {
        return latest1.source.canPullValue && latest2.source.canPullValue && latest3.source.canPullValue && latest4.source.canPullValue && latest5.source.canPullValue && latest6.source.canPullValue
    }
    
    override var pullValue: CombinedType? {
        guard let t1 = latest1.value, t2 = latest2.value, t3 = latest3.value, t4 = latest4.value, t5 = latest5.value, t6 = latest6.value else {
            return nil
        }
        return combine(t1, t2, t3, t4, t5, t6)
    }
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

public func combine<SourceType1, SourceType2, SourceType3, SourceType4, SourceType5, SourceType6, CombinedType>
    (s1: Observable<SourceType1>,
    _ s2: Observable<SourceType2>,
    _ s3: Observable<SourceType3>,
    _ s4: Observable<SourceType4>,
    _ s5: Observable<SourceType5>,
    _ s6: Observable<SourceType6>,
    combine: (SourceType1, SourceType2, SourceType3, SourceType4, SourceType5, SourceType6) -> CombinedType) -> Observable<CombinedType>
{
    return Combine6(s1, s2, s3, s4, s5, s6, combine: combine)
}
