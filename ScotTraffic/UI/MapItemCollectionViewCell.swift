//
//  MapItemCollectionViewCell.swift
//  ScotTraffic
//
//  Created by Neil Gall on 15/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit

public enum MapItemCollectionViewItemType: String {
    case TrafficCameraCell
    case SafetyCameraCell
    case IncidentCell
    case BridgeStatusCell
    
    var reuseIdentifier: String {
        return rawValue
    }

    static private let allValues = [TrafficCameraCell, SafetyCameraCell, IncidentCell, BridgeStatusCell]
    
    public static func registerTypesWith(collectionView: UICollectionView) {
        for type in allValues {
            let cellClass: AnyClass? = NSClassFromString(type.rawValue)
            let cellNib = UINib(nibName: type.rawValue, bundle: nil)
            
            collectionView.registerClass(cellClass, forCellWithReuseIdentifier: type.reuseIdentifier)
            collectionView.registerNib(cellNib, forCellWithReuseIdentifier: type.reuseIdentifier)
        }
    }
}

public enum MapItemCollectionViewItem {
    case TrafficCameraItem(TrafficCameraLocation, TrafficCamera)
    case SafetyCameraItem(SafetyCamera)
    case IncidentItem(Incident)
    case BridgeStatusItem(BridgeStatus, Settings)
    
    var type: MapItemCollectionViewItemType {
        switch self {
        case .TrafficCameraItem: return .TrafficCameraCell
        case .SafetyCameraItem: return .SafetyCameraCell
        case .IncidentItem: return .IncidentCell
        case .BridgeStatusItem: return .BridgeStatusCell
        }
    }
    
    func matchesSelection(selection: SearchViewModel.Selection) -> Bool {
        switch self {
        case .TrafficCameraItem(let location, let camera):
            return location == selection.mapItem && camera == location.cameras[selection.index]
            
        case .SafetyCameraItem(let safetyCamera):
            return safetyCamera == selection.mapItem
            
        case .IncidentItem(let incident):
            return incident == selection.mapItem
            
        case .BridgeStatusItem(let bridgeStatus, _):
            return bridgeStatus == selection.mapItem
        }
    }
    
    static func forMapItem(mapItem: MapItem, settings: Settings) -> [MapItemCollectionViewItem] {
        if let trafficCameraLocation = mapItem as? TrafficCameraLocation {
            return trafficCameraLocation.cameras.map { TrafficCameraItem(trafficCameraLocation, $0) }
            
        } else if let safetyCamera = mapItem as? SafetyCamera {
            return [ SafetyCameraItem(safetyCamera) ]
            
        } else if let incident = mapItem as? Incident {
            return [ IncidentItem(incident) ]
            
        } else if let bridgeStatus = mapItem as? BridgeStatus {
            return [ BridgeStatusItem(bridgeStatus, settings) ]
            
        } else {
            fatalError("Unexpected mapItem \(mapItem)")
        }
    }
}

public protocol MapItemCollectionViewCellDelegate: class {
    func collectionViewCell(cell: UICollectionViewCell, didRequestShareItem item: SharableItem, fromRect rect: CGRect)
    func collectionViewCellDidToggleFavourite(item: FavouriteTrafficCamera)
    func collectionViewItemIsFavourite(item: FavouriteTrafficCamera) -> Bool
}

public protocol MapItemCollectionViewCell {
    weak var delegate: MapItemCollectionViewCellDelegate? { get set }
    func configure(item: MapItemCollectionViewItem)
}

extension MapItemCollectionViewCell where Self: UICollectionViewCell {
    
    public func fillCellWithFirstSubview() {
        if let subview = self.subviews.first {
            subview.translatesAutoresizingMaskIntoConstraints = false
            for attribute: NSLayoutAttribute in [.Left, .Right, .Top, .Bottom] {
                addConstraint(NSLayoutConstraint(
                    item: subview,
                    attribute: attribute,
                    relatedBy: .Equal,
                    toItem: self,
                    attribute: attribute,
                    multiplier: 1.0,
                    constant: 0.0))
            }
        }
    }
}

