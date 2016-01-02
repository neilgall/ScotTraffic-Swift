//
//  SettingsIntTableViewCell.swift
//  ScotTraffic
//
//  Created by Neil Gall on 10/11/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit

class SettingsIntTableViewCell: UITableViewCell, SettingsTableViewCell {

    @IBOutlet var iconImageView: UIImageView?
    @IBOutlet var titleLabel: UILabel?
    @IBOutlet var control: UISegmentedControl?

    private var observation: Observation?
    private var updateValue: (Int -> Void)?
    
    func configure(configuration: SettingConfiguration) {

        guard let configuration = configuration as? SettingsIntConfiguration else {
            return
        }
        
        self.iconImageView?.image = UIImage(named: configuration.iconImageName)
        self.titleLabel?.text = configuration.title

        self.control?.removeAllSegments()
        for (value, title) in configuration.settingValueTitles {
            self.control?.insertSegmentWithTitle(title, atIndex: value, animated: false)
        }

        observation = configuration.setting => {
            self.control?.selectedSegmentIndex = $0
        }

        self.updateValue = {
            configuration.setting.value = $0
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        observation = nil
        updateValue = nil
    }
    
    @IBAction func intValueChanged(sender: UISegmentedControl) {
        if let update = self.updateValue {
            update(sender.selectedSegmentIndex)
        }
    }
}
