//
//  MapItemCollectionViewCellWithMap.swift
//  ScotTraffic
//
//  Created by Neil Gall on 07/11/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import MapKit

private let mapRectSize: Double = 4000

class MapItemCollectionViewCellWithMap : MapItemCollectionViewCell, MKMapViewDelegate {
    
    @IBOutlet var mapView: MKMapView?

    var mapImage: Input<UIImage?> = Input(initial: nil)

    func configureMap(mapItem: MapItem) {
        if let mapView = mapView {
            let origin = MKMapPoint(x: mapItem.mapPoint.x - mapRectSize * 0.5, y: mapItem.mapPoint.y - mapRectSize * 0.65)
            let mapRect = MKMapRect(origin: origin, size: MKMapSize(width: mapRectSize, height: mapRectSize))
        
            mapView.alpha = 0
            mapView.visibleMapRect = mapView.mapRectThatFits(mapRect)
            mapView.addAnnotation(MapAnnotation(mapItems: [mapItem]))
        }
    }
    
    // -- MARK: MKMapViewDelegate
    
    func mapViewDidFinishRenderingMap(mapView: MKMapView, fullyRendered: Bool) {
        mapView.alpha = 1
        mapImage.value = mapView.snapshotImage()
        mapView.alpha = 0
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
        CGPointMake(size.width/2, 0),
        CGPointMake(size.width/2, size.height),
        CGGradientDrawingOptions.DrawsBeforeStartLocation)
    
    let mask = CGBitmapContextCreateImage(context)
    
    let maskedImage = CGImageCreateWithMask(image.CGImage, mask)
    return maskedImage.map { UIImage(CGImage: $0) }
}
