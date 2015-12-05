//
//  DataSource.swift
//  ScotTraffic
//
//  Created by Neil Gall on 01/11/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import Foundation

public enum DataSourceValue<ValueType> {
    case Cached(ValueType, expired: Bool)
    case Fresh(ValueType)
    case Error(AppError)
    case Empty
}

public typealias DataSourceData = DataSourceValue<NSData>

public protocol DataSource: Startable {
    var value: Observable<DataSourceData> { get }
}

public extension DataSourceValue {
    public func map<TargetValueType>(transform: ValueType throws -> TargetValueType) -> DataSourceValue<TargetValueType> {
        do {
            switch self {
            case .Cached(let data, let expired):
                return .Cached(try transform(data), expired: expired)
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
        case .Cached(let value, _):
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
    public var value: Observable<DataSourceData> {
        return Const(value: .Empty)
    }
    
    public func start() {
    }
}
