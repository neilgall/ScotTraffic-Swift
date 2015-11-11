//
//  MapViewController.swift
//  ScotTraffic
//
//  Created by Neil Gall on 05/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import MapKit
import UIKit

private let minimumAnnotationSpacingX: CGFloat = 35
private let minimumAnnotationSpacingY: CGFloat = 32
private let zoomEdgePadding = UIEdgeInsetsMake(60, 40, 60, 40)
private let zoomToMapItemInsetX: Double = -40000
private let zoomToMapItemInsetY: Double = -40000

class MapViewController: UIViewController, MKMapViewDelegate, MapViewModelDelegate, CalloutContainerViewDelegate {

    @IBOutlet var mapView: MKMapView!
    @IBOutlet var calloutContainerView: CalloutContainerView!
    
    var maximumDetailItemsForCollectionCallout: Int = 1
    
    var viewModel: MapViewModel?
    var observations = [Observation]()
    var updatingAnnotations: Bool = false
    var calloutConstructor: ([MapItem] -> UIViewController)?
    var calloutViewControllerByAnnotation = ViewKeyedMap<UIViewController>()
    var animationSequence = AsyncSequence()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let viewModel = viewModel {
            viewModel.delegate.value = self
            calloutContainerView.delegate = self
            
            observations.append(viewModel.annotations => self.updateAnnotations)
            observations.append(viewModel.selectedAnnotation => self.autoSelectAnnotation)
            observations.append(viewModel.selectedMapItem => self.zoomToSelectedMapItem)
            observations.append(viewModel.locationServices.authorised => self.updateShowsCurrentLocation)
            
            mapView.setVisibleMapRect(viewModel.visibleMapRect.value, animated: false)
        }
    }
    
    var currentAnnotations: Set<MapAnnotation> {
        return Set(mapView.annotations.flatMap { $0 as? MapAnnotation })
    }
    
    func updateAnnotations(newAnnotations: [MapAnnotation]) {
        with(&updatingAnnotations) {
            let oldAnnotations = self.currentAnnotations
            let annotationsToRemove = oldAnnotations.subtract(newAnnotations)
            let annotationsToAdd = Set(newAnnotations).subtract(oldAnnotations)
            
            self.mapView.removeAnnotations(Array(annotationsToRemove))
            self.mapView.addAnnotations(Array(annotationsToAdd))
        }
    }
    
    func updateShowsCurrentLocation(enable: Bool) {
        mapView.showsUserLocation = enable
    }
    
    func autoSelectAnnotation(annotation: MapAnnotation?) {
        guard let annotation = annotation where annotation.mapItems.flatCount <= maximumDetailItemsForCollectionCallout else {
            return
        }
        
        for unselected in currentAnnotations {
            if unselected == annotation {
                mapView.selectAnnotation(unselected, animated: true)
                
                // we have now consumed the selectedMapItem
                viewModel?.selectedMapItem.value = nil
                return
            }
        }
    }
    
    func deselectAnnotations() {
        for selected in mapView.selectedAnnotations {
            mapView.deselectAnnotation(selected, animated: true)
        }
    }
    
    private func showMapItems(mapItems: [MapItem], fromAnnotationView annotationView: MKAnnotationView) {
        guard let constructor = calloutConstructor else {
            return
        }
        
        let viewController = constructor(mapItems)
        attachViewController(viewController, toAnnotationView: annotationView)
    }
    
    private func hideMapItemsPresentedFromAnnotationView(annotationView: MKAnnotationView) {
        guard let viewController = calloutViewControllerByAnnotation[annotationView] else {
            return
        }
        detachViewController(viewController, fromAnnotationView: annotationView)
    }
    
    private func attachViewController(viewController: UIViewController, toAnnotationView annotationView: MKAnnotationView) {
        animationSequence.dispatch { completion in
            viewController.willMoveToParentViewController(self)
            viewController.beginAppearanceTransition(true, animated: true)
            self.addChildViewController(viewController)
            self.calloutContainerView.addCalloutView(viewController.view, withPreferredSize: viewController.preferredContentSize, fromAnnotationView: annotationView) {
                viewController.endAppearanceTransition()
                viewController.didMoveToParentViewController(self)
                self.calloutViewControllerByAnnotation[annotationView] = viewController
                completion()
            }
        }
    }
    
    private func detachViewController(viewController: UIViewController, fromAnnotationView annotationView: MKAnnotationView) {
        animationSequence.dispatch { completion in
            viewController.willMoveToParentViewController(nil)
            viewController.beginAppearanceTransition(false, animated: true)
            self.calloutContainerView.hideCalloutView(viewController.view, forAnnotationView: annotationView, animated: true) {
                viewController.removeFromParentViewController()
                viewController.endAppearanceTransition()
                self.calloutViewControllerByAnnotation[annotationView] = nil
                completion()
            }
        }
    }

    // MARK: - Navigation

    func zoomToSelectedMapItem(item: MapItem?) {
        if let item = item where shouldZoomToMapItem(item) {
            let targetRect = MKMapRectInset(MKMapRectNull.addPoint(item.mapPoint), zoomToMapItemInsetX, zoomToMapItemInsetY)
            zoomToMapRectWithPadding(targetRect, animated: true)
        }
    }
    
    func zoomToMapRectWithPadding(targetRect: MKMapRect, animated: Bool) {
        let mapRect = mapView.mapRectThatFits(targetRect, edgePadding: zoomEdgePadding)
        self.mapView.setVisibleMapRect(mapRect, animated: true)
    }

    func shouldZoomToMapItem(mapItem: MapItem) -> Bool {
        if !mapView.visibleMapRect.contains(mapItem.mapPoint) {
            return true
        }
        if let annotation = viewModel?.annotationForMapItem(mapItem)
            where annotation.mapItems.flatCount > maximumDetailItemsForCollectionCallout {
                return true
        }
        return false
    }
    
    // -- MARK: MKMapViewDelegete --
    
    func mapView(mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        deselectAnnotations()
        viewModel?.animatingMapRect.value = animated
    }
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        viewModel?.animatingMapRect.value = false
        viewModel?.visibleMapRect.value = mapView.visibleMapRect
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        guard let mapAnnotation = annotation as? MapAnnotation else {
            return nil
        }
        
        let showsCustomCallout = mapAnnotation.mapItems.flatCount <= maximumDetailItemsForCollectionCallout
        let reuseIdentifier = "\(mapAnnotation.reuseIdentifier).\(showsCustomCallout)"
        
        let annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseIdentifier)
            ?? MKAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)

        annotationView.image = mapAnnotation.image
        annotationView.canShowCallout = !showsCustomCallout

        if mapAnnotation.mapItems.count > 1 {
            if let zoomInImage = UIImage(named: "736-zoom-in") {
                let button = UIButton(type: .Custom)
                button.frame = CGRectMake(0, 0, zoomInImage.size.width, zoomInImage.size.height)
                button.setImage(zoomInImage, forState: .Normal)
                annotationView.rightCalloutAccessoryView = button
            }
        }
        
        return annotationView
    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        guard let annotation = mapView.selectedAnnotations.first as? MapAnnotation else {
            return
        }
        zoomToMapRectWithPadding(annotation.mapItems.boundingRect, animated: true)
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        // views which show the
        guard !view.canShowCallout, let annotation = view.annotation as? MapAnnotation else {
            return
        }
        showMapItems(annotation.mapItems, fromAnnotationView: view)
    }
    
    func mapView(mapView: MKMapView, didDeselectAnnotationView view: MKAnnotationView) {
        if !updatingAnnotations {
            hideMapItemsPresentedFromAnnotationView(view)
        }
    }

    // -- MARK: MapViewModelDelegate
    
    func annotationAtMapPoint(mapPoint1: MKMapPoint, wouldOverlapWithAnnotationAtMapPoint mapPoint2: MKMapPoint) -> Bool {
        let screenPoint1 = mapView.convertCoordinate(MKCoordinateForMapPoint(mapPoint1), toPointToView: mapView)
        let screenPoint2 = mapView.convertCoordinate(MKCoordinateForMapPoint(mapPoint2), toPointToView: mapView)
        let dx = fabs(screenPoint1.x - screenPoint2.x)
        let dy = fabs(screenPoint1.y - screenPoint2.y)
        return dx < minimumAnnotationSpacingX && dy < minimumAnnotationSpacingY
    }
    
    // -- MARK: CalloutContainerViewDelegate
    
    func calloutContainerView(calloutContainerView: CalloutContainerView, didDismissCalloutForAnnotationView annotationView: MKAnnotationView) {
        mapView.deselectAnnotation(annotationView.annotation, animated: true)
    }
}
