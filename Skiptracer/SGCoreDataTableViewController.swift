//
//  SGCoreDataTableViewController.swift
//  Skiptracer
//
//  Created by Colin Caufield on 4/1/15.
//  Copyright (c) 2015 Secret Geometry, Inc. All rights reserved.
//

import UIKit
import CoreData

class SGCoreDataTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.leftBarButtonItem = self.editButtonItem()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "add:")
    }
    
    // MARK: - Methods to override.
    
    var fetchPredicate: NSPredicate? { return nil }
    
    var fetchBatchSize: Int { return 20 }
    
    var sortDescriptors: [NSSortDescriptor] { return [] }
    
    var sectionKey: String? { return nil }
    
    var headerHeight: CGFloat { return 0.0 }
    
    var cacheName: String? { return nil }
    
    var entityName: String {
        assertionFailure("entityName must be overridden in SGCoreDataTableViewController subclasses.")
        return ""
    }
    
    func cellIdentifierForObject(object: AnyObject) -> String {
        assertionFailure("cellIdentifierForObject must be overridden in SGCoreDataTableViewController subclasses.")
        return ""
    }
    
    func createNewObject() -> AnyObject {
        return NSEntityDescription.insertNewObjectForEntityForName(self.entityName, inManagedObjectContext: self.context!)
    }
    
    func prepareNewObject(object: AnyObject) {
        // nothing
    }
    
    func configureCell(cell: UITableViewCell, withObject object: AnyObject) {
        // nothing
    }
    
    func didSelectObject(object: AnyObject) {
        // nothing
    }
    
    func canEditObject(object: AnyObject) -> Bool {
        return true
    }
    
    // MARK: - UITableViewController
    
    @IBAction func add(sender: AnyObject?) {
        
        let object: AnyObject = self.createNewObject()
        self.prepareNewObject(object)
        
        if self.autoSelectAddedObjects {
            self.didSelectObject(object)
        }
        
        AppData.shared.save()
    }
    
    @IBAction func edit(sender: AnyObject?) {
        self.tableView.setEditing(!self.tableView.editing, animated: true)
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.fetchController.sections?.count ?? 0
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return self.headerHeight
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionInfo = self.fetchController.sections![section] as! NSFetchedResultsSectionInfo
        return sectionInfo.name
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = self.fetchController.sections![section] as! NSFetchedResultsSectionInfo
        return sectionInfo.numberOfObjects
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let object: AnyObject = self.fetchController.objectAtIndexPath(indexPath)
        let identifier = self.cellIdentifierForObject(object)
        let cell = tableView.dequeueReusableCellWithIdentifier(identifier, forIndexPath: indexPath) as! UITableViewCell
        self.configureCell(cell, withObject: object)
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let object: AnyObject = self.fetchController.objectAtIndexPath(indexPath)
        self.didSelectObject(object)
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        let object: AnyObject = self.fetchController.objectAtIndexPath(indexPath)
        return self.canEditObject(object)
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let object = self.fetchController.objectAtIndexPath(indexPath) as! NSManagedObject
            self.context!.deleteObject(object)
            AppData.shared.save()
        }
    }
    
    // MARK: - NSFetchedResultsController
    
    var fetchController: NSFetchedResultsController {
        
        if self.fetchedResultsController != nil {
            return self.fetchedResultsController!
        }
        
        var request = NSFetchRequest(entityName: self.entityName)
        self.configureRequest(request)
        
        self.fetchedResultsController = NSFetchedResultsController(fetchRequest: request,
                                                           managedObjectContext: self.context!,
                                                             sectionNameKeyPath: self.sectionKey,
                                                                      cacheName: self.cacheName)
        self.fetchedResultsController?.delegate = self
        
        self.refreshData()
        
        return self.fetchedResultsController!
    }
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        self.tableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        
        switch type {
        case .Insert:
            self.tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        case .Delete:
            self.tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        default:
            return
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        switch type {
        case .Insert:
            self.tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
            self.pathToScrollTo = newIndexPath!
        case .Delete:
            self.tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
        case .Update:
            if let cell = tableView.cellForRowAtIndexPath(indexPath!) {
                self.configureCell(cell, withObject: anObject)
            }
        case .Move:
            self.tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            self.tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        default:
            return
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
        self.tableView.endUpdates()
        
        if let path = self.pathToScrollTo {
            self.tableView.scrollToRowAtIndexPath(path, atScrollPosition: .Bottom, animated: true)
        }
        
        self.pathToScrollTo = nil
    }
    
    var context: NSManagedObjectContext? {
        return AppData.shared.managedObjectContext
    }
    
    func updateRequest() {
        NSFetchedResultsController.deleteCacheWithName(self.cacheName)
        self.configureRequest(self.fetchController.fetchRequest)
        self.refreshData()
    }
    
    func configureRequest(request: NSFetchRequest) {
        request.predicate = self.fetchPredicate
        request.fetchBatchSize = self.fetchBatchSize
        request.sortDescriptors = self.sortDescriptors
    }
    
    func refreshData() {
        var error: NSError?
        self.fetchController.performFetch(&error)
        self.tableView.reloadData()
    }
    
    var fetchedResultsController: NSFetchedResultsController?
    var pathToScrollTo: NSIndexPath?
    var autoSelectAddedObjects = true
}
