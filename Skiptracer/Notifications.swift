//
//  Notifications.swift
//  Skiptracer
//
//  Created by Colin Caufield on 4/1/15.
//  Copyright (c) 2015 Secret Geometry, Inc. All rights reserved.
//

import UIKit
import AVFoundation

private var _shared: Notifications? = nil

private let SKIP_ACTION_ID           = "Skip"
private let SKIP_ACTION_TITLE        = "Skip"
private let START_ACTION_ID          = "Start"
private let START_ACTION_TITLE       = "Start"
private let STOP_ACTION_ID           = "Stop"
private let STOP_ACTION_TITLE        = "Resume"
private let SNOOZE_ACTION_ID         = "Snooze"
private let SNOOZE_ACTION_TITLE      = "Snooze"
private let BREAK_CATEGORY_ID        = "Break"
private let BREAK_CATEGORY_TITLE     = "Break"
private let BREAK_END_CATEGORY_ID    = "BreakEnd"
private let BREAK_END_CATEGORY_TITLE = "Resume"
private let PROGRESS_CATEGORY_ID     = "Progress"
private let PROGRESS_CATEGORY_TITLE  = "Progress"
private let ACTIVITY_URI_KEY         = "ActivityURI"
private let REPORT_URI_KEY           = "ReportURI"

enum NoteType {
    
    case Break
    case BreakEnd
    case Progress
}

class Notifications: NSObject {
    
    var nextBreakNoteIndex: Int? = nil
    var nextBreakEndNoteIndex: Int? = nil
    var nextProgressNoteIndex: Int? = nil
    
    var player: AVAudioPlayer?
    
    class var shared: Notifications {
        if _shared == nil {
            _shared = Notifications()
        }
        return _shared!
    }
    
    override init() {
        
        super.init()
        
        // Break begin notifications
        
        let skipAction = UIMutableUserNotificationAction()
        skipAction.identifier = SKIP_ACTION_ID
        skipAction.title = SKIP_ACTION_TITLE
        skipAction.activationMode = .Background
        skipAction.destructive = false
        skipAction.authenticationRequired = false
        
        let startAction = UIMutableUserNotificationAction()
        startAction.identifier = START_ACTION_ID
        startAction.title = START_ACTION_TITLE
        startAction.activationMode = .Background
        startAction.destructive = false
        startAction.authenticationRequired = false
        
        let breakCategory = UIMutableUserNotificationCategory()
        breakCategory.identifier = BREAK_CATEGORY_ID
        breakCategory.setActions([skipAction, startAction], forContext: .Default)
        
        // Break end notifications
        
        let snoozeAction = UIMutableUserNotificationAction()
        snoozeAction.identifier = SNOOZE_ACTION_ID
        snoozeAction.title = SNOOZE_ACTION_TITLE
        snoozeAction.activationMode = .Background
        snoozeAction.destructive = false
        snoozeAction.authenticationRequired = false
        
        let stopAction = UIMutableUserNotificationAction()
        stopAction.identifier = STOP_ACTION_ID
        stopAction.title = STOP_ACTION_TITLE
        stopAction.activationMode = .Background
        stopAction.destructive = false
        stopAction.authenticationRequired = false
        
        let breakEndCategory = UIMutableUserNotificationCategory()
        breakCategory.identifier = BREAK_END_CATEGORY_ID
        breakCategory.setActions([snoozeAction, stopAction], forContext: .Default)
        
        // Progress notifications
        
        let progressCategory = UIMutableUserNotificationCategory()
        progressCategory.identifier = PROGRESS_CATEGORY_ID
        
        // Register notifications
        
        let categories = Set<NSObject>([breakCategory, breakEndCategory, progressCategory])
        let settings = UIUserNotificationSettings(forTypes: .Alert | .Sound, categories: categories)
        self.app.registerUserNotificationSettings(settings)
        
        // Sound
        
        let path = NSBundle.mainBundle().pathForResource("Sounds/Klink", ofType: "wav")!
        let url = NSURL(fileURLWithPath: path)
        self.player = AVAudioPlayer(contentsOfURL: url, error: nil)
        self.player?.prepareToPlay()
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
    
    var currentBreak: Report? {
        return self.currentUser?.currentBreak
    }
    
    func registerUserObserver(observer: AnyObject) {
        self.center.addObserver(observer, selector: "userWasSwitched:", name: UserWasSwitchedNotification, object: nil)
    }
    
    func registerBreakObserver(observer: AnyObject) {
        self.center.addObserver(observer, selector: "autoBreakWasStarted:", name: AutoBreakWasStartedNotification, object: nil)
        self.center.addObserver(observer, selector: "autoBreakWasEnded:", name: AutoBreakWasEndedNotification, object: nil)
    }
    
    var shouldShowAlerts: Bool {
        let types = self.app.currentUserNotificationSettings().types
        return (types & .Alert) != nil
    }
    
    func infoForReport(report: Report) -> [NSObject: AnyObject]? {
        
        assert(!report.objectID.temporaryID)
        assert(!report.activity!.objectID.temporaryID)
        
        if let activity = report.activity {
            if let activityID = activity.objectIDString {
                if let reportID = report.objectIDString {
                    return [ACTIVITY_URI_KEY: activityID, REPORT_URI_KEY: reportID]
                }
            }
        }
        
        return nil
    }
    
    func noteIsForCurrentReport(note: UILocalNotification) -> Bool {
        
        if self.currentUser?.currentReport == nil {
            println("Skipping notification due to no current report.")
            return false
        }
        
        let noteReportID = note.userInfo?[REPORT_URI_KEY] as? String
        let currentReportID = self.currentReport?.objectIDString
        
        if noteReportID != currentReportID {
            println("Skipping notification because of objectIDString mismatch.")
            return false
        }
        
        return true
    }
    
    func showBreakAlert() {
        self.showAlert(BREAK_CATEGORY_ID)
    }
    
    func showBreakEndAlert() {
        self.showAlert(BREAK_END_CATEGORY_ID)
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
    
    func showBreakEndAlert(viewController: UIViewController, report: Report) {
        
        if let message = report.activity?.breakEndMessage {
            
            let alert = UIAlertController(title: BREAK_END_CATEGORY_TITLE, message: message, preferredStyle: .Alert)
            
            alert.addAction(UIAlertAction(title: SNOOZE_ACTION_TITLE, style: .Default, handler: handleBreakEndAlertWithSnooze))
            alert.addAction(UIAlertAction(title: STOP_ACTION_TITLE, style: .Default, handler: handleBreakEndAlertWithStop))
            
            println("Showing break end alert view")
            viewController.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    func playProgressSound() {
        self.player?.play()
    }
    
    func showAlert(category: String) {
        
        let tabController = AppDelegate.shared.window!.rootViewController! as! UITabBarController
        let navigationController = tabController.selectedViewController as! UINavigationController
        let topController = navigationController.topViewController
        
        if let report = self.currentReport {
            
            switch category {
                
            case BREAK_CATEGORY_ID:
                self.showBreakAlert(topController, report: report)
                
            case BREAK_END_CATEGORY_ID:
                self.showBreakEndAlert(topController, report: report)
                
            case PROGRESS_CATEGORY_ID:
                self.playProgressSound()
            
            default:
                break
            }
        }
    }
    
    func handleBreakNotification(note: UILocalNotification) {
        
        if !self.shouldShowAlerts {
            return
        }
        
        if note.category == BREAK_CATEGORY_ID {
            
            if !self.noteIsForCurrentReport(note) {
                return
            }
            
            if self.currentUser?.currentBreak != nil {
                println("Skipping break begin notification due to break already in progress.")
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
    
    func handleBreakEndNotification(note: UILocalNotification) {
        
        if !self.shouldShowAlerts {
            return
        }
        
        if note.category == BREAK_END_CATEGORY_ID {
            
            if !self.noteIsForCurrentReport(note) {
                return
            }
            
            if self.currentUser?.currentBreak == nil {
                println("Skipping break end notification due to no break in progress.")
                return
            }
            
            switch self.app.applicationState {
                
            case .Active:
                println("handleBreakEndNotification (Active)")
                self.showBreakEndAlert()
                
            case .Inactive:
                println("handleBreakEndNotification (Inactive)")
                self.handleBreakEndAlertWithStop()
                
            case .Background:
                println("handleBreakEndNotification (Background)")
                self.handleBreakEndAlertWithStop()
            }
        }
    }
    
    func handleProgressNotification(note: UILocalNotification) {
        
        if !self.shouldShowAlerts {
            return
        }
        
        if note.category == PROGRESS_CATEGORY_ID {
            
            if !self.noteIsForCurrentReport(note) {
                return
            }
            
            switch self.app.applicationState {
                
            case .Active:
                println("handleProgressNotification (Active)")
                self.playProgressSound()
                
            case .Inactive:
                println("handleProgressNotification (Inactive)")
                
            case .Background:
                println("handleProgressNotification (Background)")
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
            
        case BREAK_END_CATEGORY_ID:
            self.handleBreakEndNotification(note)
            
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
    
    func handleBreakEndAlertWithStop(alert: UIAlertAction!) {
        self.handleBreakEndAlertWithStop()
    }
    
    func handleBreakEndAlertWithSnooze(alert: UIAlertAction!) {
        self.handleBreakEndAlertWithSnooze()
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
    
    func handleBreakEndAlertWithStop() {
        println("handleBreakAlertWithStop")
        StatusController.shared.endCurrentBreak()
        self.center.postNotificationName(AutoBreakWasEndedNotification, object: nil)
    }
    
    func handleBreakEndAlertWithSnooze() {
        println("handleBreakAlertWithSnooze")
        //StatusController.shared.snoozeBreak()
        //self.center.postNotificationName(AutoBreakWasSnoozedNotification, object: nil)
    }
    
    func handleNotification(notification: UILocalNotification, action: String?) {
        
        println("Handle action \(action) for notification \(notification)")
        
        if action == nil { return }
        
        switch action! {
            
        case START_ACTION_ID:
            self.handleBreakAlertWithStart()
            
        case SKIP_ACTION_ID:
            self.handleBreakAlertWithSkip()
            
        case STOP_ACTION_ID:
            self.handleBreakEndAlertWithStop()
            
        case SNOOZE_ACTION_ID:
            self.handleBreakEndAlertWithSnooze()
        
        default:
            break
        }
    }
    
    /*
    func cancelNotification(note: UILocalNotification) {
        self.app.cancelLocalNotification(note)
        println("Cancelled notification \(note)")
    }
    */
    
    func cancelAllNotifications() {
        
        self.app.cancelAllLocalNotifications()
        println("Cancelled all notifications")
        
        self.nextBreakNoteIndex = 0
        self.nextBreakEndNoteIndex = 0
        self.nextProgressNoteIndex = 0
    }
    
    func scheduleAllNotificationsForReport(report: Report) {
        
        if let activity = report.activity {
            
            let now = NSDate()
            var count = self.app.scheduledLocalNotifications.count
            
            self.nextBreakNoteIndex = safeMax(self.nextBreakNoteIndex, report.nextBreakIndex(now))
            self.nextBreakEndNoteIndex = safeMax(self.nextBreakEndNoteIndex, report.nextBreakEndIndex(now))
            self.nextProgressNoteIndex = safeMax(self.nextProgressNoteIndex, report.nextProgressIndex(now))
            
            assert(self.nextBreakNoteIndex >= 0)
            assert(self.nextBreakEndNoteIndex >= 0)
            
            while count < 64 { // The docs state that 64 is the limit.
                
                var nextBreakDate = report.breakDateForIndex(self.nextBreakNoteIndex)
                var nextBreakEndDate = report.breakEndDateForIndex(self.nextBreakEndNoteIndex)
                var nextProgressDate = report.progressDateForIndex(self.nextProgressNoteIndex)
                
                let earliest = safeEarliestDate([nextBreakDate, nextBreakEndDate, nextProgressDate])
                if earliest == nil { return }
                
                let progressMessage = activity.progressMessageForIndex(self.nextProgressNoteIndex!)
                
                if earliest == nextBreakDate {
                    
                    // Combine with a progress message, if necessary.
                    var message = activity.breakMessage
                    if nextBreakDate == nextProgressDate {
                        message = progressMessage + "\n" + message
                        self.nextProgressNoteIndex!++
                    }
                    
                    self.scheduleBreakNotificationForReport(report, date: nextBreakDate!, message: message)
                    println("Scheduled break note \(self.nextBreakNoteIndex!) for \(nextBreakDate!)")
                    self.nextBreakNoteIndex!++
                }
                else if earliest == nextBreakEndDate {
                    
                    // Combine with a progress message, if necessary.
                    var message = activity.breakEndMessage
                    if nextBreakEndDate == nextProgressDate {
                        message = progressMessage + "\n" + message
                        self.nextProgressNoteIndex!++
                    }
                    
                    self.scheduleBreakEndNotificationForReport(report, date: nextBreakEndDate!, message: message)
                    println("Scheduled break end note \(self.nextBreakEndNoteIndex!) for \(nextBreakEndDate!)")
                    self.nextBreakEndNoteIndex!++
                }
                else if earliest == nextProgressDate {
                    
                    self.scheduleProgressNotificationForReport(report, date: nextProgressDate!, message: progressMessage, index: self.nextProgressNoteIndex!)
                    println("Scheduled progress note \(self.nextProgressNoteIndex!) for \(nextProgressDate!)")
                    self.nextProgressNoteIndex!++
                }
                
                count++
            }
        }
    }
    
    func scheduleBreakNotificationForReport(report: Report, date: NSDate, message: String) {
        if let info = self.infoForReport(report) {
            self.scheduleNotification(
                date,
                title: BREAK_CATEGORY_TITLE,
                body: message,
                action: nil,
                category: BREAK_CATEGORY_ID,
                info: info)
        }
    }
    
    func scheduleBreakEndNotificationForReport(report: Report, date: NSDate, message: String) {
        if let info = self.infoForReport(report) {
            self.scheduleNotification(
                date,
                title: BREAK_END_CATEGORY_TITLE,
                body: message,
                action: nil,
                category: BREAK_END_CATEGORY_ID,
                info: info)
        }
    }
    
    func scheduleProgressNotificationForReport(report: Report, date: NSDate, message: String, index: Int) {
        if let info = self.infoForReport(report) {
            self.scheduleNotification(
                date,
                title: PROGRESS_CATEGORY_TITLE,
                body: message,
                action: nil,
                category: PROGRESS_CATEGORY_ID,
                info: info)
        }
    }
    
    func scheduleNotification(date: NSDate, title: String, body: String? = nil, action: String? = nil, category: String? = nil, info: [NSObject: AnyObject]? = nil, badgeNumber: Int? = nil) {
        
        if !self.shouldShowAlerts {
            return
        }
        
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
        
        //println("Scheduled notification \(note)")
    }
}
