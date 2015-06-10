//
//  NowViewController.swift
//  Skiptracer
//
//  Created by Colin Caufield on 3/21/15.
//  Copyright (c) 2015 Secret Geometry, Inc. All rights reserved.
//

import UIKit
import CoreData

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
        
        Notifications.shared.registerBreakObserver(self)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        AppData.shared.registerCloudDataObserver(self)
        self.refreshData(animated: false)
        self.timer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: "updateClock", userInfo: nil, repeats: true)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        AppData.shared.unregisterCloudDataObserver(self)
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
    
    func refreshData(animated animated: Bool) {
        
        let data = AppData.shared
        self.user = data.settings.currentUser
        self.activities = data.fetchOrderedActivities(self.user!)
        
        var row = 0
        
        if let activity = self.user?.currentReport?.activity {
            if let index = self.activities.indexOf(activity) {
                row = index
            }
        }
        
        self.picker.reloadAllComponents()
        self.picker.selectRow(row, inComponent: 0, animated: false)
        
        self.updateClock()
        self.updateClockControlStates(animated)
    }
    
    func switchActivity(newActivity: Activity) {
        StatusController.shared.switchActivity(newActivity)
        self.updateClock()
        self.updateClockControlStates()
    }
    
    @IBAction func finishActivity(sender: AnyObject) {
        if let relaxing = self.activities.first {
            self.picker.selectRow(0, inComponent: 0, animated: true)
            self.switchActivity(relaxing)
        }
    }
    
    @IBAction func toggleBreak(sender: AnyObject) {
        StatusController.shared.toggleBreak()
        self.updateClock()
        self.updateClockControlStates()
    }
    /*
    func endCurrentBreak() {
        StatusController.shared.endCurrentBreak()
        self.updateClock()
        self.updateClockControlStates()
    }
    
    func endReport(report: Report) {
        StatusController.shared.endReport(report)
        self.updateClock()
        self.updateClockControlStates()
    }
    */
    func autoBreakWasStarted(note: NSNotification) {
        self.updateClock()
        self.updateClockControlStates()
    }
    
    func autoBreakWasEnded(note: NSNotification) {
        self.updateClock()
        self.updateClockControlStates()
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
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
    
    func cloudDataDidChange(note: NSNotification) {
        self.refreshData(animated: true)
    }
}

