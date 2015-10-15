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

public struct DetailMapItems {
    let mapItems: [MapItem]
    let mapViewRect: CGRect
    
    var flatCount: Int {
        return mapItems.reduce(0) { $0 + $1.count }
    }
}

class MapViewController: UIViewController, MKMapViewDelegate, MapViewModelDelegate {

    @IBOutlet var mapView: MKMapView!

    let detailMapItems = Input<DetailMapItems?>(initial: nil)
    var minimumDetailItemsForAnnotationCallout: Int = 1
    
    var viewModel: MapViewModel?
    var observations = [Observation]()
    var updatingAnnotations: Bool = false
    var callbackOnMapScroll: (CGRect, CGRect->Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let viewModel = viewModel {
            viewModel.delegate.value = self
            
            observations.append(viewModel.annotations.output(self.updateAnnotations))
            observations.append(viewModel.selectedAnnotation.output(self.autoSelectAnnotation))
            observations.append(viewModel.selectedMapItem.output(self.zoomToSelectedMapItem))
            
            observations.append(detailMapItems
                .filter({ $0 == nil })
                .output({ _ in self.deselectAnnotations() })
            )
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
    
    func scrollUntilRect(presentRect: CGRect, makesWayForPopoverWithContentSize contentSize: CGSize, completion: CGRect->Void) {
        let contentTopIfAbove = CGRectGetMinY(presentRect) - contentSize.height - 23
        let contentBottomIfBelow = CGRectGetMaxY(presentRect) + contentSize.height + 23
        let screenBottom = CGRectGetHeight(mapView.frame)
        
        if contentTopIfAbove < 10 && contentBottomIfBelow > screenBottom - 10 {
            let scrollDown = 10 - contentTopIfAbove
            let scrollUp = contentBottomIfBelow - (screenBottom - 10)
            let scroll: CGFloat
            if scrollDown < scrollUp {
                scroll = scrollDown
            } else {
                scroll = -scrollUp
            }
            
            let newRect = CGRectMake(
                presentRect.origin.x,
                presentRect.origin.y + scroll,
                presentRect.size.width,
                presentRect.size.height)
            callbackOnMapScroll = (newRect, completion)
            scrollMapVerticallyBy(scroll)

        } else {
            // no scroll required
            completion(presentRect)
        }
    }

    
    private func scrollMapVerticallyBy(scroll: CGFloat) {
        var rect = mapView.bounds
        rect.origin.y -= scroll
        let region = mapView.convertRect(rect, toRegionFromView: mapView)
        mapView.setRegion(region, animated: false)
    }

    // MARK: - Navigation

    func annotationZoomButtonTapped(sender: AnyObject?) {
        guard let annotation = mapView?.selectedAnnotations.first as? MapAnnotation else {
            return
        }
        zoomToMapRectWithPadding(annotation.mapItems.boundingRect, animated: true)
    }
    
    func zoomToSelectedMapItem(item: MapItem?) {
        if let item = item {
            let targetRect = MKMapRectInset(MKMapRectNull.addPoint(item.mapPoint), zoomToMapItemInsetX, zoomToMapItemInsetY)
            zoomToMapRectWithPadding(targetRect, animated: true)
        }
    }
    
    func zoomToMapRectWithPadding(targetRect: MKMapRect, animated: Bool) {
        let mapRect = mapView.mapRectThatFits(targetRect, edgePadding: zoomEdgePadding)
        mapView.setVisibleMapRect(mapRect, animated: animated)
    }

    
    // -- MARK: MKMapViewDelegete --
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let visibleMapRect = mapView.visibleMapRect
        let mapRect = MKMapRectInset(mapView.visibleMapRect,
            visibleMapRectInsetRatio * visibleMapRect.size.width,
            visibleMapRectInsetRatio * visibleMapRect.size.height)
        viewModel?.visibleMapRect.value = mapRect
        
        if let (rect, callback) = callbackOnMapScroll {
            callback(rect)
            callbackOnMapScroll = nil
        }
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        guard let mapAnnotation = annotation as? MapAnnotation else {
            return nil
        }
        
        let detailMapItems = DetailMapItems(mapItems: mapAnnotation.mapItems, mapViewRect: CGRectNull)
        let canShowCallout = detailMapItems.flatCount >= minimumDetailItemsForAnnotationCallout
        
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
            detailMapItems.value = DetailMapItems(mapItems: annotation.mapItems, mapViewRect: rect)
        }
    }
    
    func mapView(mapView: MKMapView, didDeselectAnnotationView view: MKAnnotationView) {
        if !updatingAnnotations {
            viewModel?.selectedMapItem.value = nil
            detailMapItems.value = nil
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
