//
//  WeatherViewModel.swift
//  ScotTraffic
//
//  Created by Neil Gall on 14/11/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import MapKit

class WeatherViewModel {
 
    // Outputs
    let weatherHidden: Signal<Bool>
    let temperatureText: Signal<String>
    let weatherIconName: Signal<String>

    init(weatherFinder: Signal<MapItem -> Weather?>, mapItem: Signal<MapItem?>, temperatureUnit: Signal<TemperatureUnit>) {
        
        let weather = combine(weatherFinder, mapItem) { weatherFinder, mapItem in
            mapItem.flatMap({ weatherFinder($0) })
        }
        
        weatherHidden = isNil(weather)
 
        temperatureText = combine(weather, temperatureUnit) { weather, unit in
            guard let weather = weather else {
                return ""
            }
            var temperatureValue: Float
            switch unit {
            case .Celcius:
                temperatureValue = weather.temperature
            case .Fahrenheit:
                temperatureValue = weather.temperatureFahrenheit
            }
            return unit.numberFormatter.stringFromNumber(temperatureValue)!
        }
        
        let currentDate = ComputedSignal({ NSDate() })
        let isDaytime = combine(currentDate, weather) { (date: NSDate, weather: Weather?) -> Bool in
            guard let weather = weather else {
                return false
            }
            let coord = MKCoordinateForMapPoint(weather.mapPoint)
            let (sunrise, sunset) = sunriseAndSunsetOnDate(date, atLatitude: coord.latitude, longitude: coord.longitude)
            return date.laterDate(sunrise) == date && date.earlierDate(sunset) == date
        }
        
        weatherIconName = combine(isDaytime, weather) { (isDaytime: Bool, weather: Weather?) -> String in
            guard let weather = weather else {
                return ""
            }
            guard let baseName = isDaytime ? dayIcons[weather.weatherType] : nightIcons[weather.weatherType] else {
                return ""
            }
            return "wsymbol_\(baseName)"
        }
    }
    
    private func testIconMaps() {
        for map in [dayIcons, nightIcons] {
            for (_, iconName) in map {
                guard let _ = UIImage(named: "wsymbol_\(iconName)") else {
                    fatalError("can't get image \(iconName)")
                }
                print("found image \(iconName)")
            }
        }
    }
}

extension TemperatureUnit {
    var numberFormatter: NSNumberFormatter {
        let numberFormatter = NSNumberFormatter()
        numberFormatter.roundingMode = .RoundHalfUp
        numberFormatter.maximumFractionDigits = 0
        switch self {
        case .Celcius:
            numberFormatter.positiveSuffix = "ºC"
            numberFormatter.negativeSuffix = "ºC"
        case .Fahrenheit:
            numberFormatter.positiveSuffix = "ºF"
            numberFormatter.negativeSuffix = "ºF"
        }
        return numberFormatter
    }
}

class CurrentDate: Signal<NSDate> {
    override var latestValue: LatestValue<NSDate> {
        return .Computed({ NSDate() })
    }
}

private let dayIcons: [WeatherType:String] = [
    .Clear           : "0001_sunny",
    .PartCloudy      : "0002_sunny_intervals",
    .Mist            : "0006_mist",
    .Fog             : "0007_fog",
    .Cloudy          : "0003_white_cloud",
    .Overcast        : "0004_black_low_cloud",
    .LightRainShower : "0009_light_rain_showers",
    .Drizzle         : "0048_drizzle",
    .LightRain       : "0017_cloudy_with_light_rain",
    .HeavyRainShower : "0010_heavy_rain_showers",
    .HeavyRain       : "0018_cloudy_with_heavy_rain",
    .SleetShower     : "0013_sleet_showers",
    .Sleet           : "0021_cloudy_with_sleet",
    .HailShower      : "0014_light_hail_showers",
    .Hail            : "0022_cloudy_with_light_hail",
    .LightSnowShower : "0011_light_snow_showers",
    .LightSnow       : "0019_cloudy_with_light_snow",
    .HeavySnowShower : "0012_heavy_snow_showers",
    .HeavySnow       : "0020_cloudy_with_heavy_snow",
    .ThunderShower   : "0016_thundery_showers",
    .Thunder         : "0024_thunderstorms"
]

private let nightIcons: [WeatherType:String] = [
    .Clear           : "0008_clear_sky_night",
    .PartCloudy      : "0041_partly_cloudy_night",
    .Mist            : "0063_mist_night",
    .Fog             : "0064_fog_night",
    .Cloudy          : "0044_mostly_cloudy_night",
    .Overcast        : "0042_cloudy_night",
    .LightRainShower : "0025_light_rain_showers_night",
    .Drizzle         : "0066_drizzle_night",
    .LightRain       : "0033_cloudy_with_light_rain_night",
    .HeavyRainShower : "0026_heavy_rain_showers_night",
    .HeavyRain       : "0034_cloudy_with_heavy_rain_night",
    .SleetShower     : "0029_sleet_showers_night",
    .Sleet           : "0037_cloudy_with_sleet_night",
    .HailShower      : "0030_light_hail_showers_night",
    .Hail            : "0038_cloudy_with_light_hail_night",
    .LightSnowShower : "0027_light_snow_showers_night",
    .LightSnow       : "0035_cloudy_with_light_snow_night",
    .HeavySnowShower : "0028_heavy_snow_showers_night",
    .HeavySnow       : "0036_cloudy_with_heavy_snow_night",
    .ThunderShower   : "0032_thundery_showers_night",
    .Thunder         : "0040_thunderstorms_night"
]

