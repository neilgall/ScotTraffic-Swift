//
//  CalloutContainerView.swift
//  ScotTraffic
//
//  Created by Neil Gall on 07/11/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import MapKit

private let scaleAnimationDuration: NSTimeInterval = 0.22
private let minimumContainedViewAlpha: CGFloat = 0.5
private let calloutEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10)

class CalloutContainerView: UIView {

    override func layoutSubviews() {
        // manual layout
    }

    override func hitTest(point: CGPoint, withEvent event: UIEvent?) -> UIView? {
        // only process events in subviews
        let view = super.hitTest(point, withEvent: event)
        return view === self ? nil : view
    }
    
    private var containerBounds: CGRect {
        return UIEdgeInsetsInsetRect(self.bounds, calloutEdgeInsets)
    }
    
    func addCalloutView(view: UIView, withPreferredSize preferredSize: CGSize, fromAnnotationView annotationView: MKAnnotationView, completion: Void->Void) {
        let calloutFrame = calloutFrameForPreferredSize(preferredSize, fromAnnotationView: annotationView)
        
        view.translatesAutoresizingMaskIntoConstraints = true
        view.bounds = CGRect(origin: CGPointZero, size: calloutFrame.size)
        view.center = centerOfView(annotationView)
        view.transform = scaleDownTransformFromSize(calloutFrame.size, toSize: annotationView.bounds.size)
        view.alpha = minimumContainedViewAlpha
        
        addSubview(view)
        
        UIView.animateWithDuration(scaleAnimationDuration, delay: 0, options: [.CurveEaseOut], animations: {
            view.center = CGPoint(x: calloutFrame.midX, y: calloutFrame.midY)
            view.transform = CGAffineTransformIdentity
            view.alpha = 1
        }, completion: { finished in
            completion()
        })
    }
    
    func hideCalloutView(view: UIView, forAnnotationView annotationView: MKAnnotationView, animated: Bool, completion: Void->Void) {
        if !animated {
            view.removeFromSuperview()
            completion()
            return
        }
        
        UIView.animateWithDuration(scaleAnimationDuration, delay: 0, options: [.CurveEaseIn], animations: {
            view.center = self.centerOfView(annotationView)
            view.transform = scaleDownTransformFromSize(view.bounds.size, toSize: annotationView.bounds.size)
            view.alpha = minimumContainedViewAlpha
        }, completion: { finished in
            view.removeFromSuperview()
            completion()
        })
    }
    
    private func centerOfView(view: UIView) -> CGPoint {
        let center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
        return view.convertPoint(center, toView: self)
    }
    
    private func calloutFrameForPreferredSize(preferredSize: CGSize, fromAnnotationView annotationView: MKAnnotationView) -> CGRect {
        let size = CGSize(
            width: min(preferredSize.width, containerBounds.size.width),
            height: min(preferredSize.height, containerBounds.size.height))
        
        let calloutFrameRelativeToAnnotation = CGRect(origin: CGPoint(x: -size.width/2, y: -size.height/2), size: size)
        var calloutFrameInContainer = annotationView.convertRect(calloutFrameRelativeToAnnotation, toView: self)
        let left = containerBounds.minX - calloutFrameInContainer.minX
        let right = calloutFrameInContainer.maxX - containerBounds.maxX
        let top = containerBounds.minY - calloutFrameInContainer.minY
        let bottom = calloutFrameInContainer.maxY - containerBounds.maxY
        
        if left > 0 {
            calloutFrameInContainer.origin.x += left
        } else if right > 0 {
            calloutFrameInContainer.origin.x -= right
        }
        if top > 0 {
            calloutFrameInContainer.origin.y += top
        } else if bottom > 0 {
            calloutFrameInContainer.origin.y -= bottom
        }
        
        return CGRectIntegral(calloutFrameInContainer)
    }
}

private func scaleDownTransformFromSize(fromSize: CGSize, toSize: CGSize) -> CGAffineTransform {
    return CGAffineTransformMakeScale(toSize.width / fromSize.width, toSize.height / fromSize.height)
}
