//
//  AppCoordinator.swift
//  ScotTraffic
//
//  Created by Neil Gall on 05/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit

public class AppCoordinator: UISplitViewControllerDelegate {
    let appModel: AppModel
    let rootWindow: UIWindow
    let splitViewController: UISplitViewController
    let searchViewController: SearchViewController
    let mapViewController: MapViewController
    
    public init(appModel: AppModel, rootWindow: UIWindow) {
        self.appModel = appModel
        self.rootWindow = rootWindow
        
        splitViewController = rootWindow.rootViewController as! UISplitViewController
        splitViewController.presentsWithGesture = false
        
        searchViewController = (splitViewController.viewControllers[0] as! UINavigationController).topViewController as! SearchViewController
        mapViewController = (splitViewController.viewControllers[1] as! UINavigationController).topViewController as! MapViewController
        
        searchViewController.searchViewModel = SearchViewModel(appModel: appModel)
        searchViewController.favouritesViewModel = FavouritesViewModel(favourites: appModel.favourites)
        searchViewController.coordinator = self
        
        mapViewController.viewModel = MapViewModel(appModel: appModel)
    }
    
    public func start() {
        splitViewController.delegate = self
    }
    
    public func cancelSearch() {
        splitViewController.showDetailViewController(mapViewController, sender: self)
        mapViewController.deselectAnnotations()
    }
    
    public func zoomToMapItem(item: MapItem) {
        splitViewController.showDetailViewController(mapViewController, sender: self)
        mapViewController.zoomToMapItem(item, animated: true)
    }
    
    // -- MARK: UISplitViewControllerDelegate --
    
    @objc public func splitViewController(svc: UISplitViewController, willChangeToDisplayMode displayMode: UISplitViewControllerDisplayMode) {
    }
}