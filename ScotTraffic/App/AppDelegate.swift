//
//  AppDelegate.swift
//  ScotTraffic
//
//  Created by Neil Gall on 15/09/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var appWidgetManager: AppWidgetManager?
    var appCoordinator: AppCoordinator?
    var appNotifications: AppNotifications?
    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        if Configuration.betaTesting {
            loadUserDefaultsFromDiagnosticDataIfPresent()
        }
        
        analyticsStart()
        migrateUserDefaultsToAppGroup()
        
        let appModel = AppModel()
        appWidgetManager = AppWidgetManager(favourites: appModel.favourites)
        appNotifications = AppNotifications(settings: appModel.settings, httpAccess: appModel.httpAccess)
        
        if let window = window where !Configuration.runningUnitTests {
            let appCoordinator = AppCoordinator(appModel: appModel, rootWindow: window)
            appCoordinator.start()
            self.appCoordinator = appCoordinator
        }
        
        appModel.remoteNotifications.parseLaunchOptions(launchOptions)

        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        NSUserDefaults.standardUserDefaults().synchronize()
    }

    func applicationWillEnterForeground(application: UIApplication) {
        if let appModel = appCoordinator?.appModel {
            appModel.settings.reload()
            appModel.favourites.reloadFromUserDefaults()
        }
    }

    // -- MARK: Notifications
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        appNotifications?.didFailToRegisterWithError(error)
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        appNotifications?.didRegisterWithDeviceToken(deviceToken)
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        appCoordinator?.appModel.remoteNotifications.parseRemoteNotificationOptions(userInfo, inApplicationState: application.applicationState)
    }
}
