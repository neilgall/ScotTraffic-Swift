//
//  NGSplitViewController.swift
//  NGSplitViewController
//
//  Created by Neil Gall on 23/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit

@objc public protocol NGSplitViewControllerDelegate {
    optional func splitViewControllerTraitCollectionChanged(splitViewController: NGSplitViewController)
    optional func splitViewController(splitViewController: NGSplitViewController, didChangeMasterViewControllerVisibility viewController: UIViewController)
    optional func splitViewController(splitViewController: NGSplitViewController, didChangeDetailViewControllerVisibility viewController: UIViewController)
}

public class NGSplitViewController: UIViewController {

    // -- MARK: Public API
    
    public var transitionDuration: NSTimeInterval = 0.3
    
    public var delegate: NGSplitViewControllerDelegate?

    public var masterViewController: UIViewController? {
        willSet(newMasterViewController) {
            guard isViewLoaded() else {
                return
            }
            if let oldVC = masterViewController, newVC = newMasterViewController {
                crossFadeFromViewController(oldVC, toViewController: newVC)
            } else if let oldVC = masterViewController {
                removeChild(oldVC)
            } else if let newVC = newMasterViewController {
                addChild(newVC, withFrame: containerFrames.master)
            }
        }
    }
    
    public var detailViewController: UIViewController? {
        willSet(newDetailViewController) {
            guard isViewLoaded() else {
                return
            }
            if let oldVC = detailViewController, newVC = newDetailViewController {
                crossFadeFromViewController(oldVC, toViewController: newVC)
            } else if let oldVC = detailViewController {
                removeChild(oldVC)
            } else if let newVC = newDetailViewController {
                addChild(newVC, withFrame: containerFrames.detail)
            }
        }
    }
    
    public var masterViewControllerIsVisible: Bool {
        return presentationStyle.showsMaster
    }
    
    public var detailViewControllerIsVisible: Bool {
        return presentationStyle.showsDetail
    }
    
    public var splitRatio: CGFloat = 0.333 {
        didSet {
            view.setNeedsLayout()
        }
    }
    
    public func overlayMasterViewController() {
        guard presentationStyle == .DetailOnly else {
            return
        }
        
        if view.bounds.size.width <= 320 {
            presentationStyle = .MasterOnly
        } else {
            presentationStyle = .MasterOverlay
        }
    }
    
    public func dismissOverlaidMasterViewController() {
        if presentationStyle == .MasterOnly || presentationStyle == .MasterOverlay {
            presentationStyle = .DetailOnly
        }
    }

    // -- MARK: Presentation state

    private var overlayHideButton: UIButton? {
        willSet(newValue) {
            if newValue == nil {
                overlayHideButton?.removeFromSuperview()
            }
        }
    }
    
    private enum PresentationStyle {
        case MasterOnly
        case DetailOnly
        case SideBySide
        case MasterOverlay
        
        var showsMaster: Bool {
            return self != .DetailOnly
        }
        
        var showsDetail: Bool {
            return self != .MasterOnly
        }
    }
    
    private var presentationStyle: PresentationStyle = .MasterOnly {
        willSet(newStyle) {
            transitionFromPresentationStyle(presentationStyle, toPresentationStyle: newStyle)
        }
        didSet(oldStyle) {
            view.setNeedsLayout()
            updateChildTraitCollections()
            notifyDelegateOfChangeFromPresentationStyle(oldStyle, toPresentationStyle: presentationStyle)
        }
    }

    // -- MARK: UIViewController implementation
    
    public override func viewDidLoad() {
        super.viewDidLoad()

        let frames = containerFrames
        addChild(masterViewController, withFrame: frames.master)
        addChild(detailViewController, withFrame: frames.detail)
    }
    
    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        updatePresentationStyle()
        updateFrames()
        updateChildTraitCollections()
    }
    
    public override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
        updatePresentationStyle()
        updateChildTraitCollections()
        view.setNeedsLayout()
        
        delegate?.splitViewControllerTraitCollectionChanged?(self)
    }
    
    public override func viewWillLayoutSubviews() {
        updateFrames()
    }
    
    // -- MARK: Layout
    
    private var containerFrames: (master: CGRect, detail: CGRect) {
        var masterFrame: CGRect = view.bounds
        var detailFrame: CGRect = view.bounds

        switch presentationStyle {
            
        case .SideBySide:
            let frames = view.bounds.divide(splitRatio)
            masterFrame = frames.left
            detailFrame = frames.right
            
        case .MasterOverlay:
            masterFrame = CGRectMake(0, 0, 320, view.bounds.size.height)
            
        case .DetailOnly:
            // fudge to fix a strange unexpected call to viewWillLayoutSubviews() on the animate-out transition
            masterFrame = CGRectMake(-320, 0, 320, view.bounds.size.height)
            
        case .MasterOnly:
            break
        }
        
        return (master: masterFrame.integral, detail: detailFrame.integral)
    }

    private func addChild(childViewController: UIViewController?, withFrame frame: CGRect) {
        guard isViewLoaded(), let child = childViewController else {
            return
        }
        
        child.willMoveToParentViewController(self)
        addChildViewController(child)
        child.view.translatesAutoresizingMaskIntoConstraints = false
        child.view.frame = frame
        view.addSubview(child.view)
        child.didMoveToParentViewController(self)
        view.setNeedsLayout()
    }

    private func removeChild(childViewController: UIViewController?) {
        guard let child = childViewController else {
            return
        }
        
        child.willMoveToParentViewController(nil)
        child.view.removeFromSuperview()
        child.removeFromParentViewController()
        child.didMoveToParentViewController(nil)
    }
    
    private func updatePresentationStyle() {
        if traitCollection.horizontalSizeClass == .Regular {
            presentationStyle = .SideBySide
        } else {
            presentationStyle = .DetailOnly
        }
    }
   
    private func updateFrames() {
        let frames = containerFrames
        masterViewController?.view.frame = frames.master
        detailViewController?.view.frame = frames.detail
    }
    
    private func updateChildTraitCollections() {
        let compact = UITraitCollection(horizontalSizeClass: .Compact)
        
        if let master = masterViewController {
            if presentationStyle == .MasterOnly {
                setOverrideTraitCollection(traitCollection, forChildViewController: master)
            } else {
                let masterTraitCollection = UITraitCollection(traitsFromCollections: [traitCollection, compact])
                setOverrideTraitCollection(masterTraitCollection, forChildViewController: master)
            }
        }
        
        if let detail = detailViewController {
            if presentationStyle == .DetailOnly || presentationStyle == .MasterOverlay {
                setOverrideTraitCollection(traitCollection, forChildViewController: detail)
            } else {
                let detailTraitCollection = UITraitCollection(traitsFromCollections: [traitCollection, compact])
                setOverrideTraitCollection(detailTraitCollection, forChildViewController: detail)
            }
        }
    }
    
    // -- MARK: Transitions
    
    private func animateInMasterViewControllerOverlay() {
        guard let master = masterViewController else {
            return
        }
        
        let frames = containerFrames
        
        let button = UIButton(type: .Custom)
        button.translatesAutoresizingMaskIntoConstraints = true
        button.frame = frames.detail
        button.addTarget(self, action: Selector("dismissOverlaidMasterViewController"), forControlEvents: .TouchUpInside)
        view.addSubview(button)
        
        overlayHideButton = button
        addChild(masterViewController, withFrame: frames.master)
        
        master.view.transform = CGAffineTransformMakeTranslation(-frames.master.size.width, 0)
        UIView.animateWithDuration(transitionDuration,
            delay: 0,
            options: .CurveEaseOut,
            animations: { master.view.transform = CGAffineTransformIdentity },
            completion: nil)
    }
    
    private func animateOutMasterViewControllerOverlay() {
        guard let master = masterViewController else {
            return
        }
        
        let frame = containerFrames.master
        
        UIView.animateWithDuration(transitionDuration,
            delay: 0,
            options: .CurveEaseIn,
            animations: {
                master.view.transform = CGAffineTransformMakeTranslation(-frame.size.width, 0)
            },
            completion: { _ in
                self.overlayHideButton = nil
                self.removeChild(master)
        })
    }
    
    private func transitionFromPresentationStyle(fromPresentationStyle: PresentationStyle, toPresentationStyle: PresentationStyle) {
        guard fromPresentationStyle != toPresentationStyle, let master = masterViewController, let detail = detailViewController else {
            return
        }
        
        switch toPresentationStyle {
        case .MasterOverlay:
            switch fromPresentationStyle {
            case .DetailOnly:
                animateInMasterViewControllerOverlay()
            default:
                illegalTransition(fromPresentationStyle, to: toPresentationStyle)
            }
            
        case .DetailOnly:
            switch fromPresentationStyle {
            case .MasterOverlay:
                animateOutMasterViewControllerOverlay()
            case .SideBySide:
                removeChild(master)
                break
            case .MasterOnly:
                detail.view.frame = containerFrames.detail
                crossFadeFromViewController(master, toViewController: detail)
            default:
                illegalTransition(fromPresentationStyle, to: toPresentationStyle)
            }
            
        case .MasterOnly:
            switch fromPresentationStyle {
            case .MasterOverlay:
                break
            case .SideBySide:
                removeChild(detail)
            case .DetailOnly:
                master.view.frame = containerFrames.master
                crossFadeFromViewController(detail, toViewController: master)
            default:
                illegalTransition(fromPresentationStyle, to: toPresentationStyle)
            }
            
        case .SideBySide:
            switch fromPresentationStyle {
            case .DetailOnly:
                addChild(master, withFrame: containerFrames.master)
            case .MasterOnly:
                addChild(detail, withFrame: containerFrames.detail)
            case .MasterOverlay:
                overlayHideButton = nil
            default:
                illegalTransition(fromPresentationStyle, to: toPresentationStyle)
            }
            break
        }
    }
    
    private func illegalTransition(from: PresentationStyle, to: PresentationStyle) {
        fatalError("illegal transition from \(from) to \(to)")
    }
    
    private func notifyDelegateOfChangeFromPresentationStyle(fromPresentationStyle: PresentationStyle, toPresentationStyle: PresentationStyle) {
        if let master = masterViewController {
            if fromPresentationStyle.showsMaster != toPresentationStyle.showsMaster {
                delegate?.splitViewController?(self, didChangeMasterViewControllerVisibility: master)
            }
        }
        
        if let detail = detailViewController {
            if fromPresentationStyle.showsDetail != toPresentationStyle.showsDetail {
                delegate?.splitViewController?(self, didChangeDetailViewControllerVisibility: detail)
            }
        }
    }
    
    private func crossFadeFromViewController(from: UIViewController, toViewController to: UIViewController) {
        transitionFromViewController(from,
            toViewController: to,
            duration: transitionDuration,
            options: [.CurveEaseInOut, .TransitionCrossDissolve, .LayoutSubviews],
            animations: {},
            completion: nil)
    }
}

extension CGRect {
    func divide(split: CGFloat) -> (left: CGRect, right: CGRect) {
        var left: CGRect = CGRectZero
        var right: CGRect = CGRectZero
        CGRectDivide(self, &left, &right, size.width*split, .MinXEdge)
        return (left: left, right: right)
    }
    
    var integral: CGRect {
        return CGRectMake(round(origin.x), round(origin.y), round(size.width), round(size.height))
    }
}
