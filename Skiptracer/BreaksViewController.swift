//
//  BreaksViewController.swift
//  Skiptracer
//
//  Created by Colin Caufield on 4/17/15.
//  Copyright (c) 2015 Secret Geometry, Inc. All rights reserved.
//

import UIKit

class BreaksViewController: SGCoreDataTableViewController {
    
    var timer: NSTimer?
    
    override var needsBackButton: Bool { return true }
    
    override var entityName: String { return "Report" }
    
    override var fetchPredicate: NSPredicate? { return AppData.shared.currentUserPredicate() }
    
    override var sortDescriptors: [NSSortDescriptor] { return [NSSortDescriptor(key: "startDate", ascending: false)] }
    
    //override var sectionKey: String? { return "dayText" }
    
    //override var headerHeight: CGFloat { return 22.0 }
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
    
    func updateClock() {
        let user = AppData.shared.settings.currentUser
        if let report = user?.currentReport {
            if report.active {
                
                // CJC grab break report here
                
                if let path = self.fetchController.indexPathForObject(report) {
                    if let cell = self.tableView.cellForRowAtIndexPath(path) as? ReportsTableViewCell {
                        self.configureCell(cell, withObject: report)
                    }
                }
            }
        }
    }
    
    override func cellIdentifierForObject(object: AnyObject) -> String {
        return "Break"
    }
    
    override func createNewObject() -> AnyObject {
        let user = AppData.shared.settings.currentUser
        let report = user?.currentReport
        return AppData.shared.createBreak(report, user: user, active: false)
    }
    
    override func configureCell(cell: UITableViewCell, withObject object: AnyObject) {
        
        let report = object as? Report
        
        if let statsCell = cell as? ReportsTableViewCell {
            statsCell.leftLabel?.text = report?.activity?.name ?? "Untitled"
            statsCell.middleLabel?.text = report?.startAndEndText ?? ""
            statsCell.rightLabel?.text = report?.lengthText ?? ""
        }
    }
    
    override func didSelectObject(object: AnyObject) {
        
        let newController = self.storyboard?.instantiateViewControllerWithIdentifier("Break") as! BreakViewController
        newController.report = object as? Report
        
        self.navigationController?.pushViewController(newController, animated: true)
    }
    
    override func canEditObject(object: AnyObject) -> Bool {
        if let report = object as? Report {
            return report.active == false
        }
        return true
    }
}
