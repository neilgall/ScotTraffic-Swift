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
    private var observation: Observation?
    
    func configure(configuration: SettingsToggleConfiguration) {
        self.iconImageView?.image = UIImage(named: configuration.iconImageName)
        self.titleLabel?.text = configuration.title
        self.toggle = configuration.toggle
        
        self.observation = configuration.toggle.output({ on in
            self.toggleSwitch?.setOn(on, animated: true)
        })
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        toggle = nil
        observation = nil
    }
    
    @IBAction func toggleSwitchChangedValue(sender: UISwitch) {
        toggle?.value = sender.on
    }
}
