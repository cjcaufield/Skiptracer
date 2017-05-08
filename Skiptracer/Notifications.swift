//
//  Notifications.swift
//  Skiptracer
//
//  Created by Colin Caufield on 4/1/15.
//  Copyright (c) 2015 Secret Geometry, Inc. All rights reserved.
//

import UIKit
import SecretKit
import AVFoundation
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func >= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l >= r
  default:
    return !(lhs < rhs)
  }
}


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
    
    case `break`
    case breakEnd
    case progress
}

@objc protocol UserObserver {
    
    func userWasSwitched(_ note: Notification)
}

@objc protocol BreakObserver {
    
    func autoBreakWasStarted(_ note: Notification)
    func autoBreakWasEnded(_ note: Notification)
}

@objc class Notifications: NSObject {
    
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
        skipAction.activationMode = .background
        skipAction.isDestructive = false
        skipAction.isAuthenticationRequired = false
        
        let startAction = UIMutableUserNotificationAction()
        startAction.identifier = START_ACTION_ID
        startAction.title = START_ACTION_TITLE
        startAction.activationMode = .background
        startAction.isDestructive = false
        startAction.isAuthenticationRequired = false
        
        let breakCategory = UIMutableUserNotificationCategory()
        breakCategory.identifier = BREAK_CATEGORY_ID
        breakCategory.setActions([skipAction, startAction], for: .default)
        
        // Break end notifications
        
        let snoozeAction = UIMutableUserNotificationAction()
        snoozeAction.identifier = SNOOZE_ACTION_ID
        snoozeAction.title = SNOOZE_ACTION_TITLE
        snoozeAction.activationMode = .background
        snoozeAction.isDestructive = false
        snoozeAction.isAuthenticationRequired = false
        
        let stopAction = UIMutableUserNotificationAction()
        stopAction.identifier = STOP_ACTION_ID
        stopAction.title = STOP_ACTION_TITLE
        stopAction.activationMode = .background
        stopAction.isDestructive = false
        stopAction.isAuthenticationRequired = false
        
        let breakEndCategory = UIMutableUserNotificationCategory()
        breakCategory.identifier = BREAK_END_CATEGORY_ID
        breakCategory.setActions([snoozeAction, stopAction], for: .default)
        
        // Progress notifications
        
        let progressCategory = UIMutableUserNotificationCategory()
        progressCategory.identifier = PROGRESS_CATEGORY_ID
        
        // Register notifications
        
        self.categories = Set([breakCategory, breakEndCategory, progressCategory])
        
        let settings = UIUserNotificationSettings(types: [.alert, .sound], categories: self.categories)
        
        self.app.registerUserNotificationSettings(settings)
        
        // Sound
        
        let path = Bundle.main.path(forResource: "Sounds/Klink", ofType: "wav")!
        let url = URL(fileURLWithPath: path)
        do {
            self.player = try AVAudioPlayer(contentsOf: url)
        } catch {
            self.player = nil
        }
        self.player?.prepareToPlay()
    }
    
    func enableNotifications(_ value: Bool) {
        if value {
            self.scheduleAllNotificationsForCurrentReport()
        } else {
            self.cancelAllNotifications()
        }
    }
    
    var app: UIApplication {
        return AppDelegate.shared.app
    }
    
    var center: NotificationCenter {
        return NotificationCenter.default
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
    
    func registerUserObserver(_ observer: UserObserver) {
        self.center.addObserver(observer, selector: #selector(UserObserver.userWasSwitched(_:)), name: Notification.Name(rawValue: UserWasSwitchedNotification), object: nil)
    }
    
    func registerBreakObserver(_ observer: BreakObserver) {
        self.center.addObserver(observer, selector: #selector(BreakObserver.autoBreakWasStarted(_:)), name: Notification.Name(rawValue: AutoBreakWasStartedNotification), object: nil)
        self.center.addObserver(observer, selector: #selector(BreakObserver.autoBreakWasEnded(_:)), name: Notification.Name(rawValue: AutoBreakWasEndedNotification), object: nil)
    }
    
    var shouldShowAlerts: Bool {
        return self.shouldAllowAlertTypes(.alert)
    }
    
    var shouldPlaySounds: Bool {
        return self.shouldAllowAlertTypes(.sound)
    }
    
    func shouldAllowAlertTypes(_ types: UIUserNotificationType) -> Bool {
        let systemSetting = self.app.currentUserNotificationSettings?.types.contains(types) ?? false
        let dataSetting = AppData.shared.settings.enableAlerts
        return systemSetting && dataSetting
    }
    
    func infoForReport(_ report: Report) -> [AnyHashable: Any]? {
        
        assert(!report.objectID.isTemporaryID)
        assert(!report.activity!.objectID.isTemporaryID)
        
        if let activity = report.activity {
            if let activityID = activity.objectIDString {
                if let reportID = report.objectIDString {
                    return [ACTIVITY_URI_KEY: activityID, REPORT_URI_KEY: reportID]
                }
            }
        }
        
        return nil
    }
    
    func noteIsForCurrentReport(_ note: UILocalNotification) -> Bool {
        
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
    
    func showBreakAlert(_ viewController: UIViewController, report: Report) {
        
        if let message = report.activity?.breakMessage {
            
            let alert = UIAlertController(title: BREAK_CATEGORY_TITLE, message: message, preferredStyle: .alert)
            
            alert.addAction(
                UIAlertAction(
                    title: SKIP_ACTION_TITLE,
                    style: .default,
                    handler: { action in self.handleBreakAlertWithSkip() }))
            
            alert.addAction(
                UIAlertAction(
                    title: START_ACTION_TITLE,
                    style: .default,
                    handler: { action in self.handleBreakAlertWithStart() }))
            
            print("Showing break alert view")
            viewController.present(alert, animated: true, completion: nil)
        }
    }
    
    func showBreakEndAlert(_ viewController: UIViewController, report: Report) {
        
        if let message = report.activity?.breakEndMessage {
            
            let alert = UIAlertController(title: BREAK_END_CATEGORY_TITLE, message: message, preferredStyle: .alert)
            
            alert.addAction(
                UIAlertAction(
                    title: SNOOZE_ACTION_TITLE,
                    style: .default,
                    handler: { action in self.handleBreakEndAlertWithSnooze() }))
                
            alert.addAction(
                UIAlertAction(
                    title: STOP_ACTION_TITLE,
                    style: .default,
                    handler: { action in self.handleBreakEndAlertWithStop() }))
                
            print("Showing break end alert view")
            viewController.present(alert, animated: true, completion: nil)
        }
    }
    
    func playProgressSound() {
        if self.shouldPlaySounds {
            self.player?.play()
        }
    }
    
    func showAlert(_ category: String) {
        
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
    
    func handleBreakNotification(_ note: UILocalNotification) {
        
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
            
            case .active:
                print("handleBreakNotification (Active)")
                self.showBreakAlert()
            
            case .inactive:
                print("handleBreakNotification (Inactive)")
                self.handleBreakAlertWithStart()
            
            case .background:
                print("handleBreakNotification (Background)")
                self.handleBreakAlertWithStart()
            }
        }
    }
    
    func handleBreakEndNotification(_ note: UILocalNotification) {
        
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
                
            case .active:
                print("handleBreakEndNotification (Active)")
                self.showBreakEndAlert()
                
            case .inactive:
                print("handleBreakEndNotification (Inactive)")
                self.handleBreakEndAlertWithStop()
                
            case .background:
                print("handleBreakEndNotification (Background)")
                self.handleBreakEndAlertWithStop()
            }
        }
    }
    
    func handleProgressNotification(_ note: UILocalNotification) {
        
        if !self.shouldShowAlerts {
            return
        }
        
        if note.category == PROGRESS_CATEGORY_ID {
            
            if !self.noteIsForCurrentReport(note) {
                return
            }
            
            switch self.app.applicationState {
                
            case .active:
                print("handleProgressNotification (Active)")
                self.playProgressSound()
                
            case .inactive:
                print("handleProgressNotification (Inactive)")
                
            case .background:
                print("handleProgressNotification (Background)")
            }
        }
    }
    
    func handleNotification(_ note: UILocalNotification) {
        
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
        self.center.post(name: Notification.Name(rawValue: AutoBreakWasStartedNotification), object: nil)
    }
    
    func handleBreakAlertWithSkip() {
        print("handleBreakAlertWithSkip")
        // Do nothing.
    }
    
    func handleBreakEndAlertWithStop() {
        print("handleBreakAlertWithStop")
        StatusController.shared.endCurrentBreak()
        self.center.post(name: Notification.Name(rawValue: AutoBreakWasEndedNotification), object: nil)
    }
    
    func handleBreakEndAlertWithSnooze() {
        print("handleBreakAlertWithSnooze")
        //StatusController.shared.snoozeBreak()
        //self.center.postNotificationName(AutoBreakWasSnoozedNotification, object: nil)
    }
    
    func handleNotification(_ notification: UILocalNotification, action: String?) {
        
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
    
    func scheduleAllNotificationsForReport(_ report: Report) {
        
        if !self.shouldShowAlerts {
            return
        }
        
        if let activity = report.activity {
            
            let now = Date()
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
                        self.nextProgressNoteIndex! += 1
                    }
                    
                    self.scheduleBreakNotificationForReport(report, date: nextBreakDate!, message: message)
                    print("Scheduled break note \(self.nextBreakNoteIndex!) for \(nextBreakDate!)")
                    self.nextBreakNoteIndex! += 1
                }
                else if earliest == nextBreakEndDate {
                    
                    // Combine with a progress message, if necessary.
                    var message = activity.breakEndMessage
                    if nextBreakEndDate == nextProgressDate {
                        message = progressMessage + "\n" + message
                        self.nextProgressNoteIndex! += 1
                    }
                    
                    self.scheduleBreakEndNotificationForReport(report, date: nextBreakEndDate!, message: message)
                    print("Scheduled break end note \(self.nextBreakEndNoteIndex!) for \(nextBreakEndDate!)")
                    self.nextBreakEndNoteIndex! += 1
                }
                else if earliest == nextProgressDate {
                    
                    self.scheduleProgressNotificationForReport(report, date: nextProgressDate!, message: progressMessage, index: self.nextProgressNoteIndex!)
                    print("Scheduled progress note \(self.nextProgressNoteIndex!) for \(nextProgressDate!)")
                    self.nextProgressNoteIndex! += 1
                }
                
                count += 1
            }
        }
    }
    
    func scheduleBreakNotificationForReport(_ report: Report, date: Date, message: String) {
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
    
    func scheduleBreakEndNotificationForReport(_ report: Report, date: Date, message: String) {
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
    
    func scheduleProgressNotificationForReport(_ report: Report, date: Date, message: String, index: Int) {
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
    
    func scheduleNotification(_ date: Date, title: String, body: String? = nil, action: String? = nil, category: String? = nil, info: [AnyHashable: Any]? = nil, badgeNumber: Int? = nil) {
        
        if !self.shouldShowAlerts {
            return
        }
        
        let note = UILocalNotification()
        note.timeZone = TimeZone.current
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
