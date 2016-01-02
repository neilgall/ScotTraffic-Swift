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
    @IBOutlet var spinner: DeferredStartSpinner?
    @IBOutlet var shareButton: UIButton?

    private var item: Item?
    private var image: Observable<DataSourceImage>?
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

            spinner?.startAnimatingDeferred()

            // image from server if available, otherwise map image
            let serverImage = safetyCamera.imageValue
            let serverImageIsNil = serverImage.map({
                $0.value == nil
            })

            // wrap a map image in a DataSourceImage so we can union the two
            let mapImage = self.mapImage.map(DataSourceValue.fromOptional)
            
            let imageSelector = union(serverImage, serverImageIsNil.gate(mapImage))
            
            observations.append(imageSelector.output { [weak self] image in
                switch image {
                case .Cached(let image, let expired):
                    self?.imageView?.image = applyGradientMask(image)
                    if !expired {
                        self?.spinner?.stopAnimating()
                    }
                    
                case .Fresh(let image):
                    self?.imageView?.image = applyGradientMask(image)
                    self?.spinner?.stopAnimating()

                case .Empty, .Error:
                    self?.imageView?.image = nil
                    self?.spinner?.stopAnimating()
                }
            })
            
            observations.append(imageSelector.output { [weak self] _ in
                self?.shareButton?.enabled = true
            })

            // keep the original image for sharing
            self.image = imageSelector.latest()
            safetyCamera.updateImage()

            if let bg = imageView {
                // start rendering the map
                configureMap(safetyCamera, forReferenceView: bg)
            }
        }
    }
    
    @IBAction func share() {
        if let shareButton = shareButton, item = item, case .SafetyCameraItem(let safetyCamera) = item {
            let coordinate = MKCoordinateForMapPoint(safetyCamera.mapPoint)
            let image = self.image?.pullValue?.value
            let shareItem = SharableSafetyCamera(name: safetyCamera.name, image: image, coordinate: coordinate, link: safetyCamera.url)
            let rect = convertRect(shareButton.bounds, fromView: shareButton)
            delegate?.collectionViewCell(self, didRequestShareItem: shareItem, fromRect: rect)
        }
    }
    
    override func prepareForReuse() {
        observations.removeAll()
        image = nil
        mapImage.value = nil
        
        iconImageView?.image = nil
        roadLabel?.text = nil
        descriptionLabel?.text = nil
        imageView?.image = nil
        spinner?.stopAnimating()

        super.prepareForReuse()
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