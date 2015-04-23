//
//  ReportViewController.swift
//  Skiptracer
//
//  Created by Colin Caufield on 4/2/15.
//  Copyright (c) 2015 Secret Geometry, Inc. All rights reserved.
//

import UIKit

class ReportViewController: SGExpandableTableViewController {
    
    var report: Report? { return self.object as? Report }
    var timer: NSTimer?
    var user: User?
    var activities = [Activity]()
    var endDateIndex = 2
    
    override func createCellData() -> [[SGCellData]] {
        
        var data = [
            [ SGCellData(cellIdentifier: PICKER_LABEL_CELL_ID, title: "Activity",   modelPath: "activity.name") ],
            [ SGCellData(cellIdentifier: DATE_LABEL_CELL_ID,   title: "Start Date", modelPath: "startDate") ],
            [ SGCellData(cellIdentifier: DATE_LABEL_CELL_ID,   title: "End Date",   modelPath: "liveEndDate") ],
            [ SGCellData(cellIdentifier: BREAKS_LABEL_CELL_ID, title: "Breaks",     modelPath: "breaks.@count") ],
            [ SGCellData(cellIdentifier: TEXT_VIEW_CELL_ID,    title: "",           modelPath: "notes") ]
        ]
        
        if self.report?.isBreak ?? false {
            data.removeAtIndex(3)
            data.removeAtIndex(0)
            self.endDateIndex--
        }
        
        return data
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
            return false
        }
        return true
    }
    
    func updateClock() {
        if self.report?.active == true {
            let path = NSIndexPath(forRow: 0, inSection: self.endDateIndex)
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
        
        let data = self.dataForIndexPath(indexPath)
        
        let isActivityLabel = (data?.modelPath == "activity.name")
        let isStartDateLabel = (data?.modelPath == "startDate")
        let isEndDateLabel = (data?.modelPath == "liveEndDate")
        
        let isLabelCell = isActivityLabel || isStartDateLabel || isEndDateLabel
        return isLabelCell
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let path = NSIndexPath(forRow: 0, inSection: section)
        let data = self.dataForIndexPath(path)
        let isNotes = (data?.modelPath == "notes")
        return isNotes ? "Notes" : nil
    }
    
    override func configurePicker(picker: UIPickerView, forModelPath: String) {
        if let activity = self.report?.activity {
            if let index = find(self.activities, activity) {
                picker.reloadAllComponents()
                picker.selectRow(index, inComponent: 0, animated: false)
            }
        }
    }
    
    override func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {
        if component != 0 {
            return ""
        } else {
            return self.activities[row].name
        }
    }
    
    override func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        if let path = self.targetedCell() {
            
            let activity = self.activities[row]
        
            self.report?.activity = activity
            AppData.shared.save()
            
            if let cell = self.tableView.cellForRowAtIndexPath(path) {
                self.configureCell(cell, atIndexPath: path)
            }
        }
    }
    
    override func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    override func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.activities.count
    }
}
