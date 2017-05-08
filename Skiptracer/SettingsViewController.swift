//
//  SettingsViewController.swift
//  Skiptracer
//
//  Created by Colin Caufield on 3/31/15.
//  Copyright (c) 2015 Secret Geometry, Inc. All rights reserved.
//

import UIKit
import SecretKit

class SettingsViewController: SGDynamicTableViewController {
    
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        AppData.shared.registerCloudDataObserver(self)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        AppData.shared.unregisterCloudDataObserver(self)
    }
    
    override func makeTableData() -> SGTableData {
        return (
            SGTableData(
                SGSectionData(
                    SGRowData(
                        cellIdentifier: SWITCH_CELL_ID,
                        title: "Alerts",
                        modelPath: self.enableAlertsKey
                    ),
                    SGRowData(
                        cellIdentifier: SWITCH_CELL_ID,
                        title: "iCloud",
                        modelPath: self.enableICloudKey
                    ),
                    SGRowData(
                        cellIdentifier: SWITCH_CELL_ID,
                        title: "Test User",
                        modelPath: self.enableTestUserKey
                    ),
                    SGRowData(
                        cellIdentifier: SWITCH_CELL_ID,
                        title: "Include breaks in totals",
                        modelPath: nil
                    ),
                    SGRowData(
                        cellIdentifier: SWITCH_CELL_ID,
                        title: "Automatically start/stop breaks",
                        modelPath: nil
                    )
                )
            )
        )
    }
    
    override func refreshData() {
        self.object = AppData.shared.settings
        super.refreshData()
    }
    
    override func dataModelDidChange(_ data: SGRowData) {
        
        let notes = Notifications.shared
        let settings = AppData.shared.settings
        
        if let path = data.modelPath {
            
            switch path {
                
            case self.enableAlertsKey:
                let wantsNotes = AppData.shared.settings.enableAlerts
                notes.enableNotifications(wantsNotes)
                
            case self.enableTestUserKey:
                settings?.currentUser = (settings?.enableTestUser)! ? settings?.testUser : settings?.basicUser
                AppData.shared.save()
                NotificationCenter.default.post(name: Notification.Name(rawValue: UserWasSwitchedNotification), object: nil)
                
            default:
                break
            }
        }
    }
    
    func cloudDataDidChange(_ note: Notification) {
        self.refreshData()
    }
}
