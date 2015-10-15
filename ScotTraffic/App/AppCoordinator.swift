//
//  AppCoordinator.swift
//  ScotTraffic
//
//  Created by Neil Gall on 05/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit

public class AppCoordinator: NSObject, UISplitViewControllerDelegate, UIPopoverControllerDelegate {
    let appModel: AppModel
    let storyboard: UIStoryboard
    let rootWindow: UIWindow
    
    let splitViewController: UISplitViewController
    let searchViewController: SearchViewController
    let mapViewController: MapViewController
    var popoverController: UIPopoverController?
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
            if let detail = detail where detail.flatCount < 20 {
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
            
            let popoverController = UIPopoverController(contentViewController: collectionController)
            popoverController.popoverContentSize = CGSizeMake(480, 380)
            popoverController.delegate = self
            
            let splitViewRect = splitViewController.view.convertRect(detail.mapViewRect, fromView: mapViewController.mapView)
            popoverController.presentPopoverFromRect(splitViewRect, inView: self.splitViewController.view, permittedArrowDirections: UIPopoverArrowDirection.Any, animated: true)
            
            self.collectionController = collectionController
            self.popoverController = popoverController
        }
    }
    
    private func hideDetail() {
        popoverController?.dismissPopoverAnimated(true)
        popoverController = nil
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
    
    // -- MARK: UIPopoverControllerDelegate --
    
    public func popoverControllerDidDismissPopover(popoverController: UIPopoverController) {
        self.popoverController = nil
        self.collectionController = nil
        self.mapViewController.detailMapItems.value = nil
        self.mapViewModel.selectedMapItem.value = nil
    }
}