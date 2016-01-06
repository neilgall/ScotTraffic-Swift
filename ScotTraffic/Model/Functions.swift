//
//  Functions.swift
//  ScotTraffic
//
//  Created by Neil Gall on 03/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import Foundation

infix operator <== { associativity right precedence 90 }

// Function composition
//
//  g <== f  means  \x -> g(f(x))
//
public func <== <A, B, C> (g: B->C, f: A->B) -> A->C {
    return { a in g(f(a)) }
}

// Function composition for functions that throw
//
public func <== <A, B, C> (g: B throws -> C, f: A throws -> B) -> A throws -> C {
    return { a in try g(try f(a)) }
}

// Tuple selectors
//
public func first<A, B>(tuple: (A, B)) -> A {
    return tuple.0
}

public func second<A, B>(tuple: (A, B)) -> B {
    return tuple.1
}