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
        self.refreshData(animated: false)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.refreshData(animated: false)
        self.timer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: "updateClock", userInfo: nil, repeats: true)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        self.timer?.invalidate()
        self.timer = nil
    }
    
    func configureButton(button: UIButton) {
        
        let enabledColor = button.titleColorForState(.Normal)!
        var disabledColor = button.titleColorForState(.Disabled)!
        disabledColor = disabledColor.colorWithAlphaComponent(0.5)
        
        let color = button.enabled ? enabledColor : disabledColor
        let backgroundColor = button.enabled ? UIColor.whiteColor() : UIColor.clearColor()
        
        let layer = button.layer
        layer.cornerRadius = button.bounds.width / 2.0
        layer.borderWidth = 1.0
        layer.borderColor = color.CGColor
        layer.backgroundColor = backgroundColor.CGColor
    }
    
    func setButtonState(button: UIButton, on: Bool) {
        button.enabled = on
        self.configureButton(button)
    }
    
    func updateClockControlStates(animated: Bool = true) {
        
        let stopEnabled = (self.user?.currentReport != nil)
        let inBreak = (self.user?.currentBreak != nil)
        let breakEnabled = stopEnabled
        
        self.setButtonState(self.stopButton, on: stopEnabled)
        self.setButtonState(self.breakButton, on: breakEnabled)
        
        let breakImageTitle = inBreak ? "Play" : "Pause"
        let breakImage = UIImage(named: breakImageTitle)
        self.breakButton.setImage(breakImage, forState: .Normal)
        
        //let breakText = inBreak ? "Resume" : "Break"
        //self.breakButton.setTitle(breakText, forState: .Normal)
        
        //self.clockLabel.enabled = !inBreak
        
        let alpha: CGFloat = (!stopEnabled || inBreak) ? 0.3 : 1.0
        self.setClockAlpha(alpha, animated: animated)
    }
    
    func updateClock() {
        self.clockLabel.text = self.user?.currentReport?.lengthWithoutBreaksText ?? "--:--"
    }
    
    func setClockAlpha(alpha: CGFloat, animated: Bool) {
        
        func setClockLabelAlpha() {
            self.clockLabel.alpha = alpha
        }
        
        if !animated {
            //self.clockLabel.alpha = alpha
            setClockLabelAlpha()
            return
        }
        
        UIView.transitionWithView(
            self.clockLabel,
            duration: 0.5,
            options: .CurveEaseInOut,
            animations: setClockLabelAlpha,
            completion: nil
        )
    }
    
    func refreshData(#animated: Bool) {
        
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
        self.updateClockControlStates(animated: animated)
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
        self.updateClockControlStates()
        
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
        
        self.updateClock()
        self.updateClockControlStates()
        
        AppData.shared.save()
    }
    
    func endBreak() {
        
        if let report = self.user?.currentBreak {
            self.endReport(report)
        }
        
        self.user?.currentBreak = nil
        
        self.updateClock()
        self.updateClockControlStates()
        
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
        
        self.updateClock()
        self.updateClockControlStates()
        
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

