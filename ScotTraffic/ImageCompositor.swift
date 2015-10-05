//
//  ImageCompositor.swift
//  ScotTraffic
//
//  Created by Neil Gall on 05/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit

private var cache = [String : UIImage]()

public func compositeImagesNamed(imageComponents: [String]) -> UIImage? {
    if imageComponents.isEmpty {
        return nil
    } else if imageComponents.count == 1 {
        return UIImage(named: imageComponents[0])
    }
    
    let cacheKey = imageComponents.joinWithSeparator("/")
    if let image = cache[cacheKey] {
        return image
    }
    
    let draw = compositedSize(imageComponents)
    
    let context = CGBitmapContextCreate(nil,
        Int(draw.size.width),
        Int(draw.size.height),
        8,
        Int(draw.size.width*4),
        CGColorSpaceCreateDeviceRGB(),
        CGImageAlphaInfo.PremultipliedFirst.rawValue)
    
    imageComponents.forEach { imageName in
        if let image = UIImage(named: imageName) {
            let rect = CGRectMake((draw.size.width - draw.scale*image.size.width) / 2,
                (draw.size.height - draw.scale*image.size.height) / 2,
                draw.scale * image.size.width,
                draw.scale * image.size.height)
            CGContextDrawImage(context, rect, image.CGImage)
        }
    }
    
    guard let composited = CGBitmapContextCreateImage(context) else {
        return nil
    }
    
    let image = UIImage(CGImage: composited, scale: draw.scale, orientation: UIImageOrientation.Up)
    cache[cacheKey] = image

    return image
    
}

private func compositedSize(imageComponents: [String]) -> (size: CGSize, scale: CGFloat) {
    let result = imageComponents.reduce((CGFloat(0), CGFloat(0), CGFloat(0))) { accumulator, imageName in
        guard let image = UIImage(named: imageName) else {
            return accumulator
        }
        return (max(accumulator.0, image.size.width), max(accumulator.1, image.size.height), max(accumulator.2, image.scale))
    }
    return (size: CGSizeMake(result.0 * result.2, result.1 * result.2), scale: result.2)
}