//
//  StatisticsViewController.swift
//  Skiptracer
//
//  Created by Colin Caufield on 3/31/15.
//  Copyright (c) 2015 Secret Geometry, Inc. All rights reserved.
//

import UIKit
import CoreData

class StatisticsViewController: SGCoreDataTableViewController {

    var timer: NSTimer?
    
    override var entityName: String { return "Report" }
    
    override var fetchPredicate: NSPredicate? { return AppData.shared.currentUserPredicate() }
    
    override var sortDescriptors: [NSSortDescriptor] { return [NSSortDescriptor(key: "startDate", ascending: false)] }
    
    override var sectionKey: String? { return "dayText" }
    
    override var headerHeight: CGFloat { return 22.0 }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.refreshData() // Currently needed to handle activity name changes.
        let center = NSNotificationCenter.defaultCenter()
        center.addObserver(self, selector: "userWasSwitched:", name: UserWasSwitchedNotification, object: nil)
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
                if let path = self.fetchController.indexPathForObject(report) {
                    if let cell = self.tableView.cellForRowAtIndexPath(path) as? StatisticsTableViewCell {
                        self.configureCell(cell, withObject: report)
                    }
                }
            }
        }
    }
    
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! UITableViewHeaderFooterView
        header.textLabel.textColor = UIColor(white: 0.6, alpha: 1.0)
        header.textLabel.font = UIFont.systemFontOfSize(12.0)
        header.textLabel.frame = header.frame
        //header.textLabel.textAlignment = NSTextAlignment.Center
    }
    
    override func cellIdentifierForObject(object: AnyObject) -> String {
        return "Report"
    }
    
    override func createNewObject() -> AnyObject {
        return AppData.shared.createReport(nil, user: AppData.shared.settings.currentUser, active: false)
    }
    
    override func configureCell(cell: UITableViewCell, withObject object: AnyObject) {
        
        let report = object as? Report
        
        if let statsCell = cell as? StatisticsTableViewCell {
            statsCell.leftLabel?.text = report?.activity?.name ?? "Untitled"
            statsCell.middleLabel?.text = report?.startAndEndText ?? ""
            statsCell.rightLabel?.text = report?.lengthText ?? ""
        }
    }
    
    override func didSelectObject(object: AnyObject) {
        
        let newController = self.storyboard?.instantiateViewControllerWithIdentifier("Report") as! ReportViewController
        newController.report = object as? Report
        
        self.navigationController?.pushViewController(newController, animated: true)
    }
    
    override func canEditObject(object: AnyObject) -> Bool {
        if let report = object as? Report {
            return report.active == false
        }
        return true
    }
    
    func userWasSwitched(note: NSNotification) {
        self.updateRequest()
    }
}
