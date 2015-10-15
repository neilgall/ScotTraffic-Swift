//
//  AppSplitViewController.swift
//  ScotTraffic
//
//  Created by Neil Gall on 15/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit

class AppSplitViewController: UISplitViewController {

    weak var coordinator: AppCoordinator?
    
    override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
        coordinator?.traitCollectionDidChange(previousTraitCollection)
    }
}
