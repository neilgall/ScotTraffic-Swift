//
//  NotificationView.swift
//  ScotTraffic
//
//  Created by Neil Gall on 12/01/2016.
//  Copyright © 2016 Neil Gall. All rights reserved.
//

import UIKit

private let notificationAppearTime: NSTimeInterval = 0.66
private let notificationDisplayTime: NSTimeInterval = 4.0
private let notificationDisappearTime: NSTimeInterval = 0.4

extension NGSplitViewController {
    
    func showNotificationMessage(message: String) {
        let nib = UINib(nibName: "NotificationView", bundle: nil)
        guard let background = nib.instantiateWithOwner(self, options: nil).first as? UIView,
            label = background.subviews[0] as? UILabel else {
                return
        }
        
        label.text = message
        
        let constraints = [.Top, .Left, .Right].map({
            NSLayoutConstraint(item: background,
                attribute: $0,
                relatedBy: .Equal,
                toItem: view,
                attribute: $0,
                multiplier: 1.0,
                constant: 0.0)
        })
        
        let slideOnConstraint = constraints[0]
        let slideOffConstraint = NSLayoutConstraint(item: background,
            attribute: .Top,
            relatedBy: .Equal,
            toItem: view,
            attribute: .Top,
            multiplier: 1.0,
            constant: -view.frame.height)
        
        slideOnConstraint.priority = 998
        slideOffConstraint.priority = 999
        
        background.translatesAutoresizingMaskIntoConstraints = false
        background.addSubview(label)
        view.addSubview(background)
        view.addConstraints(constraints)
        view.addConstraint(slideOffConstraint)
        
        dispatch_async(dispatch_get_main_queue()) {
            
            // adjust slide off constraint to laid out height of background
            slideOffConstraint.constant = -background.frame.height
            
            UIView.animateWithDuration(notificationAppearTime, delay: 0, options: [.CurveEaseOut], animations: {
                slideOnConstraint.priority = 999
                slideOffConstraint.priority = 998
                self.view.layoutIfNeeded()
            }, completion: { _ in
                UIView.animateWithDuration(notificationDisappearTime, delay: notificationDisplayTime, options: [.CurveEaseIn], animations: { () -> Void in
                    slideOnConstraint.priority = 998
                    slideOffConstraint.priority = 999
                    self.view.layoutIfNeeded()
                }, completion: { _ in
                    background.removeFromSuperview()
                })
            })
        }
    }
}
