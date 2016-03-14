//
//  AppCoordinator.swift
//  ScotTraffic
//
//  Created by Neil Gall on 05/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit

let maximumItemsInDetailView = 10

class AppCoordinator: NSObject {
    let appModel: AppModel
    let rootWindow: UIWindow
    let httpAccess: HTTPAccess
    
    let storyboard: UIStoryboard
    let splitViewController: NGSplitViewController
    let searchViewController: FavouritesAndSearchViewController
    let mapViewController: MapViewController
    var collectionController: MapItemCollectionViewController?
    
    let mapViewModel: MapViewModel
    let favouritesAndSearchViewModel: FavouritesAndSearchViewModel
    let collectionViewModel: MapItemCollectionViewModel
    var receivers = [ReceiverType]()
    
    init(appModel: AppModel, httpAccess: HTTPAccess, rootWindow: UIWindow) {
        self.appModel = appModel
        self.httpAccess = httpAccess
        self.rootWindow = rootWindow
        
        // Verify storyboard structure
        guard
            let splitViewController = rootWindow.rootViewController as? NGSplitViewController,
            let storyboard = splitViewController.storyboard,
            let masterNavigationController = storyboard.instantiateViewControllerWithIdentifier("searchNavigationController") as? UINavigationController,
            let detailNavigationController = storyboard.instantiateViewControllerWithIdentifier("mapNavigationController") as? UINavigationController,
            let searchViewController = masterNavigationController.topViewController as? FavouritesAndSearchViewController,
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
        
        favouritesAndSearchViewModel = FavouritesAndSearchViewModel(scotTraffic: appModel)
        searchViewController.viewModel = favouritesAndSearchViewModel
        
        mapViewModel = MapViewModel(scotTraffic: appModel, maximumItemsInDetailView: maximumItemsInDetailView)
        mapViewController.viewModel = mapViewModel
        
        collectionViewModel = MapItemCollectionViewModel(scotTraffic: appModel, selection: favouritesAndSearchViewModel.contentSelection)
    }
    
    func start() {
        splitViewController.delegate = self

        mapViewController.calloutConstructor = viewControllerWithMapItems
        mapViewController.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named:"740-gear"), style: .Plain, target: self, action: Selector("settingsButtonTapped:"))

        // network reachability
        receivers.append(httpAccess.serverIsReachable.onFallingEdge(notifyNoNetworkReachability))

        // message of the day
        receivers.append(appModel.messageOfTheDay --> showMessageOfTheDay)
        
        // show map when search cancelled
        receivers.append(favouritesAndSearchViewModel.searchActive.onFallingEdge(showMap))
        
        // show map when search selection changes
        receivers.append(favouritesAndSearchViewModel.contentSelection --> contentSelectionChanged)
        
        // sharing
        receivers.append(collectionViewModel.shareAction --> shareAction)
        
        // remote notifications
        receivers.append(appModel.remoteNotifications.zoomToBridge --> { [weak self] in
            if let bridge = $0, my = self {
                dispatch_async(dispatch_get_main_queue()) {
                    my.mapViewModel.selectedMapItem <-- bridge
                    my.appModel.remoteNotifications.clear()
                }
            }
        })
        
        receivers.append(appModel.remoteNotifications.showNotification --> { [weak self] in
            if let message = $0, my = self {
                dispatch_async(dispatch_get_main_queue()) {
                    my.showNotificationMessage(message)
                    my.appModel.remoteNotifications.clear()
                }
            }
        })
        
        receivers.append(appModel.settings.searchViewPinned --> { [weak self] pinned in
            self?.splitViewController.changePresentationStyle()
            self?.updateCancelOrPinSearchButton()
        })
        
        updateShowSearchButton()
        updateCancelOrPinSearchButton()
    
        // defer any initial reachability notification until the view has appeared
        dispatch_async(dispatch_get_main_queue()) {
            self.httpAccess.startReachabilityNotifier()
        }
    }

    private func viewControllerWithMapItems(mapItems: [MapItem]) -> UIViewController {
        collectionViewModel.mapItems <-- mapItems

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
    
    private func contentSelectionChanged(selection: Search.Selection) {
        guard case .Item(let mapItem, _) = selection else {
            return
        }
        
        showMap()
        mapViewModel.selectedMapItem <-- mapItem
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
    
    private func updateCancelOrPinSearchButton() {
        let canPinSearch = canPinSearchView(splitViewController.traitCollection.horizontalSizeClass,
            width: splitViewController.view.bounds.width)
        
        if canPinSearch {
            let pinned = appModel.settings.searchViewPinned.latestValue.get ?? false
            let image = UIImage(named: pinned ? "940-pin-selected" : "940-pin")
            let button = UIBarButtonItem(image: image, style: .Plain, target: self, action: Selector("pinSearchButtonTapped:"))
            searchViewController.navigationItem.rightBarButtonItem = button

        } else if splitViewController.detailViewControllerIsVisible {
            searchViewController.navigationItem.rightBarButtonItem = nil
        
        } else {
            searchViewController.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: Selector("searchDoneButtonTapped:"))
        }
    }
    
    private func canPinSearchView(horizontalSizeClass: UIUserInterfaceSizeClass, width: CGFloat) -> Bool {
        return horizontalSizeClass == .Regular && width > 768
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
            self.collectionViewModel.shareAction <-- nil
        }
        
        analyticsEvent(.ShareItem, ["name": action.item.name])
    }
    
    private func notifyNoNetworkReachability() {
        let alert = UIAlertController(title: "No Internet Connection", message: "Your device is not connected to the internet. The most recently available information is being shown.", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
        splitViewController.presentViewController(alert, animated: true, completion: nil)
    }
    
    private func showMessageOfTheDay(message: MessageOfTheDay?) {
        guard let message = message else {
            return
        }
        let alert = UIAlertController(title: message.title, message: message.body, preferredStyle: .Alert)
    
        alert.addAction(UIAlertAction(title: "Close", style: .Default) { _ in
            self.splitViewController.dismissViewControllerAnimated(true, completion: nil)
        })
        
        if let url = message.url {
            alert.addAction(UIAlertAction(title: "More...", style: .Default) { _ in
                self.splitViewController.dismissViewControllerAnimated(true, completion: nil)
                UIApplication.sharedApplication().openURL(url)
            })
        }
    
        splitViewController.presentViewController(alert, animated: true, completion: nil)
    }
    
    private func showNotificationMessage(message: String?) {
        if let message = message {
            splitViewController.showNotificationMessage(message)
        }
    }

    // -- MARK: UI Actions --
    
    func searchButtonTapped(button: UIBarButtonItem) {
        analyticsEvent(.Search)
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
        
        analyticsEvent(.Settings)
        
        navigationController.modalPresentationStyle = .Popover
        if let popover = navigationController.popoverPresentationController {
            popover.barButtonItem = button
            popover.permittedArrowDirections = .Any
        }
        
        settingsViewController.settings = appModel.settings
        settingsViewController.serverIsReachable = httpAccess.serverIsReachable
        settingsViewController.preferredContentSize = CGSize(width: 320, height: 650)
        settingsViewController.delegate = self
        
        splitViewController.presentViewController(navigationController, animated: true, completion: nil)
    }
    
    func pinSearchButtonTapped(button: UIBarButtonItem) {
        appModel.settings.searchViewPinned.modify {
            return !$0
        }
    }
}

extension AppCoordinator: NGSplitViewControllerDelegate {

    func splitViewController(splitViewController: NGSplitViewController, shouldShowMasterViewControllerForHorizontalSizeClass horizontalSizeClass: UIUserInterfaceSizeClass, viewWidth: CGFloat) -> Bool {
        let pinned = appModel.settings.searchViewPinned.latestValue.get ?? false
        return canPinSearchView(horizontalSizeClass, width: viewWidth) && pinned
    }
    
    func splitViewController(splitViewController: NGSplitViewController, didChangeMasterViewControllerVisibility viewController: UIViewController) {
        updateShowSearchButton()
        updateCancelOrPinSearchButton()
    }

    func splitViewController(splitViewController: NGSplitViewController, willChangeDetailViewControllerVisibility viewController: UIViewController) {
        mapViewModel.animatingVisibility <-- true
    }
    
    func splitViewController(splitViewController: NGSplitViewController, didChangeDetailViewControllerVisibility viewController: UIViewController) {
        updateCancelOrPinSearchButton()
        mapViewModel.animatingVisibility <-- false
    }
}

extension AppCoordinator : SettingsTableViewControllerDelegate {

    func settingsViewControllerDidDismiss(settingsViewController: SettingsTableViewController) {
        splitViewController.dismissViewControllerAnimated(true, completion: nil)
    }
}
