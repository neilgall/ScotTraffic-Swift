//
//  NotificationView.swift
//  ScotTraffic
//
//  Created by Neil Gall on 12/01/2016.
//  Copyright © 2016 Neil Gall. All rights reserved.
//

import UIKit

private let notificationDisplayTime = 4.0
private let notificationAppearTime = 0.25

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
        
        background.addSubview(label)
        view.addSubview(background)
        view.addConstraints(constraints)

        background.alpha = 0
        let animations = {
            UIView.addKeyframeWithRelativeStartTime(0, relativeDuration: notificationAppearTime / notificationDisplayTime) {
                background.alpha = 1.0
            }
        }
        UIView.animateKeyframesWithDuration(notificationDisplayTime, delay: 0, options: [.Autoreverse], animations: animations) { _ in
            self.view.removeConstraints(constraints)
            background.removeFromSuperview()
        }
    }
}