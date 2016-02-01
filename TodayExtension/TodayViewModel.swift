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
        let userDefaults = Configuration.sharedUserDefaults()
        let diskCache = DiskCache(withPath: "scottraffic")
        let httpAccess = HTTPAccess(baseURL: scotTrafficBaseURL, indicator: nil)
        
        let cachedDataSource = CachedHTTPDataSource.dataSourceWithHTTPAccess(httpAccess, cache: diskCache)
        let fiveMinuteCache = cachedDataSource(300)
        let fifteenMinuteCache = cachedDataSource(900)
        
        self.diskCache = diskCache
        self.httpAccess = httpAccess
        self.settings = TodaySettings(userDefaults: userDefaults)
        
        // -- traffic cameras
        
        self.trafficCamerasSource = fifteenMinuteCache("trafficcameras.json")
        let trafficCamerasContext = TrafficCameraDecodeContext(makeImageDataSource: fiveMinuteCache)
        let trafficCameraLocations = trafficCamerasSource.value.map {
            return $0.map(Array<TrafficCameraLocation>.decodeJSON(trafficCamerasContext) <== JSONArrayFromData)
        }
        
        // -- weather
        
        self.weatherSource = fifteenMinuteCache("weather.json")
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
        
        self.favourites = Favourites(userDefaults: userDefaults)
    
        let locations = trafficCameraLocations.map({ $0.value ?? [] }).latest()
        let favouriteTrafficCameras = favourites.trafficCamerasFromLocations(locations)
        
        let selectedFavourite: Signal<FavouriteTrafficCamera> = combine(favouriteTrafficCameras, settings.imageIndex) { favourites, imageIndex in
            let index = max(0, min(imageIndex, favourites.count))
            return favourites[index]
        }
        
        // -- outputs
        
        self.title = selectedFavourite.map({ favourite in
            return favourite.location.nameAtIndex(favourite.cameraIndex)
        }).latest()
        
        self.weatherViewModel = WeatherViewModel(
            weatherFinder: weatherFinder,
            mapItem: selectedFavourite.map({ $0.location }),
            temperatureUnit: settings.temperatureUnit)
        
        
        self.canMoveToPrevious = settings.imageIndex.map({ index in
            return index > 0
        }).latest()
        
        self.canMoveToNext = combine(favouriteTrafficCameras, settings.imageIndex) { favourites, index in
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
                case .Cached(let image, let expired):
                    if expired, let grayImage = imageWithGrayColorspace(image) {
                        self.image.pushValue(grayImage)
                    } else {
                        self.image.pushValue(image)
                    }
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
            settings.imageIndex <-- settings.imageIndex.value - 1
        }
    }
    
    func moveToNextImage() {
        if let canMove = canMoveToNext.latestValue.get where canMove {
            settings.imageIndex <-- settings.imageIndex.value + 1
        }
    }
}