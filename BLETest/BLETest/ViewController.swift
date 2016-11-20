//
//  ViewController.swift
//  BLETest
//
//  Created by Rick Pasetto on 11/17/16.
//  Copyright © 2016 Rick Pasetto. All rights reserved.
//

import UIKit
import BluetoothKit

// TODO: Dropping central

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, BKCentralDelegate,
BKRemotePeripheralDelegate, BKPeripheralDelegate, BKRemotePeerDelegate, BKAvailabilityObserver {

    let TimeoutToCentral = 5 // secs
    let TimeoutToPeripheral = 5 // secs
    let AckTimeout = 4 // secs

    var acksWaiting: [UUID : Timer] = [:]

    @IBOutlet weak var deviceName: UITextField!
    @IBOutlet weak var status: UISwitch!
    @IBOutlet weak var energyProduced: UILabel!
    @IBOutlet weak var energyProducedSlider: UISlider!
    @IBOutlet weak var totalEnergy: UILabel!
    @IBOutlet weak var itemsTableView: UITableView!

    @IBAction func sliderValueChanged(_ sender: UISlider) {
        let val = Double(trunc(energyProducedSlider.value))
        let valStr = "\(val)"
        energyProduced.text = valStr + " Watts"
    }

    @IBAction func sliderValueDone(_ sender: UISlider) {
        let val = Double(trunc(energyProducedSlider.value))
        let valStr = "\(val)"
        model.changeMyEnergy(valStr)
        sendUpdate()
        self.updateTotal()
    }

    @IBAction func statusValueChanged(_ sender: Any) {

        model.changeMyStatus(self.status!.isOn ? "1" : "0")
        sendUpdate()

    }

    let tableViewCellIdentifier = "SolClients"

    fileprivate var timer: Timer?
    fileprivate var peripheral: BKPeripheral? = BKPeripheral()
    fileprivate let central = BKCentral()
    fileprivate var discoveries = [BKDiscovery]()

    fileprivate var model = DataModel()

    override func viewDidLoad() {
        super.viewDidLoad()
//        itemsTableView.register(FlareTableViewCell.self, forCellReuseIdentifier: tableViewCellIdentifier)
//        itemsTableView.dataSource = self
//        itemsTableView.delegate = self

        deviceName.text = model.me()["name"]
        deviceName.addTarget(self, action: #selector(ViewController.nameFieldDidChange), for: UIControlEvents.editingDidEndOnExit)

        self.updateTotal()

        startAsPeripheral()
    }

    @objc private func nameFieldDidChange() {
        model.changeMyName(deviceName.text!)
        sendUpdate()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    internal func startAsPeripheral() {

        do {
            peripheral?.delegate = self
            peripheral?.addAvailabilityObserver(self)
            let serviceUUID = UUID(uuidString: "6E6B5C64-FAF7-40AE-9C21-D4933AF45B23")!
            let characteristicUUID = UUID(uuidString: "477A2967-1FAB-4DC5-920A-DEE5DE685A3D")!
            let localName = model.myId
            let configuration = BKPeripheralConfiguration(dataServiceUUID: serviceUUID, dataServiceCharacteristicUUID: characteristicUUID, localName: localName)
            try peripheral?.startWithConfiguration(configuration)

            print("Starting as Peripheral, Looking for a Central")

            if #available(iOS 10.0, *) {
                timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(TimeoutToCentral), repeats: false, block: {_ in
                    print("No Central found, switching to Central")
                    self.switchToCentral()
                })
            } else {
                // Fallback on earlier versions
            }
        } catch _ {
            // Handle error.
        }
    }

    internal func switchToCentral() {
        let _ = try? peripheral?.stop()

        peripheral?.delegate = nil
        peripheral = nil

        startAsCentral()
    }

    internal func startAsCentral() {
        do {
            central.delegate = self
            central.addAvailabilityObserver(self)
            let serviceUUID = UUID(uuidString: "6E6B5C64-FAF7-40AE-9C21-D4933AF45B23")!
            let characteristicUUID = UUID(uuidString: "477A2967-1FAB-4DC5-920A-DEE5DE685A3D")!
            let localName = model.myId
            let configuration = BKPeripheralConfiguration(dataServiceUUID: serviceUUID, dataServiceCharacteristicUUID:  characteristicUUID, localName: localName)
            try central.startWithConfiguration(configuration)

            print("Starting as Central, Looking for a Peripheral")

            deviceName.textColor = UIColor.blue

//            if #available(iOS 10.0, *) {
//                timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(TimeoutToPeripheral), repeats: false, block: {_ in
//                    print("No Peripheral found, switching to Peripheral")
//                    self.switchToPeripheral()
//                })
//            } else {
//                // Fallback on earlier versions
//            }

        } catch _ {

        }
    }

    internal func switchToPeripheral() {
        let _ = try? central.stop()

        startAsPeripheral()
    }


    fileprivate func scan() {
        central.scanContinuouslyWithChangeHandler({ changes, discoveries in

//            print("changes: \(changes), discoveries: \(discoveries)")
//
            for discovery in discoveries {
                self.central.connect(remotePeripheral: discovery.remotePeripheral) { remotePeripheral, error in
//                    print("Connected to \(remotePeripheral.name)")
//                    self.timer?.invalidate()
                    remotePeripheral.delegate = self
                    remotePeripheral.peripheralDelegate = self
                }
            }
            self.discoveries = discoveries

//            for lost in changes.filter({ $0 == .remove(discovery: nil) }) {
//                print("Lost \(lost.discovery.localName)!")
//                self.model.remove( id: lost.discovery.remotePeripheral.identifier.uuidString )
//            }

//            let indexPathsToRemove = changes.filter({ $0 == .remove(discovery: nil) }).map({ IndexPath(row: self.discoveries.index(of: $0.discovery)!, section: 0) })
//            let indexPathsToInsert = changes.filter({ $0 == .insert(discovery: nil) }).map({ IndexPath(row: self.discoveries.index(of: $0.discovery)!, section: 0) })
//            if !indexPathsToRemove.isEmpty {
//                self.itemsTableView.deleteRows(at: indexPathsToRemove, with: UITableViewRowAnimation.automatic)
//            }
//            if !indexPathsToInsert.isEmpty {
//                self.itemsTableView.insertRows(at: indexPathsToInsert, with: UITableViewRowAnimation.automatic)
//            }
//            for insertedDiscovery in changes.filter({ $0 == .insert(discovery: nil) }) {
//                print("Discovery: \(insertedDiscovery)")
//            }

        }, stateHandler: { newState in
            if newState == .scanning {
//                self.activityIndicator?.startAnimating()
                return
            } else if newState == .stopped {
//                self.discoveries.removeAll()
//                self.discoveriesTableView.reloadData()
            }
//            self.activityIndicator?.stopAnimating()
        }, errorHandler: { error in
//            print("Error from scanning: \(error)")
        })
    }

    // MARK: BKPeripheralDelegate

    internal func peripheral(_ peripheral: BKPeripheral, remoteCentralDidConnect remoteCentral: BKRemoteCentral) {
        print("Remote central did connect: \(remoteCentral)")
        timer?.invalidate()
        remoteCentral.delegate = self

//
//        if let data = model.toJSON() {
//
//            peripheral.sendData(data, toRemotePeer: remoteCentral) { data, remoteCentral, error in
//                guard error == nil else {
//                    print("Failed sending to \(remoteCentral)")
//                    return
//                }
//                print("Sent \(String(data: data, encoding: .utf8)) to \(remoteCentral)")
//            }
//        }

        sendUpdate()
    }

    internal func peripheral(_ peripheral: BKPeripheral, remoteCentralDidDisconnect remoteCentral: BKRemoteCentral) {
        print("Remote central did disconnect: \(remoteCentral)")

        
    }

    // MARK: BKRemotePeerDelegate

    func remotePeer(_ remotePeer: BKRemotePeer, didSendArbitraryData data: Data) {

        if isCentral() && String(data: data, encoding: .utf8) == "ACK" {
            print("GOT ACK from \(self.model.associatedId(bluetoothId: remotePeer.identifier))")
            acksWaiting[remotePeer.identifier]?.invalidate()
            acksWaiting[remotePeer.identifier] = nil
            return
        }

        if let array = dataToArray(data) {
            print("Received data \(data): " + debugDataStr(data))

            self.model.mergeWith(data: data, clearFirst: !isCentral())

            let other = array[0]
            print("Peer: \(other): bluetoothId: \(remotePeer.identifier)")
            self.model.associate(id: other["id"]! as! Id, bluetoothId: remotePeer.identifier)

            self.updateUI()

            if isCentral() {
                sendUpdate()
            } else {
                self.peripheral?.sendData("ACK".data(using: .utf8)!, toRemotePeer: remotePeer) { _ in
                    print("SENT ACK")
                }
            }
        }
    }

    private func updateUI() {
        self.itemsTableView.reloadData()
        self.updateTotal()
    }

    private func isCentral() -> Bool {
        return peripheral == nil
    }

    public func central(_ central: BKCentral, remotePeripheralDidConnect remotePeripheral: BKRemotePeripheral) {
        print("Remote peripheral did connect: \(remotePeripheral.name!) (\(remotePeripheral.identifier.uuidString))")
    }

    
    public func central(_ central: BKCentral, remotePeripheralDidDisconnect remotePeripheral: BKRemotePeripheral) {

        remotePeripheral.delegate = nil

        model.remove(id: remotePeripheral.identifier)

        print("Remote \(remotePeripheral.name!) (\(remotePeripheral.identifier.uuidString)) disconnected: now have \(model.count) remotes")

        self.updateUI()
        sendUpdate()
    }

    private func sendUpdate() {
        if let peripheral = peripheral {
            broadcastUpdateTo(from: peripheral, to: peripheral.connectedRemoteCentrals)
        } else {
            broadcastUpdateTo(from: central, to: central.connectedRemotePeripherals)
        }
    }

    private func broadcastUpdateTo(from: BKPeer, to: [BKRemotePeer]) {
        if let data = model.toJSON() {

            for remote in to {

                from.sendData(data, toRemotePeer: remote) { data, remote, error in
                    guard error == nil else {
                        print("Failed sending to \(remote)")
                        return
                    }
                    print("Sent data: \(self.debugDataStr(data)) to \(self.model.associatedId(bluetoothId: remote.identifier))")

                    if self.isCentral() {
                        if #available(iOS 10.0, *) {
                            self.acksWaiting[remote.identifier] = Timer.scheduledTimer(
                                withTimeInterval: TimeInterval(self.AckTimeout),
                                repeats: true, block: { _ in
                                    if self.acksWaiting[remote.identifier] != nil {
                                        print("TRYING AGAIN to \(self.model.associatedId(bluetoothId: remote.identifier))")
                                        self.central.sendData(data, toRemotePeer: remote, completionHandler: nil)
                                    }
                            })
                        } else {
                            // Fallback on earlier versions
                        }

                    }
                }
            }
        }
    }

    private func debugDataStr(_ data: Data) -> String {
//        return String(data: data, encoding: .utf8)

        return "\(dataToArray(data))"
    }

    /**
     Informs the observer about a change in Bluetooth LE availability.
     - parameter availabilityObservable: The object that registered the availability change.
     - parameter availability: The new availability value.
     */
    public func availabilityObserver(_ availabilityObservable: BKAvailabilityObservable, availabilityDidChange availability: BKAvailability) {
//        availabilityView.availabilityObserver(availabilityObservable, availabilityDidChange: availability)
        if availability == .available {
            scan()
        } else {
            central.interruptScan()
        }
    }

    /**
     Informs the observer that the cause of Bluetooth LE unavailability changed.
     - parameter availabilityObservable: The object that registered the cause change.
     - parameter unavailabilityCause: The new cause of unavailability.
     */
    public func availabilityObserver(_ availabilityObservable: BKAvailabilityObservable, unavailabilityCauseDidChange unavailabilityCause: BKUnavailabilityCause) {

    }

    // MARK: RemotePeripheralDelegate

    public func remotePeripheral(_ remotePeripheral: BKRemotePeripheral, didUpdateName name: String) {

    }
    
    /**
     Called when services and charateristic are discovered and the device is ready for send/receive
     - parameter remotePeripheral: The remote peripheral that is ready.
     */
    public func remotePeripheralIsReady(_ remotePeripheral: BKRemotePeripheral) {

        print("Remote peripheral is ready: \(remotePeripheral.name!) (\(remotePeripheral.identifier.uuidString))")
        sendUpdate()
    }

    // MARK: UITableViewDataSource

    internal func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return discoveries.count

        return model.count

    }

    internal func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Other Devices:"
    }

    internal func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let baseCell = tableView.dequeueReusableCell(withIdentifier: tableViewCellIdentifier, for: indexPath)

        if let cell = baseCell as? FlareTableViewCell {
            cell.updateWith(flare: model[indexPath.row])
            return cell
        }
        else {
//        let discovery = discoveries[indexPath.row]

            baseCell.textLabel?.text = model[indexPath.row]["name"]! +
                ": " + model[indexPath.row]["status"]! +
                ": " + model[indexPath.row]["energyProduced"]!
        }
        return baseCell
    }

    private func updateTotal() {

        self.totalEnergy.text = "\(model.total) Watts"
    }

}

