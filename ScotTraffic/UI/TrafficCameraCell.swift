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
    
    override func configure(item: Item, usingHTTPFetcher fetcher: HTTPFetcher) {
        if case .TrafficCameraItem(let location, let camera) = item {
            locationName = trafficCameraName(camera, atLocation: location)
            favouriteItem = FavouriteTrafficCamera(location: location, camera: camera)
            titleLabel?.text = locationName
            obtainImage(camera, usingHTTPFetcher: fetcher)
        }
    }
    
    func obtainImage(supplier: ImageSupplier, usingHTTPFetcher fetcher: HTTPFetcher) {
        self.errorLabel?.hidden = true
        
        let image = supplier.image(fetcher)
        
        observations.append(image.output { [weak self] image in
            self?.errorLabel?.hidden = (image != nil)
            self?.imageView?.image = image
        })
        
        observations.append(image.map({ $0 != nil }).output { [weak self] enabled in
            self?.shareButton?.enabled = enabled
            self?.favouriteButton?.enabled = enabled
        })
        
        self.image = image
    }
    
    @IBAction func share() {
        if let name = locationName, let image = image?.pullValue {
            delegate?.collectionViewCellDidRequestShare(SharableTrafficCamera(name: name, image: image))
        }
    }
    
    @IBAction func toggleFavourite() {
        if let item = favouriteItem {
            delegate?.collectionViewCellDidToggleFavourite(item)
        }
    }
    
    override func prepareForReuse() {
        observations.removeAll()
        image = nil
        locationName = nil
        favouriteItem = nil
    }
}

struct SharableTrafficCamera: SharableItem {
    let name: String
    let image: UIImage?
    let link: NSURL? = nil
}