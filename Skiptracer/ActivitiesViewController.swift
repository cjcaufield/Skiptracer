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
        let center = NSNotificationCenter.defaultCenter()
        center.addObserver(self, selector: "userWasSwitched:", name: UserWasSwitchedNotification, object: nil)
    }
    
    override var entityName: String { return "Activity" }
    
    override var fetchPredicate: NSPredicate? { return AppData.shared.currentUserPredicate() }
    
    override var sortDescriptors: [NSSortDescriptor] { return AppData.shared.activitySortDescriptors() }
    
    override func cellIdentifierForObject(object: AnyObject) -> String {
        return "Activity"
        UILayoutPriorityRequired
    }
    
    override func createNewObject() -> AnyObject {
        return AppData.shared.createActivity(nil, user: AppData.shared.settings.currentUser)
    }
    
    override func configureCell(cell: UITableViewCell, withObject object: AnyObject) {
        
        let activity = object as? Activity
        
        if let name = activity?.name {
            cell.textLabel!.text = name
        }
    }
    
    override func didSelectObject(object: AnyObject) {
        
        let newController = self.storyboard?.instantiateViewControllerWithIdentifier("Activity") as! ActivityViewController
        newController.activity = object as? Activity
        
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
