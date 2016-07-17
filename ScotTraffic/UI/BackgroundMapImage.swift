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
        mapView.mapType = .Satellite
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
    guard let image = image, cgImage = image.CGImage else {
        return nil
    }

    return image.size
        |> alphaOnlyBitmap
        |> alphaGradient([(1.0, 0.3), (0.0, 1.0)])
        |> CGBitmapContextCreateImage
        |> mask(cgImage)
}

private func alphaOnlyBitmap(size: CGSize) -> CGContext? {
    return CGBitmapContextCreate(
        nil,
        Int(size.width),
        Int(size.height),
        8,
        Int(size.width),
        CGColorSpaceCreateDeviceGray(),
        CGImageAlphaInfo.Only.rawValue)
}

private func alphaGradient(stops: [(CGFloat, CGFloat)]) -> CGContext -> CGContext {
    return { context in
        let colors = stops.map({ UIColor(white: 0, alpha: $0.0).CGColor })
        let colorLocations = stops.map({ $0.1 })
        if let gradient = CGGradientCreateWithColors(CGColorSpaceCreateDeviceGray(), colors, colorLocations) {
            let width = CGFloat(CGBitmapContextGetWidth(context))
            let height = CGFloat(CGBitmapContextGetHeight(context))
            CGContextDrawLinearGradient(context,
                                        gradient,
                                        CGPoint(x: width/2, y: 0),
                                        CGPoint(x: width/2, y: height),
                                        CGGradientDrawingOptions.DrawsBeforeStartLocation)
        }
        return context
    }
}

private func mask(image: CGImage) -> CGImage -> UIImage? {
    return { mask in
        let maskedImage = CGImageCreateWithMask(image, mask)
        return maskedImage.map { UIImage(CGImage: $0) }
    }
}
