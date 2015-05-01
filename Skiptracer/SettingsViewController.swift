//
//  SettingsViewController.swift
//  Skiptracer
//
//  Created by Colin Caufield on 3/31/15.
//  Copyright (c) 2015 Secret Geometry, Inc. All rights reserved.
//

import UIKit

private var context = 0

class SettingsViewController: SGExpandableTableViewController {
    
    var settings: Settings? { return self.object as? Settings }
    let enableAlertsKey = "enableAlerts"
    let enableTestUserKey = "enableTestUser"
    
    override var titleString: String {
        return "Settings"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.object = AppData.shared.settings
        self.refreshData()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        AppData.shared.registerCloudObserver(self)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        AppData.shared.unregisterCloudObserver(self)
    }
    
    override func createCellData() -> [[SGCellData]] {
        
        var data = [
            [ SGCellData(cellIdentifier: SWITCH_CELL_ID, title: "Alerts", modelPath: self.enableAlertsKey) ],
            [ SGCellData(cellIdentifier: SWITCH_CELL_ID, title: "Test User", modelPath: self.enableTestUserKey) ],
            [ SGCellData(cellIdentifier: SWITCH_CELL_ID, title: "Include breaks in totals", modelPath: nil) ],
            [ SGCellData(cellIdentifier: SWITCH_CELL_ID, title: "Automatically start/stop breaks", modelPath: nil) ]
        ]
        
        //#if !DEBUG
        //    data.removeAtIndex(1)
        //#endif
        
        return data
    }
    
    override func switchDidChange(toggle: UISwitch) {
        
        super.switchDidChange(toggle)
        
        let info = self.dataForControl(toggle)
        
        if info?.modelPath == self.enableTestUserKey {
            
            let data = AppData.shared
            self.settings?.currentUser = toggle.on ? data.testUser : data.basicUser
            data.save()
            
            let center = NSNotificationCenter.defaultCenter()
            center.postNotificationName(UserWasSwitchedNotification, object: nil)
        }
    }
    
    func cloudDidChange(note: NSNotification) {
        println("SettingsVC.cloudDidChange")
    }
}
