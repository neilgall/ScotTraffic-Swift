//
//  SafetyCameraCell.swift
//  ScotTraffic
//
//  Created by Neil Gall on 15/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit
import MapKit

class SafetyCameraCell: MapItemCollectionViewCell {
    @IBOutlet var iconImageView: UIImageView?
    @IBOutlet var roadLabel: UILabel?
    @IBOutlet var descriptionLabel: UILabel?
    @IBOutlet var imageView: UIImageView?
    @IBOutlet var shareButton: UIButton?

    private var item: Item?
    private var image: Observable<UIImage?>?
    private var observations = [Observation]()
    
    override func configure(item: Item, usingHTTPFetcher fetcher: HTTPFetcher) {
        if case .SafetyCameraItem(let safetyCamera) = item {
            self.item = item
            iconImageView?.image = iconForSpeedLimit(safetyCamera.speedLimit)
            roadLabel?.text = safetyCamera.road
            descriptionLabel?.text = safetyCamera.name
            obtainImage(safetyCamera, usingHTTPFetcher: fetcher)
        }
    }
    
    func obtainImage(supplier: ImageSupplier, usingHTTPFetcher fetcher: HTTPFetcher) {
        let image = supplier.image(fetcher)
        
        observations.append(image.map(applyGradientMask).output { [weak self] image in
            self?.imageView?.image = image
        })
        
        observations.append(image.output { [weak self] _ in
            self?.shareButton?.enabled = true
        })
        
        // keep the unmasked image for sharing
        self.image = image.latest()
    }
    
    @IBAction func share() {
        if let item = item, let image = image?.pullValue, case .SafetyCameraItem(let safetyCamera) = item {
            let coordinate = MKCoordinateForMapPoint(safetyCamera.mapPoint)
            let shareItem = SharableSafetyCamera(name: safetyCamera.name, image: image, coordinate: coordinate, link: safetyCamera.url)
            let rect = convertRect(shareButton!.bounds, fromView: shareButton!)
            delegate?.collectionViewCell(self, didRequestShareItem: shareItem, fromRect: rect)
        }
    }
    
    override func prepareForReuse() {
        observations.removeAll()
        image = nil
    }
}

private func iconForSpeedLimit(speedLimit: SpeedLimit) -> UIImage? {
    switch speedLimit {
    case .MPH20: return UIImage(named: "20")
    case .MPH30: return UIImage(named: "30")
    case .MPH40: return UIImage(named: "40")
    case .MPH50: return UIImage(named: "50")
    case .MPH60: return UIImage(named: "60")
    case .MPH70: return UIImage(named: "70")
    case .National: return UIImage(named: "nsl")
    default: return nil
    }
}

private func applyGradientMask(image: UIImage?) -> UIImage? {
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
    
    let colors = [ UIColor.blackColor().CGColor, UIColor.clearColor().CGColor ]
    let colorLocations: [CGFloat] = [ 0.3, 1.0 ]
    
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

private struct SharableSafetyCamera: SharableItem {
    let name: String
    let image: UIImage?
    let coordinate: CLLocationCoordinate2D
    let link: NSURL?
    
    var text: String {
        let latStr = formatCoordinate(coordinate.latitude, positiveSymbol: "N", negativeSymbol: "S")
        let lonStr = formatCoordinate(coordinate.longitude, positiveSymbol: "E", negativeSymbol: "W")
        return "Safety Camera: \(name) \(latStr) \(lonStr)\n\nShared using ScotTraffic"
    }
    
    func formatCoordinate(coord: CLLocationDegrees, positiveSymbol: String, negativeSymbol: String) -> String {
        let formatter = NSNumberFormatter()
        formatter.numberStyle = NSNumberFormatterStyle.DecimalStyle
        formatter.maximumFractionDigits = 6
        guard let coordString = formatter.stringFromNumber(NSNumber(double: fabs(coord))) else {
            return ""
        }
        let suffix = coord < 0 ? negativeSymbol : positiveSymbol
        return "\(coordString)º\(suffix)"
    }
}