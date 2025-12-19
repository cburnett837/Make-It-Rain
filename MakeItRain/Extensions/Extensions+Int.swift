//
//  Extensions+Int.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/24/25.
//

import Foundation


extension Int: @retroactive Identifiable {
    public var id: Int {
        return self
    }
}

extension Int {
    func withOrdinal() -> String {
        /// Number formatter in ``MakeItRainApp``
        let formatter = AppState.shared.numberFormatter
        formatter.numberStyle = .ordinal
        let first = formatter.string(from: NSNumber(value: self))
        return first ?? ""
    }
}


extension Optional where Wrapped == Int {
    var specialDefaultIfNil: Int {
        switch self {
        case let .some(wrapped): wrapped
        case .none: Int.max
        }
    }
}

