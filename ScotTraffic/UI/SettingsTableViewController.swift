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
    case AboutSection
    case Count
}

private enum SettingsItems: Int {
    case ShowCurrentLocation = 0
    case TemperatureUnit
    case Count
}

private enum AboutItems: Int {
    case AboutScotTraffic = 0
    case SupportLink
    case Count
}

protocol SettingsTableViewControllerDelegate {
    func settingsViewControllerDidDismiss(settingsViewController: SettingsTableViewController)
}

class SettingsTableViewController: UITableViewController {

    var settings: Settings?
    var delegate: SettingsTableViewControllerDelegate?
    var serverIsReachable: Observable<Bool>?
    
    private var toggleConfigurations = [SettingsToggleConfiguration]()
    private var showCurrentLocationConfiguration: SettingsToggleConfiguration?
    private var temperatureUnitConfiguration: SettingsEnumConfiguration<TemperatureUnit>?
    private let aboutTitles: [String] = [ "About ScotTraffic", "Support" ]
    
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
            
            if #available(iOS 9.0, *) {
                toggleConfigurations.append(SettingsToggleConfiguration(
                    iconImageName: "warning-traffic",
                    title: "Traffic",
                    toggle: settings.showTrafficOnMap))
            }

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
        case .AboutSection:
            return AboutItems.Count.rawValue
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
        case .AboutSection:
            return "Help"
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
            
        case .AboutSection:
            let cell = tableView.dequeueReusableCellWithIdentifier("SettingsInformationCell", forIndexPath: indexPath)
            cell.textLabel?.text = aboutTitles[indexPath.row]
            return cell
            
        default:
            break
        }

        return tableView.dequeueReusableCellWithIdentifier("dummyCell", forIndexPath: indexPath)
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == TableSections.AboutSection.rawValue {
            switch AboutItems(rawValue: indexPath.row)! {
            case .AboutScotTraffic:
                pushWebView("about")
            case .SupportLink:
                pushWebView("index")
            default:
                break
            }
        }
    }
    
    private func pushWebView(page: String) {
        guard let webViewController = storyboard?.instantiateViewControllerWithIdentifier("webViewController") as? WebViewController else {
            return
        }
        webViewController.page = page
        webViewController.loadFromWeb = serverIsReachable?.pullValue ?? false
        navigationController?.pushViewController(webViewController, animated: true)
    }
}
