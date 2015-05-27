//
//  Data.swift
//  Skiptracer
//
//  Created by Colin Caufield on 4/1/15.
//  Copyright (c) 2015 Secret Geometry, Inc. All rights reserved.
//

import UIKit
import CoreData

private var _shared: Data? = nil

class Data: NSObject {
    
    var name = "Data"
    var useCloud = false
    
    class var shared: Data {
        assert(_shared != nil)
        return _shared!
    }
    
    init(name: String, useCloud: Bool) {
        super.init()
        assert(_shared == nil)
        _shared = self
        self.name = name
        self.useCloud = useCloud
        self.registerCloudStoreObserver(self)
        self.refreshProperties()
    }
    
    deinit {
        self.unregisterCloudStoreObserver(self)
    }
    
    var center: NSNotificationCenter {
        return NSNotificationCenter.defaultCenter()
    }
    
    func registerCloudStoreObserver(observer: AnyObject) {
        
        if !self.useCloud { return }
        
        self.center.addObserver(
            observer,
            selector: "cloudStoreWillChange:",
            name: NSPersistentStoreCoordinatorStoresWillChangeNotification,
            object: self.persistentStoreCoordinator)
        
        self.center.addObserver(
            observer,
            selector: "cloudStoreDidChange:",
            name: NSPersistentStoreCoordinatorStoresDidChangeNotification,
            object: self.persistentStoreCoordinator)
        
        self.center.addObserver(
            observer,
            selector: "cloudStoreDidImport:",
            name: NSPersistentStoreDidImportUbiquitousContentChangesNotification,
            object: self.persistentStoreCoordinator)
    }
    
    func unregisterCloudStoreObserver(observer: AnyObject) {
        
        if !self.useCloud { return }
        
        self.center.removeObserver(
            observer,
            name: NSPersistentStoreCoordinatorStoresWillChangeNotification,
            object: self.persistentStoreCoordinator)
        
        self.center.removeObserver(
            observer,
            name: NSPersistentStoreCoordinatorStoresDidChangeNotification,
            object: self.persistentStoreCoordinator)
        
        self.center.removeObserver(
            observer,
            name: NSPersistentStoreDidImportUbiquitousContentChangesNotification,
            object: self.persistentStoreCoordinator)
    }
    
    func registerCloudDataObserver(observer: AnyObject) {
        self.center.addObserver(
            observer,
            selector: "cloudDataDidChange:",
            name: CloudDataDidChangeNotification,
            object: nil)
    }
    
    func unregisterCloudDataObserver(observer: AnyObject) {
        self.center.removeObserver(
            observer,
            name: CloudDataDidChangeNotification,
            object: nil)
    }
    
    func cloudStoreWillChange(note: NSNotification) {
        
        println("Data.cloudStoreWillChange \(note)")
        //UIApplication.sharedApplication().beginIgnoringInteractionEvents()
        
        if let context = self.context {
            context.performBlockAndWait({
                if context.hasChanges {
                    self.save()
                } else {
                    context.reset()
                }
            })
        }
    }
    
    func cloudStoreDidChange(note: NSNotification) {
        
        println("Data.cloudStoreDidChange \(note)")
        
        if let context = self.context {
            context.performBlockAndWait({
                self.deduplicate()
                self.refreshProperties()
                self.center.postNotificationName(CloudDataDidChangeNotification, object: nil)
            })
        }
        
        // CJC revisit: make other VC refreshes happen before reenabling interaction.
        //UIApplication.sharedApplication().endIgnoringInteractionEvents()
    }
    
    func cloudStoreDidImport(note: NSNotification) {
        
        println("Data.cloudStoreDidImport \(note)")
        
        if let context = self.context {
            context.performBlockAndWait({
                context.mergeChangesFromContextDidSaveNotification(note)
                self.deduplicate()
                self.refreshProperties()
                self.center.postNotificationName(CloudDataDidChangeNotification, object: nil)
            })
        }
    }

    func insertNewObject(entityName: String) -> AnyObject {
        return NSEntityDescription.insertNewObjectForEntityForName(entityName, inManagedObjectContext: self.context!)
    }
    
    func uniqueDeviceString() -> String {
        let idiomName = (UIDevice.currentDevice().userInterfaceIdiom == .Phone) ? "iPhone" : "iPad"
        let deviceID = UIDevice.currentDevice().identifierForVendor.UUIDString
        return "\(idiomName) - \(deviceID)"
    }
    
    func refreshProperties() {
        // empty
    }
    
    func deduplicate() {
        // empty
    }
    
    func save() {
        
        println("*** SAVING")
        
        if let context = self.context {
            context.performBlockAndWait({
                var error: NSError? = nil
                if context.hasChanges && !context.save(&error) {
                    // CJC: Replace this with something shipable.
                    NSLog("Unresolved error \(error), \(error!.userInfo)")
                    //abort()
                }
            })
        }
            
        println("*** SAVED")
    }
    
    func fetchRequest(entityName: String, predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor] = []) -> NSFetchRequest {
        var request = NSFetchRequest(entityName: entityName)
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        return request
    }
    
    func fetchObject(request: NSFetchRequest) -> AnyObject? {
        return self.fetchObjects(request).first
    }
    
    func fetchObject(entityName: String, predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor] = []) -> AnyObject? {
        let request = self.fetchRequest(entityName, predicate: predicate, sortDescriptors: sortDescriptors)
        return self.fetchObject(request)
    }
    
    func fetchObjectNamed(name: String, entityName: String, predicate: NSPredicate? = nil) -> AnyObject? {
        let namePredicate = NSPredicate(format: "(name = %@)", name)
        let predicate = self.andPredicates([namePredicate, predicate])
        let request = self.fetchRequest(entityName, predicate: predicate)
        return self.fetchObject(request)
    }
    
    func fetchObjects(request: NSFetchRequest) -> [AnyObject] {
        var error: NSError? = nil
        let objects = self.context!.executeFetchRequest(request, error: &error)
        return objects ?? []
    }
    
    func fetchObjects(entityName: String, predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor] = []) -> [AnyObject] {
        let request = self.fetchRequest(entityName, predicate: predicate, sortDescriptors: sortDescriptors)
        return self.fetchObjects(request)
    }
    
    func nextAvailableName(desiredName: String, entityName: String, predicate: NSPredicate? = nil) -> String {
        
        var name = ""
        var index = 1
        var existingObject: AnyObject? = nil
        
        do {
            let suffix = (index == 1) ? "" : " " + String(index)
            name = desiredName + suffix
            existingObject = self.fetchObjectNamed(name, entityName: entityName, predicate: predicate) as AnyObject?
            index++
        }
        while existingObject != nil
        
        return name
    }
    
    func nullablePredicate(name: String, object: AnyObject?) -> NSPredicate {
        if object != nil {
            let format = "\(name) = %@"
            return NSPredicate(format: format, argumentArray: [object!])
        } else {
            let format = "\(name) = nil"
            return NSPredicate(format: format)
        }
    }
    
    func booleanPredicate(name: String, value: Bool) -> NSPredicate {
        if value {
            let format = "\(name) = true"
            return NSPredicate(format: format)
        } else {
            let format = "\(name) = false"
            return NSPredicate(format: format)
        }
    }
    
    func andPredicates(predicates: [NSPredicate?]) -> NSPredicate {
        
        var finalPredicate: NSPredicate?
        for possiblePredicate in predicates {
            if let predicate = possiblePredicate {
                if finalPredicate == nil {
                    finalPredicate = predicate
                } else {
                    finalPredicate = NSCompoundPredicate.andPredicateWithSubpredicates([finalPredicate!, predicate])
                }
            }
        }
        
        assert(finalPredicate != nil)
        return finalPredicate!
    }
    
    lazy var applicationDocumentsDirectory: NSURL = {
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count - 1] as! NSURL
    }()
    
    lazy var cloudDirectory: NSURL? = {
        return NSFileManager.defaultManager().URLForUbiquityContainerIdentifier(nil)
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        let modelURL = NSBundle.mainBundle().URLForResource(self.name, withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let filename = self.name + ".sqlite"
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent(filename)
        
        var error: NSError? = nil
        var failureReason = "There was an error creating or loading the application's saved data."
        
        var options = [NSObject: AnyObject]()
        
        options = [
            NSMigratePersistentStoresAutomaticallyOption: true,
            NSInferMappingModelAutomaticallyOption: true
        ]
        
        if self.useCloud {
            if let cloudDir = self.cloudDirectory {
                options[NSPersistentStoreUbiquitousContentNameKey] = self.name
            }
        }
        
        let store = coordinator!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: options, error: &error)
        
        if store == nil {
            
            coordinator = nil
            
            // Report any error.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            dict[NSUnderlyingErrorKey] = error
            error = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            
            // CJC: Replace this with something shipable.
            NSLog("Unresolved error \(error), \(error!.userInfo)")
            abort()
        }
        
        println("Persistent store url is \(store!.URL)")
        
        return coordinator
    }()
    
    lazy var context: NSManagedObjectContext? = {
        
        let coordinator = self.persistentStoreCoordinator
        if coordinator == nil {
            return nil
        }
        
        var context = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        return context
    }()
}
