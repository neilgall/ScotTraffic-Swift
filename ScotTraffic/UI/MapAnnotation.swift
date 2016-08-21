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

        var imageComponents = [String]()
 
        if mapItems.contains(isAvailableTrafficCamera) {
            imageComponents.append("camera")
        
        } else if mapItems.filter({ $0 is TrafficCamera }).count > mapItems.filter({ $0 is SafetyCamera }).count {
            imageComponents.append("camera-unavailable")

        } else if mapItems.contains({ $0 is SafetyCamera }) {
            imageComponents.append("safetycamera")
        }
        
        if mapItems.contains(isAlert) {
            imageComponents.append("incident")
        
        } else if mapItems.contains(isRoadworks) {
            imageComponents.append("roadworks")
        }

        if imageComponents.isEmpty && mapItems.contains({ $0 is BridgeStatus }) {
            imageComponents.append("blue-circle")
        }
        
        image = compositeImagesNamed(imageComponents)
        reuseIdentifier = imageComponents.joinWithSeparator(".")
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

private func isAvailableTrafficCamera(mapItem: MapItem) -> Bool {
    guard let location = mapItem as? TrafficCameraLocation else {
        return false
    }
    return location.cameras.filter({ $0.isAvailable }).count > 0
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
