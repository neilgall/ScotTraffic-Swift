//
//  AppCoordinator.swift
//  ScotTraffic
//
//  Created by Neil Gall on 05/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit

let maximumItemsInDetailView = 10

public class AppCoordinator: NSObject, NGSplitViewControllerDelegate, UINavigationControllerDelegate {
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
    var observations = [Observation]()
    
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
        
        collectionViewModel = MapItemCollectionViewModel(
            selection: searchViewModel.searchSelection,
            fetcher: appModel.fetcher,
            favourites: appModel.favourites)
    }
    
    public func start() {
        splitViewController.delegate = self
        searchViewController.navigationController?.delegate = self
        mapViewController.navigationController?.delegate = self
        mapViewController.calloutConstructor = viewControllerWithMapItems

        // show map when search cancelled
        observations.append(searchViewModel.searchActive.filter({ $0 == false }).output({ _ in
            self.showMap()
        }))
        
        // show map when search selection changes
        observations.append(searchViewModel.searchSelection.output({ selection in
            if selection != nil {
                self.showMap()
            }
            self.mapViewModel.selectedMapItem.value = selection?.mapItem
        }))
        
        // sharing
        observations.append(collectionViewModel.shareAction.filter({ $0 != nil }).output({ action in
            self.shareAction(action!)
        }))
        
        updateShowSearchButton()
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
        mapViewController.deselectAnnotations()
        collectionController = nil
    }
    
    private func showMap() {
        splitViewController.dismissOverlaidMasterViewController()
    }
    
    private func dismissCollectionPopoverAnimated(animated: Bool) {
        if collectionController != nil {
            splitViewController.dismissViewControllerAnimated(animated, completion: nil)
            collectionController = nil
        }
    }
    
    private func updateShowSearchButton() {
        if splitViewController.masterViewControllerIsVisible {
            mapViewController.navigationItem.leftBarButtonItem = nil
        } else {
            mapViewController.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "708-search"), style: .Plain, target: self, action: Selector("searchButtonTapped"))
        }
    }
    
    private func shareAction(action: ShareAction) {
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
    
    // -- MARK: NGSplitViewControllerDelegate --
    
    public func splitViewController(splitViewController: NGSplitViewController, didChangeMasterViewControllerVisibility viewController: UIViewController) {
        updateShowSearchButton()
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
    
    // -- MARK: UI Actions --
    
    func searchButtonTapped() {
        dismissCollectionPopoverAnimated(true)
        splitViewController.overlayMasterViewController()
    }
}