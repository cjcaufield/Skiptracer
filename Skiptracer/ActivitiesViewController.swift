//
//  ActivitiesViewController.swift
//  Skiptracer
//
//  Created by Colin Caufield on 3/21/15.
//  Copyright (c) 2015 Secret Geometry, Inc. All rights reserved.
//

import UIKit
import CoreData

class ActivitiesViewController: SGCoreDataTableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Notifications.shared.registerUserObserver(self)
    }
    
    override var entityName: String {
        return "Activity"
    }
    
    override var fetchPredicate: NSPredicate? {
        return AppData.shared.currentUserPredicate()
    }
    
    override var sortDescriptors: [NSSortDescriptor] {
        return AppData.shared.activitySortDescriptors()
    }
    
    override func cellIdentifierForObject(object: AnyObject) -> String {
        return "Activity"
    }
    
    override func createNewObject() -> NSManagedObject {
        let data = AppData.shared
        let user = data.settings.currentUser
        let name = data.nextAvailableName("Untitled", entityName: "Activity", predicate: nil)
        return data.createActivity(name, user: user)
    }
    
    override func configureCell(cell: UITableViewCell, withObject object: AnyObject) {
        let activity = object as? Activity
        if let name = activity?.name {
            cell.textLabel!.text = name
        }
    }
    
    override func didSelectObject(object: AnyObject, new: Bool = false) {
        let newController = self.storyboard?.instantiateViewControllerWithIdentifier("Activity") as! ActivityViewController
        newController.showDoneButton = new
        newController.object = object
        self.navigationController?.pushViewController(newController, animated: true)
    }
    
    override func canEditObject(object: AnyObject) -> Bool {
        if let activity = object as? Activity {
            return activity.permanent == false
        }
        return true
    }
    
    func userWasSwitched(note: NSNotification) {
        self.updateRequest()
    }
}
