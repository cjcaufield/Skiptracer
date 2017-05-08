//
//  AppDelegate.swift
//  Skiptracer
//
//  Created by Colin Caufield on 3/21/15.
//  Copyright (c) 2015 Secret Geometry, Inc. All rights reserved.
//

import UIKit
//import XCGLogger

private var _shared: AppDelegate? = nil

/*
let log = XCGLogger.defaultInstance()

func ENTRY_LOG(functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__) -> Void {
    log.debug("ENTRY", functionName: functionName, fileName: fileName, lineNumber: lineNumber)
}

func EXIT_LOG(functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__) -> Void {
    log.debug("EXIT", functionName: functionName, fileName: fileName, lineNumber: lineNumber)
}
*/

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    var app: UIApplication {
        return UIApplication.shared
    }
    
    class var shared: AppDelegate {
        assert(_shared != nil)
        return _shared!
    }
    
    override init() {
        super.init()
        assert(_shared == nil)
        _shared = self
        let _ = Notifications.shared // Force the notification system to be created early.
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        /*
        log.setup(
            logLevel: .Debug,
            showLogLevel: true,
            showFileNames: true,
            showLineNumbers: true,
            writeToFile: nil, //"path/to/file",
            fileLogLevel: .Debug)
        */
        
        let _ = AppData.shared // Force the database to be created early.
        
        // Handle notifications that arrived in the background.
        let localNote: AnyObject? = launchOptions?[UIApplicationLaunchOptionsKey.localNotification] as AnyObject?
        
        if let note = localNote as? UILocalNotification {
            Notifications.shared.handleNotification(note)
        }
        
        print("Launch options notification \(localNote)")
        return true
    }
    
    func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
        Notifications.shared.handleNotification(notification)
    }

    func application(_ application: UIApplication, handleActionWithIdentifier identifier: String?, for notification: UILocalNotification, completionHandler: @escaping () -> Void) {
        Notifications.shared.handleNotification(notification, action: identifier)
        completionHandler()
    }
    
    func application(_ application: UIApplication, didRegister notificationSettings: UIUserNotificationSettings) {
        print("Did register for notification settings \(notificationSettings)")
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        //ENTRY_LOG()
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        //ENTRY_LOG()
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        //ENTRY_LOG()
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        //ENTRY_LOG()
        Notifications.shared.scheduleAllNotificationsForCurrentReport()
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        AppData.shared.save()
    }
}
