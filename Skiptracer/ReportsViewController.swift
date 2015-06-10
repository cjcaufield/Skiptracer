//
//  ReportsViewController.swift
//  Skiptracer
//
//  Created by Colin Caufield on 3/31/15.
//  Copyright (c) 2015 Secret Geometry, Inc. All rights reserved.
//

import UIKit
import CoreData

class ReportsViewController: SGCoreDataTableViewController {

    var timer: NSTimer?
    var parent: Report?
    
    override var needsBackButton: Bool {
        return self.parent != nil
    }
    
    override var entityName: String {
        return "Report"
    }
    
    override var fetchPredicate: NSPredicate? {
        let data = AppData.shared
        return data.reportsPredicateForParent(self.parent, user: data.settings.currentUser!)
    }
    
    override var sortDescriptors: [NSSortDescriptor] {
        return AppData.shared.reportSortDescriptors()
    }
    
    override var sectionKey: String? {
        return (self.parent == nil) ? "dayText" : nil
    }
    
    override var headerHeight: CGFloat {
        return (self.parent == nil) ? 32.0 : 0.0
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureView() // Currently needed for refreshing if a report's activity name changes.
        Notifications.shared.registerUserObserver(self)
        Notifications.shared.registerBreakObserver(self)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.configureView()
        self.timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "updateClock", userInfo: nil, repeats: true)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        self.timer?.invalidate()
        self.timer = nil
    }
    
    func configureView() {
        self.title = (self.parent == nil) ? "Reports" : "Breaks"
        self.refreshData()
    }
    
    func updateClock() {
        
        let user = AppData.shared.settings.currentUser
        let activeReports = [user?.currentReport, user?.currentBreak]
        
        for report in activeReports {
            if report != nil && report!.active {
                if let path = self.fetchController.indexPathForObject(report!) {
                    if let cell = self.tableView.cellForRowAtIndexPath(path) as? ReportsTableViewCell {
                        self.configureCell(cell, withObject: report!)
                    }
                }
            }
        }
    }
    
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! UITableViewHeaderFooterView
        header.textLabel?.textColor = UIColor(white: 0.6, alpha: 1.0)
        header.textLabel?.font = UIFont.systemFontOfSize(12.0)
        header.textLabel?.frame = header.frame
        if self.centerHeaderText {
            header.textLabel?.textAlignment = NSTextAlignment.Center
        }
    }
    
    override func cellIdentifierForObject(object: AnyObject) -> String {
        return "Report"
    }
    
    override func createNewObject() -> NSManagedObject {
        let data = AppData.shared
        let user = data.settings.currentUser
        let isBreak = (self.parent != nil)
        return data.createReport(nil, parent: parent, user: user, active: false, isBreak: isBreak)
    }
    
    override func deleteObject(object: NSManagedObject) {
        if AppData.shared.settings.currentUser?.currentReport != nil {
            Notifications.shared.cancelAllNotifications()
        }
        super.deleteObject(object)
    }
    
    override func configureCell(cell: UITableViewCell, withObject object: AnyObject) {
        
        let report = object as? Report
        
        if let statsCell = cell as? ReportsTableViewCell {
            
            statsCell.leftLabel?.text = self.nameForReport(report)
            statsCell.middleLabel?.text = report?.startAndEndText ?? ""
            statsCell.rightLabel?.text = report?.lengthWithoutBreaksText ?? ""
            
            if report?.active ?? false {
                //statsCell.leftLabel.textColor = statsCell.leftLabel.tintColor
                statsCell.rightLabel.textColor = statsCell.rightLabel.tintColor
                //statsCell.backgroundColor = UIColor(red: 0.0, green: 0.478, blue: 1.0, alpha: 0.03)
            } else {
                //statsCell.leftLabel.textColor = UIColor.blackColor()
                statsCell.rightLabel.textColor = UIColor.blackColor()
                //statsCell.backgroundColor = UIColor.whiteColor()
            }
        }
    }
    
    override func didSelectObject(object: AnyObject, new: Bool = false) {
        
        let newController = self.storyboard?.instantiateViewControllerWithIdentifier("Report") as! ReportViewController
        newController.showDoneButton = new
        newController.object = object
        newController.title = self.nameForReport(object as? Report)
        
        self.navigationController?.pushViewController(newController, animated: true)
    }
    
    func nameForReport(report: Report?) -> String {
        
        var name = "Untitled"
        
        if report != nil && report!.isBreak {
            name = "Break"
            if let breaks = self.fetchController.fetchedObjects as? [Report] {
                if let index = breaks.indexOf(report!) {
                    name += " \(breaks.count - index)"
                }
            }
        } else {
            name = report?.activity?.name ?? "Untitled"
        }
        
        return name
    }
    
    func userWasSwitched(note: NSNotification) {
        self.updateRequest()
    }
    
    func autoBreakWasStarted(note: NSNotification) {
        self.refreshData()
    }
    
    func autoBreakWasEnded(note: NSNotification) {
        self.refreshData()
    }
}
