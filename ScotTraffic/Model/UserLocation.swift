//
//  UserLocation.swift
//  ScotTraffic
//
//  Created by Neil Gall on 10/11/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import CoreLocation

public class UserLocation: NSObject, CLLocationManagerDelegate {
    
    // Outputs
    public let location = Observable<CLLocation?>()

    private let locationManager = CLLocationManager()
    private let authorizationStatus = Input(initial: CLAuthorizationStatus.NotDetermined)
    private var observations = [Observation]()
    
    public init(enabled: Input<Bool>) {
        super.init()

        locationManager.delegate = self

        observations.append(enabled.onRisingEdge({
            self.authorizationStatus.value = CLLocationManager.authorizationStatus()
            if self.authorizationStatus.value == .NotDetermined {
                self.locationManager.requestWhenInUseAuthorization()
            }
        }))
        
        observations.append(enabled.onFallingEdge({
            self.locationManager.stopUpdatingLocation()
        }))
        
        let isAuthorized = authorizationStatus.map { (status: CLAuthorizationStatus) -> Bool in
            switch status {
            case .AuthorizedAlways, .AuthorizedWhenInUse:
                return true
                
            case .Denied, .Restricted, .NotDetermined:
                return false
            }
        }
        
        observations.append(isAuthorized.onRisingEdge({
        }))
        
        observations.append(isAuthorized.output({ authorized in
            if authorized {
                self.locationManager.startUpdatingLocation()
            } else {
                enabled.value = false
                self.location.pushValue(nil)
            }
        }))
    }
    
    public func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        self.authorizationStatus.value = status
    }
    
    public func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.location.pushValue(locations.last)
    }
}
