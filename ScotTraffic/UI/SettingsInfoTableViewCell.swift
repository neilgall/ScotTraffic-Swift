//
//  SettingsInfoTableViewCell.swift
//  ScotTraffic
//
//  Created by Neil Gall on 02/01/2016.
//  Copyright © 2016 Neil Gall. All rights reserved.
//

import UIKit

class SettingsInfoTableViewCell: UITableViewCell, SettingsTableViewCell {
    
    func configure(configuration: SettingConfiguration) {
        guard let configuration = configuration as? SettingsInfoConfiguration else {
            return
        }

        textLabel?.text = configuration.text
        detailTextLabel?.text = configuration.detailText
        
        if case .InformationOnly = configuration.type {
            accessoryType = .None
        } else {
            accessoryType = .DisclosureIndicator
        }
    }
}
