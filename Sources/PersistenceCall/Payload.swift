//
//  Payload.swift
//  CallablePersist
//
//  Created by Scott Lydon on 6/14/22.
//

import Foundation
import Callable
import CommonExtensions

public struct Payload<T: Codable>: Codable {
    var date: Date
    var value: T
    /// URLRequestHash, keeps the request anonymous.
    var hash: String
}

public extension Payload where T == Data {
    var jsonDictionary: [String: Any] {
        (try? value.jsonDictionary()) ?? [:]
    }
}
