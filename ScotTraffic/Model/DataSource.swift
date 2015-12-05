//
//  DataSource.swift
//  ScotTraffic
//
//  Created by Neil Gall on 01/11/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import Foundation

public enum DataSourceValue<ValueType> {
    case Cached(ValueType)
    case Fresh(ValueType)
    case Error(AppError)
    case Empty
}

public protocol DataSource: Startable {
    var value: Observable<DataSourceValue<NSData>> { get }
}

public extension DataSourceValue {
    public func map<TargetValueType>(transform: ValueType throws -> TargetValueType) -> DataSourceValue<TargetValueType> {
        do {
            switch self {
            case .Cached(let data):
                return .Cached(try transform(data))
            case .Fresh(let data):
                return .Fresh(try transform(data))
            case .Error(let error):
                return .Error(error)
            case .Empty:
                return .Empty
            }
        } catch {
            return .Error(AppError.wrap(error))
        }
    }
    
    public var value: ValueType? {
        switch self {
        case .Cached(let value):
            return value
        case .Fresh(let value):
            return value
        case .Error, .Empty:
            return nil
        }
    }

    var error: AppError? {
        switch self {
        case .Cached, .Fresh, .Empty:
            return nil
        case .Error(let error):
            return error
        }
    }
}

public class EmptyDataSource : DataSource {
    public var value: Observable<DataSourceValue<NSData>> {
        return Const(value: .Empty)
    }
    
    public func start() {
    }
}
