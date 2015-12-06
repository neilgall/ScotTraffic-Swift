//
//  DeferredStartSpinner.swift
//  ScotTraffic
//
//  Created by ZBS on 06/12/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit

private let startDelay = 1.5

public class DeferredStartSpinner: UIActivityIndicatorView {

    private weak var timer: NSTimer?

    public func startAnimatingDeferred() {
        self.timer = NSTimer.scheduledTimerWithTimeInterval(startDelay, target: self, selector: Selector("startAnimating"), userInfo: nil, repeats: false)
    }
    
    override public func startAnimating() {
        super.startAnimating()
        self.timer?.invalidate()
    }
    
    override public func stopAnimating() {
        super.stopAnimating()
        self.timer?.invalidate()
    }
}
