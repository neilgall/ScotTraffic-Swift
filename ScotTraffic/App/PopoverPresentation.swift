//
//  PopoverPresentation.swift
//  ScotTraffic
//
//  Created by Neil Gall on 21/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit

public struct PopoverPresentation {
    public let traitCollection: UITraitCollection
    public let viewBounds: CGRect
    
    public var preferredCollectionContentSize: CGSize {
        if traitCollection.horizontalSizeClass == .Compact {
            // inset from the screen edges
            if aspectIsPortrait {
                return preferredCollectionContentSizeForWidth(CGRectGetWidth(viewBounds)-20)
            } else {
                return preferredCollectionContentSizeForHeight(CGRectGetHeight(viewBounds)-20)
            }
        } else {
            // maximum size
            return preferredCollectionContentSizeForWidth(480)
        }
    }
    
    public var permittedArrowDirections: UIPopoverArrowDirection {
        if traitCollection.horizontalSizeClass == .Compact {
            if aspectIsPortrait {
                return [.Up, .Down]
            } else {
                return [.Left, .Right]
            }
        } else {
            return .Any
        }
    }
    
    public func mapScrollDistanceToPresentContentSize(contentSize: CGSize, anchoredToRect anchorRect: CGRect) -> (x: CGFloat, y: CGFloat) {
        let contentTopIfAbove = CGRectGetMinY(anchorRect) - contentSize.height - 23
        let contentBottomIfBelow = CGRectGetMaxY(anchorRect) + contentSize.height + 23
        let contentLeftIfToLeft = CGRectGetMinX(anchorRect) - contentSize.width - 23
        let contentRightIfToRight = CGRectGetMaxX(anchorRect) + contentSize.width + 23
        var presentContainer = CGRectInset(viewBounds, 10, 10)
        
        // account for status bar
        presentContainer.origin.y += 20
        presentContainer.size.height -= 20
        
        let scrollUp = contentBottomIfBelow - CGRectGetMaxY(presentContainer)
        let scrollDown = CGRectGetMinY(presentContainer) - contentTopIfAbove
        let scrollLeft = contentRightIfToRight - CGRectGetMaxX(presentContainer)
        let scrollRight = CGRectGetMinX(presentContainer) - contentLeftIfToLeft
        
        if scrollUp > 0 && scrollDown > 0 && scrollLeft > 0 && scrollRight > 0 {
            if scrollUp < scrollDown && scrollUp < scrollLeft && scrollUp < scrollRight {
                return (x: 0, y: -scrollUp)
            } else if scrollDown < scrollLeft && scrollDown < scrollRight {
                return (x: 0, y: scrollDown)
            } else if scrollLeft < scrollRight {
                return (x: -scrollLeft, y: 0)
            } else {
                return (x: scrollRight, y: 0)
            }
        }
        
        return (x: 0, y: 0)
    }
    
    private func preferredCollectionContentSizeForWidth(width: CGFloat) -> CGSize {
        return CGSizeMake(width, width*0.75+64)
    }
    
    private func preferredCollectionContentSizeForHeight(height: CGFloat) -> CGSize {
        return CGSizeMake((height-64)/0.75, height)
    }
    
    private var aspectIsPortrait: Bool {
        return CGRectGetWidth(viewBounds) < CGRectGetHeight(viewBounds)
    }
}