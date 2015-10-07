//
//  WithFlag.swift
//  ScotTraffic
//
//  Created by Neil Gall on 07/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import Foundation

public func with(inout flag: Bool, _ closure: Void -> Void) {
    let oldValue = flag
    flag = true
    closure()
    flag = oldValue
}