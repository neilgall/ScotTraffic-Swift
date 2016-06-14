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
func <== <A, B, C> (g: B -> C, f: A -> B) -> A -> C {
    return { a in g(f(a)) }
}

// Function composition for functions that throw
//
func <== <A, B, C> (g: B throws -> C, f: A throws -> B) -> A throws -> C {
    return { a in try g(try f(a)) }
}

// Monadic bind for optionals. Synonym for flatMap()
//
infix operator |> { associativity left precedence 40 }
func |> <A, B> (lhs: A?, rhs: A -> B?) ->

// Tuple selectors
//
func first<A, B>(tuple: (A, B)) -> A {
    return tuple.0
}

func second<A, B>(tuple: (A, B)) -> B {
    return tuple.1
}

// Boolean transforms
//
func not<A>(f: A -> Bool) -> A -> Bool {
    return { a in !f(a) }
}

// GCD
//
func onMainQueue(block: () -> ()) {
    dispatch_async(dispatch_get_main_queue(), block)
}