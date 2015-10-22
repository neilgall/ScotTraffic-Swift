//
//  MapViewModel.swift
//  ScotTraffic
//
//  Created by Neil Gall on 05/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import MapKit

private let visibleMapRectInsetRatio: Double = -0.2

typealias MapItemGroup = [MapItem]

public protocol MapViewModelDelegate {
    func annotationAtMapPoint(mapPoint1: MKMapPoint, wouldOverlapWithAnnotationAtMapPoint mapPoint2: MKMapPoint) -> Bool
}

public class MapViewModel {

    let visibleMapRect: Input<MKMapRect>
    let selectedMapItem: Input<MapItem?>
    let delegate: Input<MapViewModelDelegate?>

    let mapItemGroups : Observable<[MapItemGroup]>
    let annotations: Observable<[MapAnnotation]>
    let selectedAnnotation: Observable<MapAnnotation?>
 
    public init(scotTraffic: ScotTraffic) {
        
        visibleMapRect = scotTraffic.settings.visibleMapRect
        selectedMapItem = Input(initial: nil)
        delegate = Input(initial: nil)
        
        let expandedVisibleMapRect = visibleMapRect.map { rect in
            return MKMapRectInset(rect,
                visibleMapRectInsetRatio * rect.size.width,
                visibleMapRectInsetRatio * rect.size.height)
        }
        
        let trafficCameras = combine(
            scotTraffic.trafficCameraLocations,
            scotTraffic.favourites.trafficCameras,
            scotTraffic.settings.showTrafficCamerasOnMap,
            expandedVisibleMapRect,
            combine: trafficCamerasFromRectAndFavourites)

        let safetyCameras = combine(
            scotTraffic.safetyCameras,
            scotTraffic.settings.showSafetyCamerasOnMap,
            expandedVisibleMapRect,
            combine: mapItemsFromRect)
        
        let alerts = combine(
            scotTraffic.alerts,
            scotTraffic.settings.showAlertsOnMap,
            expandedVisibleMapRect,
            combine: mapItemsFromRect)
        
        let roadworks = combine(
            scotTraffic.roadworks,
            scotTraffic.settings.showRoadworksOnMap,
            expandedVisibleMapRect,
            combine: mapItemsFromRect)
        
        mapItemGroups = combine(trafficCameras, safetyCameras, alerts, roadworks, delegate) {
            guard let delegate = $4 else {
                return []
            }
            return groupMapItems([$0, $1, $2, $3].flatten(), delegate: delegate)
        }
        
        annotations = mapItemGroups.map {
            $0.map { group in MapAnnotation(mapItems: group) }
        }
        
        let selectedMapItemGroup = combine(mapItemGroups, selectedMapItem, combine:mapItemGroupContainingItem)

        selectedAnnotation = selectedMapItemGroup.map { optionalGroup in
            optionalGroup.map { items in MapAnnotation(mapItems: items) }
        }
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

func groupMapItems<MapItems: CollectionType where MapItems.Generator.Element == MapItem>
    (mapItems: MapItems, delegate: MapViewModelDelegate) -> [MapItemGroup]
{
    var groups = [ (point: MKMapPoint, items: MapItemGroup) ]()
    
    mapItems.forEach { item in
        for i in 0..<groups.count {
            if delegate.annotationAtMapPoint(groups[i].point, wouldOverlapWithAnnotationAtMapPoint: item.mapPoint) {
                groups[i].items.append(item)
                groups[i].point = groups[i].items.weightedCentrePoint
                return
            }
        }

        let group = (point: item.mapPoint, items: [item])
        groups.append(group)
    }
    
    return groups.map { $0.items }
}

func mapItemGroupContainingItem(groups: [MapItemGroup], item: MapItem?) -> [MapItem]? {
    guard let item = item else {
        return nil
    }
    let possibleIndex = groups.indexOf { groupItems in
        groupItems.contains({ $0 == item })
    }
    guard let index = possibleIndex else {
        return nil
    }
    return groups[index]
}
