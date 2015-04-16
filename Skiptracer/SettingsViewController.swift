//
//  SettingsViewController.swift
//  Skiptracer
//
//  Created by Colin Caufield on 3/31/15.
//  Copyright (c) 2015 Secret Geometry, Inc. All rights reserved.
//

import UIKit

class SettingsViewController: UITableViewController {

    @IBOutlet weak var testUserRow: UITableViewCell!
    @IBOutlet weak var alertsSwitch: UISwitch!
    @IBOutlet weak var testUserSwitch: UISwitch!
    
    let testUserPath = NSIndexPath(forRow: 0, inSection: 1)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureView()
    }
    
    func configureView() {
        self.alertsSwitch.on = AppData.shared.settings.enableAlerts
        self.testUserSwitch.on = AppData.shared.settings.enableTestUser
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        #if !DEBUG
            if indexPath == self.testUserPath {
                return 0.0
            }
        #endif
        
        return super.tableView(tableView, heightForRowAtIndexPath: indexPath)
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        
        #if !DEBUG
            if indexPath == self.testUserPath {
                cell.hidden = true
                cell.userInteractionEnabled = false
            }
        #endif
    }
    
    @IBAction func setEnableAlerts(sender: UISwitch) {
        AppData.shared.settings.enableAlerts = sender.on
        AppData.shared.save()
    }
    
    @IBAction func setEnableTestUser(sender: UISwitch) {
        
        let data = AppData.shared
        let settings = data.settings
        settings.enableTestUser = sender.on
        settings.currentUser = sender.on ? data.testUser : data.basicUser
        data.save()
        
        let center = NSNotificationCenter.defaultCenter()
        center.postNotificationName(UserWasSwitchedNotification, object: nil)
    }
}
