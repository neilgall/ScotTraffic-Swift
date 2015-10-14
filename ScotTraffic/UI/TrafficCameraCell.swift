//
//  TrafficCameraCell.swift
//  ScotTraffic
//
//  Created by ZBS on 14/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit

public class TrafficCameraCell: UICollectionViewCell {
    
    @IBOutlet var imageView: UIImageView?
    @IBOutlet var errorLabel: UILabel?
    @IBOutlet var titleLabel: UILabel?
    @IBOutlet var favouriteButton: UIButton?
    @IBOutlet var shareButton: UIButton?
    var imageObservation: Observation?
    
    func obtainImage(supplier: ImageSupplier, usingHTTPFetcher fetcher: HTTPFetcher) {
        self.errorLabel?.hidden = true
        
        imageObservation = supplier.image(fetcher).output { [weak self] image in
            self?.errorLabel?.hidden = (image != nil)
            self?.imageView?.image = image
        }
    }

    @IBAction func share() {
        
    }
    
    @IBAction func toggleFavourite() {
        
    }
    
    override public func prepareForReuse() {
        imageObservation = nil
    }
}
