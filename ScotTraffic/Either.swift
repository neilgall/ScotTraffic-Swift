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

    // If .Value, transform to a new value.
    // If .Error, ignore the transform and lift the error to AppError if necessary
    //
    func map<U> (transform: V->U) -> Either<U,AppError> {
        switch self {
            
        case .Value(let v):
            return .Value(transform(v))

        case .Error(let e):
            return .Error(AppError.wrap(e))

        }
    }
    
    // Throwable transformation on V; if the transform succeeds this is
    // like the simple map(); else the resulting Either becomes an .Error
    // lifted to AppError
    //
    func map<U> (transform: V throws -> U) -> Either<U,AppError> {
        switch self {
            
        case .Value(let v):
            do {
                return .Value(try transform(v))
            } catch {
                return .Error(AppError.wrap(error))
            }
            
        case .Error(let e):
            return .Error(AppError.wrap(e))

        }
    }
}

// FRP operations on Either

class SplitEitherValue<V, E:ErrorType> : Observable<V> {
    var output: Output<Either<V,E>>?
    
    init(_ source: Observable<Either<V,E>>) {
        super.init()
        self.output = Output<Either<V,E>>(source) {
            switch $0 {
            case .Value(let v): self.pushValue(v)
            case .Error: break
            }
        }
    }
}

class SplitEitherError<V, E:ErrorType> : Observable<E> {
    var output: Output<Either<V,E>>?
    
    init(_ source: Observable<Either<V,E>>) {
        super.init()
        self.output = Output<Either<V,E>>(source) {
            switch $0 {
            case .Value: break
            case .Error(let e): self.pushValue(e)
            }
        }
    }
}

public func valueFromEither<V, E:ErrorType>(either: Observable<Either<V,E>>) -> Observable<V> {
    return SplitEitherValue(either)
}

public func errorFromEither<V, E:ErrorType>(either: Observable<Either<V,E>>) -> Observable<E> {
    return SplitEitherError(either)
}
