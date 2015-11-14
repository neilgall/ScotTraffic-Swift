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
    
    var weatherViewModel: WeatherViewModel?
    var observations = [Observation]()
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let model = weatherViewModel else {
            return
        }
        
        observations.append(model.weatherHidden => { hide in
            self.temperatureLabel?.hidden = hide
            self.weatherIconImageView?.hidden = hide
            })
        
        observations.append(model.temperatureText => {
            self.temperatureLabel?.text = $0
        })
        
        observations.append(model.weatherIconName => {
            self.weatherIconImageView?.image = UIImage(named: $0)
        })
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        observations.removeAll()
    }
}
