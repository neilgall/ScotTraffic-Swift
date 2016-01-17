//
//  LocationServices.swift
//  ScotTraffic
//
//  Created by Neil Gall on 10/11/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import CoreLocation

class LocationServices: NSObject, CLLocationManagerDelegate {
    
    // Outputs
    let authorised = Signal<Bool>()

    private let locationManager = CLLocationManager()
    private let authorisationStatus = Input(initial: CLAuthorizationStatus.NotDetermined)
    private var receivers = [ReceiverType]()
    
    init(enabled: Input<Bool>) {
        super.init()

        locationManager.delegate = self

        receivers.append(enabled.onRisingEdge({
            self.authorisationStatus <-- CLLocationManager.authorizationStatus()
            if self.authorisationStatus.latestValue.get == .NotDetermined {
                self.locationManager.requestWhenInUseAuthorization()
            }
        }))
        
        let isAuthorised = authorisationStatus.map { (status: CLAuthorizationStatus) -> Bool in
            switch status {
            case .AuthorizedAlways, .AuthorizedWhenInUse:
                return true
                
            case .Denied, .Restricted, .NotDetermined:
                return false
            }
        }

        receivers.append((enabled && isAuthorised) --> {
            self.authorised.pushValue($0)
        })
    }
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        self.authorisationStatus <-- status
    }
}
