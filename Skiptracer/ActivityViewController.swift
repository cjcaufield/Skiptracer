//
//  ActivityViewController.swift
//  Skiptracer
//
//  Created by Colin Caufield on 3/31/15.
//  Copyright (c) 2015 Secret Geometry, Inc. All rights reserved.
//

import UIKit
import CoreData

let TEXT_FIELD_CELL_ID = "TextFieldCell"
let SWITCH_CELL_ID = "SwitchCell"
let TIME_LABEL_CELL_ID = "DateLabelCell"
let TIME_CELL_ID = "DatePickerCell"
let ANOTHER_CELL_ID = "Other"

class SGCellData {
    
    var cellIdentifier: String
    var title = ""
    var modelPath = ""
    var expandable = false
    var hidden = false
    
    init(cellIdentifier: String, title: String, modelPath: String) {
        self.cellIdentifier = cellIdentifier
        self.title = title
        self.modelPath = modelPath
    }
}

class ActivityViewController: UITableViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    var cellData = [[SGCellData]]()
    var dateFormatter: NSDateFormatter?
    var revealedCellIndexPath: NSIndexPath?
    var showDoneButton = false
    
    var activity: Activity? {
        didSet {
            if self.tableView != nil {
                self.configureView()
            }
        }
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.cellData = [
            [
                SGCellData(cellIdentifier: TEXT_FIELD_CELL_ID, title: "Name",              modelPath: "name")
            ],
            [
                SGCellData(cellIdentifier: SWITCH_CELL_ID,     title: "Atomic",            modelPath: "atomic")
            ],
            [
                SGCellData(cellIdentifier: SWITCH_CELL_ID,     title: "Break Alerts",      modelPath: "breaks"),
                SGCellData(cellIdentifier: TIME_LABEL_CELL_ID, title: "Break Length",      modelPath: "breakLength"),
                SGCellData(cellIdentifier: TIME_LABEL_CELL_ID, title: "Break Interval",    modelPath: "breakInterval")
            ],
            [
                SGCellData(cellIdentifier: SWITCH_CELL_ID,     title: "Progress Alerts",   modelPath: "progress"),
                SGCellData(cellIdentifier: TIME_LABEL_CELL_ID, title: "Progress Interval", modelPath: "progressInterval")
            ]
        ]
        
        self.configureView()
    }
    
    func configureView() {
        
        if self.showDoneButton {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "done:")
        }
        
        self.title = self.activity?.name ?? "Untitled"
    }
    
    func cellForControl(control: UIControl) -> UITableViewCell? {
        return control.superview?.superview as? UITableViewCell
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        if let data = self.dataForControl(textField) {
            self.activity?.setValue(textField.text, forKey: data.modelPath)
            AppData.shared.save()
        }
    }
    
    @IBAction func switchDidChange(toggle: UISwitch) {
        if let data = self.dataForControl(toggle) {
            self.activity?.setValue(toggle.on, forKey: data.modelPath)
            AppData.shared.save()
        }
    }
    
    @IBAction func done(sender: AnyObject) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func refreshData() {
        self.title = self.activity?.name ?? "Untitled"
        self.tableView.reloadData()
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.cellData.count
    }
    
    /*
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        if self.indexPathHasDatePicker(indexPath) {
            return 216.0
        }
        
        return self.tableView.rowHeight
    }
    */
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: NSInteger) -> NSInteger {
        
        var numRows = self.cellData[section].count;
        
        if section == self.revealedCellIndexPath?.section {
            numRows++
        }
        
        return numRows
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cellID = self.cellIdentifierForIndexPath(indexPath)
        var cell = self.tableView.dequeueReusableCellWithIdentifier(cellID) as? UITableViewCell
        self.configureCell(cell!, atIndexPath: indexPath)
        return cell!
    }
    
    func dataForControl(control: UIControl) -> SGCellData? {
        
        if let cell = self.cellForControl(control) {
            if let path = self.tableView.indexPathForCell(cell) {
                return self.dataForIndexPath(path)
            }
        }
        
        return nil
    }
    
    func dataForIndexPath(indexPath: NSIndexPath) -> SGCellData? {
        
        if indexPath.section < self.cellData.count {
            let section = self.cellData[indexPath.section]
            if indexPath.row < section.count {
                let data = section[indexPath.row]
                return data
            }
        }
        
        return nil
    }
    
    func cellIdentifierForIndexPath(indexPath: NSIndexPath) -> String {
        return self.dataForIndexPath(indexPath)?.cellIdentifier ?? ANOTHER_CELL_ID
    }
    
    func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        
        var modelPath = indexPath
        if let path = self.revealedCellIndexPath {
            if (path.section == indexPath.section && path.row <= indexPath.row) {
                modelPath = indexPath.previous()
            }
        }
        
        let item = self.dataForIndexPath(modelPath)!
        
        let cellID = cell.reuseIdentifier
        
        if cellID == TEXT_FIELD_CELL_ID {
            
            let label = cell.viewWithTag(1) as! UILabel
            label.text = item.title
            
            let value = self.activity?.valueForKey(item.modelPath) as? String
            let textField = cell.viewWithTag(2) as! UITextField
            textField.text = value ?? "Untitled"
            
            let enabled = self.enabledStateForRowAtIndexPath(indexPath)
            self.setEnabled(enabled, forCell: cell)
            
        } else if cellID == SWITCH_CELL_ID {
            
            let label = cell.viewWithTag(1) as! UILabel
            label.text = item.title
            
            let value = self.activity?.valueForKey(item.modelPath) as? Bool
            let toggle = cell.viewWithTag(2) as! UISwitch
            toggle.on = value ?? false
            
            let enabled = self.enabledStateForRowAtIndexPath(indexPath)
            self.setEnabled(enabled, forCell: cell)
            
        } else if cellID == TIME_LABEL_CELL_ID {
            
            cell.textLabel?.text = item.title
            
            var timeString = ""
            if let length = self.activity?.valueForKey(item.modelPath) as? NSTimeInterval {
                timeString = Formatter.stringFromLength(length)
            }
            
            cell.detailTextLabel?.text = timeString
            
            let enabled = self.enabledStateForRowAtIndexPath(indexPath)
            self.setEnabled(enabled, forCell: cell)
            
        } else if cellID == ANOTHER_CELL_ID {
            
            cell.textLabel?.text = item.title
            cell.selectionStyle = .None
            
            let enabled = self.enabledStateForRowAtIndexPath(indexPath)
            self.setEnabled(enabled, forCell: cell)
        }
    }
    
    func enabledStateForRowAtIndexPath(indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func setEnabled(enabled: Bool, forCell cell: UITableViewCell) {
        cell.userInteractionEnabled = enabled
        cell.textLabel?.enabled = enabled
        cell.detailTextLabel?.enabled = enabled
    }
    
    /*
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    
        if let cell = self.tableView.cellForRowAtIndexPath(indexPath) {
    
            let isLabelCell = (cell.reuseIdentifier == ACTIVITY_LABEL_CELL_ID || cell.reuseIdentifier == DATE_LABEL_CELL_ID)
            let isStartDateLabelCell = (indexPath.section == START_DATE_SECTION && indexPath.row == 0)
            let canModify = isStartDateLabelCell || (self.report?.active == false && isLabelCell)
            
            if canModify {
                self.displayRevealedCellForRowAtIndexPath(indexPath)
            } else {
                self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
            }
        }
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
    
    func indexPathHasRevealedActivityPicker(indexPath: NSIndexPath) -> Bool {
        
        if self.hasRevealedCell() {
            if let pickerPath = self.revealedCellIndexPath {
                if pickerPath == indexPath && indexPath.section == ACTIVITY_SECTION {
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
    
    func indexPathHasRevealedDatePicker(indexPath: NSIndexPath) -> Bool {
        
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
    */
}
