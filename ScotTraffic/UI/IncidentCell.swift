//
//  IncidentCell.swift
//  ScotTraffic
//
//  Created by Neil Gall on 15/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit

class IncidentCell: MapItemCollectionViewCell {
    
    @IBOutlet var iconImageView: UIImageView?
    @IBOutlet var dateLabel: UILabel?
    @IBOutlet var titleLabel: UILabel?
    @IBOutlet var textLabel: UILabel?
    @IBOutlet var shareButton: UIButton?
    private var item: SharableIncident?
    
    override func configure(item: Item, usingHTTPFetcher fetcher: HTTPFetcher) {
        textLabel?.text = nil
        
        if case .IncidentItem(let incident) = item {
            iconImageView?.image = iconForIncidentType(incident.type)
            titleLabel?.text = incident.name
            dateLabel?.text = formatIncidentDate(incident.date)
            
            // The first time we parse HTML using NSAttributedString involves dynamically
            // linking the WebKit framework which causes a noticable delay. Because the
            // collection view cells are populated immediately on the transition to the
            // view controller, defer setting the text to avoid a stutter in the animation.
            dispatch_async(dispatch_get_main_queue()) {
                let text = formatIncidentHTMLText(incident.text)
                self.textLabel?.text = text
                self.setNeedsLayout()
                
                self.item = SharableIncident(name: text, type: incident.type, link: incident.url)
            }
        }
    }
    
    @IBAction func share() {
        if let item = item {
            let rect = convertRect(shareButton!.bounds, fromView: shareButton!)
            delegate?.collectionViewCell(self, didRequestShareItem: item, fromRect: rect)
        }
    }
    
    override func prepareForReuse() {
        item = nil
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
    return ""
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
    let image: UIImage? = nil
    let link: NSURL?
    
    var text: String {
        let typeStr = (type == .Alert) ? "Incident" : "Roadworks"
        return "\(typeStr): \(name)\n\nShared using ScotTraffic"
    }
}