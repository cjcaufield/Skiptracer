//
//  AppDelegate.swift
//  Skiptracer
//
//  Created by Colin Caufield on 3/21/15.
//  Copyright (c) 2015 Secret Geometry, Inc. All rights reserved.
//

import UIKit

private var _shared: AppDelegate? = nil

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
        
        Notifications.shared // Initialize notifications
    }
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        // Handle notifications that arrived in the background.
        let settings = self.app.currentUserNotificationSettings() // check before scheduling
        let localNote: AnyObject? = launchOptions?[UIApplicationLaunchOptionsLocalNotificationKey]
        
        if let note = localNote as? UILocalNotification {
            Notifications.shared.didFinishLaunchingWithNotification(note)
        }
        
        println("Launch options notification \(localNote)")
        return true
    }
    
    func application(application: UIApplication, didRegisterUserNotificationSettings notificationSettings: UIUserNotificationSettings) {
        println("Did register for notification settings \(notificationSettings)")
    }
    
    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
        // Handle notifications that arrived in the foreground.
        println("Foreground notification \(notification)")
        Notifications.shared.handleBreakNotification(notification)
    }

    func application(application: UIApplication, handleActionWithIdentifier identifier: String?, forLocalNotification notification: UILocalNotification, completionHandler: () -> Void) {
        Notifications.shared.handleAction(identifier, note: notification)
        completionHandler()
    }
    
    func applicationWillTerminate(application: UIApplication) {
        AppData.shared.save()
    }
}
