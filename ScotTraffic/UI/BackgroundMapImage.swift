//
//  BackgroundMapImage.swift
//  ScotTraffic
//
//  Created by Neil Gall on 07/11/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import MapKit

private let mapRectSize: Double = 4000
private let renderStartTimeout: NSTimeInterval = 1.0

protocol BackgroundMapImage: class {
    var mapImage: Input<UIImage?> { get }
}

extension BackgroundMapImage where Self: UICollectionViewCell, Self: MKMapViewDelegate {
    
    func configureMap(mapItem: MapItem, forReferenceView view: UIView) -> MKMapView {
        let mapView = MKMapView(frame: view.frame)
        mapView.mapType = .Hybrid
        mapView.delegate = self
        mapView.translatesAutoresizingMaskIntoConstraints = false
        view.superview!.insertSubview(mapView, atIndex: 0)
        for attr: NSLayoutAttribute in [.Top, .Bottom, .Left, .Right] {
            view.superview!.addConstraint(NSLayoutConstraint(item: mapView, attribute: attr, relatedBy: .Equal, toItem: view, attribute: attr, multiplier: 1.0, constant: 0))
        }
        
        let origin = MKMapPoint(x: mapItem.mapPoint.x - mapRectSize * 0.5, y: mapItem.mapPoint.y - mapRectSize * 0.65)
        let mapRect = MKMapRect(origin: origin, size: MKMapSize(width: mapRectSize, height: mapRectSize))
        
        mapView.visibleMapRect = mapView.mapRectThatFits(mapRect)
        mapView.addAnnotation(MapAnnotation(mapItems: [mapItem]))
        
        return mapView
    }
    
    func takeSnapshotOfRenderedMap(mapView: MKMapView) {
        mapImage <-- mapView.snapshotImage()
        mapView.removeFromSuperview()
    }

    func resetMap(mapView: MKMapView?) {
        mapImage <-- nil
        mapView?.removeFromSuperview()
    }
}

func applyGradientMask(image: UIImage?) -> UIImage? {
    guard let image = image else {
        return nil
    }
    
    let size = image.size
    
    let colorSpace = CGColorSpaceCreateDeviceGray()
    let context = CGBitmapContextCreate(nil,
        Int(size.width),
        Int(size.height),
        8,
        Int(size.width),
        colorSpace,
        CGImageAlphaInfo.Only.rawValue)
    
    let colors = [
        UIColor(white: 0, alpha: 1.0).CGColor,
        UIColor(white: 0, alpha: 0.0).CGColor
    ]
    let colorLocations: [CGFloat] = [
        0.3,
        1.0
    ]
    
    let gradient = CGGradientCreateWithColors(colorSpace, colors, colorLocations)
    CGContextDrawLinearGradient(context,
        gradient,
        CGPoint(x: size.width/2, y: 0),
        CGPoint(x: size.width/2, y: size.height),
        CGGradientDrawingOptions.DrawsBeforeStartLocation)
    
    let mask = CGBitmapContextCreateImage(context)
    
    let maskedImage = CGImageCreateWithMask(image.CGImage, mask)
    return maskedImage.map { UIImage(CGImage: $0) }
}
