//
//  SettingsConfigurations.swift
//  ScotTraffic
//
//  Created by Neil Gall on 10/11/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import Foundation

struct SettingsToggleConfiguration {
    let iconImageName: String
    let title: String
    let toggle: Input<Bool>
}

struct SettingsEnumConfiguration<EnumType: Hashable> {
    let iconImageName: String
    let title: String
    let setting: Input<EnumType>
    let settingValueTitles: [EnumType : String]
}
