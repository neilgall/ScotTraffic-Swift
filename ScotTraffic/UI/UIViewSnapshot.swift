//
//  UIViewSnapshot.swift
//  ScotTraffic
//
//  Created by Neil Gall on 07/11/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit

extension UIView {
    
    func snapshotImage() -> UIImage? {
        UIGraphicsBeginImageContext(bounds.size)
        layer.renderInContext(UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
}
