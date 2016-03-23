//
//  ViewKeyedMap.swift
//  ScotTraffic
//
//  Created by Neil Gall on 07/11/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit

private var nextKey: Int = 0

class ViewKeyedMap<Element> {
    private var mapping = [Int:Element]()
    
    subscript(view: UIView) -> Element? {
        get {
            return mapping[view.tag]
        }
        set(element) {
            if element == nil {
                mapping.removeValueForKey(view.tag)
            } else {
                view.tag = nextKey
                mapping[view.tag] = element
                nextKey += 1
            }
        }
    }
}