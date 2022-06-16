//
//  URL.swift
//  CallablePersist
//
//  Created by Scott Lydon on 6/15/22.
//

import Foundation

public extension URL {

    var fileHandleData: Data? {
        try? FileHandle(forReadingFrom: self).availableData
    }
}
