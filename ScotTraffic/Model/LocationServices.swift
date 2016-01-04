//
//  LocationServices.swift
//  ScotTraffic
//
//  Created by Neil Gall on 10/11/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import CoreLocation

public class LocationServices: NSObject, CLLocationManagerDelegate {
    
    // Outputs
    public let authorised = Signal<Bool>()

    private let locationManager = CLLocationManager()
    private let authorisationStatus = Input(initial: CLAuthorizationStatus.NotDetermined)
    private var receivers = [ReceiverType]()
    
    public init(enabled: Input<Bool>) {
        super.init()

        locationManager.delegate = self

        receivers.append(enabled.onRisingEdge({
            self.authorisationStatus.value = CLLocationManager.authorizationStatus()
            if self.authorisationStatus.value == .NotDetermined {
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
    
    public func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        self.authorisationStatus.value = status
    }
}
