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

    // -- MARK: Inputs
    
    // The visible map rect
    public let visibleMapRect: Input<MKMapRect>
    
    // The map items selected outside of the map view, if any
    public let selectedMapItem: Input<MapItem?>

    // A delegate to answer queries on map annotation overlaps
    public let delegate: Input<MapViewModelDelegate?>
    
    // A flag indicating whether the map is currently animating its visible rect
    public let animatingMapRect: Input<Bool>
    
    // A general purpose animation sequence. Dispatch animations via this sequence to (a) serialise
    // them and (b) defer annotation selection until the map is stable
    public let animationSequence = AsyncSequence()

    // -- MARK: Outputs
    
    // The set of annotations in the visible map rect
    public let annotations: Observable<[MapAnnotation]>
    
    // The selected annotation, if any
    public let selectedAnnotation: Observable<MapAnnotation?>
    
    // Indicates whether the user location should be shown on the map
    public let showsUserLocationOnMap: Observable<Bool>
    
    // Indicates whether traffic should be shown on the map
    public let showTrafficOnMap: Observable<Bool>
    
    
    // -- MARK: private data
    
    private let locationServices: LocationServices
    private var observations = [Observation]()

    public init(scotTraffic: ScotTraffic) {
        
        visibleMapRect = scotTraffic.settings.visibleMapRect
        locationServices = LocationServices(enabled: scotTraffic.settings.showCurrentLocationOnMap)
        showsUserLocationOnMap = locationServices.authorised
        showTrafficOnMap = scotTraffic.settings.showTrafficOnMap
        
        selectedMapItem = Input(initial: nil)
        animatingMapRect = Input(initial: false)
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
        
        let bridges = combine(
            scotTraffic.bridges,
            scotTraffic.settings.showBridgesOnMap,
            expandedVisibleMapRect,
            combine: mapItemsFromRect)
        
        let mapItemGroups: Observable<[MapItemGroup]> = combine(trafficCameras, safetyCameras, alerts, roadworks, bridges, delegate) {
            guard let delegate = $5 else {
                return []
            }
            return groupMapItems([$0, $1, $2, $3, $4].flatten(), delegate: delegate)
        }
        
        annotations = mapItemGroups.map({
            $0.map { group in MapAnnotation(mapItems: group) }
        }).latest()

        let selectionInputWhenNotAnimating = not(animatingMapRect || animationSequence.busy).gate(selectedMapItem)
        
        let selectedMapItemGroup = combine(mapItemGroups, selectionInputWhenNotAnimating) { groups, item in
            return mapItemGroupFromGroups(groups, containingItem: item)
        }
        
        selectedAnnotation = selectedMapItemGroup.map { optionalGroup in
            optionalGroup.map { items in MapAnnotation(mapItems: items) }
        }
    }
    
    public func annotationForMapItem(mapItem: MapItem) -> MapAnnotation? {
        for annotation in annotations.pullValue ?? [] {
            if annotation.mapItems.contains({ $0 == mapItem }) {
                return annotation
            }
        }
        return nil
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

func mapItemGroupFromGroups(groups: [MapItemGroup], containingItem item: MapItem?) -> [MapItem]? {
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
