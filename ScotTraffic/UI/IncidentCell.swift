//
//  IncidentCell.swift
//  ScotTraffic
//
//  Created by Neil Gall on 15/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit
import MapKit

class IncidentCell: UICollectionViewCell, MapItemCollectionViewCell, BackgroundMapImage {
    
    @IBOutlet var backgroundImageView: UIImageView?
    @IBOutlet var iconImageView: UIImageView?
    @IBOutlet var dateLabel: UILabel?
    @IBOutlet var roadLabel: UILabel?
    @IBOutlet var titleLabel: UILabel?
    @IBOutlet var textView: UITextView?
    @IBOutlet var shareButton: UIButton?

    weak var delegate: MapItemCollectionViewCellDelegate?
    weak var mapView: MKMapView?
    let mapImage: Input<UIImage?> = Input(initial: nil)
    
    private var item: SharableIncident?
    private var receivers = [ReceiverType]()
    
    func configure(item: MapItemCollectionViewItem) {
        textView?.text = nil
        
        if case .IncidentItem(let incident) = item {
            iconImageView?.image = iconForIncidentType(incident.type)
            roadLabel?.text = incident.road
            titleLabel?.text = incident.name
            dateLabel?.text = formatIncidentDate(incident.date)

            if let bg = backgroundImageView {
                mapView = configureMap(incident, forReferenceView: bg)
            }
            
            receivers.append(mapImage.map(applyGradientMask) --> { [weak self] image in
                self?.backgroundImageView?.image = image
            })

            self.textView?.text = incident.text
            self.setNeedsLayout()
            
            self.item = SharableIncident(
                name: "\(incident.road) \(incident.text)",
                type: incident.type,
                link: incident.url,
                mapImage: self.mapImage.latest())
        }
    }
    
    @IBAction func share() {
        if let item = item, shareButton = shareButton {
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
        item = nil
        resetMap(mapView)
        
        iconImageView?.image = nil
        titleLabel?.text = nil
        dateLabel?.text = nil
        backgroundImageView?.image = nil

        super.prepareForReuse()
    }
}

extension IncidentCell: MKMapViewDelegate {
    func mapViewDidFinishRenderingMap(mapView: MKMapView, fullyRendered: Bool) {
        if fullyRendered {
            takeSnapshotOfRenderedMap(mapView)
        }
    }
}

private func iconForIncidentType(type: IncidentType) -> UIImage? {
    switch type {
    case .Alert:
        return UIImage(named: "incident-large")
    case .Roadworks:
        return UIImage(named: "roadworks-large")
    }
}

private func formatIncidentDate(date: NSDate) -> String {
    let formatter = NSDateFormatter()
    formatter.dateStyle = .MediumStyle
    formatter.timeStyle = .ShortStyle
    return formatter.stringFromDate(date)
}

private struct SharableIncident: SharableItem {
    let name: String
    let type: IncidentType
    let link: NSURL?
    let mapImage: Signal<UIImage?>
    
    var image: UIImage? {
        return mapImage.latestValue.get.flatMap { $0 }
    }
    
    var text: String {
        let typeStr = (type == .Alert) ? "Incident" : "Roadworks"
        return "\(typeStr): \(name)\n\nShared using ScotTraffic"
    }
}