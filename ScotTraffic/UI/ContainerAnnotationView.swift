//
//  ContainerAnnotationView.swift
//  ScotTraffic
//
//  Created by Neil Gall on 31/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import MapKit

private let scaleAnimationDuration: NSTimeInterval = 0.22
private let minimumContainedViewAlpha: CGFloat = 0.5

class ContainerAnnotationView: MKAnnotationView {
    
    var animationSequence = AsyncSequence()
    private var calloutView: UIView?
    
    func showView(view: UIView, inMapView container: MKMapView, withPreferredSize preferredSize: CGSize, edgeInsets insets: UIEdgeInsets, completion: Void->Void) {
        let containerBounds = UIEdgeInsetsInsetRect(container.bounds, insets)
        let size = CGSize(
            width: min(preferredSize.width, containerBounds.size.width),
            height: min(preferredSize.height, containerBounds.size.height))
        
        var frame = CGRect(origin: CGPoint(x: -size.width/2, y: -size.height/2), size: size)
        let frameInContainer = convertRect(frame, toView: container)
        let left = containerBounds.minX - frameInContainer.minX
        let right = frameInContainer.maxX - containerBounds.maxX
        let top = containerBounds.minY - frameInContainer.minY
        let bottom = frameInContainer.maxY - containerBounds.maxY
        
        if left > 0 {
            frame.origin.x += left
        } else if right > 0 {
            frame.origin.x -= right
        }
        if top > 0 {
            frame.origin.y += top
        } else if bottom > 0 {
            frame.origin.y -= bottom
        }
        
        view.translatesAutoresizingMaskIntoConstraints = true
        view.bounds = CGRect(origin: CGPointZero, size: frame.size)
        view.center = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
        view.transform = scaleDownTransformForSize(frame.size)
        view.alpha = minimumContainedViewAlpha
        
        calloutView = view
        addSubview(view)

        UIView.animateWithDuration(scaleAnimationDuration, delay: 0, options: [.CurveEaseOut], animations: {
            view.center = CGPoint(x: frame.midX, y: frame.midY)
            view.transform = CGAffineTransformIdentity
            view.alpha = 1
        }, completion: { finished in
            completion()
        })
    }
    
    func hideCollectionViewAnimated(animated: Bool, completion: Void->Void) {
        guard let view = calloutView else {
            completion()
            return
        }
        
        if !animated {
            view.removeFromSuperview()
            completion()
            return
        }
        
        UIView.animateWithDuration(scaleAnimationDuration, delay: 0, options: [.CurveEaseIn], animations: {
            view.center = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
            view.transform = self.scaleDownTransformForSize(view.bounds.size)
            view.alpha = minimumContainedViewAlpha
        }, completion: { finished in
            view.removeFromSuperview()
            self.setNeedsLayout()
            self.calloutView = nil
            completion()
        })
    }
    
    func isPresentingViewController(viewController: UIViewController) -> Bool {
        return viewController.view.superview === self
    }
    
    func scaleDownTransformForSize(size: CGSize) -> CGAffineTransform {
        return CGAffineTransformMakeScale(self.bounds.size.width / size.width, self.bounds.size.height / size.height)
        
    }
    
    var showingCalloutView: Bool {
        return calloutView != nil
    }
    
    override func prepareForReuse() {
        hideCollectionViewAnimated(false, completion: {})
        super.prepareForReuse()
    }
    
    override func hitTest(point: CGPoint, withEvent event: UIEvent?) -> UIView? {
        guard let calloutView = calloutView where CGRectContainsPoint(calloutView.frame, point) else {
            return nil
        }
        let view = calloutView.hitTest(convertPoint(point, toView: calloutView), withEvent: event)
        print("ContainerAnnotationView hitTest(\(point), \(event)) -> \(view) nr=\(view?.nextResponder())")
        return view
    }
    
    override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        guard let calloutView = calloutView else {
            return false
        }
        return CGRectContainsPoint(calloutView.frame, point)
    }
}
