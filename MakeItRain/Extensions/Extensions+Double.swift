//
//  Extentions+Double.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/24/25.
//

import Foundation


extension Double {
    var axisCurrencyLabel: String {
        let absValue = abs(self)
        
        // ≥ 1000 → use compact (1k, 1.5k, etc)
        if absValue >= 1000 {
            let formatted = self.formatted(
                .number
                    .notation(.compactName)
                    .precision(.fractionLength(0...1))
            )
            
            return "$" + formatted.replacingOccurrences(of: "K", with: "k")
        }
        
        // < 1000 → show full number (no rounding to 1k!)
        return "$" + self.formatted(
            .number
                .precision(.fractionLength(0))
        )
    }
}


extension Double {
    var isWholeNumber: Bool {
        return self.isZero || (self.isNormal && self.exponent >= 0)
    }
    
    var isNegative: Bool {
        return self.sign == .minus
    }
    
    func kVersion(_ fractions: Int = 0) -> String {
        return "\(self.formatted(.number.notation(.compactName).precision(.fractionLength(fractions))))"
    }
    
    var kVersion: String {
        return "\(self.formatted(.number.notation(.compactName).precision(.fractionLength(0))))"
    }
    
    func currencyWithDecimals(_ decimals: Int = AppSettings.shared.useWholeNumbers ? 0 : 2) -> String {
        formatted(
            .currency(code: "USD")
            .precision(.fractionLength(0))
        )
    }
    
//    func currencyWithDecimals(_ decimals: Int = AppSettings.shared.useWholeNumbers ? 0 : 2) -> String {
//        let formatter = AppState.shared.numberFormatter
//        formatter.numberStyle = .currency
//        formatter.currencyCode = "USD"
//        formatter.maximumFractionDigits = decimals
//        return formatter.string(from: NSNumber(value: self)) ?? ""
//    }
    
    
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

