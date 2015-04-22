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
        
        self.cellData = [[
                SGCellData(cellIdentifier: TEXT_FIELD_CELL_ID, title: "Name",              modelPath: "name")
            ], /*[
                SGCellData(cellIdentifier: SWITCH_CELL_ID,     title: "Atomic",            modelPath: "atomic")
            ],*/ [
                SGCellData(cellIdentifier: SWITCH_CELL_ID,     title: "Break Alerts",      modelPath: "breaks"),
                SGCellData(cellIdentifier: TIME_LABEL_CELL_ID, title: "Break Length",      modelPath: "breakLength"),
                SGCellData(cellIdentifier: TIME_LABEL_CELL_ID, title: "Break Interval",    modelPath: "breakInterval")
            ], [
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
    
    @IBAction func dateDidChange(picker: UIDatePicker) {
        
        // Update the model.
        
        if let data = self.dataForControl(picker) {
            let length = picker.countDownDuration
            self.activity?.setValue(length, forKey: data.modelPath)
            AppData.shared.save()
        }
        
        // Update the cell above.
        
        if let path = self.revealedCellIndexPath?.previous() {
            if let cell = self.tableView.cellForRowAtIndexPath(path) {
                self.configureCell(cell, atIndexPath: path)
            }
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
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        if self.cellIdentifierForIndexPath(indexPath) == TIME_CELL_ID {
            return 216.0 // CJC todo: don't hardcode.
        }
        
        return self.tableView.rowHeight
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: NSInteger) -> NSInteger {
        
        var numRows = self.cellData[section].count
        
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
        
        let modelPath = self.modelPathForIndexPath(indexPath)
        if modelPath.section < self.cellData.count {
            let section = self.cellData[modelPath.section]
            if modelPath.row < section.count {
                return section[modelPath.row]
            }
        }
        
        return nil
    }
    
    func modelPathForIndexPath(indexPath: NSIndexPath) -> NSIndexPath {
        
        if let path = self.revealedCellIndexPath {
            if (path.section == indexPath.section && path.row <= indexPath.row) {
                return indexPath.previous()
            }
        }
        
        return indexPath
    }
    
    func cellIdentifierForIndexPath(indexPath: NSIndexPath) -> String {
        
        if indexPath == self.revealedCellIndexPath {
            return TIME_CELL_ID // CJC: revisit
        }
        
        let data = self.dataForIndexPath(indexPath)
        return data?.cellIdentifier ?? ANOTHER_CELL_ID
    }
    
    func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        
        let item = self.dataForIndexPath(indexPath)!
        
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
            
            let length = self.activity?.valueForKey(item.modelPath) as? NSTimeInterval ?? 0.0
            let timeString = Formatter.stringFromLength(length)
            
            cell.detailTextLabel?.text = timeString
            
            let enabled = self.enabledStateForRowAtIndexPath(indexPath)
            self.setEnabled(enabled, forCell: cell)
            
        } else if cellID == TIME_CELL_ID {
            
            let length = self.activity?.valueForKey(item.modelPath) as? NSTimeInterval ?? 0.0
            
            let picker = cell.viewWithTag(2) as! UIDatePicker
            picker.countDownDuration = length
            
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
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    
        if let cell = self.tableView.cellForRowAtIndexPath(indexPath) {
            
            let hasRevealableCellBelow = (cell.reuseIdentifier == TIME_LABEL_CELL_ID) // CJC: revisit
            let canModify = true // CJC: revisit
            
            if hasRevealableCellBelow && canModify {
                self.displayRevealedCellForRowAtIndexPath(indexPath)
            } else {
                self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
            }
        }
    }
    
    func hasRevealedCellForIndexPath(indexPath: NSIndexPath) -> Bool {
    
        let targetPath = indexPath.next()
        
        if let cell = self.tableView.cellForRowAtIndexPath(targetPath) {
            return cell.reuseIdentifier == TIME_CELL_ID
        }
        
        return false
    }
    
    func updateRevealedControl() {
        if let path = self.revealedCellIndexPath {
            if let cell = self.tableView.cellForRowAtIndexPath(path) {
                self.configureCell(cell, atIndexPath: path)
            }
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
        var sameCellClicked = false
        
        if let path = self.revealedCellIndexPath {
            before = path.row < indexPath.row
            sameCellClicked = (path.previous() == indexPath)
            self.tableView.deleteRowsAtIndexPaths([path], withRowAnimation: .Fade)
            self.revealedCellIndexPath = nil
        }
        
        if !sameCellClicked {
            let path = (before) ? indexPath.previous() : indexPath
            self.toggleRevealedCellForSelectedIndexPath(path)
            self.revealedCellIndexPath = path.next()
        }
        
        self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
        self.tableView.endUpdates()
        
        self.updateRevealedControl()
    }
    
    func targetedCell() -> NSIndexPath? {
        if let path = self.revealedCellIndexPath {
            return path.previous()
        } else {
           return self.tableView.indexPathForSelectedRow()
        }
    }
    
    func hasRevealedCell() -> Bool {
        return self.revealedCellIndexPath != nil
    }
}
