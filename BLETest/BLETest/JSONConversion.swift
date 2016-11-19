//
//  JSONConversion.swift
//  BLETest
//
//  Created by Rick Pasetto on 11/18/16.
//  Copyright © 2016 Rick Pasetto. All rights reserved.
//

import Foundation

protocol JSONRepresentable {
    var JSONRepresentation: AnyObject { get }
}

protocol JSONSerializable: JSONRepresentable {
}

extension JSONSerializable {
    var JSONRepresentation: AnyObject {
        var representation = [String: AnyObject]()

        for case let (label?, value) in Mirror(reflecting: self).children {
            switch value {
            case let value as JSONRepresentable:
                representation[label] = value.JSONRepresentation

            case let value as NSObject:
                representation[label] = value

            default:
                // Ignore any unserializable properties
                break
            }
        }

        return representation as AnyObject
    }
}

extension JSONSerializable {
    func toJSON() -> String? {
        let representation = JSONRepresentation

        guard JSONSerialization.isValidJSONObject(representation) else {
            return nil
        }

        do {
            let data = try JSONSerialization.data(withJSONObject: representation, options: [])
            return String(data: data, encoding: String.Encoding.utf8)
        } catch {
            return nil
        }
    }
}

extension Date: JSONRepresentable {
    var JSONRepresentation: AnyObject {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"

        return formatter.string(from: self) as AnyObject
    }
}

//extension Array: JSONSerializable {
//    func toJSON() -> String? {
//        do {
//
//            let json = try JSONSerialization.data(withJSONObject: self.map { $0.toJSON() }, options: .prettyPrinted)
//
//            return String(data: json, encoding: String.Encoding.utf8)
//        }
//        catch {
//            return nil
//        }
//
//    }
//}
