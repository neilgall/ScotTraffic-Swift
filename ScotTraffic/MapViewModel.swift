//
//  MapViewModel.swift
//  ScotTraffic
//
//  Created by Neil Gall on 05/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import MapKit

public protocol MapViewModelDelegate {
    func annotationsWouldOverlap(mapPoint1: MKMapPoint, mapPoint2: MKMapPoint) -> Bool
}

public class MapViewModel {
    
    let mapItemGroups : Observable<[[MapItem]]>
    let annotations: Latest<[MapAnnotation]>
    let visibleMapRect: Input<MKMapRect>
    let delegate: Input<MapViewModelDelegate?>
 
    public init(appModel: AppModel) {
        
        visibleMapRect = Input(initial: MKMapRectWorld)
        delegate = Input(initial: nil)
        
        let trafficCameras = combine(
            appModel.trafficCameraLocations,
            appModel.favourites.trafficCameras,
            appModel.settings.showTrafficCamerasOnMap,
            visibleMapRect,
            combine: trafficCamerasFromRectAndFavourites)

        let safetyCameras = combine(
            appModel.safetyCameras,
            appModel.settings.showSafetyCamerasOnMap,
            visibleMapRect,
            combine: mapItemsFromRect)
        
        let alerts = combine(
            appModel.alerts,
            appModel.settings.showAlertsOnMap,
            visibleMapRect,
            combine: mapItemsFromRect)
        
        let roadworks = combine(
            appModel.roadworks,
            appModel.settings.showRoadworksOnMap,
            visibleMapRect,
            combine: mapItemsFromRect)
        
        mapItemGroups = combine(trafficCameras, safetyCameras, alerts, roadworks, delegate) {
            guard let delegate = $4 else {
                return []
            }
            return groupMapItems($0 + $1 + $2 + $3, delegate: delegate)
        }

        let annotations = mapItemGroups.map {
            $0.map { group in MapAnnotation(mapItems: group) }
        }
        
        self.annotations = annotations.latest()
        
    }
}

func trafficCamerasFromRectAndFavourites(mapItems: [TrafficCameraLocation], favourites: [FavouriteTrafficCamera], isEnabled: Bool, mapRect: MKMapRect) -> [MapItem] {
    if isEnabled {
        return mapItemsFromRect(mapItems, isEnabled: true, mapRect: mapRect)
    } else {
        return mapItemsFromRect(favourites.map { $0.location }, isEnabled: true, mapRect: mapRect)
    }
}

func mapItemsFromRect<T: MapItem>(mapItems: [T], isEnabled: Bool, mapRect: MKMapRect) -> [MapItem] {
    guard isEnabled else {
        return []
    }
    return mapItems.flatMap { item in
        MKMapRectContainsPoint(mapRect, item.mapPoint) ? (item as MapItem) : nil
    }
}

func groupMapItems(mapItems: [MapItem], delegate: MapViewModelDelegate) -> [[MapItem]] {
    var groups = [ (centrePoint: MKMapPoint, items: [MapItem]) ]()
    
    mapItems.forEach { item in
        for i in 0..<groups.count {
            if delegate.annotationsWouldOverlap(groups[i].centrePoint, mapPoint2: item.mapPoint) {
                groups[i].items.append(item)
                groups[i].centrePoint = groups[i].items.boundingRect.centrePoint
                return
            }
        }
        groups.append( (centrePoint: item.mapPoint, items: [item]) )
    }

    return groups.map { $0.items }
}