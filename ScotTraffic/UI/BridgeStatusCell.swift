//
//  BridgeStatusCell.swift
//  ScotTraffic
//
//  Created by ZBS on 06/12/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit
import MapKit

class BridgeStatusCell: UICollectionViewCell, MapItemCollectionViewCell, BackgroundMapImage {

    @IBOutlet var backgroundImageView: UIImageView?
    @IBOutlet var dateLabel: UILabel?
    @IBOutlet var titleLabel: UILabel?
    @IBOutlet var messageLabel: UILabel?
    @IBOutlet var shareButton: UIButton?
    @IBOutlet var notificationEnableSwitch: UISwitch?

    weak var delegate: MapItemCollectionViewCellDelegate?
    weak var mapView: MKMapView?
    let mapImage: Input<UIImage?> = Input(initial: nil)
    
    private var receivers = [ReceiverType]()
    private var sharableItem: ShareableBridge?
    
    func configure(item: MapItemCollectionViewItem) {
        messageLabel?.text = nil

        if case .BridgeStatusItem(let bridgeStatus) = item {
            titleLabel?.text = bridgeStatus.name
            messageLabel?.text = bridgeStatus.message
            dateLabel?.text = nil
            
            if let bg = backgroundImageView {
                mapView = configureMap(bridgeStatus, forReferenceView: bg)
            }
            
            receivers.append(mapImage.map(applyGradientMask) --> { [weak self] image in
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

    override func awakeFromNib() {
        super.awakeFromNib()
        fillCellWithFirstSubview()
    }
    
    override func prepareForReuse() {
        receivers.removeAll()
        resetMap(mapView)
        
        titleLabel?.text = nil
        messageLabel?.text = nil
        dateLabel?.text = nil
        backgroundImageView?.image = nil
        
        super.prepareForReuse()
    }
}

extension BridgeStatusCell: MKMapViewDelegate {
    func mapViewDidFinishRenderingMap(mapView: MKMapView, fullyRendered: Bool) {
        if fullyRendered {
            takeSnapshotOfRenderedMap(mapView)
        }
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