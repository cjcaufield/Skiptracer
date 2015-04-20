//
//  ReportViewController.swift
//  Skiptracer
//
//  Created by Colin Caufield on 4/2/15.
//  Copyright (c) 2015 Secret Geometry, Inc. All rights reserved.
//

import UIKit

struct CellData {
    var title: String
    var modelPath: String
}

let ACTIVITY_SECTION        = 0
let START_DATE_SECTION      = 1
let FINISH_DATE_SECTION     = 2
let BREAKS_SECTION          = 3
let NOTES_SECTION           = 4
let ACTIVITY_PICKER_TAG     = 1000
let DATE_PICKER_TAG         = 1001
let ACTIVITY_LABEL_CELL_ID  = "ActivityLabel"
let ACTIVITY_PICKER_CELL_ID = "ActivityPicker"
let DATE_LABEL_CELL_ID      = "DateLabel"
let DATE_PICKER_CELL_ID     = "DatePicker"
let BREAKS_LABEL_CELL_ID    = "BreaksLabel"
let NOTES_CELL_ID           = "Notes"
let OTHER_CELL_ID           = "Other"

class ReportViewController: UITableViewController, UITextViewDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    var timer: NSTimer?
    var user: User?
    var activities = [Activity]()
    var cellData = [[CellData]]()
    var dateFormatter: NSDateFormatter?
    var revealedCellIndexPath: NSIndexPath?
    var showDoneButton = false
    
    var report: Report? {
        didSet {
            if self.tableView != nil {
                self.refreshData()
            }
        }
    }
    
    var hideActivityRow: Bool { return self.report?.isBreak ?? false }
    var hideBreaksRow: Bool { return self.report?.isBreak ?? false }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        if self.showDoneButton {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "done:")
        }
        
        self.dateFormatter = NSDateFormatter()
        self.dateFormatter?.dateStyle = .MediumStyle
        self.dateFormatter?.timeStyle = .MediumStyle
        
        self.cellData =
        [
            [
                CellData(title: "Activity", modelPath: "activity")
            ],
            [
                CellData(title: "Start Date", modelPath: "startDate")
            ],
            [
                CellData(title: "End Date", modelPath: "endDate")
            ],
            [
                CellData(title: "Breaks", modelPath: "breaks")
            ],
            [
                CellData(title: "", modelPath: "notes")
            ]
        ]
        
        self.refreshData()
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
    
    func refreshData() {
        
        self.title = self.report?.activity?.name ?? "Untitled"
        
        let active = self.report?.active ?? false
        
        let data = AppData.shared
        self.user = data.settings.currentUser
        self.activities = data.fetchOrderedActivities()
        
        self.tableView.reloadData()
        
        self.updateClock()
    }
    
    func hasRevealedCellForIndexPath(indexPath: NSIndexPath) -> Bool {
        
        let targetPath = indexPath.next()
        let cell = self.tableView.cellForRowAtIndexPath(targetPath)
        
        let datePicker = cell?.viewWithTag(DATE_PICKER_TAG)
        let picker = cell?.viewWithTag(ACTIVITY_PICKER_TAG)
        
        return datePicker != nil || picker != nil
    }
    
    func updateRevealedControl() {
        
        if let path = self.revealedCellIndexPath {
            if let cell = self.tableView.cellForRowAtIndexPath(path) {
                
                let item = self.cellData[path.section][path.row - 1]
                
                if let picker = cell.viewWithTag(DATE_PICKER_TAG) as? UIDatePicker {
                    if let date = self.report?.valueForKey(item.modelPath) as? NSDate {
                        picker.setDate(date, animated: false)
                    }
                }
                
                if let picker = cell.viewWithTag(ACTIVITY_PICKER_TAG) as? UIPickerView {
                    if let activity = self.report?.activity {
                        if let index = find(self.activities, activity) {
                            picker.reloadAllComponents()
                            picker.selectRow(index, inComponent: 0, animated: false)
                        }
                    }
                }
            }
        }
    }
    
    func hasRevealedCell() -> Bool {
        return self.revealedCellIndexPath != nil
    }
    
    func indexPathHasActivityLabel(indexPath: NSIndexPath) -> Bool {
        return indexPath.section == ACTIVITY_SECTION && indexPath.row == 0
    }
    
    func indexPathHasActivityPicker(indexPath: NSIndexPath) -> Bool {
        
        if self.hasRevealedCell() {
            if let datePath = self.revealedCellIndexPath {
                if datePath == indexPath && indexPath.section == ACTIVITY_SECTION {
                    return true
                }
            }
        }
        
        return false
    }
    
    func indexPathHasDateLabel(indexPath: NSIndexPath) -> Bool {
        
        let isStartDateCell = indexPath.section == START_DATE_SECTION && indexPath.row == 0
        let isFinishDateCell = indexPath.section == FINISH_DATE_SECTION && indexPath.row == 0
        
        return isStartDateCell || isFinishDateCell
    }
    
    func indexPathHasDatePicker(indexPath: NSIndexPath) -> Bool {
        
        if self.hasRevealedCell() {
            if let datePath = self.revealedCellIndexPath {
                if datePath == indexPath &&
                   (indexPath.section == START_DATE_SECTION || indexPath.section == FINISH_DATE_SECTION) {
                    return true
                }
            }
        }
        
        return false
    }
    
    func indexPathHasBreaksLabel(indexPath: NSIndexPath) -> Bool {
        return indexPath.section == BREAKS_SECTION && indexPath.row == 0
    }
    
    func indexPathHasNotes(indexPath: NSIndexPath) -> Bool {
        return indexPath.section == NOTES_SECTION && indexPath.row == 0
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.cellData.count
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
        
        if self.indexPathHasDatePicker(indexPath) {
            return 216.0 //self.pickerCellRowHeight
        }
        
        if self.indexPathHasNotes(indexPath) {
            return 178.0 //self.notesCellRowHeight
        }
        
        if self.indexPathHasActivityPicker(indexPath) {
            return 162.0
        }
        
        return self.tableView.rowHeight
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: NSInteger) -> NSInteger {
        
        var numRows = self.cellData[section].count;
        
        if section == self.revealedCellIndexPath?.section {
            numRows++
        }
        
        return numRows
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cellID = OTHER_CELL_ID
        
        if self.indexPathHasActivityLabel(indexPath) {
            cellID = ACTIVITY_LABEL_CELL_ID
        }
        else if self.indexPathHasActivityPicker(indexPath) {
            cellID = ACTIVITY_PICKER_CELL_ID
        }
        else if self.indexPathHasDateLabel(indexPath) {
            cellID = DATE_LABEL_CELL_ID
        }
        else if self.indexPathHasDatePicker(indexPath) {
            cellID = DATE_PICKER_CELL_ID
        }
        else if self.indexPathHasBreaksLabel(indexPath) {
            cellID = BREAKS_LABEL_CELL_ID
        }
        else if self.indexPathHasNotes(indexPath) {
            cellID = NOTES_CELL_ID
        }
        
        var cell = self.tableView.dequeueReusableCellWithIdentifier(cellID) as? UITableViewCell
        
        self.configureCell(cell!, atIndexPath: indexPath)
        
        return cell!
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        
        let isActivity = indexPath.section == ACTIVITY_SECTION && self.hideActivityRow
        let isBreaks = indexPath.section == BREAKS_SECTION && self.hideBreaksRow
        
        if isActivity || isBreaks {
            cell.hidden = true
            cell.userInteractionEnabled = false
        }
    }
    
    func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        
        var modelPath = indexPath
        if let path = self.revealedCellIndexPath {
            if (path.section == indexPath.section && path.row <= indexPath.row) {
                modelPath = indexPath.previous()
            }
        }
        
        let item = self.cellData[modelPath.section][modelPath.row]
        
        let cellID = cell.reuseIdentifier
        
        if cellID == ACTIVITY_LABEL_CELL_ID {
            
            cell.textLabel?.text = item.title
            cell.detailTextLabel?.text = self.report?.activity?.name ?? "Untitled"
            
            let editable = (self.report?.active == false)
            cell.userInteractionEnabled = editable
            cell.textLabel?.enabled = editable
            cell.detailTextLabel?.enabled = editable
            
        } else if cellID == DATE_LABEL_CELL_ID {
            
            cell.textLabel?.text = item.title
            
            let live = (self.report?.active == true && item.modelPath == "endDate")
            let storedDate = self.report?.valueForKey(item.modelPath) as? NSDate
            let dateToUse = (live) ? NSDate() : storedDate
            
            if let date = dateToUse {
                cell.detailTextLabel?.text = self.dateFormatter?.stringFromDate(date)
            } else {
                cell.detailTextLabel?.text = ""
            }
            
            let editable = (self.report?.active == false)
            cell.userInteractionEnabled = editable
            cell.textLabel?.enabled = editable
            cell.detailTextLabel?.enabled = editable
        
        } else if cellID == BREAKS_LABEL_CELL_ID {
            
            let breakCount = self.report?.breaks.count ?? 0
            
            cell.textLabel?.text = item.title
            cell.detailTextLabel?.text = "\(breakCount)"
            
            let editable = (self.report?.active == false)
            cell.userInteractionEnabled = editable
            cell.textLabel?.enabled = editable
            cell.detailTextLabel?.enabled = editable
            
        } else if cellID == OTHER_CELL_ID {
            
            cell.textLabel?.text = item.title
            cell.selectionStyle = .None
        }
    }
    
    func toggleRevealedCellForSelectedIndexPath(indexPath: NSIndexPath) {
        
        self.tableView.beginUpdates()
        
        let indexPaths = [indexPath.next()]
        
        if self.hasRevealedCellForIndexPath(indexPath) {
            self.tableView.deleteRowsAtIndexPaths(indexPaths, withRowAnimation: .Fade)
        } else {
            self.tableView.insertRowsAtIndexPaths(indexPaths, withRowAnimation: .Fade)
        }
        
        self.tableView.endUpdates()
    }
    
    func displayRevealedCellForRowAtIndexPath(indexPath: NSIndexPath) {
        
        self.tableView.beginUpdates()
        
        var before = false
        if self.hasRevealedCell() {
            if let path = self.revealedCellIndexPath {
                before = path.row < indexPath.row
            }
        }
        
        var sameCellClicked = false
        if let path = self.revealedCellIndexPath {
            sameCellClicked = (path.previous() == indexPath)
        }
        
        if self.hasRevealedCell() {
            if let path = self.revealedCellIndexPath {
                self.tableView.deleteRowsAtIndexPaths([path], withRowAnimation: .Fade)
                self.revealedCellIndexPath = nil
            }
        }
        
        if (!sameCellClicked) {
            let indexPathToReveal = (before) ? indexPath.previous() : indexPath
            self.toggleRevealedCellForSelectedIndexPath(indexPathToReveal)
            self.revealedCellIndexPath = indexPathToReveal.next()
        }
        
        self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
        self.tableView.endUpdates()
        
        self.updateRevealedControl()
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let cell = self.tableView.cellForRowAtIndexPath(indexPath) {
            let isLabelCell = (cell.reuseIdentifier == ACTIVITY_LABEL_CELL_ID || cell.reuseIdentifier == DATE_LABEL_CELL_ID)
            if self.report?.active == false && isLabelCell {
                self.displayRevealedCellForRowAtIndexPath(indexPath)
            } else {
                self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
            }
        }
    }
    
    func targetedCell() -> NSIndexPath? {
        
        if self.hasRevealedCell() {
            if let path = self.revealedCellIndexPath {
                return path.previous()
            }
        } else {
            return self.tableView.indexPathForSelectedRow()
        }
        
        return nil
    }
    
    @IBAction func datePickerAction(sender: AnyObject) {
        
        if let path = self.targetedCell() {
            
            var item = self.cellData[path.section][path.row]
            
            if let picker = sender as? UIDatePicker {
                
                self.report?.setValue(picker.date, forKey: item.modelPath)
                AppData.shared.save()
                
                if let cell = self.tableView.cellForRowAtIndexPath(path) {
                    self.configureCell(cell, atIndexPath: path)
                }
            }
        }
    }
    
    @IBAction func done(sender: AnyObject) {
        self.navigationController?.popViewControllerAnimated(true)
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
