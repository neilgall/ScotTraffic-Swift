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

protocol CalloutContainerViewDelegate {
    func calloutContainerView(calloutContainerView: CalloutContainerView, didDismissCalloutForAnnotationView annotationView: MKAnnotationView)
}

class CalloutContainerView: UIView {

    private var annotationsByCallout = ViewKeyedMap<MKAnnotationView>()
    
    var delegate: CalloutContainerViewDelegate?
    
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
        view.bounds = CGRect(origin: CGPoint.zero, size: calloutFrame.size)
        view.center = centerOfView(annotationView)
        view.transform = scaleDownTransformFromSize(calloutFrame.size, toSize: annotationView.bounds.size)
        view.alpha = minimumContainedViewAlpha
        
        addSubview(view)
        annotationsByCallout[view] = annotationView
        
        UIView.animateWithDuration(scaleAnimationDuration, delay: 0, options: [.CurveEaseOut], animations: {
            view.center = CGPoint(x: calloutFrame.midX, y: calloutFrame.midY)
            view.transform = CGAffineTransformIdentity
            view.alpha = 1
        }, completion: { finished in
            completion()
        })
        
        let swipe = UISwipeGestureRecognizer(target: self, action: .handleSwipeGesture)
        swipe.direction = [.Up, .Down]
        view.addGestureRecognizer(swipe)
    }
    
    func hideCalloutView(view: UIView, animated: Bool, completion: Void->Void) {
        let finish = {
            view.removeFromSuperview()
            self.annotationsByCallout[view] = nil
            completion()
        }
        
        guard animated, let annotationView = annotationsByCallout[view] else {
            finish()
            return
        }
        
        UIView.animateWithDuration(scaleAnimationDuration, delay: 0, options: [.CurveEaseIn], animations: {
            view.center = self.centerOfView(annotationView)
            view.transform = scaleDownTransformFromSize(view.bounds.size, toSize: annotationView.bounds.size)
            view.alpha = minimumContainedViewAlpha
        }, completion: { finished in
            finish()
        })
    }
    
    func handleSwipeGesture(swipe: UIGestureRecognizer) {
        guard let view = swipe.view, let annotationView = annotationsByCallout[view] else {
            return
        }
        
        delegate?.calloutContainerView(self, didDismissCalloutForAnnotationView: annotationView)
    }
    
    private func centerOfView(view: UIView) -> CGPoint {
        let center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
        return view.convertPoint(center, toView: self)
    }
    
    private func calloutFrameForPreferredSize(preferredSize: CGSize, fromAnnotationView annotationView: MKAnnotationView) -> CGRect {
        let size = reduceSize(preferredSize, toFitContainer: containerBounds.size)
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

private func reduceSize(size: CGSize, toFitContainer containerSize: CGSize) -> CGSize {
    if size.width < containerSize.width && size.height < containerSize.height {
        return size
    }
    let scale = min(containerSize.width / size.width, containerSize.height / size.height)
    return CGSize(width: size.width * scale, height: size.height * scale)
}

private func scaleDownTransformFromSize(fromSize: CGSize, toSize: CGSize) -> CGAffineTransform {
    return CGAffineTransformMakeScale(toSize.width / fromSize.width, toSize.height / fromSize.height)
}

private extension Selector {
    static let handleSwipeGesture = #selector(CalloutContainerView.handleSwipeGesture(_:))
}
