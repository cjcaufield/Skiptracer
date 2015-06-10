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
        return UIApplication.sharedApplication()
    }
    
    class var shared: AppDelegate {
        assert(_shared != nil)
        return _shared!
    }
    
    override init() {
        super.init()
        assert(_shared == nil)
        _shared = self
        Notifications.shared // Force the notification system to be created early.
    }
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        /*
        log.setup(
            logLevel: .Debug,
            showLogLevel: true,
            showFileNames: true,
            showLineNumbers: true,
            writeToFile: nil, //"path/to/file",
            fileLogLevel: .Debug)
        */
        
        AppData.shared // Force the database to be created early.
        
        // Handle notifications that arrived in the background.
        let localNote: AnyObject? = launchOptions?[UIApplicationLaunchOptionsLocalNotificationKey]
        
        if let note = localNote as? UILocalNotification {
            Notifications.shared.handleNotification(note)
        }
        
        print("Launch options notification \(localNote)")
        return true
    }
    
    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
        Notifications.shared.handleNotification(notification)
    }

    func application(application: UIApplication, handleActionWithIdentifier identifier: String?, forLocalNotification notification: UILocalNotification, completionHandler: () -> Void) {
        Notifications.shared.handleNotification(notification, action: identifier)
        completionHandler()
    }
    
    func application(application: UIApplication, didRegisterUserNotificationSettings notificationSettings: UIUserNotificationSettings) {
        print("Did register for notification settings \(notificationSettings)")
    }
    
    func applicationWillResignActive(application: UIApplication) {
        //ENTRY_LOG()
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        //ENTRY_LOG()
    }
    
    func applicationWillEnterForeground(application: UIApplication) {
        //ENTRY_LOG()
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        //ENTRY_LOG()
        Notifications.shared.scheduleAllNotificationsForCurrentReport()
    }
    
    func applicationWillTerminate(application: UIApplication) {
        AppData.shared.save()
    }
}
