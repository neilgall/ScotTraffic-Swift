//
//  Sequences.swift
//  ScotTraffic
//
//  Created by Neil Gall on 04/01/2016.
//  Copyright © 2016 Neil Gall. All rights reserved.
//

import Foundation

public extension Observable where Value: SequenceType {

    public func mapSeq<TargetType>(transform: Value.Generator.Element -> TargetType) -> Observable<[TargetType]> {
        return map({ $0.map(transform) })
    }
}