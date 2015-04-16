//
//  SGViewController.swift
//  Skiptracer
//
//  Created by Colin Caufield on 4/4/15.
//  Copyright (c) 2015 Secret Geometry, Inc. All rights reserved.
//

import UIKit

class SGViewController: UIViewController {

    var timer: NSTimer?
    var timerInterval = 1.0
    var shouldUseTimer = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.addObservers()
    }
    
    override func viewWillAppear(animated: Bool) {
        if self.shouldUseTimer {
            self.createTimer()
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        if self.shouldUseTimer {
            self.destroyTimer()
        }
    }
    
    func addObservers() {
        
    }
    
    func removeObservers() {
        
    }
    
    func createTimer() {
        self.timer = NSTimer.scheduledTimerWithTimeInterval(self.timerInterval, target: self, selector: "timerUpdate", userInfo: nil, repeats: true)
    }
    
    func destroyTimer() {
        self.timer?.invalidate()
        self.timer = nil
    }
    
    func timerUpdate() {
        
    }
}
