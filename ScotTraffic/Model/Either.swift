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
    public func map<U> (transform: V -> U) -> Either<U,AppError> {
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
    public func map<U> (transform: V throws -> U) -> Either<U,AppError> {
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

public class SplitEitherValue<V, E:ErrorType> : Observable<V> {
    private let source: Observable<Either<V,E>>
    private var observer: Observer<Either<V,E>>?
    
    init(_ source: Observable<Either<V,E>>) {
        self.source = source
        super.init()
        self.observer = Observer(source) { transaction in
            switch transaction {
            case .Begin:
                break
            case .End(let value):
                switch value {
                case .Value(let v):
                    self.pushValue(v)
                case .Error:
                    break
                }
            }
        }
    }
    
    override public var canPullValue: Bool {
        return pullValue != nil
    }
    
    override public var pullValue: V? {
        guard let either = source.pullValue else {
            return nil
        }
        switch either {
        case .Value(let v):
            return v
            case .Error:
                return nil
        }
    }
}

public class SplitEitherError<V, E:ErrorType> : Observable<E> {
    private let source: Observable<Either<V,E>>
    private var observer: Observer<Either<V,E>>?
    
    init(_ source: Observable<Either<V,E>>) {
        self.source = source
        super.init()
        self.observer = Observer(source) { transaction in
            switch transaction {
            case .Begin:
                break
            case .End(let value):
                switch value {
                case .Value:
                    break
                case .Error(let e):
                    self.pushValue(e)
                }
            }
        }
    }

    override public var canPullValue: Bool {
        return pullValue != nil
    }
    
    override public var pullValue: E? {
        guard let either = source.pullValue else {
            return nil
        }
        switch either {
        case .Error(let e):
            return e
        case .Value:
            return nil
        }
    }
}

public func valueFromEither<V, E:ErrorType>(either: Observable<Either<V,E>>) -> Observable<V> {
    return SplitEitherValue(either)
}

public func errorFromEither<V, E:ErrorType>(either: Observable<Either<V,E>>) -> Observable<E> {
    return SplitEitherError(either)
}
