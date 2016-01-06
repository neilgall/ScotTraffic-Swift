//
//  AppErrors.swift
//  ScotTraffic
//
//  Created by Neil Gall on 03/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import Foundation

public enum AppError: ErrorType {
    case Network(NetworkError)
    case Image(ImageError)
    case JSON(JSONError)
    case System(NSError)
    case Unknown(ErrorType)
    
    public static func wrap(e: ErrorType) -> AppError {
        if let ae = e as? AppError {
            return ae
        } else if let ne = e as? NetworkError {
            return .Network(ne)
        } else if let ie = e as? ImageError {
            return .Image(ie)
        } else if let je = e as? JSONError {
            return .JSON(je)
        } else if e.dynamicType == NSError.self {
            return .System(e as NSError)
        } else {
            return .Unknown(e)
        }
    }
}
