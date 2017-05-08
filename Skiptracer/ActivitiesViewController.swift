//
//  ActivitiesViewController.swift
//  Skiptracer
//
//  Created by Colin Caufield on 3/21/15.
//  Copyright (c) 2015 Secret Geometry, Inc. All rights reserved.
//

import UIKit
import CoreData
import SecretKit

class ActivitiesViewController: SGCoreDataTableViewController, UserObserver {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Notifications.shared.registerUserObserver(self)
    }
    
    override var typeName: String {
        return "Activity"
    }
    
    override var fetchPredicate: NSPredicate? {
        return AppData.shared.currentUserPredicate()
    }
    
    override var sortDescriptors: [NSSortDescriptor] {
        return AppData.shared.activitySortDescriptors()
    }
    
    override func cellIdentifierForObject(_ object: AnyObject) -> String {
        return "Activity"
    }
    
    override func createNewObject() -> AnyObject {
        let data = AppData.shared
        let user = data.settings.currentUser
        let name = data.nextAvailableName("Untitled", entityName: "Activity", predicate: nil)
        return data.createActivity(name, user: user)
    }
    
    override func configureCell(_ cell: UITableViewCell, withObject object: AnyObject) {
        let activity = object as? Activity
        if let name = activity?.name {
            cell.textLabel!.text = name
        }
    }
    
    override func didSelectObject(_ object: AnyObject, new: Bool = false) {
        let newController = self.storyboard?.instantiateViewController(withIdentifier: "Activity") as! ActivityViewController
        newController.showDoneButton = new
        newController.shouldAutoSelectNameField = new
        newController.object = object
        self.navigationController?.pushViewController(newController, animated: true)
    }
    
    override func canEditObject(_ object: AnyObject) -> Bool {
        if let activity = object as? Activity {
            return activity.permanent == false
        }
        return true
    }
    
    func userWasSwitched(_ note: Notification) {
        self.updateRequest()
    }
}
