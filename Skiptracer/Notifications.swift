//
//  Notifications.swift
//  Skiptracer
//
//  Created by Colin Caufield on 4/1/15.
//  Copyright (c) 2015 Secret Geometry, Inc. All rights reserved.
//

import UIKit

private var _shared: Notifications? = nil

private let SKIP_ACTION_ID = "Skip"
private let SKIP_ACTION_TITLE = "Skip"
private let START_ACTION_ID = "Start"
private let START_ACTION_TITLE = "Start"
private let OK_ACTION_ID = "OK"
private let OK_ACTION_TITLE = "OK"
private let BREAK_CATEGORY_ID = "Break"
private let BREAK_CATEGORY_TITLE = "Break"
private let PROGRESS_CATEGORY_ID = "Progress"
private let PROGRESS_CATEGORY_TITLE = "Progress"
private let ACTIVITY_URI_KEY = "ActivityURI"

class Notifications: NSObject {
    
    var breakStartAlerts = [UILocalNotification]()
    var breakEndAlerts = [UILocalNotification]()
    var progressAlerts = [UILocalNotification]()
    
    //var nextNote: UILocalNotification?
    
    class var shared: Notifications {
        
        if _shared == nil {
            _shared = Notifications()
        }
        
        return _shared!
    }
    
    override init() {
        
        super.init()
        
        // Breaks
        
        let skipAction = UIMutableUserNotificationAction()
        skipAction.identifier = SKIP_ACTION_TITLE
        skipAction.title = SKIP_ACTION_TITLE
        skipAction.activationMode = .Background
        skipAction.destructive = false
        skipAction.authenticationRequired = false
        
        let startAction = UIMutableUserNotificationAction()
        startAction.identifier = START_ACTION_TITLE
        startAction.title = START_ACTION_TITLE
        startAction.activationMode = .Background
        startAction.destructive = false
        startAction.authenticationRequired = false
        
        let breakCategory = UIMutableUserNotificationCategory()
        breakCategory.identifier = BREAK_CATEGORY_TITLE
        breakCategory.setActions([skipAction, startAction], forContext: .Default)
        
        // Progress
        
        let progressCategory = UIMutableUserNotificationCategory()
        progressCategory.identifier = PROGRESS_CATEGORY_TITLE
        //progressCategory.setActions([], forContext: .Default)
        
        let categories = Set<NSObject>([breakCategory/*, progressCategory*/])
        let settings = UIUserNotificationSettings(forTypes: .Alert | .Sound, categories: categories)
        self.app.registerUserNotificationSettings(settings)
    }
    
    var app: UIApplication {
        return AppDelegate.shared.app
    }
    
    var center: NSNotificationCenter {
        return NSNotificationCenter.defaultCenter()
    }
    
    var currentUser: User? {
        return AppData.shared.settings.currentUser
    }
    
    var currentReport: Report? {
        return self.currentUser?.currentReport
    }
    
    func registerUserObserver(observer: AnyObject) {
        self.center.addObserver(self, selector: "userWasSwitched:", name: UserWasSwitchedNotification, object: nil)
    }
    
    func registerBreakObserver(observer: AnyObject) {
        self.center.addObserver(observer, selector: "autoBreakWasStarted:", name: AutoBreakWasStartedNotification, object: nil)
        self.center.addObserver(observer, selector: "autoBreakWasEnded:", name: AutoBreakWasEndedNotification, object: nil)
    }
    
    var shouldShowAlerts: Bool {
        let types = self.app.currentUserNotificationSettings().types
        return (types & .Alert) != nil
    }
    
    func didFinishLaunchingWithNotification(note: UILocalNotification) {
        self.handleNotification(note)
    }
    
    func scheduleNextBreakNotificationForReport(report: Report) {
        if let date = report.nextBreakDate {
            if let activity = report.activity {
                if let message = activity.breakMessage {
                    if let activityID = activity.objectID.URIRepresentation().absoluteString {
                        self.scheduleNotification(
                            date,
                            title: BREAK_CATEGORY_ID,
                            body: message,
                            action: "OK",
                            category: BREAK_CATEGORY_TITLE,
                            info: [ACTIVITY_URI_KEY: activityID])
                    }
                }
            }
        }
    }
    
    func scheduleNextProgressNotificationForReport(report: Report) {
        if let date = report.nextProgressDate {
            if let activity = report.activity {
                if let activityID = activity.objectID.URIRepresentation().absoluteString {
                    self.scheduleNotification(
                        date,
                        title: PROGRESS_CATEGORY_ID,
                        body: report.progressMessage,
                        action: "OK",
                        category: PROGRESS_CATEGORY_TITLE,
                        info: [ACTIVITY_URI_KEY: activityID])
                }
            }
        }
    }
    
    func showBreakAlert() {
        self.showAlert(BREAK_CATEGORY_ID)
    }
    
    func showBreakAlert(viewController: UIViewController, report: Report) {
        
        if let message = report.activity?.breakMessage {
            
            let alert = UIAlertController(title: BREAK_CATEGORY_TITLE, message: message, preferredStyle: .Alert)
            
            alert.addAction(UIAlertAction(title: SKIP_ACTION_TITLE, style: .Default, handler: handleBreakAlertWithSkip))
            alert.addAction(UIAlertAction(title: START_ACTION_TITLE, style: .Default, handler: handleBreakAlertWithStart))
            
            println("Showing break alert view")
            viewController.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    func showProgressAlert() {
        self.showAlert(PROGRESS_CATEGORY_ID)
    }
    
    func showProgressAlert(viewController: UIViewController, report: Report) {
        
        let message = report.progressMessage
        
        let alert = UIAlertController(title: PROGRESS_CATEGORY_TITLE, message: message, preferredStyle: .Alert)
        
        alert.addAction(UIAlertAction(title: OK_ACTION_TITLE, style: .Default, handler: nil))
        
        println("Showing progress alert view")
        viewController.presentViewController(alert, animated: true, completion: nil)
    }
    
    func showAlert(category: String) {
        
        let tabController = AppDelegate.shared.window!.rootViewController! as! UITabBarController
        let navigationController = tabController.selectedViewController as! UINavigationController
        let topController = navigationController.topViewController
        
        if let report = self.currentReport {
            
            switch category {
                
            case BREAK_CATEGORY_ID:
                self.showBreakAlert(topController, report: report)
                
            case PROGRESS_CATEGORY_ID:
                self.showProgressAlert(topController, report: report)
            
            default:
                break
            }
        }
    }
    
    func handleBreakNotification(note: UILocalNotification) {
        
        if !self.shouldShowAlerts {
            return
        }
        
        if note.category == BREAK_CATEGORY_TITLE {
            
            if self.currentUser?.currentReport == nil {
                println("Skipping notification due to no current report.")
                return
            }
            
            if self.currentUser?.currentBreak != nil {
                println("Skipping notification due to break already in progress.")
                return
            }
            
            let noteActivityID = note.userInfo?[ACTIVITY_URI_KEY] as? String
            let currentActivityID = self.currentReport?.activity?.objectID.URIRepresentation().absoluteString
            
            if noteActivityID != currentActivityID {
                println("Skipping notification because of activity mismatch.")
                return
            }
            
            switch self.app.applicationState {
            
            case .Active:
                println("handleBreakNotification (Active)")
                self.showBreakAlert()
            
            case .Inactive:
                println("handleBreakNotification (Inactive)")
                self.handleBreakAlertWithStart()
            
            case .Background:
                println("handleBreakNotification (Background)")
                self.handleBreakAlertWithStart()
            }
        }
    }
    
    func handleProgressNotification(note: UILocalNotification) {
        
        if !self.shouldShowAlerts {
            return
        }
        
        if note.category == PROGRESS_CATEGORY_TITLE {
            
            if self.currentUser?.currentReport == nil {
                println("Skipping notification due to no current report.")
                return
            }
            
            let noteActivityID = note.userInfo?[ACTIVITY_URI_KEY] as? String
            let currentActivityID = self.currentReport?.activity?.objectID.URIRepresentation().absoluteString
            
            if noteActivityID != currentActivityID {
                println("Skipping notification because of activity mismatch.")
                return
            }
            
            switch self.app.applicationState {
                
            case .Active:
                println("handleBreakNotification (Active)")
                self.showProgressAlert()
                
            case .Inactive:
                println("handleBreakNotification (Inactive)")
                break
                
            case .Background:
                println("handleBreakNotification (Background)")
                break
            }
        }
    }
    
    func handleNotification(note: UILocalNotification) {
        
        if note.category == nil {
            return
        }
        
        switch note.category! {
            
        case BREAK_CATEGORY_ID:
            self.handleBreakNotification(note)
            
        case PROGRESS_CATEGORY_ID:
            self.handleProgressNotification(note)
            
        default:
            break
        }
    }
    
    func handleBreakAlertWithStart(alert: UIAlertAction!) {
        self.handleBreakAlertWithStart()
    }
    
    func handleBreakAlertWithSkip(alert: UIAlertAction!) {
        self.handleBreakAlertWithSkip()
    }
    
    func handleBreakAlertWithStart() {
        println("handleBreakAlertWithStart")
        StatusController.shared.beginBreak()
        self.center.postNotificationName(AutoBreakWasStartedNotification, object: nil)
    }
    
    func handleBreakAlertWithSkip() {
        println("handleBreakAlertWithSkip")
        // Do nothing.
    }
    
    func handleAction(identifier: String?, note: UILocalNotification) {
        
        println("Handle action \(identifier) for notification \(note)")
        
        if identifier == nil { return }
        
        switch identifier! {
            
        case START_ACTION_TITLE:
            self.handleBreakAlertWithStart()
            break
            
        case SKIP_ACTION_TITLE:
            self.handleBreakAlertWithSkip()
            break
        
        default:
            break
        }
    }
    
    func cancelNotification(note: UILocalNotification) {
        self.app.cancelLocalNotification(note)
        println("Cancelled notification \(note)")
    }
    
    func cancelAllNotifications() {
        self.app.cancelAllLocalNotifications()
        println("Cancelled all notifications")
    }
    
    func scheduleNotification(date: NSDate, title: String, body: String? = nil, action: String? = nil, category: String? = nil, info: [NSObject: AnyObject]? = nil, badgeNumber: Int? = nil) {
        
        //if let note = self.nextNote {
        //    self.cancelNotification(note)
        //}
        
        if !self.shouldShowAlerts {
            return
        }
        
        //self.nextNote = UILocalNotification()
        //let note = self.nextNote!
        
        let note = UILocalNotification()
        note.timeZone = NSTimeZone.systemTimeZone()
        note.fireDate = date
        note.userInfo = info
        note.alertTitle = title
        note.alertBody = body
        note.alertAction = action
        note.soundName = UILocalNotificationDefaultSoundName
        note.category = category
        note.applicationIconBadgeNumber = badgeNumber ?? 0
        
        self.app.scheduleLocalNotification(note)
        
        println("Scheduled notification \(note)")
    }
}
