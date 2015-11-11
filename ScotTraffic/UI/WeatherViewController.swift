//
//  WeatherViewController.swift
//  ScotTraffic
//
//  Created by Neil Gall on 11/11/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit

class WeatherViewController: UIViewController {

    @IBOutlet var temperatureLabel: UILabel?
    @IBOutlet var weatherIconImageView: UIImageView?
    
    var weather: Weather?
    var settings: Settings?
    var observations = [Observation]()
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let weather = self.weather, let settings = self.settings else {
            temperatureLabel?.hidden = true
            weatherIconImageView?.hidden = true
            return
        }
        
        temperatureLabel?.hidden = false
        weatherIconImageView?.hidden = false
        
        let temperatureText = settings.temperatureUnit.map { (unit: TemperatureUnit) -> String in
            switch unit {
            case .Celcius:
                return "\(weather.temperature)ºC"
            case .Fahrenheit:
                return "\(weather.temperatureFahrenheit)ºF"
            }
        }
        observations.append(temperatureText => {
            self.temperatureLabel?.text = $0
        })
        
        weatherIconImageView?.image = UIImage(named: iconForWeatherType(weather.weatherType))
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        observations.removeAll()
    }
}

func iconForWeatherType(type: WeatherType) -> String {
    return "weather/wsymbol_0001_sunny"
}
