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
    var popoverPresentation: PopoverPresentation
    
    let mapViewModel: MapViewModel
    let searchViewModel: SearchViewModel
    let collectionViewModel: MapItemCollectionViewModel
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
        
        let collectionMapItems = mapViewController.detailMapItems.map({ $0?.mapItems ?? [] })
        collectionViewModel = MapItemCollectionViewModel(
            mapItems: collectionMapItems,
            
            selection: searchViewModel.searchSelection,
            fetcher: appModel.fetcher,
            favourites: appModel.favourites)
        
        popoverPresentation = PopoverPresentation(traitCollection: splitViewController.traitCollection,
            viewBounds: splitViewController.view.bounds)
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
        popoverPresentation = PopoverPresentation(traitCollection: splitViewController.traitCollection,
            viewBounds: splitViewController.view.bounds)
    }
    
    private func showDetailForMapItems(detail: DetailMapItems) {
        if let collectionController = self.collectionController {
            collectionController.viewModel = collectionViewModel
            
        } else {
            let anchorRect = splitViewController.view.convertRect(detail.mapViewRect, fromView: mapViewController.mapView)
            let contentSize = popoverPresentation.preferredCollectionContentSize
            let scroll = popoverPresentation.mapScrollDistanceToPresentContentSize(contentSize, anchoredToRect: anchorRect)
            let offsetAnchorRect = CGRectOffset(detail.mapViewRect, scroll.x, scroll.y)
            
            mapViewController.scrollBy(x: scroll.x, y: scroll.y) {
                let collectionController = self.instantiateCollectionViewController(contentSize, anchorRect: offsetAnchorRect)
                self.splitViewController.presentViewController(collectionController, animated: true, completion: nil)
                self.collectionController = collectionController
            }
        }
    }
    
    private func instantiateCollectionViewController(contentSize: CGSize, anchorRect: CGRect) -> MapItemCollectionViewController {
        guard let collectionController = self.storyboard.instantiateViewControllerWithIdentifier("mapItemCollectionViewController") as? MapItemCollectionViewController else {
            abort()
        }
        
        collectionController.viewModel = collectionViewModel
        collectionController.modalPresentationStyle = .Popover
        collectionController.preferredContentSize = contentSize

        if let popover = collectionController.popoverPresentationController {
            popover.backgroundColor = UIColor.blackColor()
            popover.permittedArrowDirections = popoverPresentation.permittedArrowDirections
            popover.sourceRect = anchorRect
            popover.sourceView = self.mapViewController.mapView
            popover.delegate = self
        }
    
        return collectionController
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