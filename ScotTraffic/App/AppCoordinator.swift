//
//  AppCoordinator.swift
//  ScotTraffic
//
//  Created by Neil Gall on 05/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit

let maximumItemsInDetailView = 10

public class AppCoordinator: NSObject, UISplitViewControllerDelegate, UIPopoverPresentationControllerDelegate {
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
        
        searchViewController = (splitViewController.viewControllers[0] as! UINavigationController).topViewController as! SearchViewController
        mapViewController = (splitViewController.viewControllers[1] as! UINavigationController).topViewController as! MapViewController
        
        searchViewModel = SearchViewModel(scotTraffic: appModel)
        searchViewController.searchViewModel = searchViewModel
        
        mapViewModel = MapViewModel(scotTraffic: appModel)
        mapViewController.viewModel = mapViewModel
        mapViewController.minimumDetailItemsForAnnotationCallout = maximumItemsInDetailView+1
    }
    
    public func start() {
        splitViewController.delegate = self

        observations.append(searchViewModel.searchSelection.output({ item in
            if item != nil {
                self.showMap()
            }
            self.mapViewModel.selectedMapItem.value = item
        }))
    
        observations.append(mapViewController.detailMapItems.output({ detail in
            if let detail = detail where detail.flatCount <= maximumItemsInDetailView {
                self.showDetailForMapItems(detail)
            } else {
                self.hideDetail()
            }
        }))
    }
    
    private func showDetailForMapItems(detail: DetailMapItems) {
        let model = MapItemCollectionViewModel(mapItems: detail.mapItems, fetcher: appModel.fetcher)
        
        if let collectionController = self.collectionController {
            collectionController.viewModel = model
            
        } else {
            guard let collectionController = storyboard.instantiateViewControllerWithIdentifier("mapItemCollectionViewController") as? MapItemCollectionViewController else {
                abort()
            }
            collectionController.viewModel = model
            collectionController.modalPresentationStyle = .Popover
            collectionController.preferredContentSize = CGSizeMake(480, 384)
            
            if let popover = collectionController.popoverPresentationController {
                popover.permittedArrowDirections = .Any
                popover.sourceRect = detail.mapViewRect
                popover.sourceView = mapViewController.mapView
                popover.delegate = self
            }
            
            splitViewController.presentViewController(collectionController, animated: true, completion: nil)

            self.collectionController = collectionController
        }
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