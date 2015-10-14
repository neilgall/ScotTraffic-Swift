//
//  MapItemCollectionViewModel.swift
//  ScotTraffic
//
//  Created by ZBS on 11/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit

public class MapItemCollectionViewModel: NSObject, UICollectionViewDataSource {
    
    enum CellType: String {
        case TrafficCameraCell
        case SafetyCameraCell
        case IncidentCell
        case BridgeStatusCell
        
        static let allValues = [TrafficCameraCell, SafetyCameraCell, IncidentCell, BridgeStatusCell]
        
        var reuseIdentifier: String {
            return rawValue
        }
        
        var cellClass: AnyClass? {
            return NSClassFromString(rawValue)
        }
        
        var cellNib: UINib? {
            return UINib(nibName: rawValue, bundle: nil)
        }
        
        func register(collectionView: UICollectionView) {
            collectionView.registerClass(cellClass, forCellWithReuseIdentifier: reuseIdentifier)
            collectionView.registerNib(cellNib, forCellWithReuseIdentifier: reuseIdentifier)
        }
    }
    
    enum CellItem {
        case TrafficCameraItem(TrafficCameraLocation, TrafficCamera)
        case SafetyCameraItem(SafetyCamera)
        case IncidentItem(Incident)
        
        var type: CellType {
            switch self {
            case .TrafficCameraItem: return .TrafficCameraCell
            case .SafetyCameraItem: return .SafetyCameraCell
            case .IncidentItem: return .IncidentCell
            }
        }
        
        static func forMapItem(mapItem: MapItem) -> [CellItem] {
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
    
    let cellItems: [CellItem]
    let fetcher: HTTPFetcher
    
    public init(mapItems: [MapItem], fetcher: HTTPFetcher) {
        self.cellItems = mapItems.flatMap({ CellItem.forMapItem($0) })
        self.fetcher = fetcher
    }

    // -- MARK: UICollectionViewDataSource --
    
    public func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return cellItems.count
    }
    
    public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cellItem = cellItems[indexPath.item]
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(cellItem.type.reuseIdentifier, forIndexPath: indexPath)
        
        switch cellItem {
        case .TrafficCameraItem(let location, let camera):
            if let cell = cell as? TrafficCameraCell {
                cell.titleLabel?.text = trafficCameraName(camera, atLocation: location)
                cell.obtainImage(camera, usingHTTPFetcher: fetcher)
            }
            
        case .SafetyCameraItem(let safetyCamera):
            break
            
        case .IncidentItem(let incident):
            break
        }

        return cell
    }
    
}