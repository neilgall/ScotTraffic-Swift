//
//  MapViewModel.swift
//  ScotTraffic
//
//  Created by Neil Gall on 05/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import MapKit

private let visibleMapRectInsetRatio: Double = -0.2
private let zoomToMapItemInsetX: Double = -40000
private let zoomToMapItemInsetY: Double = -40000

typealias MapItemGroup = [MapItem]

protocol MapViewModelDelegate {
    func annotationAtMapPoint(mapPoint1: MKMapPoint, wouldOverlapWithAnnotationAtMapPoint mapPoint2: MKMapPoint) -> Bool
}

class MapViewModel {

    let maximumItemsInDetailView: Int
    
    // -- MARK: Inputs
    
    // The visible map rect
    let visibleMapRect: Input<MKMapRect>
    
    // The map items selected outside of the map view, if any
    let selectedMapItem: Input<MapItem?>

    // A delegate to answer queries on map annotation overlaps
    let delegate: Input<MapViewModelDelegate?>
    
    // A flag indicating whether the map is currently animating its visible rect
    let animatingMapRect: Input<Bool>
    
    // A flag indicating whether the entire map visibility is currently being animated
    let animatingVisibility: Input<Bool>
    
    // -- MARK: Outputs
    
    // The set of annotations in the visible map rect
    let annotations: Signal<[MapAnnotation]>
    
    // The selected annotation, if any
    let selectedAnnotation: Signal<MapAnnotation?>
    
    // Indicates whether the user location should be shown on the map
    let showsUserLocationOnMap: Signal<Bool>
    
    // Indicates whether traffic should be shown on the map
    let showTrafficOnMap: Signal<Bool>
    
    
    // -- MARK: private data
    
    private let locationServices: LocationServices
    private var receivers = [ReceiverType]()

    init(scotTraffic: ScotTraffic, maximumItemsInDetailView: Int) {
        
        self.maximumItemsInDetailView = maximumItemsInDetailView
        
        visibleMapRect = scotTraffic.settings.visibleMapRect
        locationServices = LocationServices(enabled: scotTraffic.settings.showCurrentLocationOnMap)
        showsUserLocationOnMap = locationServices.authorised
        showTrafficOnMap = scotTraffic.settings.showTrafficOnMap
        
        selectedMapItem = Input(initial: nil)
        animatingMapRect = Input(initial: false)
        animatingVisibility = Input(initial: false)
        delegate = Input(initial: nil)
        
        let expandedVisibleMapRect = visibleMapRect.map { rect in
            return MKMapRectInset(rect,
                visibleMapRectInsetRatio * rect.size.width,
                visibleMapRectInsetRatio * rect.size.height)
        }
        
        let trafficCameras = combine(
            scotTraffic.trafficCameraLocations,
            scotTraffic.favourites.items,
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
        
        let mapItemGroups: Signal<[MapItemGroup]> = combine(trafficCameras, safetyCameras, alerts, roadworks, bridges, delegate) {
            guard let delegate = $5 else {
                return []
            }
            return groupMapItems([$0, $1, $2, $3, $4].flatten(), delegate: delegate)
        }
        
        annotations = mapItemGroups.map({
            $0.map { group in MapAnnotation(mapItems: group) }
        }).latest()

        let selectedMapItemEvent = notNil(selectedMapItem).event()
        
        let shouldZoomToMapItem = selectedMapItemEvent.mapWith(visibleMapRect, annotations,
            transform: { (mapItem: MapItem, mapRect: MKMapRect, annotations: [MapAnnotation]) -> Bool in
                
                // if the map item isn't visible, zoom to it
                if !mapRect.contains(mapItem.mapPoint) {
                    return true
                }
                
                // if the annotation contains too many map items to open the collection view, zoom
                if let annotation = annotations.filter({ $0.mapItems.contains({ $0 == mapItem }) }).first
                    where annotation.mapItems.flatCount > maximumItemsInDetailView {
                        return true
                }
                
                // otherwise don't zoom on selection
                return false
        })
        
        let zoomToMapItem: Signal<MKMapRect> = shouldZoomToMapItem.gate(selectedMapItemEvent).map({
            MKMapRectInset(MKMapRectNull.addPoint($0.mapPoint), zoomToMapItemInsetX, zoomToMapItemInsetY)
        })
        
        // Defer annotation selection until after visibility animations (due to the split view controller
        // transitions) and after any map rect transition also triggered by the selection.
        let selectionInputAfterZooming = not(animatingMapRect || animatingVisibility).gate(selectedMapItem)
        
        let selectedMapItemGroup = selectionInputAfterZooming.mapWith(mapItemGroups, transform: { item, groups in
            return mapItemGroupFromGroups(groups, containingItem: item)
        })
        
        selectedAnnotation = selectedMapItemGroup.map { optionalGroup in
            optionalGroup.map({ items in MapAnnotation(mapItems: items) })
        }

        receivers.append(zoomToMapItem --> { [weak self] in
            if let visibleMapRect = self?.visibleMapRect {
                visibleMapRect <-- $0
            }
        })
    }
}

func trafficCamerasFromRectAndFavourites(mapItems: [TrafficCameraLocation], favourites: [FavouriteItem], isEnabled: Bool, mapRect: MKMapRect) -> [MapItem] {
    
    if isEnabled {
        return mapItemsFromRect(mapItems, isEnabled: true, mapRect: mapRect)
    } else {
        let favouritesSet = favourites.trafficCameraIdentifiers
        
        let isMemberOfFavourites = { (location: TrafficCameraLocation) -> Bool in
            !location.cameraIdentifiers.intersect(favouritesSet).isEmpty
        }
        
        return mapItemsFromRect(mapItems.filter(isMemberOfFavourites), isEnabled: true, mapRect: mapRect)
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
                groups[i].point = groups[i].items.centrePoint
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
