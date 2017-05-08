//
//  ReportViewController.swift
//  Skiptracer
//
//  Created by Colin Caufield on 4/2/15.
//  Copyright (c) 2015 Secret Geometry, Inc. All rights reserved.
//

import UIKit
import SecretKit

class ReportViewController: SGDynamicTableViewController, BreakObserver {
    
    var report: Report? { return self.object as? Report }
    var timer: Timer?
    var user: User?
    var activities = [Activity]()
    var endDateIndex = 2
    
    override var titleString: String {
        if self.report?.isBreak ?? false {
            return super.titleString
        } else {
            return self.report?.activity?.name ?? "Untitled"
        }
    }
    
    override func makeTableData() -> SGTableData {
        
        let tableData =
            SGTableData(
                SGSectionData(
                    SGRowData(cellIdentifier: PICKER_LABEL_CELL_ID, title: "Activity",   modelPath: "activity.name"),
                    SGRowData(cellIdentifier: DATE_LABEL_CELL_ID,   title: "Start Date", modelPath: "startDate"),
                    SGRowData(cellIdentifier: DATE_LABEL_CELL_ID,   title: "End Date",   modelPath: "liveEndDate"),
                    SGRowData(cellIdentifier: LABEL_CELL_ID,        title: "Breaks",     modelPath: "breaks.@count"),
                    SGRowData(cellIdentifier: TEXT_VIEW_CELL_ID,    title: "",           modelPath: "notes")
                )
            )
        
        if self.report?.isBreak ?? false {
            let section = tableData.sections[0]
            section.rows.remove(at: 3)
            section.rows.remove(at: 0)
            self.endDateIndex -= 1
        }
        
        return tableData
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Notifications.shared.registerBreakObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        AppData.shared.registerCloudDataObserver(self)
        self.refreshData()
        self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateClock), userInfo: nil, repeats: true)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        AppData.shared.unregisterCloudDataObserver(self)
        self.timer?.invalidate()
        self.timer = nil
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let newViewController = segue.destination as! ReportsViewController
        newViewController.parentReport = self.report
    }
    
    func textView(_ textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
    
    func updateClock() {
        if self.report?.active == true {
            let path = IndexPath(row: 0, section: self.endDateIndex)
            if let cell = self.tableView.cellForRow(at: path) {
                self.configureCell(cell, atIndexPath: path)
            }
        }
    }
    
    override func refreshData() {
        
        let data = AppData.shared
        self.user = data.settings.currentUser
        self.activities = data.fetchOrderedActivities(self.user!)
        
        super.refreshData()
        
        self.updateClock()
    }
    
    override func enabledStateForModelPath(_ modelPath: String?) -> Bool {
        
        if modelPath == nil {
            return true
        }
        
        let inactive = (self.report?.active == false)
        
        switch modelPath! {
            
            case "activity.name":
                return inactive
            
            case "liveEndDate":
                return inactive
            
            default:
                return true
        }
    }
    
    override func canExpandCell(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath) -> Bool {
        
        let data = self.dataForIndexPath(indexPath)
        
        let isActivityLabel = (data?.modelPath == "activity.name")
        let isStartDateLabel = (data?.modelPath == "startDate")
        let isEndDateLabel = (data?.modelPath == "liveEndDate")
        
        let isLabelCell = isActivityLabel || isStartDateLabel || isEndDateLabel
        return isLabelCell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let path = IndexPath(row: 0, section: section)
        let data = self.dataForIndexPath(path)
        let isNotes = (data?.modelPath == "notes")
        return isNotes ? "Notes" : nil
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        super.tableView(tableView, didSelectRowAt: indexPath)
        let info = self.dataForIndexPath(indexPath)
        if info?.cellIdentifier == LABEL_CELL_ID /* break cell */ {
            self.performSegue(withIdentifier: "ReportsSegue", sender: self)
        }
    }
    
    override func configurePickerView(_ picker: UIPickerView, forModelPath path: String?) {
        if let activity = self.report?.activity {
            if let index = self.activities.index(of: activity) {
                picker.reloadAllComponents()
                picker.selectRow(index, inComponent: 0, animated: false)
            }
        }
    }
    
    override func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if component != 0 {
            return ""
        } else {
            return self.activities[row].name
        }
    }
    
    override func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        if let path = self.targetedCell() {
            
            let activity = self.activities[row]
        
            self.report?.activity = activity
            AppData.shared.save()
            
            if let cell = self.tableView.cellForRow(at: path) {
                self.configureCell(cell, atIndexPath: path)
            }
            
            self.refreshTitle()
        }
    }
    
    override func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    override func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.activities.count
    }
    
    func autoBreakWasStarted(_ note: Notification) {
        self.refreshData()
    }
    
    func autoBreakWasEnded(_ note: Notification) {
        self.refreshData()
    }
    
    func cloudDataDidChange(_ note: Notification) {
        self.refreshData()
    }
}
