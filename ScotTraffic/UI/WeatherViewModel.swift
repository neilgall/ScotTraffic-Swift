//
//  WeatherViewModel.swift
//  ScotTraffic
//
//  Created by Neil Gall on 14/11/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import Foundation

class WeatherViewModel {
 
    // Outputs
    let weatherHidden: Observable<Bool>
    let temperatureText: Observable<String>
    let weatherIconName: Observable<String>

    init(settings: Settings, weatherFinder: Observable<WeatherFinder>, mapItems: Observable<[MapItem]>) {
        
        // assume the map items are close enough geographically that picking the first one is accurate
        let weather = combine(weatherFinder, mapItems) { weatherFinder, mapItems in
            mapItems.first.flatMap { weatherFinder($0) }
        }
        
        weatherHidden = isNil(weather)
 
        temperatureText = combine(weather, settings.temperatureUnit) { weather, unit in
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
        
        weatherIconName = weather.map { weather in
            guard let weather = weather else {
                return ""
            }
            switch weather.weatherType {
            case .Clear: return "clear"
            case .PartCloudy: return "partcloudy"
            case .Mist: return "mist"
            case .Fog: return "fog"
            case .Cloudy: return "cloudy"
            case .Overcast: return "overcast"
            case .LightRainShower: return "light-rain-shower"
            case .Drizzle: return "drizzle"
            case .LightRain: return "light-rain"
            case .HeavyRainShower: return "heavy-rain-shower"
            case .HeavyRain: return "heavy-rain"
            case .SleetShower: return "sleet-shower"
            case .Sleet: return "sleet"
            case .HailShower: return "hail-shower"
            case .Hail: return "hail"
            case .LightSnowShower: return "light-snow-shower"
            case .LightSnow: return "light-snow"
            case .HeavySnowShower: return "heavy-snow-shower"
            case .HeavySnow: return "heavy-snow"
            case .ThunderShower: return "thunder-shower"
            case .Thunder: return "thunder"
            case .Unknown: return "unknown"
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