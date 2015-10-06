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

public class MapAnnotation: NSObject, MKAnnotation {

    public let mapItems: [MapItem]
    public let coordinate: CLLocationCoordinate2D
    public let title: String?
    public let subtitle: String?
    public let reuseIdentifier: String
    public let image: UIImage?
    
    public init(mapItems: [MapItem]) {
        self.mapItems = mapItems
        
        coordinate = MKCoordinateForMapPoint(mapItems.boundingRect.centrePoint)
        subtitle = nil

        if mapItems.count == 1 {
            title = mapItems[0].name

        } else {
            title = "\(mapItems.count) items"
        }
        
        let trafficCameraCount = mapItems.filter(isTrafficCamera).count
        let availableTrafficCameraCount = mapItems.filter(isAvailableTrafficCamera).count
        let safetyCameraCount = mapItems.filter(isSafetyCamera).count
        let alertCount = mapItems.filter(isAlert).count
        let roadworksCount = mapItems.filter(isRoadworks).count

        reuseIdentifier = "\(trafficCameraCount).\(availableTrafficCameraCount).\(safetyCameraCount).\(alertCount).\(roadworksCount)"
        
        var imageComponents = [String]()
 
        if trafficCameraCount > 0 && availableTrafficCameraCount >= safetyCameraCount {
            imageComponents.append(availableTrafficCameraCount > 0 ? "camera" : "camera-unavailable")

        } else if safetyCameraCount > 0 && safetyCameraCount > availableTrafficCameraCount {
            imageComponents.append("safetycamera")
        }
        
        if alertCount > 0 {
            imageComponents.append("incident")
        
        } else if roadworksCount > 0 {
            imageComponents.append("roadworks")
        }
        
        image = compositeImagesNamed(imageComponents)
    }
    
    override public var hashValue: Int {
        return Int(coordinate.latitude / coordinateEqualityAccuracy)
            ^ Int(coordinate.longitude / coordinateEqualityAccuracy)
    }
}

public func == (a: MapAnnotation, b: MapAnnotation) -> Bool {
    return fabs(a.coordinate.latitude - b.coordinate.latitude) < coordinateEqualityAccuracy
        && fabs(a.coordinate.longitude - b.coordinate.longitude) < coordinateEqualityAccuracy
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
