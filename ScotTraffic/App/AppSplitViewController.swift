//
//  AppSplitViewController.swift
//  ScotTraffic
//
//  Created by Neil Gall on 15/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit

class AppSplitViewController: UISplitViewController {

    let popoverPresentation: Input<PopoverPresentation>
    
    required init?(coder aDecoder: NSCoder) {
        popoverPresentation = Input(initial: PopoverPresentation(traitCollection: UITraitCollection(), viewBounds: CGRectZero))
        super.init(coder: aDecoder)
    }
    
    override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
        popoverPresentation.value = PopoverPresentation(traitCollection: traitCollection, viewBounds: view.bounds)
    }
}
