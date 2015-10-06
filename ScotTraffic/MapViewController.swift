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

class MapViewController: UIViewController, MKMapViewDelegate, MapViewModelDelegate {

    @IBOutlet var mapView: MKMapView!

    var viewModel: MapViewModel?
    var observations = Observations()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel?.delegate.value = self
        
        if let annotations = viewModel?.annotations {
            observations.add(annotations, closure: self.updateAnnotations)
        }
    }
    
    var currentAnnotations: Set<MapAnnotation> {
        return Set(mapView.annotations.flatMap { $0 as? MapAnnotation })
    }
    
    func updateAnnotations(newAnnotations: [MapAnnotation]) {
        let oldAnnotations = currentAnnotations
        let annotationsToRemove = oldAnnotations.subtract(newAnnotations)
        let annotationsToAdd = Set(newAnnotations).subtract(oldAnnotations)
        
        for annotation in annotationsToRemove {
            mapView?.removeAnnotation(annotation)
        }
        for annotation in annotationsToAdd {
            mapView?.addAnnotation(annotation)
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    // -- MARK: MKMapViewDelegete --
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        viewModel?.visibleMapRect.value = mapView.visibleMapRect
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

    // -- MARK: MapViewModelDelegate --
    
    func annotationsWouldOverlap(mapPoint1: MKMapPoint, mapPoint2: MKMapPoint) -> Bool {
        let screenPoint1 = mapView.convertCoordinate(MKCoordinateForMapPoint(mapPoint1), toPointToView: mapView)
        let screenPoint2 = mapView.convertCoordinate(MKCoordinateForMapPoint(mapPoint2), toPointToView: mapView)
        let dx = fabs(screenPoint1.x - screenPoint2.x)
        let dy = fabs(screenPoint1.y - screenPoint2.y)
        return dx < minimumAnnotationSpacingX && dy < minimumAnnotationSpacingY
    }
}
