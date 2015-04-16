//
//  ActivityViewController.swift
//  Skiptracer
//
//  Created by Colin Caufield on 3/31/15.
//  Copyright (c) 2015 Secret Geometry, Inc. All rights reserved.
//

import UIKit
import CoreData

class ActivityViewController: UITableViewController, UITextFieldDelegate {
    
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var atomicSwitch: UISwitch!
    @IBOutlet weak var breakSwitch: UISwitch!
    @IBOutlet weak var breakLengthField: UITextField!
    @IBOutlet weak var breakIntervalField: UITextField!
    @IBOutlet weak var progressSwitch: UISwitch!
    @IBOutlet weak var progressIntervalField: UITextField!
    
    var activity: Activity? {
        didSet {
            if self.tableView != nil {
                self.configureView()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureView()
    }
    
    func configureView() {
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "done:")
        
        if let activity = self.activity {
            
            self.title = activity.name
            
            self.nameField.text = activity.name
            self.atomicSwitch.on = activity.atomic
            self.breakSwitch.on = activity.breaks
            self.breakLengthField.text = String(Int(activity.breakLength))
            self.breakIntervalField.text = String(Int(activity.breakInterval))
            self.progressSwitch.on = activity.progress
            self.progressIntervalField.text = String(Int(activity.progressInterval))
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
    
    @IBAction func done(sender: AnyObject) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func setName(sender: UITextField) {
        self.activity!.name = sender.text
        AppData.shared.save()
    }
    
    @IBAction func setAtomic(sender: UISwitch) {
        self.activity!.atomic = sender.on
        AppData.shared.save()
    }
    
    @IBAction func setBreakAlerts(sender: UISwitch) {
        self.activity!.breaks = sender.on
        AppData.shared.save()
    }
    
    @IBAction func setBreakLength(sender: UITextField) {
        if let length = sender.text.toInt() {
            self.activity!.breakLength = Double(length)
        }
        AppData.shared.save()
    }
    
    @IBAction func setBreakInterval(sender: UITextField) {
        if let interval = sender.text.toInt() {
            self.activity!.breakInterval = Double(interval)
        }
        AppData.shared.save()
    }
    
    @IBAction func setProgressAlerts(sender: UISwitch) {
        self.activity!.progress = sender.on
        AppData.shared.save()
    }
    
    @IBAction func setProgressInterval(sender: UITextField) {
        if let interval = sender.text.toInt() {
            self.activity!.progressInterval = Double(interval)
        }
        AppData.shared.save()
    }
}
