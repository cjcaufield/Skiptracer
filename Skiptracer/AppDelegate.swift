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
        Notifications.shared // Force the notification system to be created early.
    }
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        AppData.shared // Force the database to be created early.
        
        // Handle notifications that arrived in the background.
        let localNote: AnyObject? = launchOptions?[UIApplicationLaunchOptionsLocalNotificationKey]
        
        if let note = localNote as? UILocalNotification {
            Notifications.shared.handleNotification(note)
        }
        
        println("Launch options notification \(localNote)")
        return true
    }
    
    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
        Notifications.shared.handleNotification(notification)
    }

    func application(application: UIApplication, handleActionWithIdentifier identifier: String?, forLocalNotification notification: UILocalNotification, completionHandler: () -> Void) {
        Notifications.shared.handleNotification(notification, action: identifier)
        completionHandler()
    }
    
    func applicationWillTerminate(application: UIApplication) {
        AppData.shared.save()
    }
}
