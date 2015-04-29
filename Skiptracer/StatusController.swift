//
//  StatusController.swift
//  Skiptracer
//
//  Created by Colin Caufield on 4/27/15.
//  Copyright (c) 2015 Secret Geometry, Inc. All rights reserved.
//

import UIKit

private let MINIMAL_DURATION = 0.0 // 5.0 // seconds

private var _shared: StatusController? = nil

class StatusController: NSObject {
    
    class var shared: StatusController {
        
        if _shared == nil {
            _shared = StatusController()
        }
        
        return _shared!
    }
    
    var notes: Notifications {
        return Notifications.shared
    }
    
    var data: AppData {
        return AppData.shared
    }
    
    var user: User? {
        return self.data.settings.currentUser
    }
    
    func switchActivity(newActivity: Activity) {
        
        if self.user?.currentBreak != nil {
            endBreak()
        }
        
        let oldReport = self.user?.currentReport
        let oldActivity = oldReport?.activity
        
        if (oldActivity == newActivity) {
            return
        }
        
        if let report = oldReport {
            self.endReport(report)
        }
        
        self.user?.currentReport = nil
        
        var newReport: Report?
        
        if !newActivity.silent {
            newReport = self.data.createReport(newActivity, user: self.user, active: true)
            self.notes.scheduleNextBreakNotificationForReport(newReport!)
        }
        
        self.user?.currentReport = newReport
        
        self.data.save()
    }
    
    func toggleBreak() {
        if self.user!.currentBreak == nil {
            self.beginBreak()
        } else {
            self.endBreak()
        }
    }
    
    func beginBreak() {
        
        let user = self.user!
        let report = user.currentReport
        let oldBreak = user.currentBreak
        
        if oldBreak == nil {
            user.currentBreak = self.data.createBreak(report, user: user, active: true)
        }
        
        self.data.save()
    }
    
    func endBreak() {
        
        if let report = self.user?.currentBreak {
            self.endReport(report)
        }
        
        self.user?.currentBreak = nil
        
        self.data.save()
    }
    
    func endReport(report: Report) {
        
        report.endDate = NSDate()
        report.active = false
        
        let atomic = report.activity?.atomic ?? false
        
        if !atomic && report.length < MINIMAL_DURATION {
            self.data.managedObjectContext?.deleteObject(report)
        }
        
        self.data.save()
    }
}
