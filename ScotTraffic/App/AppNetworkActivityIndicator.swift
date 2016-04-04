//
//  AppNetworkActivityIndicator.swift
//  ScotTraffic
//
//  Created by Neil Gall on 21/11/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit

class AppNetworkActivityIndicator: NetworkActivityIndicator {
    private var count = 0
    
    func push() {
        onMainQueue {
            if self.count == 0 {
                UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            }
            self.count += 1
        }
    }
    
    func pop() {
        onMainQueue {
            self.count -= 1
            if self.count == 0 {
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            }
        }
    }
}