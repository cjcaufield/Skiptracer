//
//  CustomTableViewCell.swift
//  Skiptracer
//
//  Created by Colin Caufield on 4/4/15.
//  Copyright (c) 2015 Secret Geometry, Inc. All rights reserved.
//

import UIKit

class CustomTableViewCell: UITableViewCell {

    override func layoutSubviews() {
        super.layoutSubviews()
        if self.contentView.respondsToSelector("setPreservesSuperviewLayoutMargins:") {
            self.contentView.preservesSuperviewLayoutMargins = true;
        }
    }
}
