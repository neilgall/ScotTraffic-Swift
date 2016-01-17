//
//  Sunrise.swift
//  ScotTraffic
//
//  Created by Neil Gall on 14/11/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import Foundation

private func degreesToRadians(a: Double) -> Double {
    return a * M_PI / 180.0
}

private func limit(n: Double, toRange d: Double) -> Double {
    let x = floor(n / d)
    return n - x * d
}

func sunriseAndSunsetOnDate(date: NSDate, atLatitude latitude: Double, longitude: Double) -> (sunrise: NSDate, sunset: NSDate) {
    guard let calendar = NSCalendar(identifier: NSCalendarIdentifierGregorian) else {
        fatalError("cannot get Gregorian Calendar")
    }
    
    calendar.timeZone = NSTimeZone(forSecondsFromGMT: 0)
    let dayOfYear = calendar.ordinalityOfUnit(.Day, inUnit: .Year, forDate: date)
    let latitudeRadians = degreesToRadians(latitude)
    let longitudeHour = longitude / 15.0
    
    func calc(timeReference: Double, _ hourAngleReference: Double, _ hourAngleMultiplier: Double) -> NSDate {
        let approxTime = Double(dayOfYear) + ((timeReference - longitudeHour) / 24.0)
        let meanAnomaly = degreesToRadians(0.9856 * approxTime - 3.289)
        let sunTrueLongitude = limit(meanAnomaly + (0.03344 * sin(meanAnomaly) + 3.49e-4 * sin(2 * meanAnomaly)) + 4.9329, toRange: 2*M_PI)
        let ascension = limit(atan(0.91764 * tan(sunTrueLongitude)), toRange: 2*M_PI)
        let longitudeQuadrant = floor(sunTrueLongitude / M_PI_2) * M_PI_2
        let ascensionQuadrant = floor(ascension / M_PI_2) * M_PI_2
        let sunRightAscension = (ascension + (longitudeQuadrant - ascensionQuadrant)) / (M_PI/12)
        let sinSunDeclination = 0.39782 * sin(sunTrueLongitude)
        let cosSunDeclination = cos(asin(sinSunDeclination))
        let cosLocalHourAngle = (-0.01449 - (sinSunDeclination * sin(latitudeRadians))) / (cosSunDeclination * cos(latitudeRadians))
        let hourAngle = (hourAngleReference + hourAngleMultiplier * acos(cosLocalHourAngle)) / (M_PI/12)
        let localMeanTime = hourAngle + sunRightAscension - (0.06571 * approxTime) - 6.622
        let time = limit((localMeanTime - longitudeHour), toRange: 24.0)
        let hour = floor(time)
        let minute = floor(time - hour) * 60
        let second = (((time - hour) * 60) - minute) * 60
        
        let components = calendar.components([.Year, .Month, .Day], fromDate: date)
        components.hour = Int(hour)
        components.minute = Int(minute)
        components.second = Int(second)
        
        return calendar.dateFromComponents(components)!
    }
    
    return (sunrise: calc(6, 2*M_PI, -1), sunset: calc(18, 0, 1))
}
