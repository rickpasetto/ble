//
//  ViewController.swift
//  BLETest
//
//  Created by Rick Pasetto on 11/17/16.
//  Copyright © 2016 Rick Pasetto. All rights reserved.
//

import UIKit
//import BluetoothKit

class ViewController: UIViewController {


    @IBOutlet weak var deviceName: UITextField!
    @IBOutlet weak var status: UISwitch!
    @IBOutlet weak var energyProduced: UILabel!
    @IBOutlet weak var energyProducedSlider: UISlider!
    @IBOutlet weak var totalEnergy: UILabel!

    @IBAction func sliderValueChanged(_ sender: UISlider) {
        energyProduced.text = "\(trunc(energyProducedSlider.value))"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

//        let peripheral = BKPeripheral()
//        peripheral.delegate = self
//        do {
//            let serviceUUID = UUID(uuidString: "6E6B5C64-FAF7-40AE-9C21-D4933AF45B23")!
//            let characteristicUUID = UUID(uuidString: "477A2967-1FAB-4DC5-920A-DEE5DE685A3D")!
//            let localName = "My Cool Peripheral"
//            let configuration = BKPeripheralConfiguration(dataServiceUUID: serviceUUID, dataServiceCharacteristicUUID:  characteristicUUID, localName: localName)
//            try peripheral.startWithConfiguration(configuration)
//            // You are now ready for incoming connections
//        } catch let error {
//            // Handle error.
//        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

