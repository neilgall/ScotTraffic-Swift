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
    
    return grayBitmapContext(ofSize: image.size)
        |> { draw(image: image, inContext: $0, withAlpha: 0.5) }
        |> { UIImage(CGImage: $0) }
}

private func grayBitmapContext(ofSize size: CGSize) -> CGContext? {
    return CGBitmapContextCreate(nil,
                                 Int(size.width),
                                 Int(size.height),
                                 8,
                                 Int(size.width),
                                 CGColorSpaceCreateDeviceGray(),
                                 CGImageAlphaInfo.None.rawValue)
}

private func draw(image image: UIImage, inContext context: CGContext, withAlpha alpha: CGFloat) -> CGImage? {
    guard let cgImage = image.CGImage else {
        return nil
    }
    CGContextSetAlpha(context, alpha)
    CGContextDrawImage(context, CGRect(origin: CGPoint.zero, size: image.size), cgImage)
    return CGBitmapContextCreateImage(context)
}
