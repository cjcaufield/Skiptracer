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

private let MAX_NOTIFICATION_COUNT   = 64
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
    
    var nextBreakNoteIndex: Int?
    var nextBreakEndNoteIndex: Int?
    var nextProgressNoteIndex: Int?
    var categories = Set<UIUserNotificationCategory>()
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
        
        self.categories = Set([breakCategory, breakEndCategory, progressCategory])
        
        let settings = UIUserNotificationSettings(forTypes: [.Alert, .Sound], categories: self.categories)
        
        self.app.registerUserNotificationSettings(settings)
        
        // Sound
        
        let path = NSBundle.mainBundle().pathForResource("Sounds/Klink", ofType: "wav")!
        let url = NSURL(fileURLWithPath: path)
        do {
            self.player = try AVAudioPlayer(contentsOfURL: url)
        } catch {
            self.player = nil
        }
        self.player?.prepareToPlay()
    }
    
    func enableNotifications(value: Bool) {
        if value {
            self.scheduleAllNotificationsForCurrentReport()
        } else {
            self.cancelAllNotifications()
        }
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
        return self.shouldAllowAlertTypes(.Alert)
    }
    
    var shouldPlaySounds: Bool {
        return self.shouldAllowAlertTypes(.Sound)
    }
    
    func shouldAllowAlertTypes(types: UIUserNotificationType) -> Bool {
        let systemSetting = self.app.currentUserNotificationSettings()?.types.contains(types) ?? false
        let dataSetting = AppData.shared.settings.enableAlerts
        return systemSetting && dataSetting
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
            print("Skipping notification due to no current report.")
            return false
        }
        
        let noteReportID = note.userInfo?[REPORT_URI_KEY] as? String
        let currentReportID = self.currentReport?.objectIDString
        
        if noteReportID != currentReportID {
            print("Skipping notification because of objectIDString mismatch.")
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
            
            alert.addAction(
                UIAlertAction(
                    title: SKIP_ACTION_TITLE,
                    style: .Default,
                    handler: { action in self.handleBreakAlertWithSkip() }))
            
            alert.addAction(
                UIAlertAction(
                    title: START_ACTION_TITLE,
                    style: .Default,
                    handler: { action in self.handleBreakAlertWithStart() }))
            
            print("Showing break alert view")
            viewController.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    func showBreakEndAlert(viewController: UIViewController, report: Report) {
        
        if let message = report.activity?.breakEndMessage {
            
            let alert = UIAlertController(title: BREAK_END_CATEGORY_TITLE, message: message, preferredStyle: .Alert)
            
            alert.addAction(
                UIAlertAction(
                    title: SNOOZE_ACTION_TITLE,
                    style: .Default,
                    handler: { action in self.handleBreakEndAlertWithSnooze() }))
                
            alert.addAction(
                UIAlertAction(
                    title: STOP_ACTION_TITLE,
                    style: .Default,
                    handler: { action in self.handleBreakEndAlertWithStop() }))
                
            print("Showing break end alert view")
            viewController.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    func playProgressSound() {
        if self.shouldPlaySounds {
            self.player?.play()
        }
    }
    
    func showAlert(category: String) {
        
        if !self.shouldShowAlerts {
            return
        }
        
        let tabController = AppDelegate.shared.window!.rootViewController! as! UITabBarController
        let navigationController = tabController.selectedViewController as! UINavigationController
        let topController = navigationController.topViewController
        
        if let report = self.currentReport, let controller = topController {
            
            switch category {
                
            case BREAK_CATEGORY_ID:
                self.showBreakAlert(controller, report: report)
                
            case BREAK_END_CATEGORY_ID:
                self.showBreakEndAlert(controller, report: report)
                
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
                print("Skipping break begin notification due to break already in progress.")
                return
            }
            
            switch self.app.applicationState {
            
            case .Active:
                print("handleBreakNotification (Active)")
                self.showBreakAlert()
            
            case .Inactive:
                print("handleBreakNotification (Inactive)")
                self.handleBreakAlertWithStart()
            
            case .Background:
                print("handleBreakNotification (Background)")
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
                print("Skipping break end notification due to no break in progress.")
                return
            }
            
            switch self.app.applicationState {
                
            case .Active:
                print("handleBreakEndNotification (Active)")
                self.showBreakEndAlert()
                
            case .Inactive:
                print("handleBreakEndNotification (Inactive)")
                self.handleBreakEndAlertWithStop()
                
            case .Background:
                print("handleBreakEndNotification (Background)")
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
                print("handleProgressNotification (Active)")
                self.playProgressSound()
                
            case .Inactive:
                print("handleProgressNotification (Inactive)")
                
            case .Background:
                print("handleProgressNotification (Background)")
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
        
        self.scheduleAllNotificationsForCurrentReport()
    }
    
    func handleBreakAlertWithStart() {
        print("handleBreakAlertWithStart")
        StatusController.shared.beginBreak()
        self.center.postNotificationName(AutoBreakWasStartedNotification, object: nil)
    }
    
    func handleBreakAlertWithSkip() {
        print("handleBreakAlertWithSkip")
        // Do nothing.
    }
    
    func handleBreakEndAlertWithStop() {
        print("handleBreakAlertWithStop")
        StatusController.shared.endCurrentBreak()
        self.center.postNotificationName(AutoBreakWasEndedNotification, object: nil)
    }
    
    func handleBreakEndAlertWithSnooze() {
        print("handleBreakAlertWithSnooze")
        //StatusController.shared.snoozeBreak()
        //self.center.postNotificationName(AutoBreakWasSnoozedNotification, object: nil)
    }
    
    func handleNotification(notification: UILocalNotification, action: String?) {
        
        print("Handle action \(action) for notification \(notification)")
        
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
        
        self.scheduleAllNotificationsForCurrentReport()
    }
    
    func cancelAllNotifications() {
        
        self.app.cancelAllLocalNotifications()
        print("Cancelled all notifications")
        
        self.nextBreakNoteIndex = 0
        self.nextBreakEndNoteIndex = 0
        self.nextProgressNoteIndex = 0
    }
    
    func rescheduleAllNotificationsForCurrentReport() {
        self.cancelAllNotifications()
        self.scheduleAllNotificationsForCurrentReport()
    }
    
    func scheduleAllNotificationsForCurrentReport() {
        if let report = self.currentReport {
            self.scheduleAllNotificationsForReport(report)
        } else {
            self.cancelAllNotifications()
        }
    }
    
    func scheduleAllNotificationsForReport(report: Report) {
        
        if !self.shouldShowAlerts {
            return
        }
        
        if let activity = report.activity {
            
            let now = NSDate()
            var count = self.app.scheduledLocalNotifications?.count ?? 0
            
            self.nextBreakNoteIndex = safeMax(self.nextBreakNoteIndex, b: report.nextBreakIndex(now))
            self.nextBreakEndNoteIndex = safeMax(self.nextBreakEndNoteIndex, b: report.nextBreakEndIndex(now))
            self.nextProgressNoteIndex = safeMax(self.nextProgressNoteIndex, b: report.nextProgressIndex(now))
            
            assert(self.nextBreakNoteIndex >= 0)
            assert(self.nextBreakEndNoteIndex >= 0)
            
            while count < MAX_NOTIFICATION_COUNT { // The docs state that 64 is the limit.
                
                let nextBreakDate = report.breakDateForIndex(self.nextBreakNoteIndex)
                let nextBreakEndDate = report.breakEndDateForIndex(self.nextBreakEndNoteIndex)
                let nextProgressDate = report.progressDateForIndex(self.nextProgressNoteIndex)
                
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
                    print("Scheduled break note \(self.nextBreakNoteIndex!) for \(nextBreakDate!)")
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
                    print("Scheduled break end note \(self.nextBreakEndNoteIndex!) for \(nextBreakEndDate!)")
                    self.nextBreakEndNoteIndex!++
                }
                else if earliest == nextProgressDate {
                    
                    self.scheduleProgressNotificationForReport(report, date: nextProgressDate!, message: progressMessage, index: self.nextProgressNoteIndex!)
                    print("Scheduled progress note \(self.nextProgressNoteIndex!) for \(nextProgressDate!)")
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
