//
//  NGSplitViewController.swift
//  NGSplitViewController
//
//  The MIT License (MIT)
//
//  Copyright (c) 2015 Neil Gall
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import UIKit

@objc public protocol NGSplitViewControllerDelegate {
    /**
     * Should the split view show the master view controller for a given horizontal size class and overall view width?
     * By default, the master view controller is visible in a regular size class and hidden in a compact.
     *
     * @param splitViewController The NGSplitViewController making the request
     * @param horizontalSizeClass The overall horizontalSizeClass for the NGSplitViewController
     * @param viewWidth           The overall view width for for the NGSplitViewController
     * @return true If the master view controller should be shown; false if it should be hidden
     */
    optional func splitViewController(splitViewController: NGSplitViewController,
        shouldShowMasterViewControllerForHorizontalSizeClass horizontalSizeClass: UIUserInterfaceSizeClass,
        viewWidth: CGFloat) -> Bool

    /**
     * Notify that the split view controller is about to change the master view controller's visibility.
     *
     * @param splitViewController The NGSplitViewController performing the notification
     * @param viewController      The UIViewController in the master position which is about to change visibility
     */
    optional func splitViewController(splitViewController: NGSplitViewController, willChangeMasterViewControllerVisibility viewController: UIViewController)

    /**
     * Notify that the split view controller has changed the master view controller's visibility. When the master is
     * hidden, the application should present some user interface to allow the master to be presented temporarily using
     * overlayMasterViewController()
     *
     * @param splitViewController The NGSplitViewController performing the notification
     * @param viewController      The UIViewController in the master position which has changed visibility
     */
    optional func splitViewController(splitViewController: NGSplitViewController, didChangeMasterViewControllerVisibility viewController: UIViewController)

    /**
     * Notify that the split view controller is about to change the detail view controller's visibility.
     *
     * @param splitViewController The NGSplitViewController performing the notification
     * @param viewController      The UIViewController in the detail position which is about to change visibility
     */
    optional func splitViewController(splitViewController: NGSplitViewController, willChangeDetailViewControllerVisibility viewController: UIViewController)
    
    /**
     * Notify that the split view controller has changed the master view controller's visibility. When the detail is
     * hidden, the application should present some user interface to allow the detail to be shown again using
     * dismissOverlaidMasterViewController()
     *
     * @param splitViewController The NGSplitViewController performing the notification
     * @param viewController      The UIViewController in the detail position which has changed visibility
     */
    optional func splitViewController(splitViewController: NGSplitViewController, didChangeDetailViewControllerVisibility viewController: UIViewController)
}

/**
 * A replacement UISplitViewController with a simpler, saner API and no magic.
 * 
 * This view controller along with its master and detail view controllers can be created in Interface Builder
 * but the relationships must be configured in code. This is as simple as setting the masterViewController and
 * detailViewController properties, and assigning a delegate.
 *
 * By default, NGSplitViewController shows the master and detail view controllers side-by-side when in a
 * regular horizontal size class. The split ratio can be changed by adjusting the splitRatio property.
 * In a compact horizontal size class, the master view controller disappears leaving the detail to fill the
 * view of the NGSplitViewController. The application should arrange for some means to present the master
 * view controller, and call overlayMasterViewController() to do so. On narrow (<=320 points overall) views
 * the master view controller replaces the full view of the detail using a cross-fade. On wider views, the
 * master view controller slides in from the left. The application should present some means to return to
 * the detail view using dismissOverlaidMasterViewController(), although on wider screens any touch in the
 * right margin outside the overlay will also dismiss the overlay.
 *
 * The precise behaviour of when the master view controller is shown and hidden can be overridden by the
 * delegate.
 */
public class NGSplitViewController: UIViewController {

    // -- MARK: Public API

    /**
     * The transition duration in seconds for cross-fades and master overlays
     */
    public var transitionDuration: NSTimeInterval = 0.3
    
    /**
     * The NGSplitViewControllerDelegate.
     */
    public var delegate: NGSplitViewControllerDelegate?

    /**
     * The master view controller, shown on the left in a side-by-side presentation
     */
    public var masterViewController: UIViewController? {
        willSet(newMasterViewController) {
            guard isViewLoaded() else {
                return
            }
            
            if presentationStyle.showsMaster, let oldVC = masterViewController, newVC = newMasterViewController {
                crossFadeFromViewController(oldVC, toViewController: newVC, completion: {})
            }
            
            if let oldVC = masterViewController {
                removeChild(oldVC)
            }
            
            if let newVC = newMasterViewController {
                addChild(newVC, withFrame: containerFrames.master)
            }
        }
    }
    
    /**
     * The detail view controller, shown on the right in a side-by-side presentation
     */
    public var detailViewController: UIViewController? {
        willSet(newDetailViewController) {
            guard isViewLoaded() else {
                return
            }
            
            if presentationStyle.showsDetail, let oldVC = detailViewController, newVC = newDetailViewController {
                crossFadeFromViewController(oldVC, toViewController: newVC, completion: {})
            }
            
            if let oldVC = detailViewController {
                removeChild(oldVC)
            }
            
            if let newVC = newDetailViewController {
                addChild(newVC, withFrame: containerFrames.detail)
            }
        }
    }
    
    /**
     * Is the master view controller currently visible?
     */
    public var masterViewControllerIsVisible: Bool {
        return presentationStyle.showsMaster
    }
    
    /**
     * Is the detail view controller currently visible?
     */
    public var detailViewControllerIsVisible: Bool {
        return presentationStyle.showsDetail
    }
    
    /**
     * The width of the master view controller's view width in side-by-side presentation
     */
    public var masterWidthInSideBySidePresentation: CGFloat = 320.0 {
        didSet {
            view.setNeedsLayout()
        }
    }
    
    /**
     * When in a detail-only presentation, show the master view controller as an overlay
     */
    public func overlayMasterViewController() {
        guard presentationStyle == .DetailOnly else {
            return
        }
        
        if view.bounds.size.width <= 320 {
            setPresentationStyle(.MasterOnly, withTransitionCoordinator: nil)
        } else {
            setPresentationStyle(.MasterOverlay, withTransitionCoordinator: nil)
        }
    }
    
    /**
     * Dismiss the overlaid master view controller
     */
    public func dismissOverlaidMasterViewController() {
        if presentationStyle == .MasterOnly || presentationStyle == .MasterOverlay {
            setPresentationStyle(.DetailOnly, withTransitionCoordinator: nil)
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
    
    private var presentationStyle: PresentationStyle = .SideBySide
    private var animatingMasterOverlay: Bool = false

    // -- MARK: UIViewController implementation
    
    public override func viewDidLoad() {
        super.viewDidLoad()

        let frames = containerFrames
        
        addChild(masterViewController, withFrame: frames.master)
        addChild(detailViewController, withFrame: frames.detail)
        
        switch presentationStyle {
        case .MasterOnly:
            removeChildView(detailViewController)
        case .DetailOnly:
            removeChildView(masterViewController)
        default:
            break
        }
    }
    
    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        updatePresentationStyleForHorizontalSizeClass(traitCollection.horizontalSizeClass, viewWidth: self.view.bounds.size.width, withTransitionCoordinator: nil)
        updateFrames()
        updateChildTraitCollections()
    }
    
    public override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
        updateChildTraitCollections()
        changePresentationStyle()
    }
    
    public override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        updatePresentationStyleForHorizontalSizeClass(traitCollection.horizontalSizeClass, viewWidth: size.width, withTransitionCoordinator: coordinator)
//        view.setNeedsLayout()
    }
    
    public override func viewWillLayoutSubviews() {
        updateFrames()
    }
    
    public func changePresentationStyle() {
        updatePresentationStyleForHorizontalSizeClass(traitCollection.horizontalSizeClass, viewWidth: view.bounds.width, withTransitionCoordinator: nil)
        updateChildTraitCollections()
        view.setNeedsLayout()
    }
    
    // -- MARK: Layout
    
    private var containerFrames: (master: CGRect, detail: CGRect) {
        var masterFrame: CGRect = view.bounds
        var detailFrame: CGRect = view.bounds

        switch presentationStyle {
            
        case .SideBySide:
            let frames = view.bounds.split(masterWidthInSideBySidePresentation)
            masterFrame = frames.left
            detailFrame = frames.right
            
        case .MasterOverlay:
            masterFrame = CGRect(origin: CGPoint.zero, size: CGSize(width: 320, height: view.bounds.size.height))
            
        case .DetailOnly:
            // fudge to fix a strange unexpected call to viewWillLayoutSubviews() on the animate-out transition
            if animatingMasterOverlay {
                masterFrame = CGRect(origin: CGPoint(x: -320, y: 0), size: CGSize(width: 320, height: view.bounds.size.height))
            }
            break

        case .MasterOnly:
            break
        }
        
        return (master: masterFrame.integral, detail: detailFrame.integral)
    }

    private func addChild(childViewController: UIViewController?, withFrame frame: CGRect) {
        guard isViewLoaded(), let child = childViewController else {
            return
        }
        
        addChildViewController(child)
        child.view.translatesAutoresizingMaskIntoConstraints = false
        addChildView(child, withFrame: frame)
        child.didMoveToParentViewController(self)
    }
    
    private func addChildView(childViewController: UIViewController?, withFrame frame: CGRect) {
        guard isViewLoaded(), let child = childViewController else {
            return
        }

        child.view.frame = frame
        child.view.alpha = 1.0
        view.addSubview(child.view)
        view.setNeedsLayout()
    }

    private func removeChild(childViewController: UIViewController?) {
        guard let child = childViewController else {
            return
        }
        
        child.willMoveToParentViewController(nil)
        removeChildView(child)
        child.removeFromParentViewController()
    }
    
    private func removeChildView(childViewController: UIViewController?) {
        childViewController?.view.removeFromSuperview()
    }
    
    private func updatePresentationStyleForHorizontalSizeClass(horizontalSizeClass: UIUserInterfaceSizeClass, viewWidth: CGFloat, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator?) {
        let delegateOverride = delegate?.splitViewController?(self, shouldShowMasterViewControllerForHorizontalSizeClass: horizontalSizeClass, viewWidth: viewWidth)
        let showMaster = delegateOverride ?? (horizontalSizeClass == .Regular)
        
        if showMaster {
            setPresentationStyle(.SideBySide, withTransitionCoordinator: coordinator)
        } else {
            setPresentationStyle(.DetailOnly, withTransitionCoordinator: coordinator)
        }
    }
    
    private func setPresentationStyle(newStyle: PresentationStyle, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator?) {
        let oldStyle = presentationStyle
        presentationStyle = newStyle
        
        if let coordinator = coordinator {
            coordinator.animateAlongsideTransition({ _ in
                self.transitionFromPresentationStyle(oldStyle, toPresentationStyle: newStyle)
            }, completion: nil)
        } else {
            transitionFromPresentationStyle(oldStyle, toPresentationStyle: newStyle)
        }
        
        view.setNeedsLayout()
        updateChildTraitCollections()
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
    
    private func animateInMasterViewControllerOverlay(completion: Void -> Void) {
        guard let master = masterViewController else {
            completion()
            return
        }
        
        animatingMasterOverlay = true
        let frames = containerFrames
        
        let button = UIButton(type: .Custom)
        button.translatesAutoresizingMaskIntoConstraints = true
        button.frame = frames.detail
        button.addTarget(self, action: Selector("dismissOverlaidMasterViewController"), forControlEvents: .TouchUpInside)
        view.addSubview(button)
        
        overlayHideButton = button
        addChildView(masterViewController, withFrame: frames.master)
        
        master.view.transform = CGAffineTransformMakeTranslation(-frames.master.size.width, 0)
        UIView.animateWithDuration(transitionDuration,
            delay: 0,
            options: .CurveEaseOut,
            animations: {
                master.view.transform = CGAffineTransformIdentity
            },
            completion: { _ in
                self.animatingMasterOverlay = false
                completion()
        })
    }
    
    private func animateOutMasterViewControllerOverlay(completion: Void -> Void) {
        guard let master = masterViewController else {
            completion()
            return
        }
        
        animatingMasterOverlay = true
        let frame = containerFrames.master
        
        UIView.animateWithDuration(transitionDuration,
            delay: 0,
            options: .CurveEaseIn,
            animations: {
                master.view.transform = CGAffineTransformMakeTranslation(-frame.size.width, 0)
            },
            completion: { _ in
                self.overlayHideButton = nil
                self.removeChildView(master)
                self.animatingMasterOverlay = false
                completion()
        })
    }
    
    private func transitionFromPresentationStyle(fromPresentationStyle: PresentationStyle, toPresentationStyle: PresentationStyle) {
        guard fromPresentationStyle != toPresentationStyle, let master = masterViewController, let detail = detailViewController else {
            return
        }
        
        notifyDelegatePrecedingChangeFromPresentationStyle(fromPresentationStyle, toPresentationStyle: toPresentationStyle)
        let postNotify = {
            self.notifyDelegateFollowingChangeFromPresentationStyle(fromPresentationStyle, toPresentationStyle: toPresentationStyle)
        }

        switch (fromPresentationStyle, toPresentationStyle) {

        case (.SideBySide, .MasterOnly):
            removeChildView(detail)
            postNotify()
            
        case (.SideBySide, .DetailOnly):
            removeChildView(master)
            postNotify()
            
        case (.DetailOnly, .MasterOverlay):
            animateInMasterViewControllerOverlay(postNotify)
        
        case (.MasterOverlay, .DetailOnly):
            animateOutMasterViewControllerOverlay(postNotify)
        
        case (.MasterOverlay, .MasterOnly):
            overlayHideButton = nil
            postNotify()

        case (.MasterOnly, .DetailOnly):
            detail.view.frame = containerFrames.detail
            crossFadeFromViewController(master, toViewController: detail, completion: postNotify)

        case (.DetailOnly, .MasterOnly):
            master.view.frame = containerFrames.master
            crossFadeFromViewController(detail, toViewController: master, completion: postNotify)

        case (.DetailOnly, .SideBySide):
            addChildView(master, withFrame: containerFrames.master)
            postNotify()
            
        case (.MasterOnly, .SideBySide):
            addChildView(detail, withFrame: containerFrames.detail)
            postNotify()
            
        case (.MasterOverlay, .SideBySide):
            overlayHideButton = nil
            postNotify()

        default:
            fatalError("illegal transition from \(fromPresentationStyle) to \(toPresentationStyle)")
        }
    }
    
    private func notifyDelegatePrecedingChangeFromPresentationStyle(fromPresentationStyle: PresentationStyle, toPresentationStyle: PresentationStyle) {
        if let master = masterViewController {
            if fromPresentationStyle.showsMaster != toPresentationStyle.showsMaster {
                delegate?.splitViewController?(self, willChangeMasterViewControllerVisibility: master)
            }
        }
        
        if let detail = detailViewController {
            if fromPresentationStyle.showsDetail != toPresentationStyle.showsDetail {
                delegate?.splitViewController?(self, willChangeDetailViewControllerVisibility: detail)
            }
        }
    }
    
    private func notifyDelegateFollowingChangeFromPresentationStyle(fromPresentationStyle: PresentationStyle, toPresentationStyle: PresentationStyle) {
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

    private func crossFadeFromViewController(from: UIViewController, toViewController to: UIViewController, completion: Void -> Void) {
        to.view.setNeedsLayout()
        transitionFromViewController(from,
            toViewController: to,
            duration: transitionDuration,
            options: [.TransitionCrossDissolve],
            animations: { },
            completion: { _ in completion() })
    }
}

private extension CGRect {
    func split(leftWidth: CGFloat) -> (left: CGRect, right: CGRect) {
        let left = CGRect(x: 0, y: 0, width: leftWidth, height: height)
        let right = CGRect(x: leftWidth, y: 0, width: width - leftWidth, height: height)
        return (left: left, right: right)
    }

    var integral: CGRect {
        return CGRect(x: round(origin.x), y: round(origin.y), width: round(size.width), height: round(size.height))
    }
}

