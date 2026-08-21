//
//  CurrencyHelpers.swift
//  MakeItRain
//
//  Created by Cody Burnett on 6/5/26.
//


import Foundation
import SwiftUI
import AVFoundation

struct CurrencyHelpers {
    private static let amountSeparators: (decimal: String, grouping: String) = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = .current
        return (
            formatter.decimalSeparator ?? ".",
            formatter.groupingSeparator ?? ","
        )
    }()
    
    static func parseAmountStringToDecimal(_ text: String) -> Decimal? {
        let decimalSeparator = amountSeparators.decimal
        let groupingSeparator = amountSeparators.grouping

        var result = ""
        var hasDecimalSeparator = false
        var hasNegativeSign = false

        for char in text {
            let string = String(char)

            if char.isNumber {
                result.append(char)
            } else if string == decimalSeparator || string == "." {
                guard !hasDecimalSeparator else { continue }
                result.append(".")
                hasDecimalSeparator = true
            } else if string == "-" {
                guard !hasNegativeSign, result.isEmpty else { continue }
                result.append("-")
                hasNegativeSign = true
            } else if string == groupingSeparator {
                continue
            }
        }

        guard result != "-", result != ".", result != "-." else { return nil }
        return Decimal(string: result)
    }
    
    /// Used in models to convert `amountString` to `amount` (Double).
//    static func parseAmountStringToDecimalOG(_ text: String) -> Decimal? {
//        let formatter = NumberFormatter()
//        formatter.numberStyle = .decimal
//        formatter.locale = Locale.current
//
//        let decimalSeparator = formatter.decimalSeparator ?? "."
//        let groupingSeparator = formatter.groupingSeparator ?? ","
//
//        var result = ""
//        var hasDecimalSeparator = false
//        var hasNegativeSign = false
//
//        for char in text {
//            let string = String(char)
//
//            if char.isNumber {
//                result.append(char)
//            } else if string == decimalSeparator || string == "." {
//                if !hasDecimalSeparator {
//                    result.append(".")
//                    hasDecimalSeparator = true
//                }
//            } else if string == "-" {
//                if !hasNegativeSign && result.isEmpty {
//                    result.append("-")
//                    hasNegativeSign = true
//                }
//            } else if string == groupingSeparator {
//                continue
//            } else {
//                continue
//            }
//        }
//
//        guard result != "-", result != ".", result != "-." else {
//            return nil
//        }
//
//        return Decimal(string: result)
//    }

    
    static func formatAmountText(amount: Decimal?, currencyCode: String) -> String {
        guard let amount else {
            return ""
        }

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.locale = Locale.current

        let currencyDigits = formatter.maximumFractionDigits

        if !AppSettings.shared.useWholeNumbers {
            formatter.minimumFractionDigits = currencyDigits
            formatter.maximumFractionDigits = currencyDigits
        } else {
            formatter.minimumFractionDigits = 0
            formatter.maximumFractionDigits = 0
        }
        
        //print("\(amount) \(NSNumber(value: amount))")

        return formatter.string(from: amount as NSNumber) ?? ""
    }
    
    
//    static func cleanAmountString(_ text: String) -> String? {
//        let cleaned = text.replacingOccurrences(of: #"[^0-9.-]"#, with: "", options: .regularExpression)
//        let isValid = cleaned.range(of: #"^-?\d*\.?\d*$"#, options: .regularExpression) != nil
//        return isValid ? cleaned : nil
//    }
    
    static func cleanAmountString(_ text: String, currencyCode: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode

        var result = text

        if let symbol = formatter.currencySymbol {
            result = result.replacingOccurrences(of: symbol, with: "")
        }

        result = result.replacingOccurrences(of: currencyCode, with: "")
        result = result.trimmingCharacters(in: .whitespacesAndNewlines)
        result = result.replacingOccurrences(of: " ", with: "")
        
        result = result.replacingOccurrences(
            of: #"\s+"#,
            with: "",
            options: .regularExpression
        ).trimmingCharacters(in: .whitespacesAndNewlines)

        //print("Returning cleaned string: \(result)")
        
        return result
    }
    
    static func convert(amount: Decimal, fromRate: Decimal, toRate: Decimal) -> Decimal? {
        //guard let fromRate = from.usdRate, let toRate = to.usdRate, fromRate != 0 else { return nil }
        let usd = amount / fromRate
        return usd * toRate
    }
    
    
//    static func convert(amount: Decimal, from: ExchangeRate, using exchangeRate: Decimal) -> Decimal? {
//        guard let fromRate = from.usdRate else {
//            print("Exchange rate not available")
//            return nil
//        }
//        
//        print("Converting \(amount) \(from.currencyCode) to local currency with exchange rate \(exchangeRate)")
//        
//        /// Convert source currency to USD
//        let usd = amount / fromRate
//        /// Convert USD to destination currency
//        return usd * exchangeRate
//    }
    
//    @MainActor
//    static func convertedDisplayAmountForTransLineItem(trans: CBTransaction, months: Array<CBMonth>, convertUsing: TransactionConversionOriginProperty, convertTo: String?) -> Decimal? {
//        guard
//            let cunt = trans.country,
//            let date = trans.date
//        else {
//            //print("RETURNING nil on the converstion for \(trans.title)")
//            return nil
//        }
//        
//        var fromRate = Self.getExchangeRate(date: date, currencyCode: cunt.currencyCode, months: months)
//        var toRate = Self.getExchangeRate(date: date, currencyCode: convertTo ?? AppState.shared.country.currencyCode, months: months)
//        
//        if fromRate == nil {
//            fromRate = Self.getMostRecentExchangeRate(for: cunt.currencyCode, months: months)
//        }
//        
//        if toRate == nil {
//            toRate = Self.getMostRecentExchangeRate(for: convertTo ?? AppState.shared.country.currencyCode, months: months)
//        }
//        
//        guard
//            let fromRate, let toRate
//        else {
//            //print("RETURNING nil on the converstion for \(trans.title)")
//            return nil
//        }
//        
//        
//        let amount = switch convertUsing {
//        case .amount:
//            trans.amount
//        case .originalUnconvertedAmount:
//            trans.originalUnconvertedAmount
//        }
//        
//        //print("processing converstion for \(trans.title) \(cunt.currencyCode)(\(fromRate)) ---> \(convertTo ?? AppState.shared.country.currencyCode)(\(toRate))")
//        
//        //if cunt != AppState.shared.country, let amount = amount {
//        if let amount = amount {
//            if let converted = Self.convert(amount: amount, fromRate: fromRate, toRate: toRate) {
//                //print("RATE WAS CONVERTED from \(trans.originalUnconvertedAmount ?? trans.amount) to \(converted) FOR \(trans.title)")
//                return converted
//            }
//            //print("RATE WAS NOT CONVERTED FOR \(trans.title)")
//        } else {
//            
//        }
//        
//        return nil
//    }
    
    
    @MainActor
    static func getExchangeRate(date: Date, currencyCode: String, months: Array<CBMonth>) -> Decimal? {
        if let rate = months.getDay(by: date)?.getRate(for: currencyCode) {
            return rate
        } else {
            return Self.getMostRecentExchangeRate(for: currencyCode, months: months)
        }
    }
    
    @MainActor
    static func getMostRecentExchangeRate(for currencyCode: String, months: Array<CBMonth>) -> Decimal? {
        months
            .flatMap { $0.days }
            .flatMap { $0.exchangeRates }
            .filter { $0.currencyCode == currencyCode }
            .sorted(by: { $0.date ?? Date() > $1.date ?? Date() })
            .first?
            .usdRate
            //
            //.first?
            //.usdRate
    }
    
}

enum TransactionConversionOriginProperty {
    case amount, originalUnconvertedAmount
}
