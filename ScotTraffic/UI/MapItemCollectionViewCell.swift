//
//  MapItemCollectionViewCell.swift
//  ScotTraffic
//
//  Created by Neil Gall on 15/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit

public protocol MapItemCollectionViewCellDelegate: class {
    func collectionViewCellDidRequestShare(item: SharableItem)
    func collectionViewCellDidToggleFavourite(item: FavouriteTrafficCamera)
}

public class MapItemCollectionViewCell: UICollectionViewCell {
    weak var delegate: MapItemCollectionViewCellDelegate?

    public enum Type: String {
        case TrafficCameraCell
        case SafetyCameraCell
        case IncidentCell
        case BridgeStatusCell
        
        static public let allValues = [TrafficCameraCell, SafetyCameraCell, IncidentCell, BridgeStatusCell]
        
        var reuseIdentifier: String {
            return rawValue
        }
    }
    
    public enum Item {
        case TrafficCameraItem(TrafficCameraLocation, TrafficCamera)
        case SafetyCameraItem(SafetyCamera)
        case IncidentItem(Incident)
        
        var type: Type {
            switch self {
            case .TrafficCameraItem: return .TrafficCameraCell
            case .SafetyCameraItem: return .SafetyCameraCell
            case .IncidentItem: return .IncidentCell
            }
        }
        
        static func forMapItem(mapItem: MapItem) -> [Item] {
            if let trafficCameraLocation = mapItem as? TrafficCameraLocation {
                return trafficCameraLocation.cameras.map { TrafficCameraItem(trafficCameraLocation, $0) }
                
            } else if let safetyCamera = mapItem as? SafetyCamera {
                return [ SafetyCameraItem(safetyCamera) ]
                
            } else if let incident = mapItem as? Incident {
                return [ IncidentItem(incident) ]
                
            } else {
                abort()
            }
        }
    }

    public static func registerTypesWith(collectionView: UICollectionView) {
        for type in Type.allValues {
            let cellClass: AnyClass? = NSClassFromString(type.rawValue)
            let cellNib = UINib(nibName: type.rawValue, bundle: nil)
            
            collectionView.registerClass(cellClass, forCellWithReuseIdentifier: type.reuseIdentifier)
            collectionView.registerNib(cellNib, forCellWithReuseIdentifier: type.reuseIdentifier)
        }
    }

    func configure(item: Item, usingHTTPFetcher fetcher: HTTPFetcher) {
        abort()
    }
}
