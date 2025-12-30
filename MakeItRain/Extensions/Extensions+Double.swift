//
//  Extentions+Double.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/24/25.
//

import Foundation

extension Double {
    var isWholeNumber: Bool {
        return self.isZero || (self.isNormal && self.exponent >= 0)
    }
    
    var isNegative: Bool {
        return self.sign == .minus
    }
    
    var kVersion: String {
        let num = abs(self)
        let sign = self < 0 ? "-" : ""
        
        switch num {
        case 1_000_000_000...:
            return String(format: "\(sign)%.1fB", num / 1_000_000_000)
        case 1_000_000...:
            return String(format: "\(sign)%.1fM", num / 1_000_000)
        case 1_000...:
            return String(format: "\(sign)%.1fK", num / 1_000)
        default:
            return "\(self)"
        }
    }
    
    func currencyWithDecimals(_ decimals: Int = AppSettings.shared.useWholeNumbers ? 0 : 2) -> String {
        let formatter = AppState.shared.numberFormatter
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = decimals
        return formatter.string(from: NSNumber(value: self)) ?? ""
    }
    
    
    func decimals(_ decimals: Int) -> String {
        let formatter = AppState.shared.numberFormatter
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = decimals
        return formatter.string(from: NSNumber(value: self)) ?? ""
    }
}


extension Optional where Wrapped == Double {
    var specialDefaultIfNil: Double {
        switch self {
        case let .some(wrapped): wrapped
        case .none: Double.greatestFiniteMagnitude
        }
    }
}

