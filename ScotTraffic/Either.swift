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
    func map<U> (transform: V->U) -> Either<U,E> {
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
    func map<U> (transform: V throws -> U) -> Either<U,E> {
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

// FRP operations on Either

class SplitEitherValue<V,E: ErrorType> : Observable<V> {
    var sink: Sink<Either<V,E>>?
    
    init(_ source: Observable<Either<V,E>>) {
        super.init()
        self.sink = Sink<Either<V,E>>(source) {
            switch $0 {
            case .Value(let v): self.notify(v)
            case .Error: break
            }
        }
    }
}

class SplitEitherError<V,E: ErrorType> : Observable<E> {
    var sink: Sink<Either<V,E>>?
    
    init(_ source: Observable<Either<V,E>>) {
        super.init()
        self.sink = Sink<Either<V,E>>(source) {
            switch $0 {
            case .Value: break
            case .Error(let e): self.notify(e)
            }
        }
    }
}

public func valueFromEither<V,E>(either: Observable<Either<V,E>>) -> Observable<V> {
    return SplitEitherValue(either)
}

public func errorFromEither<V,E>(either: Observable<Either<V,E>>) -> Observable<E> {
    return SplitEitherError(either)
}
