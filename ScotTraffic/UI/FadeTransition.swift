//
//  FadeTransition.swift
//  ScotTraffic
//
//  Created by Neil Gall on 21/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit

public class FadeTranstion: NSObject, UIViewControllerAnimatedTransitioning {
    
    private static let duration = 0.3

    public func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        guard let toViewController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey),
            let toView = toViewController.view else {
                transitionContext.transitionWasCancelled()
                return
        }
        
        toView.alpha = 0
        transitionContext.containerView()?.addSubview(toView)
        
        UIView.animateWithDuration(FadeTranstion.duration, animations: {
            toView.alpha = 1
        }, completion: { finished in
            transitionContext.completeTransition(finished)
        })
    }
    
    public func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return FadeTranstion.duration
    }
}
