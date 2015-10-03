//
//  AppErrors.swift
//  ScotTraffic
//
//  Created by Neil Gall on 03/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import Foundation

public enum AppError : ErrorType {
    case Network(NetworkError)
    case JSON(JSONError)
    case System(NSError)
    case Unknown(ErrorType)
    
    public static func wrap(e: ErrorType) -> AppError {
        if e.dynamicType == AppError.self {
            return e as! AppError
        } else if e.dynamicType == NetworkError.self {
            return AppError.Network(e as! NetworkError)
        } else if e.dynamicType == JSONError.self {
            return AppError.JSON(e as! JSONError)
        } else if e.dynamicType == NSError.self {
            return AppError.System(e as NSError)
        } else {
            return AppError.Unknown(e)
        }
    }
}
