//
//  SettingsEnumTableViewCell.swift
//  ScotTraffic
//
//  Created by Neil Gall on 10/11/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit

class SettingsEnumTableViewCell: UITableViewCell {

    @IBOutlet var iconImageView: UIImageView?
    @IBOutlet var titleLabel: UILabel?
    @IBOutlet var enumControl: UISegmentedControl?

    private var updateValue: (Int -> Void)?
    
    func configure<EnumType where EnumType: RawRepresentable, EnumType.RawValue == Int>(configuration: SettingsEnumConfiguration<EnumType>) {
        self.iconImageView?.image = UIImage(named: configuration.iconImageName)
        self.titleLabel?.text = configuration.title

        self.enumControl?.removeAllSegments()
        for (value, title) in configuration.settingValueTitles {
            self.enumControl?.insertSegmentWithTitle(title, atIndex: value.rawValue, animated: false)
        }

        self.enumControl?.selectedSegmentIndex = configuration.setting.value.rawValue

        self.updateValue = { rawValue in
            configuration.setting.value = EnumType(rawValue: rawValue)!
        }
    }
    
    @IBAction func enumValueChanged(sender: UISegmentedControl) {
        if let update = self.updateValue {
            update(sender.selectedSegmentIndex)
        }
    }
}
