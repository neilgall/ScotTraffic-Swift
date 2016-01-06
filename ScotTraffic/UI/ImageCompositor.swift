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
            let rect = CGRect(
                origin: CGPoint(
                    x: (draw.size.width - draw.scale*image.size.width) / 2,
                    y: (draw.size.height - draw.scale*image.size.height) / 2),
                size: CGSize(
                    width: draw.scale * image.size.width,
                    height: draw.scale * image.size.height))
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
    let zero: CGFloat = 0
    let result = imageComponents.reduce( (width:zero, height:zero, scale:zero) ) { accumulator, imageName in
        guard let image = UIImage(named: imageName) else {
            return accumulator
        }
        return (
            width:  max(accumulator.width,  image.size.width),
            height: max(accumulator.height, image.size.height),
            scale:  max(accumulator.scale,  image.scale)
        )
    }
    return (
        size: CGSize(width: result.width * result.scale, height: result.height * result.scale),
        scale: result.scale
    )
}