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
private let zoomEdgePadding = UIEdgeInsets(top: 60, left: 40, bottom: 60, right: 40)

class MapViewController: UIViewController {

    @IBOutlet var mapView: MKMapView!
    @IBOutlet var calloutContainerView: CalloutContainerView!
    
    var viewModel: MapViewModel?
    var receivers = [ReceiverType]()
    var calloutConstructor: ([MapItem] -> UIViewController)?
    var calloutViewController: UIViewController?
    var animationSequence = AsyncSequence()
    var zoomingMapRect: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let viewModel = viewModel {
            viewModel.delegate <-- self
            calloutContainerView.delegate = self
            
            receivers.append(viewModel.visibleMapRect --> { [weak self] in
                self?.zoomToMapRectWithPadding($0, animated: true)
            })
            
            receivers.append(viewModel.annotations --> { [weak self] in
                self?.updateAnnotations($0)
            })
            
            let animating = animationSequence.busy || viewModel.animatingMapRect
            
            receivers.append(not(animating).gate(viewModel.selectedAnnotation) --> { [weak self] in
                self?.autoSelectAnnotation($0)
            })
            
            receivers.append(viewModel.showsUserLocationOnMap --> { [weak self] in
                self?.mapView.showsUserLocation = $0
            })
            
            if #available(iOS 9.0, *) {
                receivers.append(viewModel.showTrafficOnMap --> { [weak self] in
                    self?.mapView.showsTraffic = $0
                })
            }
            
            mapView.setVisibleMapRect(viewModel.visibleMapRect.value, animated: false)
        }
    }
    
    var currentAnnotations: Set<MapAnnotation> {
        return Set(mapView.annotations.flatMap { $0 as? MapAnnotation })
    }
    
    func updateAnnotations(newAnnotations: [MapAnnotation]) {
        let oldAnnotations = currentAnnotations
        let annotationsToRemove = oldAnnotations.subtract(newAnnotations)
        let annotationsToAdd = Set(newAnnotations).subtract(oldAnnotations)
        
        mapView.removeAnnotations(Array(annotationsToRemove))
        mapView.addAnnotations(Array(annotationsToAdd))
    }
    
    func autoSelectAnnotation(annotation: MapAnnotation?) {
        guard let annotation = annotation, viewModel = viewModel
            where annotation.mapItems.flatCount <= viewModel.maximumItemsInDetailView else {
                return
        }
        
        // defer annotation selection to ensure annotations have a chance to update first
        onMainQueue {
            for unselected in self.currentAnnotations {
                if unselected == annotation {
                    self.mapView.selectAnnotation(unselected, animated: true)
                    return
                }
            }
        }
    }
    
    func deselectAnnotationsAnimated(animated: Bool) {
        hideMapItemsAnimated(animated)
        
        for selected in mapView.selectedAnnotations {
            mapView.deselectAnnotation(selected, animated: animated)
        }
    }
    
    private func showMapItems(mapItems: [MapItem], fromAnnotationView annotationView: MKAnnotationView) {
        guard let constructor = calloutConstructor else {
            return
        }
        
        let viewController = constructor(mapItems)
        attachViewController(viewController, toAnnotationView: annotationView)
    }
    
    private func hideMapItemsAnimated(animated: Bool) {
        guard let viewController = calloutViewController else {
            return
        }
        detachViewController(viewController, animated: animated)
    }
    
    private func attachViewController(viewController: UIViewController, toAnnotationView annotationView: MKAnnotationView) {
        animationSequence.dispatch { completion in
            // FIXME: this is a workaround for a race in the map rect update and child presentation
            // resulting from a search selection.
            self.removeOrphanedChildViewControllers()

            self.calloutViewController = viewController
            viewController.willMoveToParentViewController(self)
            viewController.beginAppearanceTransition(true, animated: true)
            self.addChildViewController(viewController)
            self.calloutContainerView.addCalloutView(viewController.view, withPreferredSize: viewController.preferredContentSize, fromAnnotationView: annotationView) {
                viewController.endAppearanceTransition()
                viewController.didMoveToParentViewController(self)
                completion()
            }
        }
    }
    
    private func detachViewController(viewController: UIViewController, animated: Bool) {
        let task = { (completion: Void -> Void) -> Void in
            viewController.willMoveToParentViewController(nil)
            viewController.beginAppearanceTransition(false, animated: true)
            self.calloutContainerView.hideCalloutView(viewController.view, animated: animated) {
                viewController.endAppearanceTransition()
                viewController.removeFromParentViewController()
                self.calloutViewController = nil
                completion()
            }
        }
        
        if animated {
            animationSequence.dispatch(task)
        } else {
            task({})
        }
    }
    
    private func removeOrphanedChildViewControllers() {
        if childViewControllers.count > 0 {
            analyticsEvent(.RemoveOrphanedViewControllersWorkaround, ["count": "\(childViewControllers.count)"])
        }
        for viewController in childViewControllers {
            viewController.willMoveToParentViewController(nil)
            viewController.beginAppearanceTransition(false, animated: false)
            viewController.view.removeFromSuperview()
            viewController.endAppearanceTransition()
            viewController.removeFromParentViewController()
        }
    }

    // MARK: - Navigation
    
    func zoomToMapRectWithPadding(targetRect: MKMapRect, animated: Bool) {
        with(&zoomingMapRect) {
            mapView.setVisibleMapRect(targetRect, animated: true)
        }
    }
}

extension MapViewController: MKMapViewDelegate {
    // -- MARK: MKMapViewDelegete --
    
    func mapView(mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        deselectAnnotationsAnimated(true)
        if let viewModel = viewModel {
            viewModel.animatingMapRect <-- animated
        }
    }
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        if let viewModel = viewModel where !zoomingMapRect {
            viewModel.animatingMapRect <-- false
            viewModel.visibleMapRect <-- mapView.visibleMapRect
        }
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        guard let mapAnnotation = annotation as? MapAnnotation, viewModel = viewModel else {
            return nil
        }
        
        let showsCustomCallout = mapAnnotation.mapItems.flatCount <= viewModel.maximumItemsInDetailView
        let reuseIdentifier = "\(mapAnnotation.reuseIdentifier).\(showsCustomCallout)"
        
        let annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseIdentifier)
            ?? MKAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)

        annotationView.image = mapAnnotation.image
        annotationView.canShowCallout = !showsCustomCallout

        if mapAnnotation.mapItems.count > 1 {
            if let zoomInImage = UIImage(named: "736-zoom-in") {
                let button = UIButton(type: .Custom)
                button.frame = CGRect(origin: CGPoint.zero, size: zoomInImage.size)
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
        guard !view.canShowCallout, let annotation = view.annotation as? MapAnnotation else {
            return
        }
        showMapItems(annotation.mapItems, fromAnnotationView: view)
    }
    
    func mapView(mapView: MKMapView, didDeselectAnnotationView view: MKAnnotationView) {
        hideMapItemsAnimated(true)
    }
}

extension MapViewController: MapViewModelDelegate {
    // -- MARK: MapViewModelDelegate
    
    func annotationAtMapPoint(mapPoint1: MKMapPoint, wouldOverlapWithAnnotationAtMapPoint mapPoint2: MKMapPoint) -> Bool {
        let screenPoint1 = mapView.convertCoordinate(MKCoordinateForMapPoint(mapPoint1), toPointToView: mapView)
        let screenPoint2 = mapView.convertCoordinate(MKCoordinateForMapPoint(mapPoint2), toPointToView: mapView)
        let dx = fabs(screenPoint1.x - screenPoint2.x)
        let dy = fabs(screenPoint1.y - screenPoint2.y)
        return dx < minimumAnnotationSpacingX && dy < minimumAnnotationSpacingY
    }
}

extension MapViewController: CalloutContainerViewDelegate {
    // -- MARK: CalloutContainerViewDelegate

    func calloutContainerView(calloutContainerView: CalloutContainerView, didDismissCalloutForAnnotationView annotationView: MKAnnotationView) {
        mapView.deselectAnnotation(annotationView.annotation, animated: true)
    }
}
