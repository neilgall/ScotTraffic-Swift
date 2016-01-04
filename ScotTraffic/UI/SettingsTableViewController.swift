//
//  SettingsTableViewController.swift
//  ScotTraffic
//
//  Created by Neil Gall on 10/11/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit

protocol SettingsTableViewControllerDelegate {
    func settingsViewControllerDidDismiss(settingsViewController: SettingsTableViewController)
}

protocol SettingsTableViewCell {
    func configure(configuration: SettingConfiguration)
}

class SettingsTableViewController: UITableViewController {

    var settings: Settings?
    var delegate: SettingsTableViewControllerDelegate?
    var serverIsReachable: Observable<Bool>?
    
    private var temperatureAdapter: BidirectionalMapToInt<TemperatureUnit>?
    private var observations = [Observation]()
    private var configurations = [(String, [SettingConfiguration])]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        guard let settings = settings else {
            return
        }

        var contentConfigurations: [SettingConfiguration] = [
            SettingsToggleConfiguration(
                iconImageName: "camera",
                title: "Traffic Cameras",
                toggle: settings.showTrafficCamerasOnMap),

            SettingsToggleConfiguration(
                iconImageName: "safetycamera",
                title: "Safety Cameras",
                toggle: settings.showSafetyCamerasOnMap),
            
            SettingsToggleConfiguration(
                iconImageName: "incident",
                title: "Alerts",
                toggle: settings.showAlertsOnMap),
            
            SettingsToggleConfiguration(
                iconImageName: "roadworks",
                title: "Roadworks",
                toggle: settings.showRoadworksOnMap),
            
            SettingsToggleConfiguration(
                iconImageName: "bridge",
                title: "Bridges",
                toggle: settings.showBridgesOnMap)
        ]
        
        if #available(iOS 9.0, *) {
            contentConfigurations.insert(SettingsToggleConfiguration(
                iconImageName: "warning-traffic",
                title: "Traffic",
                toggle: settings.showTrafficOnMap), atIndex:contentConfigurations.count-2)
        }

        let notificationConfigurations: Observable<[SettingConfiguration]> = settings.bridgeNotifications.map({ $0.map({ item in
            SettingsToggleConfiguration(
                iconImageName: "bridge",
                title: item.0.name,
                toggle: item.1)
        }) })
        
        temperatureAdapter = BidirectionalMapToInt(enumInput: settings.temperatureUnit)
        
        let settingConfigurations: [SettingConfiguration] = [
            SettingsToggleConfiguration(
                iconImageName: "07-map-marker",
                title: "Show current location",
                toggle: settings.showCurrentLocationOnMap),

            SettingsIntConfiguration(
                iconImageName: "959-thermometer",
                title: "Temperature Unit",
                setting: temperatureAdapter!.intInput,
                settingValueTitles: [
                    TemperatureUnit.Fahrenheit.rawValue: "ºF",
                    TemperatureUnit.Celcius.rawValue: "ºC"
                ])
        ]

        let infoConfigurations: [SettingConfiguration] = [
            SettingsInfoConfiguration(
                text: "Version",
                detailText: NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString") as? String,
                pageTitle: nil),
            
            SettingsInfoConfiguration(
                text: "About ScotTraffic",
                detailText: nil,
                pageTitle: "about"),
            
            SettingsInfoConfiguration(
                text: "Support",
                detailText: nil,
                pageTitle: "index")
        ]
        
        observations.append(notificationConfigurations => { [weak self] notificationConfigurations in
            self?.configurations = [
                ("Content",       contentConfigurations),
                ("Settings",      settingConfigurations),
                ("Notifications", notificationConfigurations),
                ("Help",          infoConfigurations)
            ]
            self?.tableView.reloadData()
        })
    }

    @IBAction func dismiss(sender: UIBarButtonItem) {
        delegate?.settingsViewControllerDidDismiss(self)
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return configurations.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return configurations[section].1.count
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return configurations[section].0
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let configuration = configurations[indexPath.section].1[indexPath.row]
        let cell = tableView.dequeueReusableCellWithIdentifier(configuration.cellIdentifier, forIndexPath: indexPath)
        if let cell = cell as? SettingsTableViewCell {
            cell.configure(configuration)
        }
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let configuration = configurations[indexPath.section].1[indexPath.row]
        guard let config = configuration as? SettingsInfoConfiguration, title = config.pageTitle else {
            return
        }
        
        pushWebView(title)
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
