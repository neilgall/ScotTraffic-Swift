//
//  SharableItem.swift
//  ScotTraffic
//
//  Created by Neil Gall on 15/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit

public protocol SharableItem {
    var name: String { get }
    var text: String { get }
    var image: UIImage? { get }
    var link: NSURL? { get }
}
