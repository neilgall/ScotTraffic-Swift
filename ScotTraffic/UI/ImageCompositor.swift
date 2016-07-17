//
//  ImageCompositor.swift
//  ScotTraffic
//
//  Created by Neil Gall on 05/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit

private var cache = [String : UIImage]()

private struct CompositionSize {
    let width: CGFloat
    let height: CGFloat
    let scale: CGFloat
    
    static let zero = CompositionSize(width: 0, height: 0, scale: 0)
}

private struct CompositionContext {
    let context: CGContext
    let width: CGFloat
    let height: CGFloat
    let scale: CGFloat
}

func compositeImagesNamed(imageComponents: [String]) -> UIImage? {
    if imageComponents.isEmpty {
        return nil
    } else if imageComponents.count == 1 {
        return UIImage(named: imageComponents[0])
    }
    
    let cacheKey = imageComponents.joinWithSeparator("+")
    if let image = cache[cacheKey] {
        return image
    }
    
    guard let context = imageComponents.map(sizeForImageNamed) |> compositedSize |> compositionContext else {
        return nil
    }
    
    imageComponents.forEach {
        draw(imageNamed: $0, inContext: context)
    }

    guard let composited = image(fromContext: context) else {
        return nil
    }
    
    cache[cacheKey] = composited
    return composited
}

private func sizeForImageNamed(imageName: String) -> CompositionSize {
    guard let image = UIImage(named: imageName) else {
        return .zero
    }
    return CompositionSize(width: image.size.width, height: image.size.height, scale: image.scale)
}

private func compositedSize(sizes: [CompositionSize]) -> CompositionSize {
    return sizes.reduce(CompositionSize.zero) { accumulator, size in
        CompositionSize(
            width:  max(accumulator.width, size.width * size.scale),
            height: max(accumulator.height, size.height * size.scale),
            scale:  max(accumulator.scale, size.scale)
        )
    }
}

private func compositionContext(size: CompositionSize) -> CompositionContext? {
    guard let context = CGBitmapContextCreate(
        nil,
        Int(size.width),
        Int(size.height),
        8,
        Int(size.width*4),
        CGColorSpaceCreateDeviceRGB(),
        CGImageAlphaInfo.PremultipliedFirst.rawValue) else {
            return nil
    }
    
    return CompositionContext(context: context, width: size.width, height: size.height, scale: size.scale)
}

private func draw(imageNamed imageName: String, inContext context: CompositionContext) {
    guard let image = UIImage(named: imageName), cgImage = image.CGImage else {
        return
    }
    let rect = CGRect(
        origin: CGPoint(
            x: (context.width - context.scale*image.size.width) / 2,
            y: (context.height - context.scale*image.size.height) / 2),
        size: CGSize(
            width: context.scale * image.size.width,
            height: context.scale * image.size.height))
    CGContextDrawImage(context.context, rect, cgImage)
}

private func image(fromContext context: CompositionContext) -> UIImage? {
    return CGBitmapContextCreateImage(context.context)
        |> { UIImage(CGImage: $0, scale: context.scale, orientation: UIImageOrientation.Up) }
}
