//
//  Either.swift
//  ScotTraffic
//
//  Created by Neil Gall on 01/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import Foundation

public enum Either<V, E: ErrorType> {
    case Value(V)
    case Error(E)

    // Simple map on V; E is passed through unchanged
    //
    func fmap<U> (transform: V->U) -> Either<U,E> {
        switch self {
            
        case .Value(let v):
            return Either<U,E>.Value(transform(v))

        case .Error(let e):
            return Either<U,E>.Error(e)

        }
    }

    // Throwable transformation on V; if the transform succeeds this is
    // like the simple map(); else the resulting Either becomes an .Error
    //
    func fmap<U> (transform: V throws -> U) -> Either<U,E> {
        switch self {
            
        case .Value(let v):
            do {
                return Either<U,E>.Value(try transform(v))
            } catch {
                return Either<U,E>.Error(error as! E)
            }
            
        case .Error(let e):
            return Either<U,E>.Error(e)

        }
    }
}