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
    
    var settings: Settings? {
        return self.object as? Settings
    }
    
    let enableICloudKey = "enableICloud"
    let enableAlertsKey = "enableAlerts"
    let enableTestUserKey = "enableTestUser"
    
    override var titleString: String {
        return "Settings"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.refreshData()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        AppData.shared.registerCloudDataObserver(self)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        AppData.shared.unregisterCloudDataObserver(self)
    }
    
    override func createCellData() -> [[SGCellData]] {
        
        let data = [
            [ SGCellData(cellIdentifier: SWITCH_CELL_ID, title: "Alerts", modelPath: self.enableAlertsKey) ],
            //[ SGCellData(cellIdentifier: SWITCH_CELL_ID, title: "iCloud", modelPath: self.enableICloudKey) ],
            //[ SGCellData(cellIdentifier: SWITCH_CELL_ID, title: "Test User", modelPath: self.enableTestUserKey) ],
            //[ SGCellData(cellIdentifier: SWITCH_CELL_ID, title: "Include breaks in totals", modelPath: nil) ],
            //[ SGCellData(cellIdentifier: SWITCH_CELL_ID, title: "Automatically start/stop breaks", modelPath: nil) ]
        ]
        
        //#if !DEBUG
        //    data.removeLast()
        //#endif
        
        return data
    }
    
    override func refreshData() {
        self.object = AppData.shared.settings
        super.refreshData()
    }
    
    override func switchDidChange(toggle: UISwitch) {
        
        super.switchDidChange(toggle)
        
        let data = AppData.shared
        let notes = Notifications.shared
        let info = self.dataForControl(toggle)
        
        if info?.modelPath == self.enableAlertsKey {
            
            let wantsNotes = data.settings.enableAlerts
            notes.enableNotifications(wantsNotes)
        }
        
        if info?.modelPath == self.enableTestUserKey {
            
            data.settings.currentUser = (toggle.on) ? data.testUser : data.basicUser
            data.save()
            
            let center = NSNotificationCenter.defaultCenter()
            center.postNotificationName(UserWasSwitchedNotification, object: nil)
        }
    }
    
    func cloudDataDidChange(note: NSNotification) {
        self.refreshData()
    }
}
