//
//  SafetyCameraCell.swift
//  ScotTraffic
//
//  Created by Neil Gall on 15/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit
import MapKit

class SafetyCameraCell: MapItemCollectionViewCellWithMap {
    @IBOutlet var iconImageView: UIImageView?
    @IBOutlet var roadLabel: UILabel?
    @IBOutlet var descriptionLabel: UILabel?
    @IBOutlet var imageView: UIImageView?
    @IBOutlet var shareButton: UIButton?

    private var item: Item?
    private var image: Observable<UIImage?>?
    private var observations = [Observation]()
    
    override func configure(item: Item) {
        if case .SafetyCameraItem(let safetyCamera) = item {
            self.item = item
            iconImageView?.image = iconForSpeedLimit(safetyCamera.speedLimit)
            
            if safetyCamera.road.isEmpty {
                roadLabel?.text = safetyCamera.name
                roadLabel?.font = UIFont.systemFontOfSize(17.0)
                descriptionLabel?.text = nil
            } else {
                roadLabel?.text = safetyCamera.road
                roadLabel?.font = UIFont.systemFontOfSize(20.0)
                descriptionLabel?.text = safetyCamera.name
            }

            configureMap(safetyCamera)

            // model image, otherwise map image
            let imageSelector = union(safetyCamera.image, mapImage.gate(safetyCamera.image.map({ $0 == nil })))
            
            observations.append(imageSelector.map(applyGradientMask).output { [weak self] image in
                self?.imageView?.image = image
                self?.mapView?.hidden = (image != nil)
            })
            
            observations.append(imageSelector.output { [weak self] _ in
                self?.shareButton?.enabled = true
            })

            // keep the original image for sharing
            self.image = imageSelector.latest()
            safetyCamera.updateImage()
        }
    }
    
    @IBAction func share() {
        if let item = item, case .SafetyCameraItem(let safetyCamera) = item {
            let coordinate = MKCoordinateForMapPoint(safetyCamera.mapPoint)
            let image = self.image?.pullValue?.flatMap { $0 }
            let shareItem = SharableSafetyCamera(name: safetyCamera.name, image: image, coordinate: coordinate, link: safetyCamera.url)
            let rect = convertRect(shareButton!.bounds, fromView: shareButton!)
            delegate?.collectionViewCell(self, didRequestShareItem: shareItem, fromRect: rect)
        }
    }
    
    override func prepareForReuse() {
        observations.removeAll()
        image = nil
        mapImage.value = nil
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
    default: return UIImage(named: "safetycamera-with-border")
    }
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