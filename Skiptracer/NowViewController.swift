//
//  NowViewController.swift
//  Skiptracer
//
//  Created by Colin Caufield on 3/21/15.
//  Copyright (c) 2015 Secret Geometry, Inc. All rights reserved.
//

import UIKit
import CoreData

let MINIMAL_DURATION = 0.0 // 5.0 // seconds

class NowViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    @IBOutlet var picker: UIPickerView!
    @IBOutlet var clockLabel: UILabel!
    @IBOutlet var stopButton: UIButton!
    @IBOutlet var breakButton: UIButton!
    
    var timer: NSTimer?
    var user: User?
    var activities = [Activity]()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureButton(self.stopButton)
        self.configureButton(self.breakButton)
        self.refreshData()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.refreshData()
        self.timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "updateClock", userInfo: nil, repeats: true)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        self.timer?.invalidate()
        self.timer = nil
    }
    
    func configureButton(button: UIButton) {
        
        let state: UIControlState = button.enabled ? .Normal : .Disabled
        let color = button.titleColorForState(state)!
        
        let layer = button.layer
        layer.cornerRadius = button.bounds.width / 2.0
        layer.borderWidth = 1.0
        layer.borderColor = color.CGColor
    }
    
    func setButtonState(button: UIButton, on: Bool) {
        button.enabled = on
        self.configureButton(button)
    }
    
    func updateButtonStates() {
        
        let stopEnabled = (self.user?.currentReport != nil)
        let inBreak = (self.user?.currentBreak != nil)
        let breakEnabled = stopEnabled
        let breakText = inBreak ? "Resume" : "Break"
        
        self.setButtonState(self.stopButton, on: stopEnabled)
        self.setButtonState(self.breakButton, on: breakEnabled)
        
        self.breakButton.setTitle(breakText, forState: .Normal)
    }
    
    func updateClock() {
        
        var text = ""
        
        if let report = self.user?.currentReport {
            
            let date = report.startDate
            
            let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)
            
            let units = (NSCalendarUnit.CalendarUnitDay | NSCalendarUnit.CalendarUnitHour | NSCalendarUnit.CalendarUnitMinute | NSCalendarUnit.CalendarUnitSecond)
            
            let components = calendar?.components(units, fromDate: report.startDate, toDate: NSDate(), options: NSCalendarOptions(0))
            
            func addSeparators() {
                if text != "" {
                    text += ":"
                }
            }
            
            if let d = components?.day {
                if d > 0 {
                    text += "\(d)"
                }
            }
            
            if let h = components?.hour {
                if h > 0 {
                    let hasDay = text != ""
                    addSeparators()
                    if hasDay && h < 10 {
                        text += "0"
                    }
                    text += "\(h)"
                }
            }
            
            if let m = components?.minute {
                addSeparators()
                text += String(format:"%02d", m)
            }
            
            if let s = components?.second {
                addSeparators()
                text += String(format:"%02d", s)
            }
        }
        
        if text == "" {
            text = "--:--"
        }
        
        self.clockLabel.text = text
        
        // This doesn't work because of a bug in NSDateComponentsFormatter
        //self.clockLabel.text = self.user?.currentReport?.durationText ?? "--:--"
    }
    
    func refreshData() {
        
        let data = AppData.shared
        self.user = data.settings.currentUser
        self.activities = data.fetchOrderedActivities()
        
        var row = 0
        
        if let activity = self.user?.currentReport?.activity {
            if let index = find(self.activities, activity) {
                row = index
            }
        }
        
        self.picker.reloadAllComponents()
        self.picker.selectRow(row, inComponent: 0, animated: false)
        
        self.updateClock()
        self.updateButtonStates()
    }
    
    func switchActivity(newActivity: Activity) {
        
        let data = AppData.shared
        
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
            newReport = data.createReport(newActivity, user: self.user, active: true)
        }
        
        self.user?.currentReport = newReport
        
        self.updateClock()
        self.updateButtonStates()
        
        data.save()
    }
    
    @IBAction func finishActivity(sender: AnyObject) {
        if let relaxing = self.activities.first {
            self.picker.selectRow(0, inComponent: 0, animated: true)
            self.switchActivity(relaxing)
        }
    }
    
    @IBAction func toggleBreak(sender: AnyObject) {
        
        let user = self.user!
        let report = user.currentReport
        let oldBreak = user.currentBreak
        
        if oldBreak == nil {
            let newBreak = AppData.shared.createBreak(report, user: user, active: true)
            user.currentBreak = newBreak
        } else {
            self.endBreak()
        }
        
        self.updateButtonStates()
        AppData.shared.save()
    }
    
    func endBreak() {
        
        if let report = self.user?.currentBreak {
            self.endReport(report)
        }
        
        self.user?.currentBreak = nil
        
        self.updateButtonStates()
        AppData.shared.save()
    }
    
    func endReport(report: Report) {
        
        let data = AppData.shared
        
        report.endDate = NSDate()
        report.active = false
        
        let atomic = report.activity?.atomic ?? false
        
        if !atomic && report.length < MINIMAL_DURATION {
            data.managedObjectContext?.deleteObject(report)
        }
        
        self.updateButtonStates()
        AppData.shared.save()
    }

    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {
        if component != 0 {
            return ""
        } else {
            return self.activities[row].name
        }
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        if row >= self.activities.count { return }
        let newActivity = self.activities[row]
        self.switchActivity(newActivity)
    }
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.activities.count
    }
}

