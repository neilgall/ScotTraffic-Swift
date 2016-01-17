//
//  DataSource.swift
//  ScotTraffic
//
//  Created by Neil Gall on 01/11/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import Foundation

enum DataSourceValue<ValueType> {
    case Cached(ValueType, expired: Bool)
    case Fresh(ValueType)
    case Error(AppError)
    case Empty
}

typealias DataSourceData = DataSourceValue<NSData>

protocol DataSource: Startable {
    var value: Signal<DataSourceData> { get }
}

extension DataSourceValue {
    
    // Construct a DataSourceValue from an optional of the same ValueType
    static func fromOptional(optional: ValueType?) -> DataSourceValue {
        if let value = optional {
            return .Fresh(value)
        } else {
            return .Empty
        }
    }
    
    func map<TargetValueType>(transform: ValueType throws -> TargetValueType) -> DataSourceValue<TargetValueType> {
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
    
    var value: ValueType? {
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

class EmptyDataSource: DataSource {
    var value: Signal<DataSourceData> {
        return Const(.Empty)
    }
    
    func start() {
    }
}
