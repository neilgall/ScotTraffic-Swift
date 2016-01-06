//
//  AppErrorTests.swift
//  ScotTraffic
//
//  Created by Neil Gall on 05/01/2016.
//  Copyright © 2016 Neil Gall. All rights reserved.
//

import XCTest
import ScotTraffic

class AppErrorTests: XCTestCase {
    
    func testWrapAppError() {
        let test = AppError.System(NSError(domain: "test", code: 0, userInfo: nil))
        do {
            throw AppError.wrap(test)
        } catch AppError.System {
            // pass
        } catch {
            XCTFail("incorrect error type")
        }
    }
}
