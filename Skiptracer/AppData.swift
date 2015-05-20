//
//  AppData.swift
//  Skiptracer
//
//  Created by Colin Caufield on 4/1/15.
//  Copyright (c) 2015 Secret Geometry, Inc. All rights reserved.
//

import UIKit
import CoreData

private var _shared: AppData? = nil

class AppData: Data {
    
    var settings:  Settings!
    var basicUser: User!
    var testUser:  User!
    
    override class var shared: AppData {
        if _shared == nil {
            _shared = AppData()
        }
        return _shared!
    }
    
    override init() {
        super.init()
        assert(_shared == nil)
        _shared = self
    }
    
    override func refreshProperties() {
        
        println("AppData.refreshProperties")
        
        self.settings  = self.fetchSettings().first ?? self.createSettings()
        self.basicUser = self.fetchBasicUsers().first ?? self.createBasicUser()
        self.testUser  = self.fetchTestUsers().first ?? self.createTestUser()
        
        println("*** SETTING USER: \(self.basicUser.uniqueName)")
        
        self.settings.currentUser = self.settings.enableTestUser ? self.testUser : self.basicUser
        
        for user in [self.basicUser, self.testUser] {
            
            if user.activities.count == 0 {
                
                let relaxing = self.createActivity("Relaxing", user: user)
                relaxing.permanent = true
                relaxing.silent = true
                
                self.createActivity("Working", user: user)
                self.createActivity("Playing", user: user)
            }
        }
        
        self.refreshCurrentReportAndBreak(self.basicUser)
        self.refreshCurrentReportAndBreak(self.testUser)
    }
    
    func refreshCurrentReportAndBreak(user: User) {
        
        let activeReports = self.fetchActiveReports(user)
        let activeBreaks = self.fetchActiveBreaks(user)
        
        if activeReports.count == 0 {
            
            user.currentReport = nil
            user.currentBreak = nil
            
        } else {
            
            user.currentReport = activeReports.first
            
            var validBreak: Report?
            for abreak in activeBreaks {
                if abreak.parent == user.currentReport {
                    validBreak = abreak
                    break
                }
            }
            
            user.currentBreak = validBreak
        }
        
        // Make sure only the current report and break are active.
        
        for report in activeReports {
            if report != user.currentReport {
                StatusController.shared.endReport(report, save: false)
            }
        }
        
        for abreak in activeBreaks {
            if abreak != user.currentBreak {
                StatusController.shared.endReport(abreak, save: false)
            }
        }
        
        self.save()
    }
    
    // MARK: - Creation
    
    func createSettings() -> Settings {
        
        println("*** CREATING SETTINGS")
        
        var settings = self.insertNewObject("Settings") as! Settings
        
        settings.uniqueName = "Settings - \(self.uniqueString())"
        settings.creationDate = NSDate()
        
        return settings
    }
    
    func createUser(testUser: Bool = false) -> User {
        
        println("*** CREATING USER")
        
        var user = self.insertNewObject("User") as! User
        user.isTestUser = testUser
        
        let typeName = (testUser) ? "Basic" : "Test"
        user.uniqueName = "User - \(typeName) - \(self.uniqueString())"
        user.creationDate = NSDate()
        
        return user
    }
    
    func createBasicUser() -> User {
        return self.createUser()
    }
    
    func createTestUser() -> User {
        return self.createUser(testUser: true)
    }
    
    func createActivity(name: String?, user: User?) -> Activity {
        
        println("*** CREATING ACTIVITY")
        
        var activity = self.insertNewObject("Activity") as! Activity
        if name != nil {
            activity.name = name!
        }
        
        activity.uniqueName = "Activity - \(self.uniqueString())"
        activity.creationDate = NSDate()
        
        activity.user = user
        return activity
    }
    
    func createReport(activity: Activity?, parent: Report?, user: User?, active: Bool, isBreak: Bool) -> Report {
        
        println("*** CREATING REPORT")
        
        var report = self.insertNewObject("Report") as! Report
        report.active = active
        report.isBreak = isBreak
        report.parent = parent
        report.activity = activity
        report.startDate = NSDate()
        report.endDate = NSDate()
        report.user = user
        
        report.uniqueName = "Report - \(self.uniqueString())"
        report.creationDate = NSDate()
        
        return report
    }
    
    func createReport(activity: Activity?, user: User?, active: Bool) -> Report {
        return createReport(activity, parent: nil, user: user, active: active, isBreak: false)
    }
    
    func createBreak(parent: Report?, user: User?, active: Bool) -> Report {
        return createReport(nil, parent: parent, user: user, active: active, isBreak: true)
    }
    
    // MARK: - Fetches
    
    func fetchSettings() -> [Settings] {
        let sortDescriptors = self.settingsSortDescriptors()
        return self.fetchObjects("Settings", predicate: nil, sortDescriptors: sortDescriptors) as! [Settings]
    }
    
    func fetchUsers(testUser: Bool = false) -> [User] {
        let predicate = NSPredicate(format: "isTestUser == %d", Int(testUser))
        let sortDescriptors = self.userSortDescriptors()
        return self.fetchObjects("User", predicate: predicate, sortDescriptors: sortDescriptors) as! [User]
    }
    
    func fetchBasicUsers() -> [User] {
        return self.fetchUsers()
    }
    
    func fetchTestUsers() -> [User] {
        return self.fetchUsers(testUser: true)
    }
    
    func fetchOrderedActivities(user: User) -> [Activity] {
        return self.fetchObjects(self.orderedActivitiesRequest(user)) as! [Activity]
    }
    
    func fetchOrganizedActivities(user: User) -> [Activity] {
        return self.fetchObjects(self.organizedActivitiesRequest(user)) as! [Activity]
    }
    
    func fetchOrderedReportsForParent(parent: Report?, user: User) -> [Report] {
        return self.fetchObjects(self.orderedReportsRequestForParent(parent, user: user)) as! [Report]
    }
    
    func fetchOrganizedReportsForParent(parent: Report?, user: User) -> [Report] {
        return self.fetchObjects(self.organizedReportsRequestForParent(parent, user: user)) as! [Report]
    }
    
    func fetchOrderedReportsForActivity(activity: Activity?, user: User) -> [Report] {
        return self.fetchObjects(self.orderedReportsRequestForActivity(activity, user: user)) as! [Report]
    }
    
    func fetchOrganizedReportsForActivity(activity: Activity?, user: User) -> [Report] {
        return self.fetchObjects(self.organizedReportsRequestForActivity(activity, user: user)) as! [Report]
    }
    
    func fetchActiveReports(user: User) -> [Report] {
        return self.fetchObjects(self.orderedActiveReportsRequest(user)) as! [Report]
    }
    
    func fetchActiveBreaks(user: User) -> [Report] {
        return self.fetchObjects(self.orderedActiveBreaksRequest(user)) as! [Report]
    }
    
    // MARK: - Fetch Requests
    
    func orderedActivitiesRequest(user: User) -> NSFetchRequest {
        let predicate = self.userPredicate(user)
        let sortDescriptors = self.activitySortDescriptors()
        return self.activitiesRequest(predicate: predicate, sortDescriptors: sortDescriptors)
    }
    
    func organizedActivitiesRequest(user: User) -> NSFetchRequest {
        let predicate = self.userPredicate(user)
        let sortDescriptors = self.uniqueNameSortDescriptors()
        return self.activitiesRequest(predicate: predicate, sortDescriptors: sortDescriptors)
    }
    
    func activitiesRequest(predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor] = []) -> NSFetchRequest {
        return self.fetchRequest("Activity", predicate: predicate, sortDescriptors: sortDescriptors)
    }
    
    func orderedReportsRequestForParent(parent: Report?, user: User) -> NSFetchRequest {
        let predicate = self.reportsPredicateForParent(parent, user: user)
        let sortDescriptors = self.reportSortDescriptors()
        return self.reportsRequest(predicate: predicate, sortDescriptors: sortDescriptors)
    }
    
    func organizedReportsRequestForParent(parent: Report?, user: User) -> NSFetchRequest {
        let predicate = self.reportsPredicateForParent(parent, user: user)
        let sortDescriptors = self.uniqueNameSortDescriptors()
        return self.reportsRequest(predicate: predicate, sortDescriptors: sortDescriptors)
    }
    
    func orderedReportsRequestForActivity(activity: Activity?, user: User) -> NSFetchRequest {
        let predicate = self.reportsPredicateForActivity(activity, user: user)
        let sortDescriptors = self.reportSortDescriptors()
        return self.reportsRequest(predicate: predicate, sortDescriptors: sortDescriptors)
    }
    
    func organizedReportsRequestForActivity(activity: Activity?, user: User) -> NSFetchRequest {
        let predicate = self.reportsPredicateForActivity(activity, user: user)
        let sortDescriptors = self.uniqueNameSortDescriptors()
        return self.reportsRequest(predicate: predicate, sortDescriptors: sortDescriptors)
    }
    
    func orderedActiveReportsRequest(user: User) -> NSFetchRequest {
        let predicate = self.activeReportsPredicate(user)
        let sortDescriptors = self.reportSortDescriptors()
        return self.reportsRequest(predicate: predicate, sortDescriptors: sortDescriptors)
    }
    
    func orderedActiveBreaksRequest(user: User) -> NSFetchRequest {
        let predicate = self.activeBreaksPredicate(user)
        let sortDescriptors = self.reportSortDescriptors()
        return self.reportsRequest(predicate: predicate, sortDescriptors: sortDescriptors)
    }
    
    func reportsRequest(predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor] = []) -> NSFetchRequest {
        return self.fetchRequest("Report", predicate: predicate, sortDescriptors: sortDescriptors)
    }
    
    // MARK: - Predicates
    
    func userPredicate(user: User) -> NSPredicate {
        return NSPredicate(format: "user = %@", user)
    }
    
    func currentUserPredicate() -> NSPredicate {
        let user = (self.settings.enableTestUser) ? self.testUser : self.basicUser
        return self.userPredicate(user)
    }
    
    func reportsPredicateForParent(parent: Report?, user: User) -> NSPredicate {
        return self.andPredicates([self.userPredicate(user), self.parentReportPredicate(parent)])
    }
    
    func reportsPredicateForActivity(activity: Activity?, user: User) -> NSPredicate {
        return self.andPredicates([self.userPredicate(user), self.activityPredicate(activity)])
    }
    
    func activeReportsPredicate(user: User) -> NSPredicate {
        return self.andPredicates([self.userPredicate(user), self.isActivePredicate(), self.isntBreakPredicate()])
    }
    
    func activeBreaksPredicate(user: User) -> NSPredicate {
        return self.andPredicates([self.userPredicate(user), self.isActivePredicate(), self.isBreakPredicate()])
    }
    
    func parentReportPredicate(parent: Report?) -> NSPredicate {
        return self.nullablePredicate("parent", object: parent)
    }
    
    func activityPredicate(activity: Activity?) -> NSPredicate {
        return self.nullablePredicate("activity", object: activity)
    }
    
    func isActivePredicate() -> NSPredicate {
        return self.booleanPredicate("active", value: true)
    }
    
    func isBreakPredicate() -> NSPredicate {
        return self.booleanPredicate("isBreak", value: true)
    }
    
    func isntBreakPredicate() -> NSPredicate {
        return self.booleanPredicate("isBreak", value: false)
    }
    
    // MARK: - Sort Descriptors
    
    func settingsSortDescriptors() -> [NSSortDescriptor] {
        return [
            NSSortDescriptor(key: "creationDate", ascending: true),
            NSSortDescriptor(key: "uniqueName", ascending: true)
        ]
    }
    
    func userSortDescriptors() -> [NSSortDescriptor] {
        return [
            NSSortDescriptor(key: "creationDate", ascending: true),
            NSSortDescriptor(key: "uniqueName", ascending: true)
        ]
    }
    
    func activitySortDescriptors() -> [NSSortDescriptor] {
        return [
            NSSortDescriptor(key: "permanent", ascending: false),
            NSSortDescriptor(key: "name", ascending: true),
            NSSortDescriptor(key: "creationDate", ascending: true),
            NSSortDescriptor(key: "uniqueName", ascending: true)
        ]
    }
    
    func reportSortDescriptors() -> [NSSortDescriptor] {
        return [
            NSSortDescriptor(key: "startDate", ascending: false),
            NSSortDescriptor(key: "creationDate", ascending: true),
            NSSortDescriptor(key: "uniqueName", ascending: true)
        ]
    }
    
    func uniqueNameSortDescriptors() -> [NSSortDescriptor] {
        return [
            NSSortDescriptor(key: "uniqueName", ascending: true)
        ]
    }
    
    // MARK: - Merges
    
    func mergeSettings(settings1: Settings, with settings2: Settings) {
        
        // Merge the basic user.
        if let basic1 = settings1.basicUser, basic2 = settings2.basicUser {
            self.mergeUser(basic1, with: basic2)
        }
        
        // Merge the test user.
        if let test1 = settings1.testUser, test2 = settings2.testUser {
            self.mergeUser(test1, with: test2)
        }
        
        // Delete the newer settings.
        self.context?.deleteObject(settings2)
    }
    
    func mergeUser(user1: User, with user2: User) {
        
        // Cache some objects before merging.
        
        let currentReport1 = user1.currentReport
        let currentReport2 = user2.currentReport
        let currentBreak1 = user1.currentBreak
        let currentBreak2 = user2.currentBreak
        
        // Change user for activities.
        
        var activities = user1.activities as! NSMutableSet
        
        for activity in user2.activities.allObjects as! [Activity] {
            activity.user = user1
            activities.addObject(activity)
        }
        
        // Change user for reports.
        
        var reports = user1.reports as! NSMutableSet
        
        for report in user2.reports.allObjects as! [Report] {
            report.user = user1
            reports.addObject(report)
        }
        
        // Merge duplicate activities.
        
        let organizedActivities = self.fetchOrganizedActivities(user1)
        
        for i in 0 ..< organizedActivities.count - 1 {
            
            let a = organizedActivities[i]
            let b = organizedActivities[i + 1]
            
            if a.uniqueName == b.uniqueName {
                self.mergeActivity(a, with: b, user: user1)
            }
        }
        
        // Merge identically named activities.
        
        let orderedActivities = self.fetchOrderedActivities(user1)
        
        for i in 0 ..< orderedActivities.count - 1 {
            
            let a = orderedActivities[i]
            let b = orderedActivities[i + 1]
            
            if a.name == b.name {
                self.mergeActivity(a, with: b, user: user1)
            }
        }
        
        // Delete the newer user.
        self.context?.deleteObject(user2)
    }
    
    func mergeActivity(activity1: Activity, with activity2: Activity, user: User) {
        
        // Change activity for reports
        
        var reports = activity1.reports as! NSMutableSet
        
        for report in activity2.reports.allObjects as! [Report] {
            report.activity = activity1
            reports.addObject(report)
        }
        
        // Merge duplicate reports
        
        let orderedReports = self.fetchOrganizedReportsForActivity(activity1, user: user)
        
        for i in 0 ..< orderedReports.count - 1 {
            
            let a = orderedReports[i]
            let b = orderedReports[i + 1]
            
            if a.uniqueName == b.uniqueName {
                self.mergeReport(a, with: b, user: user)
            }
        }
        
        // Delete the newer activity.
        self.context?.deleteObject(activity2)
    }
    
    func mergeReport(report1: Report, with report2: Report, user: User) {
        
        // Change parent for breaks
        
        var breaks = report1.breaks as! NSMutableSet
        
        for abreak in report2.breaks.allObjects as! [Report] {
            abreak.parent = report1
            breaks.addObject(abreak)
        }
        
        // Merge duplicate breaks.
        
        let orderedBreaks = self.fetchOrganizedReportsForParent(report1, user: user)
        
        for i in 0 ..< orderedBreaks.count - 1 {
            
            let a = orderedBreaks[i]
            let b = orderedBreaks[i + 1]
            
            if a.uniqueName == b.uniqueName {
                self.mergeReport(a, with: b, user: user)
            }
        }
        
        // Delete the newer report.
        self.context?.deleteObject(report2)
    }
}
