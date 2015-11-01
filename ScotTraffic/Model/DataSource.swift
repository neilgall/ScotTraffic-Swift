//
//  DataSource.swift
//  ScotTraffic
//
//  Created by Neil Gall on 01/11/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import Foundation

public protocol DataSource: Startable {
    var value: Observable<Either<NSData,NetworkError>> { get }
}
