//
//  MapAnnotation.swift
//  ScotTraffic
//
//  Created by Neil Gall on 05/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import CoreLocation
import MapKit

private let coordinateEqualityAccuracy = 1e-6

class MapAnnotation: NSObject, MKAnnotation {

    let mapItems: [MapItem]
    let coordinate: CLLocationCoordinate2D
    let title: String?
    let subtitle: String?
    let reuseIdentifier: String
    let image: UIImage?
    
    init(mapItems: [MapItem]) {
        self.mapItems = mapItems
        
        coordinate = MKCoordinateForMapPoint(mapItems.centrePoint)
        subtitle = nil

        if mapItems.count == 1 {
            title = mapItems[0].name

        } else {
            title = "\(mapItems.flatCount) items"
        }
        
        let trafficCameraCount = mapItems.filter(isTrafficCamera).count
        let availableTrafficCameraCount = mapItems.filter(isAvailableTrafficCamera).count
        let safetyCameraCount = mapItems.filter(isSafetyCamera).count
        let alertCount = mapItems.filter(isAlert).count
        let roadworksCount = mapItems.filter(isRoadworks).count
        let bridgeCount = mapItems.filter(isBridgeStatus).count

        reuseIdentifier = "\(trafficCameraCount > 0).\(availableTrafficCameraCount > 0).\(safetyCameraCount > 0).\(alertCount > 0).\(roadworksCount > 0).\(bridgeCount > 0)"
        
        var imageComponents = [String]()
 
        if availableTrafficCameraCount > 0 {
            imageComponents.append("camera")
        
        } else if trafficCameraCount > safetyCameraCount {
            imageComponents.append("camera-unavailable")

        } else if safetyCameraCount > 0 {
            imageComponents.append("safetycamera")
        }
        
        if alertCount > 0 {
            imageComponents.append("incident")
        
        } else if roadworksCount > 0 {
            imageComponents.append("roadworks")
        }

        if bridgeCount > 0 && imageComponents.isEmpty {
            imageComponents.append("blue-circle")
        }
        
        image = compositeImagesNamed(imageComponents)
    }

    override var hashValue: Int {
        return (Int(coordinate.latitude / coordinateEqualityAccuracy) * 31)
            ^ Int(coordinate.longitude / coordinateEqualityAccuracy)
    }
    
    override func isEqual(object: AnyObject?) -> Bool {
        guard let annotation = object as? MapAnnotation else {
            return false
        }
        return fabs(coordinate.latitude - annotation.coordinate.latitude) < coordinateEqualityAccuracy
            && fabs(coordinate.longitude - annotation.coordinate.longitude) < coordinateEqualityAccuracy
    }
}

func == (a: MapAnnotation, b: MapAnnotation) -> Bool {
    return a.isEqual(b)
}

private func isTrafficCamera(mapItem: MapItem) -> Bool {
    return mapItem as? TrafficCameraLocation != nil
}

private func isAvailableTrafficCamera(mapItem: MapItem) -> Bool {
    guard let location = mapItem as? TrafficCameraLocation else {
        return false
    }
    return location.cameras.filter({ $0.isAvailable }).count > 0
}

private func isSafetyCamera(mapItem: MapItem) -> Bool {
    return mapItem as? SafetyCamera != nil
}

private func isAlert(mapItem: MapItem) -> Bool {
    guard let incident = mapItem as? Incident else {
        return false
    }
    return incident.type == IncidentType.Alert
}

private func isRoadworks(mapItem: MapItem) -> Bool {
    guard let incident = mapItem as? Incident else {
        return false
    }
    return incident.type == IncidentType.Roadworks
}

private func isBridgeStatus(mapItem: MapItem) -> Bool {
    return mapItem as? BridgeStatus != nil
}
