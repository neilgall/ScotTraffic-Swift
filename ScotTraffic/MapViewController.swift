//
//  MapViewController.swift
//  ScotTraffic
//
//  Created by Neil Gall on 05/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import MapKit
import UIKit

class MapViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet var mapView: MKMapView?

    var viewModel: MapViewModel?
    var observations = Observations()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let annotations = viewModel?.annotations {
            observations.add(annotations) { annotations in
                annotations.forEach {
                    self.mapView?.addAnnotation($0)
                }
            }
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

}
