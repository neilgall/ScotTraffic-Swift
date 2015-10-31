//
//  PopoverContentSize.swift
//  ScotTraffic
//
//  Created by Neil Gall on 21/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit

public func popoverContentSize(traitCollection: UITraitCollection, viewBounds: CGRect) -> CGSize {
    if traitCollection.horizontalSizeClass == .Compact {
        // inset from the screen edges
        if aspectIsPortrait(viewBounds) {
            return preferredCollectionContentSizeForWidth(CGRectGetWidth(viewBounds)-20)
        } else {
            return preferredCollectionContentSizeForHeight(CGRectGetHeight(viewBounds)-20)
        }
    } else {
        // maximum size
        return preferredCollectionContentSizeForWidth(480)
    }
}

private func preferredCollectionContentSizeForWidth(width: CGFloat) -> CGSize {
    return CGSizeMake(width, width*0.75+64)
}

private func preferredCollectionContentSizeForHeight(height: CGFloat) -> CGSize {
    return CGSizeMake((height-64)/0.75, height)
}

private func aspectIsPortrait(viewBounds: CGRect) -> Bool {
    return CGRectGetWidth(viewBounds) < CGRectGetHeight(viewBounds)
}
