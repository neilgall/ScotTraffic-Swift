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
    
    public init(appModel: AppModel, rootWindow: UIWindow) {
        self.appModel = appModel
        self.rootWindow = rootWindow
        self.storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        splitViewController = rootWindow.rootViewController as! UISplitViewController
        splitViewController.presentsWithGesture = false
        
        searchViewController = (splitViewController.viewControllers[0] as! UINavigationController).topViewController as! SearchViewController
        mapViewController = (splitViewController.viewControllers[1] as! UINavigationController).topViewController as! MapViewController
        
        searchViewController.searchViewModel = SearchViewModel(appModel: appModel)
        searchViewController.favouritesViewModel = FavouritesViewModel(favourites: appModel.favourites)
        
        mapViewModel = MapViewModel(appModel: appModel)
        mapViewController.viewModel = mapViewModel

        super.init()
        searchViewController.coordinator = self
        mapViewController.coordinator = self
    }
    
    public func start() {
        splitViewController.delegate = self
    }
    
    public func cancelSearch() {
        showMap()
        mapViewController.deselectAnnotations()
    }
    
    public func zoomToMapItem(item: MapItem) {
        showMap()
        mapViewModel.selectedMapItem.value = item
    }
    
    public func showDetailForMapItems(mapItems: [MapItem], fromRectInMapView rect: CGRect) {
        let model = MapItemCollectionViewModel(mapItems: mapItems)
        
        if let collectionController = self.collectionController {
            collectionController.viewModel = model
            
        } else {
            self.collectionController = storyboard.instantiateViewControllerWithIdentifier("mapItemCollectionViewController") as? MapItemCollectionViewController
            if let collectionController = self.collectionController {
                let splitViewRect = splitViewController.view.convertRect(rect, fromView: mapViewController.view)
                collectionController.viewModel = model
                popoverController = UIPopoverController(contentViewController: collectionController)
                popoverController?.popoverContentSize = CGSizeMake(480, 380)
                popoverController?.delegate = self
                popoverController?.presentPopoverFromRect(splitViewRect, inView: self.splitViewController.view, permittedArrowDirections: .Any, animated: true)
            }
        }
    }
    
    public func hideMapItemDetail() {
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
        self.mapViewModel.selectedMapItem.value = nil
    }
}