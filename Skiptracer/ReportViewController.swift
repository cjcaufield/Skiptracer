//
//  ReportViewController.swift
//  Skiptracer
//
//  Created by Colin Caufield on 4/2/15.
//  Copyright (c) 2015 Secret Geometry, Inc. All rights reserved.
//

import UIKit

let ACTIVITY_SECTION        = 0
let START_DATE_SECTION      = 1
let FINISH_DATE_SECTION     = 2
let BREAKS_SECTION          = 3
let NOTES_SECTION           = 4
let ACTIVITY_PICKER_TAG     = 1000
let DATE_PICKER_TAG         = 1001

class ReportViewController: SGExpandableTableViewController {
    
    var report: Report? { return self.object as? Report }
    
    var timer: NSTimer?
    var user: User?
    var activities = [Activity]()
    
    var hideActivityRow: Bool { return self.report?.isBreak ?? false }
    var hideBreaksRow: Bool { return self.report?.isBreak ?? false }
    
    override func createCellData() -> [[SGCellData]] {
        return [
            [
                SGCellData(cellIdentifier: ACTIVITY_LABEL_CELL_ID, title: "Activity",   modelPath: "activity.name")
            ],
            [
                SGCellData(cellIdentifier: DATE_LABEL_CELL_ID,     title: "Start Date", modelPath: "startDate")
            ],
            [
                SGCellData(cellIdentifier: DATE_LABEL_CELL_ID,     title: "End Date",   modelPath: "liveEndDate")
            ],
            [
                SGCellData(cellIdentifier: BREAKS_LABEL_CELL_ID,   title: "Breaks",     modelPath: "breaks.@count")
            ],
            [
                SGCellData(cellIdentifier: NOTES_CELL_ID,          title: "",           modelPath: "notes")
            ]
        ]
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
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let newViewController = segue.destinationViewController as! ReportsViewController
        newViewController.parent = self.report
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
        }
        return false
    }
    
    func updateClock() {
        if self.report?.active == true {
            let path = NSIndexPath(forRow: 0, inSection: FINISH_DATE_SECTION)
            if let cell = self.tableView.cellForRowAtIndexPath(path) {
                self.configureCell(cell, atIndexPath: path)
            }
        }
    }
    
    override func refreshData() {
        
        let data = AppData.shared
        self.user = data.settings.currentUser
        self.activities = data.fetchOrderedActivities()
        
        super.refreshData()
        
        self.updateClock()
    }
    
    override func enabledStateForModelPath(modelPath: String) -> Bool {
        
        let inactive = (self.report?.active == false)
        
        switch modelPath {
            
            case "activity.name":
                return inactive
            
            case "liveEndDate":
                return inactive
            
            default:
                return true
        }
    }
    
    override func canExpandCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) -> Bool {
        let isLabelCell = (cell.reuseIdentifier == ACTIVITY_LABEL_CELL_ID || cell.reuseIdentifier == DATE_LABEL_CELL_ID)
        let isStartDateLabelCell = (indexPath.section == START_DATE_SECTION && indexPath.row == 0)
        let canExpand = isStartDateLabelCell || (self.report?.active == false && isLabelCell)
        return canExpand
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return (section == NOTES_SECTION) ? "Notes" : ""
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        if indexPath.section == ACTIVITY_SECTION && self.hideActivityRow {
            return 0.0
        }
        
        if indexPath.section == BREAKS_SECTION && self.hideBreaksRow {
            return 0.0
        }
        
        return super.tableView(tableView, heightForRowAtIndexPath: indexPath)
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        
        let isActivity = indexPath.section == ACTIVITY_SECTION && self.hideActivityRow
        let isBreaks = indexPath.section == BREAKS_SECTION && self.hideBreaksRow
        
        if isActivity || isBreaks {
            cell.hidden = true
            cell.userInteractionEnabled = false
        }
    }
    
    override func configurePicker(picker: UIPickerView, forModelPath: String) {
        if let activity = self.report?.activity {
            if let index = find(self.activities, activity) {
                picker.reloadAllComponents()
                picker.selectRow(index, inComponent: 0, animated: false)
            }
        }
    }
    
    // - MARK: UIPickerViewDelegate/DataSource
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {
        if component != 0 {
            return ""
        } else {
            return self.activities[row].name
        }
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        if let path = self.targetedCell() {
            
            let activity = self.activities[row]
        
            self.report?.activity = activity
            AppData.shared.save()
            
            if let cell = self.tableView.cellForRowAtIndexPath(path) {
                cell.detailTextLabel?.text = activity.name
            }
        }
    }
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.activities.count
    }
}
