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

class AppData: NSObject {
    
    var settings: Settings!
    var basicUser: User!
    var testUser: User!
    
    class var shared: AppData {
        
        if _shared == nil {
            _shared = AppData()
        }
        
        return _shared!
    }
    
    override init() {
        
        super.init()
        
        self.settings = self.fetchSettings() ?? self.createSettings()
        self.basicUser = self.fetchUser() ?? self.createUser()
        self.testUser = self.fetchUser(testUser: true) ?? self.createUser(testUser: true)
        
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
        
        self.save()
    }
    
    func insertNewObject(entityName: String) -> AnyObject {
        return NSEntityDescription.insertNewObjectForEntityForName(entityName, inManagedObjectContext: self.managedObjectContext!)
    }
    
    func createSettings() -> Settings {
        var settings = self.insertNewObject("Settings") as! Settings
        return settings
    }
    
    func createUser(testUser: Bool = false) -> User {
        var user = self.insertNewObject("User") as! User
        user.isTestUser = testUser
        return user
    }
    
    func createActivity(name: String?, user: User?) -> Activity {
        var activity = self.insertNewObject("Activity") as! Activity
        if name != nil {
            activity.name = name!
        }
        activity.user = user
        return activity
    }
    
    func createReport(activity: Activity?, parent: Report?, user: User?, active: Bool, isBreak: Bool) -> Report {
        var report = self.insertNewObject("Report") as! Report
        report.active = active
        report.isBreak = isBreak
        report.parent = parent
        report.activity = activity
        report.startDate = NSDate()
        report.endDate = NSDate()
        report.user = user
        return report
    }
    
    func createReport(activity: Activity?, user: User?, active: Bool) -> Report {
        return createReport(activity, parent: nil, user: user, active: active, isBreak: false)
    }
    
    func createBreak(parent: Report?, user: User?, active: Bool) -> Report {
        return createReport(nil, parent: parent, user: user, active: active, isBreak: true)
    }
    
    func save() {
        if let moc = self.managedObjectContext {
            var error: NSError? = nil
            if moc.hasChanges && !moc.save(&error) {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                NSLog("Unresolved error \(error), \(error!.userInfo)")
                abort()
            }
        }
    }
    
    func fetchSettings() -> Settings? {
        
        var request = NSFetchRequest(entityName: "Settings")
        request.sortDescriptors = []
        
        var error: NSError? = nil
        var possibleSettings = self.managedObjectContext!.executeFetchRequest(request, error: &error)
        
        if let settings = possibleSettings {
            if settings.count > 0 {
                return settings[0] as? Settings
            }
        }
        
        return nil
    }
    
    func fetchUser(testUser: Bool = false) -> User? {
        
        var request = NSFetchRequest(entityName: "User")
        request.predicate = NSPredicate(format: "isTestUser == %d", Int(testUser))
        request.sortDescriptors = []
        
        var error: NSError? = nil
        var possibleUsers = self.managedObjectContext!.executeFetchRequest(request, error: &error)
        
        if let users = possibleUsers {
            if users.count > 0 {
                return users[0] as? User
            }
        }
        
        return nil
    }
    
    func fetchOrderedActivities() -> [Activity] {
        
        let request = self.orderedActivitiesRequest()
        
        var error: NSError? = nil
        var possibleActivities = self.managedObjectContext!.executeFetchRequest(request, error: &error)
        
        if let activities = possibleActivities {
            return activities as! [Activity]
        }
        
        return []
    }
    
    func orderedActivitiesRequest() -> NSFetchRequest {
        var request = NSFetchRequest(entityName: "Activity")
        request.sortDescriptors = self.activitySortDescriptors()
        request.predicate = self.currentUserPredicate()
        return request
    }
    
    func activitySortDescriptors() -> [NSSortDescriptor] {
        return [NSSortDescriptor(key: "permanent", ascending: false), NSSortDescriptor(key: "name", ascending: true)]
    }
    
    func userPredicate(testUser: Bool = false) -> NSPredicate {
        let user = testUser ? self.testUser : self.basicUser
        return NSPredicate(format: "user = %@", user)
    }
    
    func currentUserPredicate() -> NSPredicate {
        return self.userPredicate(testUser: self.settings.enableTestUser)
    }
    
    func parentReportPredicate(parent: Report?)-> NSPredicate {
        if parent != nil {
            return NSPredicate(format: "parent = %@", parent!)
        } else {
            return NSPredicate(format: "parent = nil")
        }
    }
    
    lazy var applicationDocumentsDirectory: NSURL = {
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count - 1] as! NSURL
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        let modelURL = NSBundle.mainBundle().URLForResource("Skiptracer", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("Skiptracer.sqlite")
        
        var error: NSError? = nil
        var failureReason = "There was an error creating or loading the application's saved data."
        
        if coordinator!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil, error: &error) == nil {
            
            coordinator = nil
            
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            dict[NSUnderlyingErrorKey] = error
            error = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(error), \(error!.userInfo)")
            abort()
        }
        
        return coordinator
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext? = {
        let coordinator = self.persistentStoreCoordinator
        if coordinator == nil {
            return nil
        }
        var managedObjectContext = NSManagedObjectContext()
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
}
