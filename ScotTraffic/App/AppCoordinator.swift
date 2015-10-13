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
    
        observations.append(mapViewController.detailMapItems.output(self.showDetailForMapItems))
    }
    
    private func showDetailForMapItems(detail: DetailMapItems?) {
        if let detail = detail {
            let model = MapItemCollectionViewModel(mapItems: detail.mapItems)
        
            if let collectionController = self.collectionController {
                collectionController.viewModel = model
            
            } else {
                self.collectionController = storyboard.instantiateViewControllerWithIdentifier("mapItemCollectionViewController") as? MapItemCollectionViewController
                if let collectionController = self.collectionController {
                    let splitViewRect = splitViewController.view.convertRect(detail.mapViewRect, fromView: mapViewController.view)
                    collectionController.viewModel = model
                    popoverController = UIPopoverController(contentViewController: collectionController)
                    popoverController?.popoverContentSize = CGSizeMake(480, 380)
                    popoverController?.delegate = self
                    popoverController?.presentPopoverFromRect(splitViewRect, inView: self.splitViewController.view, permittedArrowDirections: .Any, animated: true)
                }
            }
        } else {
            popoverController?.dismissPopoverAnimated(true)
            popoverController = nil
            collectionController = nil
        }
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
        self.mapViewModel.selectedMapItem.value = nil
    }
}