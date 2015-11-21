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
    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        migrateUserDefaultsToAppGroup()
        
        let appModel = AppModel()
        appWidgetManager = AppWidgetManager(favourites: appModel.favourites)
        
        if let window = window {
            let appCoordinator = AppCoordinator(appModel: appModel, rootWindow: window)
            appCoordinator.start()

            self.appCoordinator = appCoordinator
        }
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
    }

    func applicationDidEnterBackground(application: UIApplication) {
        NSUserDefaults.standardUserDefaults().synchronize()
    }

    func applicationWillEnterForeground(application: UIApplication) {
        if let appModel = appCoordinator?.appModel {
            appModel.settings.reload()
            appModel.favourites.reloadFromUserDefaults()
        }
    }

    func applicationDidBecomeActive(application: UIApplication) {
    }

    func applicationWillTerminate(application: UIApplication) {
    }


}

