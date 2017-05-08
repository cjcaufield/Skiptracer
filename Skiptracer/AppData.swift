//
//  AppData.swift
//  Skiptracer
//
//  Created by Colin Caufield on 4/1/15.
//  Copyright (c) 2015 Secret Geometry, Inc. All rights reserved.
//

import UIKit
import CoreData
import SecretKit

private var _shared: AppData? = nil

private var settingsIndex = 0
private var userIndex = 0
private var activityIndex = 0
private var reportIndex = 0
private var breakIndex = 0

class AppData: SGData {
    
    var settings:  Settings!
    
    override class var shared: AppData {
        if _shared == nil {
            _shared = AppData()
        }
        return _shared!
    }
    
    init() {
        super.init(name: "Skiptracer", useCloud: false)
        assert(_shared == nil)
        _shared = self
    }
    
    override func refreshProperties() {
        
        print("AppData.refreshProperties")
        
        self.settings  = self.fetchSettings().first ?? self.createSettings()
        self.settings.basicUser = self.fetchBasicUsers().first ?? self.createBasicUser()
        self.settings.testUser  = self.fetchTestUsers().first ?? self.createTestUser()
        
        print("*** SETTING USER - \(self.settings.basicUser.uniqueName)")
        
        self.settings.currentUser = self.settings.enableTestUser ? self.settings.testUser : self.settings.basicUser
        
        for user in [self.settings.basicUser, self.settings.testUser] {
            
            if user?.activities.count == 0 {
                
                let relaxing = self.createActivity("Relaxing", user: user)
                relaxing.permanent = true
                relaxing.silent = true
                
                let _ = self.createActivity("Working", user: user)
                let _ = self.createActivity("Playing", user: user)
            }
        }
        
        self.refreshCurrentReportAndBreak(self.settings.basicUser)
        self.refreshCurrentReportAndBreak(self.settings.testUser)
    }
    
    func refreshCurrentReportAndBreak(_ user: User) {
        
        print("AppData.refreshCurrentReportAndBreak")
        
        let activeReports = self.fetchActiveReports(user)
        let activeBreaks = self.fetchActiveBreaks(user)
        
        if activeReports.count == 0 {
            
            print("setting current report and break to nil")
            user.currentReport = nil
            user.currentBreak = nil
            
        } else {
            
            print("setting current report to \(activeReports.first)")
            user.currentReport = activeReports.first
            
            var validBreak: Report?
            for abreak in activeBreaks {
                if abreak.parent == user.currentReport {
                    validBreak = abreak
                    break
                }
            }
            
            print("setting current break to \(validBreak)")
            user.currentBreak = validBreak
        }
        
        // Make sure only the current report and break are active.
        
        print("ending other reports")
        
        for report in activeReports {
            if report != user.currentReport {
                StatusController.shared.endReport(report, save: false)
            }
        }
        
        print("ending other breaks")
        
        for abreak in activeBreaks {
            if abreak != user.currentBreak {
                StatusController.shared.endReport(abreak, save: false)
            }
        }
        
        self.save()
    }
    
    override func deduplicate() {
        let settings = self.fetchSettings()
        if settings.count > 1 {
            self.mergeSettings(settings[0], with: settings[1])
            self.save()
        }
    }
    
    // MARK: - Creation
    
    func createSettings() -> Settings {
        
        let settings = self.insertNewObject("Settings") as! Settings
        
        let now = Date()
        settings.creationDate = now
        settings.uniqueName = "Settings - \(settingsIndex) - \(now) - \(self.uniqueDeviceString())"
        settingsIndex += 1
        
        print("*** CREATED SETTINGS - \(settings.uniqueName)")
        return settings
    }
    
    func createUser(_ testUser: Bool = false) -> User {
        
        let user = self.insertNewObject("User") as! User
        user.isTestUser = testUser
        
        let now = Date()
        let typeName = (testUser) ? "Test" : "Basic"
        user.creationDate = Date()
        user.uniqueName = "User - \(userIndex) - \(typeName) - \(now) - \(self.uniqueDeviceString())"
        userIndex += 1
        
        
        print("*** CREATED USER - \(user.uniqueName)")
        return user
    }
    
    func createBasicUser() -> User {
        return self.createUser()
    }
    
    func createTestUser() -> User {
        return self.createUser(true)
    }
    
    func createActivity(_ name: String?, user: User?) -> Activity {
        
        let activity = self.insertNewObject("Activity") as! Activity
        if name != nil {
            activity.name = name!
        }
        
        activity.user = user
        
        let now = Date()
        activity.creationDate = now
        activity.uniqueName = "Activity - \(activityIndex) - \(now) - \(self.uniqueDeviceString())"
        activityIndex += 1
        
        print("*** CREATED ACTIVITY - \(activity.uniqueName)")
        return activity
    }
    
    func createReport(_ activity: Activity?, parent: Report?, user: User?, active: Bool, isBreak: Bool) -> Report {
        
        let report = self.insertNewObject("Report") as! Report
        report.active = active
        report.isBreak = isBreak
        report.parent = parent
        report.activity = activity
        report.startDate = Date()
        report.endDate = Date()
        report.user = user
        
        let now = Date()
        report.creationDate = now
        if isBreak {
            report.uniqueName = "Break - \(breakIndex) - \(now) - \(self.uniqueDeviceString())"
            breakIndex += 1
        } else {
            report.uniqueName = "Report - \(reportIndex) - \(now) - \(self.uniqueDeviceString())"
            reportIndex += 1
        }
        
        print("*** CREATED REPORT - \(report.uniqueName)")
        return report
    }
    
    func createReport(_ activity: Activity?, user: User?, active: Bool) -> Report {
        return createReport(activity, parent: nil, user: user, active: active, isBreak: false)
    }
    
    func createBreak(_ parent: Report?, user: User?, active: Bool) -> Report {
        return createReport(nil, parent: parent, user: user, active: active, isBreak: true)
    }
    
    // MARK: - Fetches
    
    func fetchSettings() -> [Settings] {
        let sortDescriptors = self.settingsSortDescriptors()
        return self.fetchObjects("Settings", predicate: nil, sortDescriptors: sortDescriptors) as! [Settings]
    }
    
    func fetchUsers(_ testUser: Bool = false) -> [User] {
        let predicate = NSPredicate(format: "isTestUser == %d", testUser ? 1 : 0)
        let sortDescriptors = self.userSortDescriptors()
        return self.fetchObjects("User", predicate: predicate, sortDescriptors: sortDescriptors) as! [User]
    }
    
    func fetchBasicUsers() -> [User] {
        return self.fetchUsers()
    }
    
    func fetchTestUsers() -> [User] {
        return self.fetchUsers(true)
    }
    
    func fetchOrderedActivities(_ user: User) -> [Activity] {
        let request = self.orderedActivitiesRequest(user)
        return self.fetchObjects(request) as! [Activity]
    }
    
    func fetchOrganizedActivities(_ user: User) -> [Activity] {
        let request = self.organizedActivitiesRequest(user)
        return self.fetchObjects(request) as! [Activity]
    }
    
    func fetchOrderedReportsForParent(_ parent: Report?, user: User) -> [Report] {
        let request = self.orderedReportsRequestForParent(parent, user: user)
        return self.fetchObjects(request) as! [Report]
    }
    
    func fetchOrganizedReportsForParent(_ parent: Report?, user: User) -> [Report] {
        let request = self.organizedReportsRequestForParent(parent, user: user)
        return self.fetchObjects(request) as! [Report]
    }
    
    func fetchOrderedReportsForActivity(_ activity: Activity?, user: User) -> [Report] {
        let request = self.orderedReportsRequestForActivity(activity, user: user)
        return self.fetchObjects(request) as! [Report]
    }
    
    func fetchOrganizedReportsForActivity(_ activity: Activity?, user: User) -> [Report] {
        let request = self.organizedReportsRequestForActivity(activity, user: user)
        return self.fetchObjects(request) as! [Report]
    }
    
    func fetchActiveReports(_ user: User) -> [Report] {
        let request = self.orderedActiveReportsRequest(user)
        return self.fetchObjects(request) as! [Report]
    }
    
    func fetchActiveBreaks(_ user: User) -> [Report] {
        let request = self.orderedActiveBreaksRequest(user)
        return self.fetchObjects(request) as! [Report]
    }
    
    // MARK: - Fetch Requests
    
    func orderedActivitiesRequest(_ user: User) -> NSFetchRequest<NSFetchRequestResult> {
        let predicate = self.userPredicate(user)
        let sortDescriptors = self.activitySortDescriptors()
        return self.activitiesRequest(predicate, sortDescriptors: sortDescriptors)
    }
    
    func organizedActivitiesRequest(_ user: User) -> NSFetchRequest<NSFetchRequestResult> {
        let predicate = self.userPredicate(user)
        let sortDescriptors = self.uniqueNameSortDescriptors()
        return self.activitiesRequest(predicate, sortDescriptors: sortDescriptors)
    }
    
    func activitiesRequest(_ predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor] = []) -> NSFetchRequest<NSFetchRequestResult> {
        return self.fetchRequest("Activity", predicate: predicate, sortDescriptors: sortDescriptors)
    }
    
    func orderedReportsRequestForParent(_ parent: Report?, user: User) -> NSFetchRequest<NSFetchRequestResult> {
        let predicate = self.reportsPredicateForParent(parent, user: user)
        let sortDescriptors = self.reportSortDescriptors()
        return self.reportsRequest(predicate, sortDescriptors: sortDescriptors)
    }
    
    func organizedReportsRequestForParent(_ parent: Report?, user: User) -> NSFetchRequest<NSFetchRequestResult> {
        let predicate = self.reportsPredicateForParent(parent, user: user)
        let sortDescriptors = self.uniqueNameSortDescriptors()
        return self.reportsRequest(predicate, sortDescriptors: sortDescriptors)
    }
    
    func orderedReportsRequestForActivity(_ activity: Activity?, user: User) -> NSFetchRequest<NSFetchRequestResult> {
        let predicate = self.reportsPredicateForActivity(activity, user: user)
        let sortDescriptors = self.reportSortDescriptors()
        return self.reportsRequest(predicate, sortDescriptors: sortDescriptors)
    }
    
    func organizedReportsRequestForActivity(_ activity: Activity?, user: User) -> NSFetchRequest<NSFetchRequestResult> {
        let predicate = self.reportsPredicateForActivity(activity, user: user)
        let sortDescriptors = self.uniqueNameSortDescriptors()
        return self.reportsRequest(predicate, sortDescriptors: sortDescriptors)
    }
    
    func orderedActiveReportsRequest(_ user: User) -> NSFetchRequest<NSFetchRequestResult> {
        let predicate = self.activeReportsPredicate(user)
        let sortDescriptors = self.reportSortDescriptors()
        return self.reportsRequest(predicate, sortDescriptors: sortDescriptors)
    }
    
    func orderedActiveBreaksRequest(_ user: User) -> NSFetchRequest<NSFetchRequestResult> {
        let predicate = self.activeBreaksPredicate(user)
        let sortDescriptors = self.reportSortDescriptors()
        return self.reportsRequest(predicate, sortDescriptors: sortDescriptors)
    }
    
    func reportsRequest(_ predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor] = []) -> NSFetchRequest<NSFetchRequestResult> {
        return self.fetchRequest("Report", predicate: predicate, sortDescriptors: sortDescriptors)
    }
    
    // MARK: - Predicates
    
    func userPredicate(_ user: User) -> NSPredicate {
        return NSPredicate(format: "user = %@", user)
    }
    
    func currentUserPredicate() -> NSPredicate {
        let user = (self.settings.enableTestUser) ? self.settings.testUser : self.settings.basicUser
        return self.userPredicate(user!)
    }
    
    func reportsPredicateForParent(_ parent: Report?, user: User) -> NSPredicate {
        return self.andPredicates([self.userPredicate(user), self.parentReportPredicate(parent)])
    }
    
    func reportsPredicateForActivity(_ activity: Activity?, user: User) -> NSPredicate {
        return self.andPredicates([self.userPredicate(user), self.activityPredicate(activity)])
    }
    
    func activeReportsPredicate(_ user: User) -> NSPredicate {
        return self.andPredicates([self.userPredicate(user), self.isActivePredicate(), self.isntBreakPredicate()])
    }
    
    func activeBreaksPredicate(_ user: User) -> NSPredicate {
        return self.andPredicates([self.userPredicate(user), self.isActivePredicate(), self.isBreakPredicate()])
    }
    
    func parentReportPredicate(_ parent: Report?) -> NSPredicate {
        return self.nullablePredicate("parent", object: parent)
    }
    
    func activityPredicate(_ activity: Activity?) -> NSPredicate {
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
    
    func mergeSettings(_ settings1: Settings, with settings2: Settings) {
        
        print("### mergeSettings \(settings1) --- \(settings2)")
        
        // Merge the basic user.
        if let basic1 = settings1.basicUser, let basic2 = settings2.basicUser {
            self.mergeUser(basic1, with: basic2)
        }
        
        // Merge the test user.
        if let test1 = settings1.testUser, let test2 = settings2.testUser {
            self.mergeUser(test1, with: test2)
        }
        
        // Delete the newer settings.
        self.context?.delete(settings2)
    }
    
    func mergeUser(_ user1: User, with user2: User) {
        
        print("###  mergeUser \(user1) --- \(user2)")
        
        // Change user for activities.
        
        let activities = user1.activities as! NSMutableSet
        
        print("###    there were \(activities.count) activities")
        
        for activity in user2.activities.allObjects as! [Activity] {
            activity.user = user1
            activities.add(activity)
        }
        
        print("###    there are now \(activities.count) activities")
        
        // Change user for reports.
        
        let reports = user1.reports as! NSMutableSet
        
        print("###    there were \(reports.count) reports")
        
        for report in user2.reports.allObjects as! [Report] {
            report.user = user1
            reports.add(report)
        }
        
        print("###    there are now \(reports.count) reports")
        
        // Merge duplicate activities.
        
        let organizedActivities = self.fetchOrganizedActivities(user1)
        
        for i in 0 ..< organizedActivities.count - 1 {
            
            let a = organizedActivities[i]
            let b = organizedActivities[i + 1]
            
            if a.uniqueName == b.uniqueName {
                print("###    merging activities with the same uniqueName: \(a.uniqueName)")
                self.mergeActivity(a, with: b, user: user1)
            }
        }
        
        // Merge identically named activities.
        
        let orderedActivities = self.fetchOrderedActivities(user1)
        
        for i in 0 ..< orderedActivities.count - 1 {
            
            let a = orderedActivities[i]
            let b = orderedActivities[i + 1]
            
            if a.name == b.name {
                print("###      merging activities with the same name: \(a.name)")
                self.mergeActivity(a, with: b, user: user1)
            }
        }
        
        // Delete the newer user.
        self.context?.delete(user2)
    }
    
    func mergeActivity(_ activity1: Activity, with activity2: Activity, user: User) {
        
        print("###      mergeActivity \(activity1) --- \(activity2)")
        
        // Change activity for reports
        
        let reports = activity1.reports as! NSMutableSet
        
        print("###        there were \(reports.count) reports")
        
        for report in activity2.reports.allObjects as! [Report] {
            report.activity = activity1
            reports.add(report)
        }
        
        print("###        there are now \(reports.count) reports")
        
        // Merge duplicate reports
        
        let orderedReports = self.fetchOrganizedReportsForActivity(activity1, user: user)
        
        for i in 0 ..< orderedReports.count - 1 {
            
            let a = orderedReports[i]
            let b = orderedReports[i + 1]
            
            if a.uniqueName == b.uniqueName {
                print("###        merging reports with the same uniqueName: \(a.uniqueName)")
                self.mergeReport(a, with: b, user: user)
            }
        }
        
        // Delete the newer activity.
        self.context?.delete(activity2)
    }
    
    func mergeReport(_ report1: Report, with report2: Report, user: User) {
        
        print("###        mergeReport \(report1) --- \(report2)")
        
        // Change parent for breaks
        
        let breaks = report1.breaks as! NSMutableSet
        
        print("###          there were \(breaks.count) breaks")
        
        for abreak in report2.breaks.allObjects as! [Report] {
            abreak.parent = report1
            breaks.add(abreak)
        }
        
        print("###          there were \(breaks.count) breaks")
        
        // Merge duplicate breaks.
        
        let orderedBreaks = self.fetchOrganizedReportsForParent(report1, user: user)
        
        for i in 0 ..< orderedBreaks.count - 1 {
            
            let a = orderedBreaks[i]
            let b = orderedBreaks[i + 1]
            
            if a.uniqueName == b.uniqueName {
                print("###          merging breaks with the same uniqueName: \(a.uniqueName)")
                self.mergeReport(a, with: b, user: user)
            }
        }
        
        // Delete the newer report.
        self.context?.delete(report2)
    }
}
