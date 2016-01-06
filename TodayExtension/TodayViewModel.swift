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
    let image: Signal<UIImage>
    let title: Signal<String>
    let showError: Signal<Bool>
    let canMoveToPrevious: Signal<Bool>
    let canMoveToNext: Signal<Bool>
    
    let diskCache: DiskCache
    let httpAccess: HTTPAccess
    let trafficCamerasSource: DataSource
    let weatherSource: DataSource
    let favourites: Favourites
    let settings: TodaySettings
    let weatherViewModel: WeatherViewModel
    var receivers: [ReceiverType] = []
    var observeImageDataSource: ReceiverType? = nil
    
    init() {
        let diskCache = DiskCache(withPath: "scottraffic")
        let httpAccess = HTTPAccess(baseURL: scotTrafficBaseURL, indicator: nil)
        
        let cachedDataSource = CachedHTTPDataSource.dataSourceWithHTTPAccess(httpAccess, cache: diskCache)
        
        guard let userDefaults = NSUserDefaults(suiteName: scotTrafficAppGroup) else {
            fatalError("cannot create NSUserDefaults with suiteName \(scotTrafficAppGroup)")
        }
        
        self.diskCache = diskCache
        self.httpAccess = httpAccess
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
        let weatherFinder = weather.map({ $0.value ?? [] }).latest().map() { (weather: [Weather]) -> (MapItem -> Weather?) in
            return { (mapItem: MapItem) -> Weather? in
                let distanceSq = { (w: Weather) -> Double in w.mapPoint.distanceSqToMapPoint(mapItem.mapPoint) }
                return weather.minElement({ distanceSq($0) < distanceSq($1) })
            }
        }

        // -- favourites
        
        self.favourites = Favourites(userDefaults: userDefaults,
            trafficCameraLocations: trafficCameraLocations.map({ $0.value ?? [] }).latest())
        
        let selectedFavourite: Signal<FavouriteTrafficCamera> = combine(favourites.trafficCameras, settings.imageIndex) { favourites, imageIndex in
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

        self.image = Signal()
        self.showError = Signal()
        
        let imageDataSource = selectedFavourite.map({ favourite in
            return favourite.location.cameras[favourite.cameraIndex]
        }).latest()

        receivers.append(imageDataSource --> { dataSource in
            self.observeImageDataSource = dataSource.imageValue.latest() --> {
                switch $0 {
                case .Fresh(let image):
                    self.image.pushValue(image)
                    self.showError.pushValue(false)
                case .Cached(let image, _):
                    self.image.pushValue(image)
                    self.showError.pushValue(false)
                case .Error, .Empty:
                    self.showError.pushValue(true)
                }
            }
            self.image.pushValue(UIImage(named: "image-placeholder")!)
            dataSource.updateImage()
        })
    }
    
    func refresh() {
        trafficCamerasSource.start()
        weatherSource.start()
        favourites.reloadFromUserDefaults()
    }
    
    func moveToPreviousImage() {
        if let canMove = canMoveToPrevious.latestValue.get where canMove {
            settings.imageIndex.value = settings.imageIndex.value - 1
        }
    }
    
    func moveToNextImage() {
        if let canMove = canMoveToNext.latestValue.get where canMove {
            settings.imageIndex.value = settings.imageIndex.value + 1
        }
    }
}