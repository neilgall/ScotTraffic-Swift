//
//  TodayViewModel.swift
//  ScotTraffic
//
//  Created by Neil Gall on 21/11/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit

class TodayViewModel {
 
    // Outputs
    let image: Observable<UIImage>
    let title: Observable<String>
    let showError: Observable<Bool>
    let canMoveToPrevious: Observable<Bool>
    let canMoveToNext: Observable<Bool>
    
    let diskCache: DiskCache
    let fetcher: HTTPFetcher
    let trafficCamerasSource: DataSource
    let weatherSource: DataSource
    let favourites: Favourites
    let settings: TodaySettings
    let weatherViewModel: WeatherViewModel
    var observations: [Observation] = []
    var observeSupplier: Observation? = nil
    
    init() {
        let diskCache = DiskCache(withPath: "scottraffic")
        let fetcher = HTTPFetcher(baseURL: ScotTrafficBaseURL, indicator: nil)
        
        let cachedDataSource = CachedHTTPDataSource.dataSourceWithFetcher(fetcher, cache: diskCache)
        
        guard let userDefaults = NSUserDefaults(suiteName: ScotTrafficAppGroup) else {
            fatalError("cannot create NSUserDefaults with suiteName \(ScotTrafficAppGroup)")
        }
        
        self.diskCache = diskCache
        self.fetcher = fetcher
        self.settings = TodaySettings(userDefaults: userDefaults)
        
        // -- traffic cameras
        
        self.trafficCamerasSource = cachedDataSource(maximumCacheAge: 900)(path: "trafficcameras.json")
        let trafficCamerasContext = TrafficCameraDecodeContext(makeImageDataSource: cachedDataSource(maximumCacheAge: 300))
        let trafficCameraLocations = trafficCamerasSource.value.map {
            return $0.map(Array<TrafficCameraLocation>.decodeJSON(trafficCamerasContext) <== JSONArrayFromData)
        }
        
        // -- weather
        
        self.weatherSource = cachedDataSource(maximumCacheAge: 900)(path: "weather.json")
        let weather = weatherSource.value.map {
            $0.map(Array<Weather>.decodeJSON(Void) <== JSONArrayFromData)
        }
        let weatherFinder = valueFromEither(weather).latest().map() { (weather: [Weather]) -> (MapItem -> Weather?) in
            return { (mapItem: MapItem) -> Weather? in
                let distanceSq = { (w: Weather) -> Double in w.mapPoint.distanceSqToMapPoint(mapItem.mapPoint) }
                return weather.minElement( { distanceSq($0) < distanceSq($1) })
            }
        }

        // -- favourites
        
        self.favourites = Favourites(userDefaults: userDefaults,
            trafficCameraLocations: valueFromEither(trafficCameraLocations).latest())
        
        let selectedFavourite: Observable<FavouriteTrafficCamera> = combine(favourites.trafficCameras, settings.imageIndex) { favourites, imageIndex in
            let index = max(0, min(imageIndex, favourites.count))
            return favourites[index]
        }
        
        // -- outputs
        
        self.title = selectedFavourite.map({ favourite in
            return trafficCameraName(favourite.location.cameras[favourite.cameraIndex], atLocation: favourite.location)
        }).latest()
        
        self.weatherViewModel = WeatherViewModel(
            weatherFinder: weatherFinder,
            mapItem: selectedFavourite.map({ $0.location }),
            temperatureUnit: settings.temperatureUnit)
        
        
        self.canMoveToPrevious = settings.imageIndex.map({ index in
            return index > 0
        }).latest()
        
        self.canMoveToNext = combine(favourites.trafficCameras, settings.imageIndex) { favourites, index in
            return index < favourites.count-1
        }

        self.image = Observable()
        self.showError = Observable()
        
        let imageSupplier = selectedFavourite.map({ favourite in
            return favourite.location.cameras[favourite.cameraIndex]
        }).latest()

        observations.append(imageSupplier => { supplier in
            self.observeSupplier = supplier.image.latest() => {
                if let image = $0 {
                    self.image.pushValue(image)
                    self.showError.pushValue(false)
                } else {
                    self.showError.pushValue(true)
                }
            }
            self.image.pushValue(UIImage(named: "image-placeholder")!)
            supplier.updateImage()
        })
    }
    
    func refresh() {
        trafficCamerasSource.start()
        weatherSource.start()
        favourites.reloadFromUserDefaults()
    }
    
    func moveToPreviousImage() {
        if let canMove = canMoveToPrevious.pullValue where canMove {
            settings.imageIndex.value = settings.imageIndex.value - 1
        }
    }
    
    func moveToNextImage() {
        if let canMove = canMoveToNext.pullValue where canMove {
            settings.imageIndex.value = settings.imageIndex.value + 1
        }
    }
}