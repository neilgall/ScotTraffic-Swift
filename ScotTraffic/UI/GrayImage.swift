//
//  GreyImage.swift
//  ScotTraffic
//
//  Created by Neil Gall on 14/01/2016.
//  Copyright © 2016 Neil Gall. All rights reserved.
//

import Foundation

func imageWithGrayColorspace(image: UIImage?) -> UIImage? {
    guard let image = image else {
        return nil
    }
    
    let size = image.size
    
    let context = CGBitmapContextCreate(nil,
        Int(size.width),
        Int(size.height),
        8,
        Int(size.width),
        CGColorSpaceCreateDeviceGray(),
        CGImageAlphaInfo.None.rawValue)
    
    CGContextSetAlpha(context, 0.5)
    CGContextDrawImage(context, CGRect(origin: CGPoint.zero, size: size), image.CGImage)
    let grayImage = CGBitmapContextCreateImage(context)
    
    return grayImage.map { UIImage(CGImage: $0) }
}
