//
//  AppCoordinator.swift
//  ScotTraffic
//
//  Created by Neil Gall on 05/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit

let maximumItemsInDetailView = 10

public class AppCoordinator: NSObject, NGSplitViewControllerDelegate, UINavigationControllerDelegate, UIPopoverPresentationControllerDelegate {
    let appModel: AppModel
    let rootWindow: UIWindow
    
    let storyboard: UIStoryboard
    let splitViewController: NGSplitViewController
    let searchViewController: SearchViewController
    let mapViewController: MapViewController
    var collectionController: MapItemCollectionViewController?
    let popoverPresentation: Input<PopoverPresentation>
    
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
            abort()
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
        mapViewController.minimumDetailItemsForAnnotationCallout = maximumItemsInDetailView+1
        
        let selectionMapItems = mapViewController.mapSelection.map({ selection in
            selection?.mapItems ?? []
        })
        
        collectionViewModel = MapItemCollectionViewModel(
            mapItems: selectionMapItems,
            selection: searchViewModel.searchSelection,
            fetcher: appModel.fetcher,
            favourites: appModel.favourites)
        
        popoverPresentation = Input(initial: PopoverPresentation(traitCollection: splitViewController.traitCollection, viewBounds: splitViewController.view.bounds))
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
        observations.append(searchViewModel.searchSelection.output({ selection in
            if selection != nil {
                self.showMap()
            }
            self.mapViewModel.selectedMapItem.value = selection?.mapItem
        }))
    
        // show/hide popover as map selection and popover presentation change
        let popover = combine(mapViewController.mapSelection, popoverPresentation) { ($0,$1) }
        
        observations.append(popover.output({ (selection, presentation)->Void in
            if let selection = selection where selection.mapItems.flatCount <= maximumItemsInDetailView {
                self.showDetailForMapSelection(selection, presentation: presentation)
            } else {
                self.hideDetail()
            }
        }))
        
        updateShowSearchButton()
    }
    
    private func showDetailForMapSelection(selection: MapSelection, presentation: PopoverPresentation) {
        if let collectionController = self.collectionController {
            collectionController.viewModel = collectionViewModel
            
        } else {
            let anchorRect = splitViewController.view.convertRect(selection.mapViewRect, fromView: mapViewController.mapView)
            let contentSize = presentation.preferredCollectionContentSize
            let scroll = presentation.mapScrollDistanceToPresentContentSize(contentSize, anchoredToRect: anchorRect)
            let offsetAnchorRect = CGRectOffset(selection.mapViewRect, scroll.x, scroll.y)
            
            mapViewController.scrollBy(x: scroll.x, y: scroll.y) {
                let collectionController = self.instantiateCollectionViewController(contentSize, anchorRect: offsetAnchorRect, presentation: presentation)
                self.splitViewController.presentViewController(collectionController, animated: true, completion: nil)
                self.collectionController = collectionController
            }
        }
    }
    
    private func instantiateCollectionViewController(contentSize: CGSize, anchorRect: CGRect, presentation: PopoverPresentation) -> MapItemCollectionViewController {
        guard let collectionController = self.storyboard.instantiateViewControllerWithIdentifier("mapItemCollectionViewController") as? MapItemCollectionViewController else {
            abort()
        }
        
        collectionController.viewModel = collectionViewModel
        collectionController.modalPresentationStyle = .Popover
        collectionController.preferredContentSize = contentSize

        if let popover = collectionController.popoverPresentationController {
            popover.backgroundColor = UIColor.blackColor()
            popover.permittedArrowDirections = presentation.permittedArrowDirections
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
        splitViewController.dismissOverlaidMasterViewController()
    }
    
    private func updateShowSearchButton() {
        if splitViewController.masterViewControllerIsVisible {
            mapViewController.navigationItem.leftBarButtonItem = nil
        } else {
            mapViewController.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "708-search"), style: .Plain, target: self, action: Selector("searchButtonTapped"))
        }
    }
    
    // -- MARK: NGSplitViewControllerDelegate --
    
    public func splitViewControllerTraitCollectionChanged(splitViewController: NGSplitViewController) {
        popoverPresentation.value = PopoverPresentation(traitCollection: splitViewController.traitCollection, viewBounds: splitViewController.view.bounds)
    }
    
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
    
    // -- MARK: UIPopoverPresentationControllerDelegate --
    
    public func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.None
    }
    
    public func popoverPresentationControllerDidDismissPopover(popoverController: UIPopoverPresentationController) {
        self.collectionController = nil
        self.mapViewController.mapSelection.value = nil
        self.mapViewModel.selectedMapItem.value = nil
    }
    
    // -- MARK: UI Actions --
    
    func searchButtonTapped() {
        splitViewController.overlayMasterViewController()
    }
}