//
//  IncidentCell.swift
//  ScotTraffic
//
//  Created by Neil Gall on 15/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit
import MapKit

class IncidentCell: MapItemCollectionViewCellWithMap {
    
    @IBOutlet var backgroundImageView: UIImageView?
    @IBOutlet var iconImageView: UIImageView?
    @IBOutlet var dateLabel: UILabel?
    @IBOutlet var titleLabel: UILabel?
    @IBOutlet var textView: UITextView?
    @IBOutlet var shareButton: UIButton?

    private var item: SharableIncident?
    private var observations = [Observation]()
    
    override func configure(item: Item) {
        textView?.text = nil
        
        if case .IncidentItem(let incident) = item {
            iconImageView?.image = iconForIncidentType(incident.type)
            titleLabel?.text = incident.name
            dateLabel?.text = formatIncidentDate(incident.date)

            if let bg = backgroundImageView {
                configureMap(incident, forReferenceView: bg)
            }
            
            observations.append(mapImage.map(applyGradientMask) => { [weak self] image in
                self?.backgroundImageView?.image = image
            })

            // The first time we parse HTML using NSAttributedString involves dynamically
            // linking the WebKit framework which causes a noticable delay. Because the
            // collection view cells are populated immediately on the transition to the
            // view controller, defer setting the text to avoid a stutter in the animation.
            dispatch_async(dispatch_get_main_queue()) {
                let text = formatIncidentHTMLText(incident.text)
                self.textView?.text = text
                self.setNeedsLayout()
                
                self.item = SharableIncident(name: text, type: incident.type, link: incident.url, mapImage: self.mapImage.latest())
            }
        }
    }
    
    @IBAction func share() {
        if let item = item, shareButton = shareButton {
            let rect = convertRect(shareButton.bounds, fromView: shareButton)
            delegate?.collectionViewCell(self, didRequestShareItem: item, fromRect: rect)
        }
    }
    
    override func prepareForReuse() {
        observations.removeAll()
        item = nil
        
        iconImageView?.image = nil
        titleLabel?.text = nil
        dateLabel?.text = nil
        backgroundImageView?.image = nil

        super.prepareForReuse()
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

private func formatIncidentHTMLText(text: String) -> String {
    guard let textData = text.dataUsingEncoding(NSUTF8StringEncoding) else {
        return text
    }
    
    do {
        let attributedText = try NSAttributedString(data: textData,
            options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType],
            documentAttributes: nil)
        return attributedText.string.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
    } catch {
        return text
    }
}

private struct SharableIncident: SharableItem {
    let name: String
    let type: IncidentType
    let link: NSURL?
    let mapImage: Observable<UIImage?>
    
    var image: UIImage? {
        return mapImage.pullValue?.flatMap { $0 }
    }
    
    var text: String {
        let typeStr = (type == .Alert) ? "Incident" : "Roadworks"
        return "\(typeStr): \(name)\n\nShared using ScotTraffic"
    }
}