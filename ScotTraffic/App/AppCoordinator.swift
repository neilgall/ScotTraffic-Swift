//
//  AppCoordinator.swift
//  ScotTraffic
//
//  Created by Neil Gall on 05/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit

let maximumItemsInDetailView = 10

public class AppCoordinator: NSObject, NGSplitViewControllerDelegate, SettingsTableViewControllerDelegate {
    let appModel: AppModel
    let rootWindow: UIWindow
    
    let storyboard: UIStoryboard
    let splitViewController: NGSplitViewController
    let searchViewController: SearchViewController
    let mapViewController: MapViewController
    var collectionController: MapItemCollectionViewController?
    
    let mapViewModel: MapViewModel
    let searchViewModel: SearchViewModel
    let collectionViewModel: MapItemCollectionViewModel
    var receivers = [ReceiverType]()
    
    public init(appModel: AppModel, rootWindow: UIWindow) {
        self.appModel = appModel
        self.rootWindow = rootWindow
        
        // Verify storyboard structure
        guard
            let splitViewController = rootWindow.rootViewController as? NGSplitViewController,
            let storyboard = splitViewController.storyboard,
            let masterNavigationController = storyboard.instantiateViewControllerWithIdentifier("searchNavigationController") as? UINavigationController,
            let detailNavigationController = storyboard.instantiateViewControllerWithIdentifier("mapNavigationController") as? UINavigationController,
            let searchViewController = masterNavigationController.topViewController as? SearchViewController,
            let mapViewController = detailNavigationController.topViewController as? MapViewController
        else {
            fatalError("Unexpected storyboard structure")
        }
        
        self.storyboard = storyboard
        self.splitViewController = splitViewController
        self.searchViewController = searchViewController
        self.mapViewController = mapViewController
        
        splitViewController.masterViewController = masterNavigationController
        splitViewController.detailViewController = detailNavigationController
        
        searchViewModel = SearchViewModel(scotTraffic: appModel)
        searchViewController.searchViewModel = searchViewModel
        
        mapViewModel = MapViewModel(scotTraffic: appModel)
        mapViewController.viewModel = mapViewModel
        mapViewController.maximumDetailItemsForCollectionCallout = maximumItemsInDetailView
        
        collectionViewModel = MapItemCollectionViewModel(scotTraffic: appModel, selection: searchViewModel.searchSelection)
    }
    
    public func start() {
        splitViewController.delegate = self

        mapViewController.calloutConstructor = viewControllerWithMapItems
        mapViewController.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named:"740-gear"), style: .Plain, target: self, action: Selector("settingsButtonTapped:"))

        // network reachability
        receivers.append(appModel.httpAccess.serverIsReachable.onFallingEdge(notifyNoNetworkReachability))
        
        // show map when search cancelled
        receivers.append(searchViewModel.searchActive.onFallingEdge(showMap))
        
        // show map when search selection changes
        receivers.append(searchViewModel.searchSelection --> searchSelectionChanged)
        
        // sharing
        receivers.append(collectionViewModel.shareAction --> shareAction)
        
        updateShowSearchButton()
        updateCancelSearchButton()
    
        // defer any initial reachability notification until the view has appeared
        dispatch_async(dispatch_get_main_queue()) {
            self.appModel.httpAccess.startReachabilityNotifier()
        }
    }

    private func viewControllerWithMapItems(mapItems: [MapItem]) -> UIViewController {
        collectionViewModel.mapItems.value = mapItems

        guard let collectionController = self.storyboard.instantiateViewControllerWithIdentifier("mapItemCollectionViewController") as? MapItemCollectionViewController else {
            fatalError("Unable to instantiate mapItemCollectionViewController from storyboard")
        }
        
        collectionController.viewModel = collectionViewModel
        collectionController.preferredContentSize = popoverContentSize(mapViewController.traitCollection, viewBounds: mapViewController.mapView.bounds)
        return collectionController
    }
    
    private func hideDetail() {
        mapViewController.deselectAnnotationsAnimated(true)
        collectionController = nil
    }
    
    private func searchSelectionChanged(selection: SearchViewModel.Selection?) {
        if selection != nil {
            showMap()
        }
        
        // FIXME: This is to guard against rapid taps in the search view controller racing with the
        // map view and callout animations. Need a better, more general solution to queue requests
        // or cancel the imperative and latent consequences of earlier updates.
        
        if mapViewModel.selectedMapItem.value == nil {
            mapViewModel.selectedMapItem.value = selection?.mapItem
        }
    }
    
    private func showMap() {
        splitViewController.dismissOverlaidMasterViewController()
    }
    
    private func updateShowSearchButton() {
        if splitViewController.masterViewControllerIsVisible {
            mapViewController.navigationItem.leftBarButtonItem = nil
        } else {
            mapViewController.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "708-search"), style: .Plain, target: self, action: Selector("searchButtonTapped:"))
        }
    }
    
    private func updateCancelSearchButton() {
        if splitViewController.detailViewControllerIsVisible {
            searchViewController.navigationItem.rightBarButtonItem = nil
        } else {
            searchViewController.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: Selector("searchDoneButtonTapped:"))
        }
    }
    
    private func shareAction(action: ShareAction?) {
        guard let action = action else {
            return
        }
        
        var activityItems: [AnyObject] = [ action.item.text ]
        if let link = action.item.link {
            activityItems.append(link)
        }
        if let image = action.item.image {
            activityItems.append(image)
        }
        
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        controller.modalPresentationStyle = .Popover
        controller.popoverPresentationController?.sourceView = action.sourceView
        controller.popoverPresentationController?.sourceRect = action.sourceRect
        
        splitViewController.presentViewController(controller, animated: true) {
            self.collectionViewModel.shareAction.value = nil
        }
    }
    
    private func notifyNoNetworkReachability() {
        let alert = UIAlertController(title: "No Internet Connection", message: "Your device is not connected to the internet. The most recently available information is being shown.", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
        splitViewController.presentViewController(alert, animated: true, completion: nil)
    }
    
    // -- MARK: NGSplitViewControllerDelegate --
    
    public func splitViewController(splitViewController: NGSplitViewController, shouldShowMasterViewControllerForHorizontalSizeClass horizontalSizeClass: UIUserInterfaceSizeClass, viewWidth: CGFloat) -> Bool {
        return horizontalSizeClass == .Regular && viewWidth > 768
    }
    
    public func splitViewController(splitViewController: NGSplitViewController, didChangeMasterViewControllerVisibility viewController: UIViewController) {
        updateShowSearchButton()
    }
    
    public func splitViewController(splitViewController: NGSplitViewController, didChangeDetailViewControllerVisibility viewController: UIViewController) {
        updateCancelSearchButton()
    }
    
    // -- MARK: UI Actions --
    
    func searchButtonTapped(button: UIBarButtonItem) {
        mapViewController.deselectAnnotationsAnimated(false)
        splitViewController.overlayMasterViewController()
    }
    
    func searchDoneButtonTapped(button: UIBarButtonItem) {
        splitViewController.dismissOverlaidMasterViewController()
    }
    
    func settingsButtonTapped(button: UIBarButtonItem) {
        guard let navigationController = storyboard.instantiateViewControllerWithIdentifier("settingsNavigationController") as? UINavigationController,
            let settingsViewController = navigationController.topViewController as? SettingsTableViewController else {
                fatalError("unexpected storyboard structure")
        }
        
        navigationController.modalPresentationStyle = .Popover
        if let popover = navigationController.popoverPresentationController {
            popover.barButtonItem = button
            popover.permittedArrowDirections = .Any
        }

        settingsViewController.settings = appModel.settings
        settingsViewController.serverIsReachable = appModel.httpAccess.serverIsReachable
        settingsViewController.preferredContentSize = CGSize(width: 320, height: 650)
        settingsViewController.delegate = self

        splitViewController.presentViewController(navigationController, animated: true, completion: nil)
    }
    
    // -- MARK: SettingsTableViewControllerDelegate
    
    func settingsViewControllerDidDismiss(settingsViewController: SettingsTableViewController) {
        splitViewController.dismissViewControllerAnimated(true, completion: nil)
    }
}