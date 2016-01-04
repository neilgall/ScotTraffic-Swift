//
//  SettingsConfigurations.swift
//  ScotTraffic
//
//  Created by Neil Gall on 10/11/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import Foundation

protocol SettingConfiguration {
    var cellIdentifier: String { get }
}

struct SettingsToggleConfiguration : SettingConfiguration {
    let cellIdentifier = "SettingsToggleTableViewCell"
    let iconImageName: String
    let title: String
    let toggle: Input<Bool>
}

struct SettingsIntConfiguration : SettingConfiguration {
    let cellIdentifier = "SettingsIntTableViewCell"
    let iconImageName: String
    let title: String
    let setting: Input<Int>
    let settingValueTitles: [Int : String]
}

struct SettingsInfoConfiguration : SettingConfiguration {
    let cellIdentifier = "SettingsInfoTableViewCell"
    let text: String
    let detailText: String?
    let pageTitle: String?
}

// Use to bidirectionally map an Input<EnumType> to an Input<Int> for use in SettingsIntConfiguration
//
struct BidirectionalMapToInt<EnumType: RawRepresentable where EnumType.RawValue == Int> {
    let intInput: Input<Int>
    let enumInput: Input<EnumType>
    let receivers: [ReceiverType]
    
    init(enumInput: Input<EnumType>) {
        let intInput = Input(initial: 0)

        var flag = false
        
        let enumToInt = enumInput --> { enumValue in
            if !flag {
                with(&flag) {
                    intInput <-- enumValue.rawValue
                }
            }
        }
        
        let intToEnum = intInput --> { intValue in
            if !flag {
                with(&flag) {
                    if let value = EnumType(rawValue: intValue) {
                        enumInput <-- value
                    }
                }
            }
        }

        self.intInput = intInput
        self.enumInput = enumInput
        self.receivers = [enumToInt, intToEnum]
    }
}