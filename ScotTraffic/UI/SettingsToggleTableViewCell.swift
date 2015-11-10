//
//  SettingsToggleTableViewCell.swift
//  ScotTraffic
//
//  Created by Neil Gall on 10/11/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit

class SettingsToggleTableViewCell: UITableViewCell {

    @IBOutlet var iconImageView: UIImageView?
    @IBOutlet var titleLabel: UILabel?
    @IBOutlet var toggleSwitch: UISwitch?

    private var toggle: Input<Bool>?
    
    func configure(configuration: SettingsToggleConfiguration) {
        self.iconImageView?.image = UIImage(named: configuration.iconImageName)
        self.titleLabel?.text = configuration.title
        self.toggleSwitch?.on = configuration.toggle.value
        self.toggle = configuration.toggle
    }
    
    @IBAction func toggleSwitchChangedValue(sender: UISwitch) {
        toggle?.value = sender.on
    }
}
