//
//  SGExpandableTableViewController.swift
//  Skiptracer
//
//  Created by Colin Caufield on 4/17/15.
//  Copyright (c) 2015 Secret Geometry, Inc. All rights reserved.
//

import UIKit

let TEXT_FIELD_CELL_ID     = "TextFieldCell"
let SWITCH_CELL_ID         = "SwitchCell"
let TIME_LABEL_CELL_ID     = "TimeLabelCell"
let TIME_PICKER_CELL_ID    = "TimePickerCell"
let PICKER_LABEL_CELL_ID   = "PickerLabelCell"
let PICKER_CELL_ID         = "PickerCell"
let DATE_LABEL_CELL_ID     = "DateLabelCell"
let DATE_PICKER_CELL_ID    = "DatePickerCell"
let BREAKS_LABEL_CELL_ID   = "BreaksLabelCell"
let TEXT_VIEW_CELL_ID      = "TextViewCell"
let OTHER_CELL_ID          = "OtherCell"

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

class SGExpandableTableViewController: UITableViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UITextViewDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    var cellData = [[SGCellData]]()
    
    var revealedCellIndexPath: NSIndexPath?
    var showDoneButton = false
    
    var object: AnyObject? {
        didSet {
            if self.tableView != nil {
                self.configureView()
            }
        }
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.registerCellNib(DATE_PICKER_CELL_ID)
        self.registerCellNib(PICKER_CELL_ID)
        self.registerCellNib(SWITCH_CELL_ID)
        self.registerCellNib(TEXT_FIELD_CELL_ID)
        self.registerCellNib(TEXT_VIEW_CELL_ID)
        self.registerCellNib(TIME_PICKER_CELL_ID)
        
        self.cellData = self.createCellData()
        
        self.configureView()
    }
    
    func registerCellNib(name: String) {
        let nib = UINib(nibName: name, bundle: nil)
        self.tableView.registerNib(nib, forCellReuseIdentifier: name)
    }
    
    func createCellData() -> [[SGCellData]] {
        return [[]]
    }
    
    func configureView() {
        
        if self.showDoneButton {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "done:")
        }
        
        self.title = self.object?.name ?? "Untitled"
    }
    
    func cellForControl(control: UIView) -> UITableViewCell? {
        return control.superview?.superview as? UITableViewCell
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        if let data = self.dataForControl(textField) {
            self.object?.setValue(textField.text, forKey: data.modelPath)
            AppData.shared.save()
        }
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        if let data = self.dataForControl(textView) {
            self.object?.setValue(textView.text, forKey: data.modelPath)
            AppData.shared.save()
        }
    }
    
    @IBAction func switchDidChange(toggle: UISwitch) {
        if let data = self.dataForControl(toggle) {
            self.object?.setValue(toggle.on, forKey: data.modelPath)
            AppData.shared.save()
        }
    }
    
    @IBAction func timePickerDidChange(picker: UIDatePicker) {
        
        // Update the model.
        
        if let data = self.dataForControl(picker) {
            let length = picker.countDownDuration
            self.object?.setValue(length, forKey: data.modelPath)
            AppData.shared.save()
        }
        
        // Update the cell above.
        
        if let path = self.revealedCellIndexPath?.previous() {
            if let cell = self.tableView.cellForRowAtIndexPath(path) {
                self.configureCell(cell, atIndexPath: path)
            }
        }
    }
    
    @IBAction func datePickerDidChange(sender: AnyObject) {
        
        if let path = self.targetedCell() {
            
            var item = self.cellData[path.section][path.row]
            
            if let picker = sender as? UIDatePicker {
                
                self.object?.setValue(picker.date, forKey: item.modelPath)
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
    
    func configurePicker(picker: UIPickerView, forModelPath: String) {
        //
    }
    
    func refreshData() {
        self.title = self.object?.name ?? "Untitled"
        self.tableView.reloadData()
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.cellData.count
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        // CJC todo: don't hardcode these.
            
        switch self.cellIdentifierForIndexPath(indexPath) {
                
            case TIME_PICKER_CELL_ID:
                return 216.0
            
            case DATE_PICKER_CELL_ID:
                return 216.0
            
            case TEXT_VIEW_CELL_ID:
                return 178.0
            
            case PICKER_CELL_ID:
                return 162.0

            default:
                return self.tableView.rowHeight
        }
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
    
    func dataForControl(control: UIView) -> SGCellData? {
        
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
        
        let id = self.dataForIndexPath(indexPath)!.cellIdentifier
        
        if indexPath == self.revealedCellIndexPath {
            
            switch id {
                
                case PICKER_LABEL_CELL_ID:
                    return PICKER_CELL_ID
                
                case DATE_LABEL_CELL_ID:
                    return DATE_PICKER_CELL_ID
                
                case TIME_LABEL_CELL_ID:
                    return TIME_PICKER_CELL_ID
                
                default:
                    break
            }
        }
        
        return id ?? OTHER_CELL_ID
    }
    
    func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        
        let item = self.dataForIndexPath(indexPath)!
        
        switch (cell.reuseIdentifier ?? "") {
            
            case OTHER_CELL_ID:
                
                cell.textLabel?.text = item.title
                cell.selectionStyle = .None
                
            case PICKER_LABEL_CELL_ID:
            
                let name = self.object?.valueForKeyPath(item.modelPath) as? String
                
                cell.textLabel?.text = item.title
                cell.detailTextLabel?.text = name ?? "Untitled"
                
            case DATE_LABEL_CELL_ID:
                
                let date = self.object?.valueForKeyPath(item.modelPath) as! NSDate
                
                cell.textLabel?.text = item.title
                cell.detailTextLabel?.text = Formatter.dateStringFromDate(date)
            
            case TIME_LABEL_CELL_ID:
                
                cell.textLabel?.text = item.title
                
                let length = self.object?.valueForKeyPath(item.modelPath) as? NSTimeInterval ?? 0.0
                let timeString = Formatter.stringFromLength(length)
                
                cell.detailTextLabel?.text = timeString
                
            case BREAKS_LABEL_CELL_ID:
                
                var text = ""
                
                if let value: AnyObject = self.object?.valueForKeyPath(item.modelPath) {
                    text = "\(value)"
                }
                
                cell.textLabel?.text = item.title
                cell.detailTextLabel?.text = text
            
            case TEXT_FIELD_CELL_ID:
                
                let label = cell.viewWithTag(1) as! UILabel
                label.text = item.title
                
                let value = self.object?.valueForKeyPath(item.modelPath) as? String
                let textField = cell.viewWithTag(2) as! UITextField
                textField.text = value ?? "Untitled"
                textField.delegate = self
            
            case TEXT_VIEW_CELL_ID:
                
                let text = self.object?.valueForKeyPath(item.modelPath) as? String ?? ""
                let textView = cell.viewWithTag(2) as! UITextView
                textView.text = text
                textView.delegate = self
                
            case SWITCH_CELL_ID:
                
                let label = cell.viewWithTag(1) as! UILabel
                label.text = item.title
                
                let value = self.object?.valueForKeyPath(item.modelPath) as? Bool
                let toggle = cell.viewWithTag(2) as! UISwitch
                toggle.on = value ?? false
                
                toggle.addTarget(self, action: "switchDidChange:", forControlEvents: .ValueChanged)
                
            case PICKER_CELL_ID:
                
                let picker = cell.viewWithTag(2) as! UIPickerView
                picker.delegate = self
                self.configurePicker(picker, forModelPath: item.modelPath)
            
            case DATE_PICKER_CELL_ID:
                
                let date = self.object?.valueForKeyPath(item.modelPath) as? NSDate ?? NSDate()
                let picker = cell.viewWithTag(2) as! UIDatePicker
                picker.setDate(date, animated: false)
                picker.addTarget(self, action: "datePickerDidChange:", forControlEvents: .ValueChanged)
                
            case TIME_PICKER_CELL_ID:
                
                let length = self.object?.valueForKeyPath(item.modelPath) as? NSTimeInterval ?? 0.0
                let picker = cell.viewWithTag(2) as! UIDatePicker
                picker.countDownDuration = length
            
                picker.addTarget(self, action: "timePickerDidChange:", forControlEvents: .ValueChanged)
            
            default:
                break
        }
        
        let enabled = self.enabledStateForModelPath(item.modelPath)
        self.setEnabled(enabled, forCell: cell)
    }
    
    func enabledStateForModelPath(modelPath: String) -> Bool {
        return true
    }
    
    func setEnabled(enabled: Bool, forCell cell: UITableViewCell) {
        cell.userInteractionEnabled = enabled
        cell.textLabel?.enabled = enabled
        cell.detailTextLabel?.enabled = enabled
    }
    
    func canExpandCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) -> Bool {
        let hasRevealableCellBelow = (cell.reuseIdentifier == TIME_LABEL_CELL_ID) // CJC: revisit
        let canModify = true // CJC: revisit
        return hasRevealableCellBelow && canModify
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let cell = self.tableView.cellForRowAtIndexPath(indexPath) {
            if self.canExpandCell(cell, atIndexPath: indexPath) {
                self.displayRevealedCellForRowAtIndexPath(indexPath)
            } else {
                self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
            }
        }
    }
    
    func hasRevealedCellForIndexPath(indexPath: NSIndexPath) -> Bool {
        
        if let thisCell = self.tableView.cellForRowAtIndexPath(indexPath) {
            if let nextCell = self.tableView.cellForRowAtIndexPath(indexPath.next()) {
                
                let thisID = thisCell.reuseIdentifier
                let nextID = nextCell.reuseIdentifier
                
                if thisID == TIME_LABEL_CELL_ID {
                    return nextID == TIME_PICKER_CELL_ID
                }
                
                if thisID == DATE_LABEL_CELL_ID {
                    return nextID == DATE_PICKER_CELL_ID
                }
                
                if thisID == PICKER_LABEL_CELL_ID {
                    return nextID == PICKER_CELL_ID
                }
            }
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
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {
        return ""
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        //
    }
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 0
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 0
    }
}
