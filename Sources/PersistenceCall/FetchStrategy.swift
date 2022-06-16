//
//  FetchStrategy.swift
//  CallablePersist
//
//  Created by Scott Lydon on 6/14/22.
//

import Foundation
import Callable
import CommonExtensions

public enum FetchStrategy {
    case alwaysUseCacheIfAvailable
    case newCall
    case refreshAfter(timeInterval: TimeInterval)

    func tryCache(original: Date = Date(), current: Date = Date()) -> Bool {
        switch self {
        case .alwaysUseCacheIfAvailable: return true
        case .newCall: return false
        case .refreshAfter(let timeInterval):
            return abs(original.timeIntervalSince1970 - current.timeIntervalSince1970) > timeInterval
        }
    }
}
