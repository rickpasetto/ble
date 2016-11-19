//
//  FlareTableViewCell.swift
//  BLETest
//
//  Created by Rick Pasetto on 11/19/16.
//  Copyright © 2016 Rick Pasetto. All rights reserved.
//

import UIKit

class FlareTableViewCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var statusSwitch: UISwitch!
    @IBOutlet weak var energyLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func updateWith(flare: SolarFlare) {

        nameLabel?.text = flare["name"]! + ": "
        statusSwitch?.isOn = flare["status"]! == "1"
        energyLabel?.text = flare["energyProduced"]! + " Watts"
    }

}
