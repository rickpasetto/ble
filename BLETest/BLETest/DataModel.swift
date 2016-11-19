//
//  DataModel.swift
//  BLETest
//
//  Created by Rick Pasetto on 11/18/16.
//  Copyright © 2016 Rick Pasetto. All rights reserved.
//

import Foundation

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

    init() {
        // Happy Birthday
        self.add(["birthday": Date().asString(), "id": myId, "name": "SF", "status": "0", "energyProduced": "0.0"])
    }

    private func asArray() -> [SolarFlare] {
        return items
            .sorted { $0.value["name"]! < $1.value["name"]!}
            .map { $0.value }
    }

    func me() -> SolarFlare {
        return items[myId]!
    }

    func add(_ item: SolarFlare) {
        items[item["id"]!] = item
    }

    func add(_ item: [String: Any]) {

        var dict: [String: String] = [:]
        for (key, value) in item {
            dict[key] = value as? String
        }
        self.add(dict)
    }

    func remove(_ item: SolarFlare) {
        if item["id"] != myId {
            items.removeValue(forKey: item["id"]!)
        }
    }

    var count: Int { return self.asArray().filter { $0["id"]! != myId }.count }

    subscript(index: Int) -> SolarFlare {
        let array = self.asArray().filter { $0["id"] != myId }
        return array[index]
    }

    func toJSON() -> Data? {

        return try? JSONSerialization.data(withJSONObject: self.asArray(), options: .prettyPrinted)
    }

    func mergeWith(data: Data) {

        if let json = try? JSONSerialization.jsonObject(with: data, options: [])  {
            if let json = json as? [[String: Any]] {
                for each in json {
                    self.add(each)
                }
            } else if let json = json as? [String: Any] {
                self.add(json)
            }
        }

    }
}
