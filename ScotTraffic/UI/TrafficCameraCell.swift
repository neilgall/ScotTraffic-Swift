//
//  TrafficCameraCell.swift
//  ScotTraffic
//
//  Created by ZBS on 14/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit

class TrafficCameraCell: UICollectionViewCell, MapItemCollectionViewCell {
    
    @IBOutlet var imageView: UIImageView?
    @IBOutlet var errorLabel: UILabel?
    @IBOutlet var spinner: DeferredStartSpinner?
    @IBOutlet var titleLabel: UILabel?
    @IBOutlet var favouriteButton: UIButton?
    @IBOutlet var shareButton: UIButton?
    
    weak var delegate: MapItemCollectionViewCellDelegate?
    private var locationName: String?
    private var favouriteItem: FavouriteTrafficCamera?
    private var image: Signal<DataSourceImage>?
    private var receivers = [ReceiverType]()
    
    func configure(item: MapItemCollectionViewItem) {
        if case .TrafficCameraItem(let location, let camera) = item {
            locationName = trafficCameraName(camera, atLocation: location)
            favouriteItem = FavouriteTrafficCamera(location: location, camera: camera)

            errorLabel?.hidden = true
            titleLabel?.text = locationName

            updateFavouriteButton()
            spinner?.startAnimatingDeferred()
        
            let imageValue = camera.imageValue
            
            receivers.append(imageValue --> { [weak self] image in
                switch image {
                case .Cached(let image, let expired):
                    self?.errorLabel?.hidden = true
                    if expired {
                        self?.imageView?.image = imageWithGrayColorspace(image)
                    } else {
                        self?.imageView?.image = image
                        self?.spinner?.stopAnimating()
                    }
                    
                case .Fresh(let image):
                    self?.errorLabel?.hidden = true
                    self?.imageView?.image = image
                    self?.spinner?.stopAnimating()
                    
                case .Error, .Empty:
                    self?.errorLabel?.hidden = false
                    self?.spinner?.stopAnimating()
                }
            })
        
            receivers.append(not(isNil(camera.image)) --> { [weak self] enabled in
                self?.shareButton?.enabled = enabled
                self?.favouriteButton?.enabled = enabled
            })
        
            self.image = imageValue.latest()
            camera.updateImage()
        }
    }
    
    private func updateFavouriteButton() {
        favouriteButton?.selected = delegate?.collectionViewItemIsFavourite(favouriteItem!) ?? false
    }
    
    @IBAction func share() {
        if let shareButton = shareButton, name = locationName, let image = image?.latestValue.get {
            let item = SharableTrafficCamera(name: name, image: image.value)
            let rect = convertRect(shareButton.bounds, fromView: shareButton)
            delegate?.collectionViewCell(self, didRequestShareItem: item, fromRect: rect)
        }
    }
    
    @IBAction func toggleFavourite() {
        if let item = favouriteItem {
            delegate?.collectionViewCellDidToggleFavourite(item)
            updateFavouriteButton()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        fillCellWithFirstSubview()
    }
    
    override func prepareForReuse() {
        receivers.removeAll()
        image = nil
        locationName = nil
        favouriteItem = nil
        
        errorLabel?.hidden = true
        titleLabel?.text = nil
        imageView?.image = nil
        spinner?.stopAnimating()

        super.prepareForReuse()
    }
}

private struct SharableTrafficCamera: SharableItem {
    let name: String
    let image: UIImage?
    let link: NSURL? = nil
    
    var text: String {
        return "Traffic Camera Image: \(name)\n\nShared using ScotTraffic"
    }
}

private func imageWithGrayColorspace(image: UIImage?) -> UIImage? {
    guard let image = image else {
        return nil
    }
    
    let size = image.size
    
    let context = CGBitmapContextCreate(nil,
        Int(size.width),
        Int(size.height),
        8,
        Int(size.width),
        CGColorSpaceCreateDeviceGray(),
        CGImageAlphaInfo.None.rawValue)

    CGContextSetAlpha(context, 0.5)
    CGContextDrawImage(context, CGRect(origin: CGPointZero, size: size), image.CGImage)
    let grayImage = CGBitmapContextCreateImage(context)
    
    return grayImage.map { UIImage(CGImage: $0) }
}
