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
    case NotificationsSection
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
    case Version = 0
    case AboutScotTraffic
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
    
    private var contentConfigurations = [SettingsToggleConfiguration]()
    private var notificationConfigurations = [SettingsToggleConfiguration]()
    private var showCurrentLocationConfiguration: SettingsToggleConfiguration?
    private var temperatureUnitConfiguration: SettingsEnumConfiguration<TemperatureUnit>?
    private var infoConfigurations = [SettingsInfoConfiguration]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        contentConfigurations.removeAll()
        infoConfigurations.removeAll()

        if let settings = settings {
            
            contentConfigurations.append(SettingsToggleConfiguration(
                iconImageName: "camera",
                title: "Traffic Cameras",
                toggle: settings.showTrafficCamerasOnMap))

            contentConfigurations.append(SettingsToggleConfiguration(
                iconImageName: "safetycamera",
                title: "Safety Cameras",
                toggle: settings.showSafetyCamerasOnMap))
            
            contentConfigurations.append(SettingsToggleConfiguration(
                iconImageName: "incident",
                title: "Alerts",
                toggle: settings.showAlertsOnMap))
            
            contentConfigurations.append(SettingsToggleConfiguration(
                iconImageName: "roadworks",
                title: "Roadworks",
                toggle: settings.showRoadworksOnMap))
            
            contentConfigurations.append(SettingsToggleConfiguration(
                iconImageName: "bridge",
                title: "Bridges",
                toggle: settings.showBridgesOnMap))
            
            if #available(iOS 9.0, *) {
                contentConfigurations.append(SettingsToggleConfiguration(
                    iconImageName: "warning-traffic",
                    title: "Traffic",
                    toggle: settings.showTrafficOnMap))
            }
            
            notificationConfigurations.append(SettingsToggleConfiguration(
                iconImageName: "bridge",
                title: "Forth Road Bridge",
                toggle: settings.forthBridgeNotifications))

            notificationConfigurations.append(SettingsToggleConfiguration(
                iconImageName: "bridge",
                title: "Tay Road Bridge",
                toggle: settings.tayBridgeNotifications))

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
            
            let informationCellIdentifier = "SettingsInformationTableViewCell"
            let disclosureCellIdentifier = "SettingsDisclosureTableViewCell"
            
            infoConfigurations.append(SettingsInfoConfiguration(
                cellIdentifier: informationCellIdentifier,
                text: "Version",
                detailText: NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString") as? String))
            
            infoConfigurations.append(SettingsInfoConfiguration(
                cellIdentifier: disclosureCellIdentifier,
                text: "About ScotTraffic",
                detailText: nil))
            
            infoConfigurations.append(SettingsInfoConfiguration(
                cellIdentifier: disclosureCellIdentifier,
                text: "Support",
                detailText: nil))
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
            return contentConfigurations.count
        case .NotificationsSection:
            return notificationConfigurations.count
        case .SettingsSection:
            return SettingsItems.Count.rawValue
        case .AboutSection:
            return infoConfigurations.count
        default:
            return 0
        }
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch TableSections(rawValue: section)! {
        case .ContentSection:
            return "Content"
        case .NotificationsSection:
            return "Notifications"
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
            cell.configure(contentConfigurations[indexPath.row])
            return cell
            
        case .NotificationsSection:
            let cell = tableView.dequeueReusableCellWithIdentifier("SettingsToggleTableViewCell", forIndexPath: indexPath) as! SettingsToggleTableViewCell
            cell.configure(notificationConfigurations[indexPath.row])
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
            let config = infoConfigurations[indexPath.row]
            let cell = tableView.dequeueReusableCellWithIdentifier(config.cellIdentifier, forIndexPath: indexPath)
            cell.textLabel?.text = config.text
            cell.detailTextLabel?.text = config.detailText
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
        webViewController.serverIsReachable = serverIsReachable
        navigationController?.pushViewController(webViewController, animated: true)
    }
}
