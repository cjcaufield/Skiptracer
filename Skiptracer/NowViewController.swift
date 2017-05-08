//
//  NowViewController.swift
//  Skiptracer
//
//  Created by Colin Caufield on 3/21/15.
//  Copyright (c) 2015 Secret Geometry, Inc. All rights reserved.
//

import UIKit
import CoreData

@objc class NowViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, BreakObserver {
    
    @IBOutlet var picker: UIPickerView!
    @IBOutlet var clockLabel: UILabel!
    @IBOutlet var stopButton: UIButton!
    @IBOutlet var breakButton: UIButton!
    
    var timer: Timer?
    var user: User?
    var activities = [Activity]()

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.configureButton(self.stopButton)
        self.configureButton(self.breakButton)
        
        self.refreshData(false)
        
        Notifications.shared.registerBreakObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        AppData.shared.registerCloudDataObserver(self)
        self.refreshData(false)
        self.timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateClock), userInfo: nil, repeats: true)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        AppData.shared.unregisterCloudDataObserver(self)
        self.timer?.invalidate()
        self.timer = nil
    }
    
    func configureButton(_ button: UIButton) {
        
        let enabledColor = button.titleColor(for: UIControlState())!
        var disabledColor = button.titleColor(for: .disabled)!
        disabledColor = disabledColor.withAlphaComponent(0.5)
        
        let color = button.isEnabled ? enabledColor : disabledColor
        let backgroundColor = button.isEnabled ? UIColor.white : UIColor.clear
        
        let layer = button.layer
        layer.cornerRadius = button.bounds.width / 2.0
        layer.borderWidth = 1.0
        layer.borderColor = color.cgColor
        layer.backgroundColor = backgroundColor.cgColor
    }
    
    func setButtonState(_ button: UIButton, on: Bool) {
        button.isEnabled = on
        self.configureButton(button)
    }
    
    func updateClockControlStates(_ animated: Bool = true) {
        
        let stopEnabled = (self.user?.currentReport != nil)
        let inBreak = (self.user?.currentBreak != nil)
        let breakEnabled = stopEnabled
        
        self.setButtonState(self.stopButton, on: stopEnabled)
        self.setButtonState(self.breakButton, on: breakEnabled)
        
        let breakImageTitle = inBreak ? "Play" : "Pause"
        let breakImage = UIImage(named: breakImageTitle)
        self.breakButton.setImage(breakImage, for: UIControlState())
        
        let alpha: CGFloat = (!stopEnabled || inBreak) ? 0.3 : 1.0
        self.setClockAlpha(alpha, animated: animated)
    }
    
    func updateClock() {
        self.clockLabel.text = self.user?.currentReport?.lengthWithoutBreaksText ?? "--:--"
    }
    
    func setClockAlpha(_ alpha: CGFloat, animated: Bool) {
        
        func setClockLabelAlpha() {
            self.clockLabel.alpha = alpha
        }
        
        if !animated {
            setClockLabelAlpha()
            return
        }
        
        UIView.transition(
            with: self.clockLabel,
            duration: 0.5,
            options: UIViewAnimationOptions(),
            animations: setClockLabelAlpha,
            completion: nil
        )
    }
    
    func refreshData(_ animated: Bool) {
        
        let data = AppData.shared
        self.user = data.settings.currentUser
        self.activities = data.fetchOrderedActivities(self.user!)
        
        var row = 0
        
        if let activity = self.user?.currentReport?.activity {
            if let index = self.activities.index(of: activity) {
                row = index
            }
        }
        
        self.picker.reloadAllComponents()
        self.picker.selectRow(row, inComponent: 0, animated: false)
        
        self.updateClock()
        self.updateClockControlStates(animated)
    }
    
    func switchActivity(_ newActivity: Activity) {
        StatusController.shared.switchActivity(newActivity)
        self.updateClock()
        self.updateClockControlStates()
    }
    
    @IBAction func finishActivity(_ sender: AnyObject) {
        if let relaxing = self.activities.first {
            self.picker.selectRow(0, inComponent: 0, animated: true)
            self.switchActivity(relaxing)
        }
    }
    
    @IBAction func toggleBreak(_ sender: AnyObject) {
        StatusController.shared.toggleBreak()
        self.updateClock()
        self.updateClockControlStates()
    }
    
    func autoBreakWasStarted(_ note: Notification) {
        self.updateClock()
        self.updateClockControlStates()
    }
    
    func autoBreakWasEnded(_ note: Notification) {
        self.updateClock()
        self.updateClockControlStates()
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if component != 0 {
            return ""
        } else {
            return self.activities[row].name
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if row >= self.activities.count { return }
        let newActivity = self.activities[row]
        self.switchActivity(newActivity)
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.activities.count
    }
    
    func cloudDataDidChange(_ note: Notification) {
        self.refreshData(true)
    }
}

