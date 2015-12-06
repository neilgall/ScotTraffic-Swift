//
//  BridgeStatusCell.swift
//  ScotTraffic
//
//  Created by ZBS on 06/12/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit

class BridgeStatusCell : MapItemCollectionViewCellWithMap {

    @IBOutlet var backgroundImageView: UIImageView?
    @IBOutlet var dateLabel: UILabel?
    @IBOutlet var titleLabel: UILabel?
    @IBOutlet var messageLabel: UILabel?
    @IBOutlet var shareButton: UIButton?

    private var observations = [Observation]()
    private var sharableItem: ShareableBridge?
    
    override func configure(item: Item) {
        messageLabel?.text = nil

        if case .BridgeStatusItem(let bridgeStatus) = item {
            titleLabel?.text = bridgeStatus.name
            messageLabel?.text = bridgeStatus.message
            
            if let bg = backgroundImageView {
                configureMap(bridgeStatus, forReferenceView: bg)
            }
            
            observations.append(mapImage.map(applyGradientMask) => { [weak self] image in
                self?.backgroundImageView?.image = image
            })
            
            sharableItem = ShareableBridge(name: bridgeStatus.name, message: bridgeStatus.message)
        }
    }
    
    @IBAction func share() {
        if let item = sharableItem, shareButton = shareButton {
            let rect = convertRect(shareButton.bounds, fromView: shareButton)
            delegate?.collectionViewCell(self, didRequestShareItem: item, fromRect: rect)
        }
    }

    override func prepareForReuse() {
        observations.removeAll()
        
        titleLabel?.text = nil
        messageLabel?.text = nil
        dateLabel?.text = nil
        backgroundImageView?.image = nil
        
        super.prepareForReuse()
    }
}

private struct ShareableBridge: SharableItem {
    let name: String
    let message: String
    let image: UIImage? = nil
    let link: NSURL? = nil
    var text: String {
        return "\(name): \(message)\n\nShared using ScotTraffic"
    }
}