//
//  MapViewController.swift
//  ScotTraffic
//
//  Created by Neil Gall on 05/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import MapKit
import UIKit

let minimumAnnotationSpacingX: CGFloat = 35
let minimumAnnotationSpacingY: CGFloat = 32
let zoomEdgePadding = UIEdgeInsetsMake(60, 40, 60, 40)
let zoomToMapItemInsetX: Double = -40000
let zoomToMapItemInsetY: Double = -40000

public struct MapSelection {
    let mapItems: [MapItem]
    let mapViewRect: CGRect
}

class MapViewController: UIViewController, MKMapViewDelegate, MapViewModelDelegate {

    @IBOutlet var mapView: MKMapView!

    let mapSelection = Input<MapSelection?>(initial: nil)
    var minimumDetailItemsForAnnotationCallout: Int = 1
    
    var viewModel: MapViewModel?
    var observations = [Observation]()
    var updatingAnnotations: Bool = false
    var scrollingMap: Bool = false
    var callbackOnMapScroll: (Void->Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let viewModel = viewModel {
            viewModel.delegate.value = self
            
            observations.append(viewModel.annotations.output(self.updateAnnotations))
            observations.append(viewModel.selectedAnnotation.output(self.autoSelectAnnotation))
            observations.append(viewModel.selectedMapItem.output(self.zoomToSelectedMapItem))
            
            observations.append(mapSelection
                .filter({ $0 == nil })
                .output({ _ in self.deselectAnnotations() })
            )
            
            scrollingMap = true
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
    
    func autoSelectAnnotation(annotation: MapAnnotation?) {
        guard let annotation = annotation else {
            return
        }
        for unselected in currentAnnotations {
            if unselected == annotation {
                mapView.selectAnnotation(unselected, animated: true)
            }
        }
    }
    
    func deselectAnnotations() {
        for selected in mapView.selectedAnnotations {
            mapView.deselectAnnotation(selected, animated: true)
        }
    }
    
    func scrollBy(x x: CGFloat, y: CGFloat, completion: Void->Void) {
        let targetRect = CGRectOffset(mapView.bounds, -x, -y)
        let region = mapView.convertRect(targetRect, toRegionFromView: mapView)
        
        if (fabs(x) > 10 || fabs(y) > 10) {
            callbackOnMapScroll = completion
            scrollingMap = true
            mapView.setRegion(region, animated: true)
        } else {
            mapView.setRegion(region, animated: false)
            completion()
        }
    }

    // MARK: - Navigation

    func annotationZoomButtonTapped(sender: AnyObject?) {
        guard let annotation = mapView?.selectedAnnotations.first as? MapAnnotation else {
            return
        }
        zoomToMapRectWithPadding(annotation.mapItems.boundingRect, animated: true)
    }
    
    func zoomToSelectedMapItem(item: MapItem?) {
        if let item = item where shouldZoomToMapItem(item) {
            let targetRect = MKMapRectInset(MKMapRectNull.addPoint(item.mapPoint), zoomToMapItemInsetX, zoomToMapItemInsetY)
            zoomToMapRectWithPadding(targetRect, animated: true)
        }
    }
    
    func zoomToMapRectWithPadding(targetRect: MKMapRect, animated: Bool) {
        let mapRect = mapView.mapRectThatFits(targetRect, edgePadding: zoomEdgePadding)
        scrollingMap = true
        mapView.setVisibleMapRect(mapRect, animated: animated)
    }

    func shouldZoomToMapItem(mapItem: MapItem) -> Bool {
        if !mapView.visibleMapRect.contains(mapItem.mapPoint) {
            return true
        }
        if let annotation = viewModel?.annotationForMapItem(mapItem)
            where annotation.mapItems.flatCount >= minimumDetailItemsForAnnotationCallout {
                return true
        }
        return false
    }
    
    // -- MARK: MKMapViewDelegete --
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        scrollingMap = false
        viewModel?.visibleMapRect.value = mapView.visibleMapRect
        
        if let callback = callbackOnMapScroll {
            callback()
            callbackOnMapScroll = nil
        }
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        guard let mapAnnotation = annotation as? MapAnnotation else {
            return nil
        }
        
        let canShowCallout = mapAnnotation.mapItems.flatCount >= minimumDetailItemsForAnnotationCallout
        
        let annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(mapAnnotation.reuseIdentifier)
            ?? MKAnnotationView(annotation: annotation, reuseIdentifier: mapAnnotation.reuseIdentifier)

        annotationView.image = mapAnnotation.image
        annotationView.canShowCallout = canShowCallout
        annotationView.rightCalloutAccessoryView = nil

        if mapAnnotation.mapItems.count > 1 {
            if let zoomInImage = UIImage(named: "736-zoom-in") {
                let button = UIButton(type: .Custom)
                button.frame = CGRectMake(0, 0, zoomInImage.size.width, zoomInImage.size.height)
                button.setImage(zoomInImage, forState: .Normal)
                button.addTarget(self, action: Selector("annotationZoomButtonTapped:"), forControlEvents: .TouchUpInside)
                annotationView.rightCalloutAccessoryView = button
            }
        }
        
        return annotationView
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        if let annotation = view.annotation as? MapAnnotation {
            let rect = view.convertRect(view.bounds, toView: mapView)
            mapSelection.value = MapSelection(mapItems: annotation.mapItems, mapViewRect: rect)
        }
    }
    
    func mapView(mapView: MKMapView, didDeselectAnnotationView view: MKAnnotationView) {
        if !updatingAnnotations {
            viewModel?.selectedMapItem.value = nil
            mapSelection.value = nil
        }
    }

    // -- MARK: MapViewModelDelegate --
    
    func annotationAtMapPoint(mapPoint1: MKMapPoint, wouldOverlapWithAnnotationAtMapPoint mapPoint2: MKMapPoint) -> Bool {
        let screenPoint1 = mapView.convertCoordinate(MKCoordinateForMapPoint(mapPoint1), toPointToView: mapView)
        let screenPoint2 = mapView.convertCoordinate(MKCoordinateForMapPoint(mapPoint2), toPointToView: mapView)
        let dx = fabs(screenPoint1.x - screenPoint2.x)
        let dy = fabs(screenPoint1.y - screenPoint2.y)
        return dx < minimumAnnotationSpacingX && dy < minimumAnnotationSpacingY
    }
}
