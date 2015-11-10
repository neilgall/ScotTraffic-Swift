//
//  SettingsTableViewController.swift
//  ScotTraffic
//
//  Created by Neil Gall on 10/11/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit

private enum TableSections: Int {
    case ContentSection = 0
    case SettingsSection
    case Count
}

private enum SettingsItems: Int {
    case ShowCurrentLocation = 0
    case TemperatureUnit
    case Count
}

protocol SettingsTableViewControllerDelegate {
    func settingsViewControllerDidDismiss(settingsViewController: SettingsTableViewController)
}

class SettingsTableViewController: UITableViewController {

    var settings: Settings?
    var delegate: SettingsTableViewControllerDelegate?
    
    private var toggleConfigurations = [SettingsToggleConfiguration]()
    private var showCurrentLocationConfiguration: SettingsToggleConfiguration?
    private var temperatureUnitConfiguration: SettingsEnumConfiguration<TemperatureUnit>?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        toggleConfigurations.removeAll()

        if let settings = settings {
            toggleConfigurations.append(SettingsToggleConfiguration(
                iconImageName: "camera",
                title: "Traffic Cameras",
                toggle: settings.showTrafficCamerasOnMap))

            toggleConfigurations.append(SettingsToggleConfiguration(
                iconImageName: "safetycamera",
                title: "Safety Cameras",
                toggle: settings.showSafetyCamerasOnMap))
            
            toggleConfigurations.append(SettingsToggleConfiguration(
                iconImageName: "incident",
                title: "Alerts",
                toggle: settings.showAlertsOnMap))
            
            toggleConfigurations.append(SettingsToggleConfiguration(
                iconImageName: "roadworks",
                title: "Roadworks",
                toggle: settings.showRoadworksOnMap))
            
            showCurrentLocationConfiguration = SettingsToggleConfiguration(
                iconImageName: "07-map-marker",
                title: "Show current location",
                toggle: settings.showCurrentLocationOnMap)
            
            temperatureUnitConfiguration = SettingsEnumConfiguration(
                iconImageName: "959-thermometer",
                title: "Temperature Unit",
                setting: settings.temperatureUnit,
                settingValueTitles: [
                    TemperatureUnit.Fahrenheit: "ºF",
                    TemperatureUnit.Celcius: "ºC"
                ])
        }
    }
    
    @IBAction func dismiss(sender: UIBarButtonItem) {
        delegate?.settingsViewControllerDidDismiss(self)
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return TableSections.Count.rawValue
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch TableSections(rawValue: section)! {
        case .ContentSection:
            return toggleConfigurations.count
        case .SettingsSection:
            return SettingsItems.Count.rawValue
        default:
            return 0
        }
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch TableSections(rawValue: section)! {
        case .ContentSection:
            return "Content"
        case .SettingsSection:
            return "Settings"
        default:
            return nil
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch TableSections(rawValue: indexPath.section)! {
        case .ContentSection:
            let cell = tableView.dequeueReusableCellWithIdentifier("SettingsToggleTableViewCell", forIndexPath: indexPath) as! SettingsToggleTableViewCell
            cell.configure(toggleConfigurations[indexPath.row])
            return cell

        case .SettingsSection:
            switch SettingsItems(rawValue: indexPath.row)! {
            case .ShowCurrentLocation:
                let cell = tableView.dequeueReusableCellWithIdentifier("SettingsToggleTableViewCell", forIndexPath: indexPath) as! SettingsToggleTableViewCell
                cell.configure(showCurrentLocationConfiguration!)
                return cell
                
            case .TemperatureUnit:
                let cell = tableView.dequeueReusableCellWithIdentifier("SettingsEnumTableViewCell", forIndexPath: indexPath) as! SettingsEnumTableViewCell
                cell.configure(temperatureUnitConfiguration!)
                return cell
                
            default:
                break
            }
            
        default:
            break
        }

        return tableView.dequeueReusableCellWithIdentifier("dummyCell", forIndexPath: indexPath)
    }
}
