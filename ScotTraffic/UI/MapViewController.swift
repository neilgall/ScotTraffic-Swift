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
let visibleMapRectInsetRatio: Double = -0.2

class MapViewController: UIViewController, MKMapViewDelegate, MapViewModelDelegate {

    @IBOutlet var mapView: MKMapView!

    var viewModel: MapViewModel?
    var observations = Observations()
    var updatingAnnotations: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let viewModel = viewModel {
            viewModel.delegate.value = self
            observations.add(viewModel.annotations, closure: self.updateAnnotations)
            observations.add(viewModel.selectedAnnotation, closure: self.autoSelectAnnotation)
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

    // MARK: - Navigation

    func annotationZoomButtonTapped(sender: AnyObject?) {
        guard let annotation = mapView?.selectedAnnotations.first as? MapAnnotation else {
            return
        }
        zoomToMapRectWithPadding(annotation.mapItems.boundingRect, animated: true)
    }
    
    func zoomToMapItem(item: MapItem, animated: Bool) {
        viewModel?.selectedMapItem.value = item

        let targetRect = MKMapRectInset(MKMapRectNull.addPoint(item.mapPoint), zoomToMapItemInsetX, zoomToMapItemInsetY)
        zoomToMapRectWithPadding(targetRect, animated: animated)
    }
    
    func zoomToMapRectWithPadding(targetRect: MKMapRect, animated: Bool) {
        let mapRect = mapView.mapRectThatFits(targetRect, edgePadding: zoomEdgePadding)
        mapView.setVisibleMapRect(mapRect, animated: animated)
    }
    
    /*
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    // -- MARK: MKMapViewDelegete --
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let visibleMapRect = mapView.visibleMapRect
        let mapRect = MKMapRectInset(mapView.visibleMapRect,
            visibleMapRectInsetRatio * visibleMapRect.size.width,
            visibleMapRectInsetRatio * visibleMapRect.size.height)
        viewModel?.visibleMapRect.value = mapRect
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        guard let mapAnnotation = annotation as? MapAnnotation else {
            return nil
        }
        
        let annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(mapAnnotation.reuseIdentifier)
            ?? MKAnnotationView(annotation: annotation, reuseIdentifier: mapAnnotation.reuseIdentifier)

        annotationView.image = mapAnnotation.image
        annotationView.canShowCallout = true
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
        
    }
    
    func mapView(mapView: MKMapView, didDeselectAnnotationView view: MKAnnotationView) {
        if !updatingAnnotations {
            viewModel?.selectedMapItem.value = nil
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
