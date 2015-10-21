//
//  AppCoordinator.swift
//  ScotTraffic
//
//  Created by Neil Gall on 05/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit

let maximumItemsInDetailView = 10

public class AppCoordinator: NSObject, UISplitViewControllerDelegate, UINavigationControllerDelegate, UIPopoverPresentationControllerDelegate {
    let appModel: AppModel
    let storyboard: UIStoryboard
    let rootWindow: UIWindow
    
    let splitViewController: UISplitViewController
    let searchViewController: SearchViewController
    let mapViewController: MapViewController
    var collectionController: MapItemCollectionViewController?
    
    let mapViewModel: MapViewModel
    let searchViewModel: SearchViewModel
    var observations = [Observation]()
    
    public init(appModel: AppModel, rootWindow: UIWindow) {
        self.appModel = appModel
        self.rootWindow = rootWindow
        self.storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        splitViewController = rootWindow.rootViewController as! UISplitViewController
        splitViewController.presentsWithGesture = false
        
        // verify the Storyboard is structured as we expect
        guard let masterNavigationController = splitViewController.viewControllers[0] as? UINavigationController,
            let detailNavigationController = splitViewController.viewControllers[1] as? UINavigationController,
            let masterViewController = masterNavigationController.topViewController as? SearchViewController,
            let detailViewController = detailNavigationController.topViewController as? MapViewController else {
                abort()
        }
        
        searchViewController = masterViewController
        mapViewController = detailViewController
        
        searchViewModel = SearchViewModel(scotTraffic: appModel)
        searchViewController.searchViewModel = searchViewModel
        
        mapViewModel = MapViewModel(scotTraffic: appModel)
        mapViewController.viewModel = mapViewModel
        mapViewController.minimumDetailItemsForAnnotationCallout = maximumItemsInDetailView+1
    }
    
    public func start() {
        splitViewController.delegate = self
        searchViewController.navigationController?.delegate = self
        mapViewController.navigationController?.delegate = self

        // show map when search cancelled
        observations.append(searchViewModel.searchActive.filter({ $0 == false }).output({ _ in
            self.showMap()
        }))
        
        // show map when search selection changes
        observations.append(searchViewModel.searchSelection.output({ item in
            if item != nil {
                self.showMap()
            }
            self.mapViewModel.selectedMapItem.value = item
        }))
    
        // show/hide popover as map selection changes
        observations.append(mapViewController.detailMapItems.output({ detail in
            if let detail = detail where detail.flatCount <= maximumItemsInDetailView {
                self.showDetailForMapItems(detail)
            } else {
                self.hideDetail()
            }
        }))
    }
    
    func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
    }
    
    private func showDetailForMapItems(detail: DetailMapItems) {
        let model = MapItemCollectionViewModel(mapItems: detail.mapItems, fetcher: appModel.fetcher)
        
        if let collectionController = self.collectionController {
            collectionController.viewModel = model
            
        } else {
            let contentSize = preferredCollectionContentSize()
            let scroll = mapScrollDistanceToPresentContentSize(contentSize, anchoredToRect: detail.mapViewRect, inView: mapViewController.mapView)
            let anchorRect = CGRectOffset(detail.mapViewRect, scroll.x, scroll.y)
            
            mapViewController.scrollBy(x: scroll.x, y: scroll.y) {
                let collectionController = self.instantiateCollectionViewController(model, contentSize: contentSize, anchorRect: anchorRect)
                self.splitViewController.presentViewController(collectionController, animated: true, completion: nil)
                self.collectionController = collectionController
            }
        }
    }
    
    private func instantiateCollectionViewController(model: MapItemCollectionViewModel, contentSize: CGSize, anchorRect: CGRect) -> MapItemCollectionViewController {
        guard let collectionController = self.storyboard.instantiateViewControllerWithIdentifier("mapItemCollectionViewController") as? MapItemCollectionViewController else {
            abort()
        }
        
        collectionController.viewModel = model
        collectionController.modalPresentationStyle = .Popover
        collectionController.preferredContentSize = contentSize

        if let popover = collectionController.popoverPresentationController {
            popover.backgroundColor = UIColor.blackColor()
            popover.permittedArrowDirections = self.permittedArrowDirectionsForCurrentSizeClass()
            popover.sourceRect = anchorRect
            popover.sourceView = self.mapViewController.mapView
            popover.delegate = self
        }
    
        return collectionController
    }
    
    private func preferredCollectionContentSize() -> CGSize {
        if splitViewController.traitCollection.horizontalSizeClass == .Compact {
            // inset from the screen edges
            if aspectIsPortrait() {
                return preferredCollectionContentSizeForWidth(CGRectGetWidth(splitViewController.view.frame)-20)
            } else {
                return preferredCollectionContentSizeForHeight(CGRectGetHeight(splitViewController.view.frame)-20)
            }
        } else {
            // maximum size
            return preferredCollectionContentSizeForWidth(480)
        }
    }
    
    private func preferredCollectionContentSizeForWidth(width: CGFloat) -> CGSize {
        return CGSizeMake(width, width*0.75+64)
    }
    
    private func preferredCollectionContentSizeForHeight(height: CGFloat) -> CGSize {
        return CGSizeMake((height-64)/0.75, height)
    }
    
    private func permittedArrowDirectionsForCurrentSizeClass() -> UIPopoverArrowDirection {
        if splitViewController.traitCollection.horizontalSizeClass == .Compact {
            if aspectIsPortrait() {
                return [.Up, .Down]
            } else {
                return [.Left, .Right]
            }
        } else {
            return .Any
        }
    }
    
    private func aspectIsPortrait() -> Bool {
        return CGRectGetWidth(splitViewController.view.bounds) < CGRectGetHeight(splitViewController.view.bounds)
    }
    
    private func mapScrollDistanceToPresentContentSize(contentSize: CGSize, anchoredToRect anchorRect: CGRect, inView view: UIView) -> (x: CGFloat, y: CGFloat) {
        let splitViewAnchor = splitViewController.view.convertRect(anchorRect, fromView: view)
        
        let contentTopIfAbove = CGRectGetMinY(splitViewAnchor) - contentSize.height - 23
        let contentBottomIfBelow = CGRectGetMaxY(splitViewAnchor) + contentSize.height + 23
        let contentLeftIfToLeft = CGRectGetMinX(splitViewAnchor) - contentSize.width - 23
        let contentRightIfToRight = CGRectGetMaxX(splitViewAnchor) + contentSize.width + 23
        var presentContainer = CGRectInset(splitViewController.view.frame, 10, 10)
        
        // account for status bar
        presentContainer.origin.y += 20
        presentContainer.size.height -= 20

        let scrollUp = contentBottomIfBelow - CGRectGetMaxY(presentContainer)
        let scrollDown = CGRectGetMinY(presentContainer) - contentTopIfAbove
        let scrollLeft = contentRightIfToRight - CGRectGetMaxX(presentContainer)
        let scrollRight = CGRectGetMinX(presentContainer) - contentLeftIfToLeft

        if scrollUp > 0 && scrollDown > 0 && scrollLeft > 0 && scrollRight > 0 {
            if scrollUp < scrollDown && scrollUp < scrollLeft && scrollUp < scrollRight {
                return (x: 0, y: -scrollUp)
            } else if scrollDown < scrollLeft && scrollDown < scrollRight {
                return (x: 0, y: scrollDown)
            } else if scrollLeft < scrollRight {
                return (x: -scrollLeft, y: 0)
            } else {
                return (x: scrollRight, y: 0)
            }
        }
        
        return (x: 0, y: 0)
    }
    
    private func hideDetail() {
        splitViewController.dismissViewControllerAnimated(true, completion: nil)
        collectionController = nil
    }
    
    private func showMap() {
        if let nav = mapViewController.navigationController {
            splitViewController.showDetailViewController(nav, sender: self)
        }
    }
    
    // -- MARK: UISplitViewControllerDelegate --
    
    public func splitViewController(svc: UISplitViewController, willChangeToDisplayMode displayMode: UISplitViewControllerDisplayMode) {
    }
    
    // -- MARK: UINavigationControllerDelegate --
    
    public func navigationController(navigationController: UINavigationController, animationControllerForOperation operation: UINavigationControllerOperation, fromViewController fromVC: UIViewController, toViewController toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        if navigationController === searchViewController.navigationController {
            if toVC === searchViewController || toVC === mapViewController.navigationController {
                return FadeTranstion()
            }
        }
        
        return nil
    }
    
    // -- MARK: UIPopoverPresentationControllerDelegate --
    
    public func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.None
    }
    
    public func popoverPresentationControllerDidDismissPopover(popoverController: UIPopoverPresentationController) {
        self.collectionController = nil
        self.mapViewController.detailMapItems.value = nil
        self.mapViewModel.selectedMapItem.value = nil
    }
}