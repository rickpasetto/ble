//
//  DataModel.swift
//  BLETest
//
//  Created by Rick Pasetto on 11/18/16.
//  Copyright © 2016 Rick Pasetto. All rights reserved.
//

import Foundation
import UIKit

//struct SolarFlare: JSONSerializable {
//    let birthday: Date
//    let id: String
//    var name: String
//    var status: Int
//    var energyProduced: Double
//
//    static func from(dict: [String: Any]) -> SolarFlare {
//
//        let formatter = DateFormatter()
//        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
//
////        return SolarFlare(birthday: formatter.date(from: dict["birthday"]! )!,
////                          id: dict["id"]!,
////                          name: dict["name"]!,
////                          status: Int(dict["status"]!)!,
////                          energyProduced: Double(dict["energyProduced"]!)!)
//
//        // TODO: OMG USE SWIFTYJSON!
//        return SolarFlare(birthday: formatter.date(from: dict["birthday"] as! String )!,
//                          id: dict["id"] as! String,
//                          name: dict["name"] as! String,
//                          status: Int(dict["status"]! as! String)!,
//                          energyProduced: Double(dict["energyProduced"]! as! String)!)
//
//    }
//
////    func toJSON() -> Data? {
////
////        let dict = ["birthday": "\(self.birthday.timeIntervalSince1970)",
////                    "id": self.id,
////                    "name": self.name,
////                    "status": "\(self.status)",
////                    "energyProduced": "\(self.energyProduced)"]
////
////        return try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
////    }
//}

//extension SolarFlare: Equatable {}
//func ==(lhs: SolarFlare, rhs: SolarFlare) -> Bool {
//    return lhs.id == rhs.id &&
//        lhs.name == rhs.name &&
//        lhs.status == rhs.status &&
//        lhs.energyProduced == rhs.energyProduced
//}

typealias SolarFlare = [String: String]

typealias Id = String

extension Date {

    func asString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"

        return formatter.string(from: self)
    }

    static func fromString(str: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"

        return formatter.date(from: str)
    }

}

class DataModel {

    let myId = UUID().uuidString

    fileprivate var items: [Id: SolarFlare] = [:]

    fileprivate var myName: String {
//        return "Flare-" + myId.substring(to: myId.index(myId.startIndex, offsetBy: 4))
        return UIDevice.current.name
    }

    init() {
        // Happy Birthday
        self.add([//"birthday": Date().asString(),
                  "id": myId,
                  "bluetoothId": "",
                  "name": myName,
                  "status": "1",
                  "energyProduced": "0.0"])
    }

    private func asArray() -> [SolarFlare] {
        return synchronize(self) {
            var result: [SolarFlare] = []
            result.append(me())
            result.append(contentsOf: items
                .filter { $0.key != myId }
                .map { $0.value }
                .sorted { $0["name"]! > $1["name"]! }
            )
            return result
        }
    }

    func me() -> SolarFlare {
        return synchronize(self) {
            return items[myId]!
        }
    }

    func changeMyName(_ name: String) {
        synchronize(self) {
            items[myId]!["name"] = name
        }
    }

    func changeMyEnergy(_ energy: String) {
        synchronize(self) {
            items[myId]!["energyProduced"] = energy
        }
    }

    func changeMyStatus(_ status: String) {
        synchronize(self) {
            items[myId]!["status"] = status
        }
    }

    func associate(id: Id, bluetoothId: UUID) {
        synchronize(self) {
            items[id]?["bluetoothId"] = bluetoothId.uuidString
        }
    }

    func associatedId(bluetoothId: UUID) -> String? {
        return synchronize(self) {
            for (_, value) in items {
                if value["bluetoothId"] == bluetoothId.uuidString {
                    return value["id"]
                }
            }
            return nil
        }
    }

    func associatedName(bluetoothId: UUID) -> String? {
        return synchronize(self) {
            for (_, value) in items {
                if value["bluetoothId"] == bluetoothId.uuidString {
                    return value["name"]
                }
            }
            return nil
        }
    }

    func add(_ item: SolarFlare) {
        synchronize(self) {
            items[item["id"]!] = item
        }
    }

    func add(_ item: [String: Any]) {
        synchronize(self) {
            var dict: [String: String] = [:]
            for (key, value) in item {
                dict[key] = value as? String
            }
            self.add(dict)
        }
    }

    func remove(id: UUID) {
        synchronize(self) {
            for (key, value) in items {
                if value["bluetoothId"] == id.uuidString {
                    items.removeValue(forKey: key)
                    return
                }
            }
        }
    }

    var total: Double {

        return self.asArray().reduce( 0.0, { $0 + Double($1["energyProduced"]!)! } )
    }

    var count: Int { return self.asArray().filter { $0["id"]! != myId }.count }

    subscript(index: Int) -> SolarFlare {
        let array = self.asArray()
            .filter { $0["id"] != myId }

        return array[index]
    }

    func toJSON() -> Data? {

        return try? JSONSerialization.data(withJSONObject: self.asArray(), options: [])
    }

    func mergeWith(data: Data, clearFirst: Bool) {
        synchronize(self) {
            if clearFirst {
                let me = self.me()
                items.removeAll()
                self.add(me)
            }

            if let json = dataToArray(data) {
                for each in json {
                    if each["id"] as? String != self.myId {
                        self.add(each)
                    }
                }
            }
        }
    }
}

func dataToArray(_ data: Data) -> [[String: Any]]? {
    if let json = try? JSONSerialization.jsonObject(with: data, options: [])  {
        if let json = json as? [[String: Any]] {
            return json
        }
        if let json = json as? [String: Any] {
            return [json]
        }
    }
    print("\n********\nCOULD NOT PARSE DATA!\n\(String(data: data, encoding: .utf8))\n********\n")
    return nil
}

func synchronize<T>(_ lockObj: AnyObject!, closure: ()->T) -> T
{
    objc_sync_enter(lockObj)
    let retVal: T = closure()
    objc_sync_exit(lockObj)
    return retVal
}

