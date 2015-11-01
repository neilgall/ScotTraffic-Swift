//
//  TrafficCameraCell.swift
//  ScotTraffic
//
//  Created by ZBS on 14/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit

class TrafficCameraCell: MapItemCollectionViewCell {
    
    @IBOutlet var imageView: UIImageView?
    @IBOutlet var errorLabel: UILabel?
    @IBOutlet var titleLabel: UILabel?
    @IBOutlet var favouriteButton: UIButton?
    @IBOutlet var shareButton: UIButton?
    
    private var locationName: String?
    private var favouriteItem: FavouriteTrafficCamera?
    private var image: Observable<UIImage?>?
    private var observations = [Observation]()
    
    override func configure(item: Item) {
        if case .TrafficCameraItem(let location, let camera) = item {
            locationName = trafficCameraName(camera, atLocation: location)
            favouriteItem = FavouriteTrafficCamera(location: location, camera: camera)

            errorLabel?.hidden = true
            titleLabel?.text = locationName
            updateFavouriteButton()
        
            let image = camera.image
            
            observations.append(image.output { [weak self] image in
                self?.errorLabel?.hidden = (image != nil)
                self?.imageView?.image = image
            })
        
            observations.append(image.map({ $0 != nil }).output { [weak self] enabled in
                self?.shareButton?.enabled = enabled
                self?.favouriteButton?.enabled = enabled
            })
        
            self.image = image.latest()
        }
    }
    
    private func updateFavouriteButton() {
        favouriteButton?.selected = delegate?.collectionViewItemIsFavourite(favouriteItem!) ?? false
    }
    
    @IBAction func share() {
        if let name = locationName, let image = image?.pullValue {
            let item = SharableTrafficCamera(name: name, image: image)
            let rect = convertRect(shareButton!.bounds, fromView: shareButton!)
            delegate?.collectionViewCell(self, didRequestShareItem: item, fromRect: rect)
        }
    }
    
    @IBAction func toggleFavourite() {
        if let item = favouriteItem {
            delegate?.collectionViewCellDidToggleFavourite(item)
            updateFavouriteButton()
        }
    }
    
    override func prepareForReuse() {
        observations.removeAll()
        image = nil
        locationName = nil
        favouriteItem = nil
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