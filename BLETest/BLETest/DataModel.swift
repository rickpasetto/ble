//
//  DataModel.swift
//  BLETest
//
//  Created by Rick Pasetto on 11/18/16.
//  Copyright © 2016 Rick Pasetto. All rights reserved.
//

import Foundation

struct SolarFlare: JSONSerializable {
    let birthday: Date
    let id: String
    var name: String
    var status: Int
    var energyProduced: Double

    static func from(dict: [String: Any]) -> SolarFlare {

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"

//        return SolarFlare(birthday: formatter.date(from: dict["birthday"]! )!,
//                          id: dict["id"]!,
//                          name: dict["name"]!,
//                          status: Int(dict["status"]!)!,
//                          energyProduced: Double(dict["energyProduced"]!)!)

        // TODO: OMG USE SWIFTYJSON!
        return SolarFlare(birthday: formatter.date(from: dict["birthday"] as! String )!,
                          id: dict["id"] as! String,
                          name: dict["name"] as! String,
                          status: Int(dict["status"]! as! String)!,
                          energyProduced: Double(dict["energyProduced"]! as! String)!)

    }

//    func toJSON() -> Data? {
//
//        let dict = ["birthday": "\(self.birthday.timeIntervalSince1970)",
//                    "id": self.id,
//                    "name": self.name,
//                    "status": "\(self.status)",
//                    "energyProduced": "\(self.energyProduced)"]
//
//        return try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
//    }
}

extension SolarFlare: Equatable {}
func ==(lhs: SolarFlare, rhs: SolarFlare) -> Bool {
    return lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.status == rhs.status &&
        lhs.energyProduced == rhs.energyProduced
}

typealias Id = String

class DataModel {

    let myId = UUID().uuidString

    fileprivate var items: [Id: SolarFlare] = [:]

    init() {
        // Happy Birthday
        self.add(SolarFlare(birthday: Date(), id: myId, name: "SF", status: 0, energyProduced: 0.0))
    }
    private func asArray() -> [SolarFlare] {
        return items
            .sorted { $0.value.name < $1.value.name}
            .map { $0.value }
    }

    func me() -> SolarFlare {
        return items[myId]!
    }

    func myJSON() -> String {
        return (items[myId]?.toJSON()!)!
    }

    func add(_ item: SolarFlare) {
        items[item.id] = item
    }

    func remove(_ item: SolarFlare) {
        if item.id != myId {
            items.removeValue(forKey: item.id)
        }
    }

    var count: Int { return self.asArray().filter { $0.id != myId }.count }

    subscript(index: Int) -> SolarFlare {
        let array = self.asArray().filter { $0.id != myId }
        return array[index]
    }

    func toJSON() -> Data? {
        
        let result = asArray().map { $0.toJSON() }

        return try? JSONSerialization.data(withJSONObject: result, options: .prettyPrinted)
    }

    func mergeWith(data: Data) {

        if let json = try? JSONSerialization.jsonObject(with: data, options: [])  {
            if let json = json as? [[String: Any]] {
                for each in json {
                    self.add(SolarFlare.from(dict: each))
                }
            } else if let json = json as? [String: Any] {
                self.add(SolarFlare.from(dict: json))
            }
        }

    }
}
