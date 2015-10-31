//
//  ContainerAnnotationView.swift
//  ScotTraffic
//
//  Created by Neil Gall on 31/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import MapKit

private let scaleAnimationDuration = 0.15

class ContainerAnnotationView: MKAnnotationView {
    
    private var calloutView: UIView?

    func showCollectionView(view: UIView, inMapView container: MKMapView, withPreferredSize preferredSize: CGSize, edgeInsets insets: UIEdgeInsets, completion: Void->Void) {
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
        
        print ("preferredSize \(preferredSize) actual size \(size)")
        print ("frame \(frame) in container \(frameInContainer) bounds \(containerBounds)")
        print ("left \(left) right \(right) top \(top) bottom \(bottom)")
        
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
        
        print ("adjusted frame \(frame)")
        
        view.bounds = CGRect(origin: CGPointZero, size: frame.size)
        view.center = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
        view.alpha = 0
        
        addSubview(view)
        calloutView = view

        view.transform = scaleDownTransformForSize(frame.size)

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
            view.alpha = 0
        }, completion: { finished in
            view.removeFromSuperview()
            self.setNeedsLayout()
            self.calloutView = nil
            completion()
        })
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
        return calloutView.hitTest(convertPoint(point, toView: calloutView), withEvent: event)
    }
}
