//
//  Helpers.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/25/24.
//

import Foundation
import SwiftUI
import AVFoundation

struct Helpers {
    #if os(iOS)
    
    static func toggleTorch(on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video) else { return }

        if device.hasTorch {
            do {
                try device.lockForConfiguration()

                if on == true {
                    device.torchMode = .on
                } else {
                    device.torchMode = .off
                }

                device.unlockForConfiguration()
            } catch {
                print("Torch could not be used")
            }
        } else {
            print("Torch is not available")
        }
    }
    
    static func buzzPhone(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }    
    #endif
    
    static func plusMinus(_ amountString: String) -> String {
        var returnString = amountString
        if returnString.hasPrefix("$") {
            returnString.removeFirst()
            returnString = "-$" + returnString
            
        } else if returnString.hasPrefix("-$") {
            returnString.removeFirst()
            returnString.removeFirst()
            returnString = "$" + returnString
        } else {
            if returnString.hasPrefix("-") {
                returnString.removeFirst()
            } else {
                returnString = "-" + returnString
            }
        }
        return returnString
    }
        
    static func plusMinus(_ amountString: Binding<String>) {
        if amountString.wrappedValue.hasPrefix("$") {
            amountString.wrappedValue.removeFirst()
            amountString.wrappedValue = "-$" + amountString.wrappedValue
            
        } else if amountString.wrappedValue.hasPrefix("-$") {
            amountString.wrappedValue.removeFirst()
            amountString.wrappedValue.removeFirst()
            amountString.wrappedValue = "$" + amountString.wrappedValue
        } else {
            if amountString.wrappedValue.hasPrefix("-") {
                amountString.wrappedValue.removeFirst()
            } else {
                amountString.wrappedValue = "-" + amountString.wrappedValue
            }
        }
    }
    
    static func plusMinus(amountString: String) -> String {
        var amountString = amountString
        if amountString.hasPrefix("$") {
            amountString.removeFirst()
            amountString = "-$" + amountString
            
        } else if amountString.hasPrefix("-$") {
            amountString.removeFirst()
            amountString.removeFirst()
            amountString = "$" + amountString
        } else {
            if amountString.hasPrefix("-") {
                amountString.removeFirst()
            } else {
                amountString = "-" + amountString
            }
        }
        
        return amountString
    }
    
    static func formatCurrency(focusValue: Int, oldFocus: Int?, newFocus: Int?, amountString: String?, amount: Decimal?) -> String? {
        
        
        //let useWholeNumbers = UserDefaults.standard.bool(forKey: "useWholeNumbers")
        
        if newFocus == focusValue {
            if amount == 0.0 {
                return ""
            } else {
                //return amountString
                return amount?.currencyWithDecimals()
            }
        } else {
            if oldFocus == focusValue && !(amountString ?? "").isEmpty {
                if amountString == "$" || amountString == "-$" {
                    return ""
                } else {
                    return amount?.currencyWithDecimals()
                }
            } else {
                //return amountString
                return amount?.currencyWithDecimals()
            }
        }
    }
        
    static func liveFormatCurrency(oldValue: String?, newValue: String?, text: Binding<String>) {
        //print(oldValue, newValue)
        if (oldValue ?? "").isEmpty && newValue == "-" { return }
        if (newValue ?? "").isEmpty { return }
        if newValue == "-" { return }
                                                        
        if (newValue ?? "").hasPrefix("-") {
            if (newValue ?? "").hasPrefix("-$") {
                return
            } else {
                text.wrappedValue.removeFirst()
                var useMe = (newValue ?? "")
                useMe.removeFirst()
                text.wrappedValue = "-$" + useMe
            }
        } else {
            if (newValue ?? "").hasPrefix("$") {
                return
            } else {
                text.wrappedValue.removeFirst()
                text.wrappedValue = "$" + (newValue ?? "")
            }
        }
    }
        
    static func createDate(month: Int, year: Int) -> Date? {
        var components = DateComponents()
        components.year = year
        components.month = month

        // Use the current calendar to create the date
        let calendar = Calendar.current
        return calendar.date(from: components)
    }
    
    static func generateCsv(fileName: String, headers: [String], rows: [[String]]) -> URL {
        var fileURL: URL!
        
        /// Heading of CSV file.
        var heading = headers.joined(separator: ",")
        heading = heading + "\n"
        
        /// File rows
        let preparedRows = rows.map { row in
            row.map { csvEscape($0) }.joined(separator: ",")
            //$0.joined(separator: ",")
        }
        
        /// Rows to string data
        let stringData = heading + preparedRows.joined(separator: "\n")
        
        do {
            let path = try FileManager.default.url(for: .documentDirectory, in: .allDomainsMask, appropriateFor: nil, create: false)
            
            fileURL = path.appendingPathComponent("\(fileName).csv")
            
            /// Append string data to file
            try stringData.write(to: fileURL, atomically: true , encoding: .utf8)
            
        } catch {
            print("error generating csv file")
        }
        
        return fileURL
    }
    
    private static func csvEscape(_ value: String) -> String {
        var escaped = value.replacingOccurrences(of: "\"", with: "\"\"")

        if escaped.contains(",") || escaped.contains("\n") || escaped.contains("\r") {
            escaped = "\"\(escaped)\""
        }

        return escaped
    }
        
    static func getPercentage(_ value: Decimal, of total: Decimal) -> Decimal {
        return total == 0 ? value : (value / total) * 100
    }
    
    static func netWorthPercentageChange(start: Decimal, end: Decimal) -> Decimal {
        guard start != 0 else { return 0 } // Avoid division by zero
        return ((end - start) / start) * 100
    }
        
    static func categorySorter() -> (CBCategory, CBCategory) -> Bool {
        return {
            switch AppSettings.shared.categorySortMode {
            case .title:
                return $0.title.lowercased() < $1.title.lowercased()
            case .listOrder:
                return $0.listOrder ?? 0 < $1.listOrder ?? 0
            }
        }
        
        //return { $0.title.lowercased() < $1.title.lowercased() }
        
        
//        if let sortModeString: String = LocalStorage.shared.get(\.categorySortMode) {
//            let sortMode = SortMode.fromString(sortModeString)
//            return {
//                switch sortMode {
//                case .title:
//                    return $0.title.lowercased() < $1.title.lowercased()
//                case .listOrder:
//                    return $0.listOrder ?? 0 < $1.listOrder ?? 0
//                }
//            }
//        }
//        
//        return { $0.title.lowercased() < $1.title.lowercased() }
        
        
    }
    
    static func budgetSorter() -> (CBBudgetItem, CBBudgetItem) -> Bool {
        //let sortMode = SortMode.fromString(UserDefaults.standard.string(forKey: "categorySortMode") ?? "")
        return {
            switch AppSettings.shared.categorySortMode {
            case .title:
                return ($0.category?.title ?? "").lowercased() < ($1.category?.title ?? "").lowercased()
            case .listOrder:
                return $0.category?.listOrder ?? 0 < $1.category?.listOrder ?? 0
            }
        }
    }
    
    static func paymentMethodSorter() -> (CBPaymentMethod, CBPaymentMethod) -> Bool {
        //let sortMode = SortMode.fromString(UserDefaults.standard.string(forKey: "paymentMethodSortMode") ?? "")
        return {
            switch AppSettings.shared.paymentMethodSortMode {
            case .title:
                return $0.title.lowercased() < $1.title.lowercased()
            case .listOrder:
                return $0.listOrder ?? 0 < $1.listOrder ?? 0
            }
        }
    }
    
    static func paymentMethodSorter() -> (CBPaymentMethod?, CBPaymentMethod?) -> Bool {
        //let sortMode = SortMode.fromString(UserDefaults.standard.string(forKey: "paymentMethodSortMode") ?? "")
        return {
            switch AppSettings.shared.paymentMethodSortMode {
            case .title:
                return $0?.title.lowercased() < $1?.title.lowercased()
            case .listOrder:
                return $0?.listOrder ?? 0 < $1?.listOrder ?? 0
            }
        }
    }
    
    static func transactionSorter() -> (CBTransaction, CBTransaction) -> Bool {
        //let sortMode = TransactionSortMode.fromString(UserDefaults.standard.string(forKey: "transactionSortMode") ?? "")
        //let categorySortMode = SortMode.fromString(UserDefaults.standard.string(forKey: "categorySortMode") ?? "")
        
        return {
            if AppSettings.shared.transactionSortMode == .title {
                return $0.title < $1.title
                
            } else if AppSettings.shared.transactionSortMode == .enteredDate {
                return $0.enteredDate < $1.enteredDate
                
            } else {                
                switch AppSettings.shared.categorySortMode {
                case .title:
                    return ($0.category?.title ?? "").lowercased() < ($1.category?.title ?? "").lowercased()
                case .listOrder:
                    return $0.category?.listOrder ?? 0 < $1.category?.listOrder ?? 0
                }
            }
        }
    }
    
    static func decodeAttributedString(from base64: String) throws -> AttributedString {
        guard let data = Data(base64Encoded: base64) else {
            throw NSError(domain: "InvalidBase64", code: -1)
        }

        let attributed = try JSONDecoder().decode(AttributedString.self, from: data)
        return attributed
    }
        
    /// Turn a SwiftUI AttributedString into an NSAttributedString suitable for UITextView,
    /// applying default UIKit font/color if there is no NS styling.
    static func makeUITextViewString(from swiftAttr: AttributedString) -> NSAttributedString {
        // Bridge SwiftUI.AttributedString -> NSAttributedString
        let bridged = NSAttributedString(swiftAttr)  // this is a real initializer on iOS 15+

        // Check if there is *any* UIFont already applied in NS land
        var hasFontAttribute = false
        bridged.enumerateAttribute(.font,
                                   in: NSRange(location: 0, length: bridged.length),
                                   options: []) { value, _, stop in
            if value != nil {
                hasFontAttribute = true
                stop.pointee = true
            }
        }

        // If there is already a UIKit font, just use it as-is.
        guard !hasFontAttribute else {
            return bridged
        }

        // Otherwise, apply default UIKit styling over the whole range
        let mutable = NSMutableAttributedString(attributedString: bridged)
        let fullRange = NSRange(location: 0, length: mutable.length)

        #if os(iOS)
        mutable.addAttribute(.font, value: UIFont.preferredFont(forTextStyle: .body), range: fullRange)
        mutable.addAttribute(.foregroundColor, value: UIColor.label, range: fullRange)
        #else
        mutable.addAttribute(.font, value: NSFont.preferredFont(forTextStyle: .body), range: fullRange)
        mutable.addAttribute(.foregroundColor, value: NSColor.textColor, range: fullRange)
        #endif

        return mutable
    }
    
    
    

    static func highlightString(query: String, in text: String) -> AttributedString {
        var attributedString = AttributedString(text)
        
        // Ensure the query is not empty to avoid infinite loops
        guard !query.isEmpty else { return attributedString }
        
        // Find all matches using regular expressions
        if let regex = try? NSRegularExpression(pattern: NSRegularExpression.escapedPattern(for: query), options: .caseInsensitive) {
            let range = NSRange(text.startIndex..<text.endIndex, in: text)
            let matches = regex.matches(in: text, options: [], range: range)
            
            // Loop backward to cleanly map ranges onto AttributedString
            for match in matches.reversed() {
                if let stringRange = Range(match.range, in: attributedString) {
                    // Apply visual highlights
                    //attributedString[stringRange].backgroundColor = .yellow
                    attributedString[stringRange].foregroundColor = Color.theme
                    attributedString[stringRange].inlinePresentationIntent = .stronglyEmphasized // Bold
                }
            }
        }
        
        return attributedString
    }
    
    
//    static func getChartGradientPosition<T>(from points: [T], budget: Decimal, value: KeyPath<T, Decimal?>) -> Decimal? {
//        let amounts = points.map { ($0[keyPath: value] ?? 0) * -1 }
//        
//        guard let minAmount = amounts.min(),
//              let maxAmount = amounts.max(),
//              minAmount != maxAmount
//        else {
//            return nil
//        }
//        
//        let result = (budget - minAmount) / (maxAmount - minAmount)
//        
//        guard !result.isInfinite, !result.isNaN else {
//            return nil
//        }
//        
//        return min(max(result, 0), 1)
//    }
    
    
    static func getChartGradientPosition<T>(from points: [T], budget: Decimal, value: KeyPath<T, Decimal>) -> Decimal? {
        getBudgetGradientPosition(
            amounts: points.map { $0[keyPath: value] },
            budget: budget
        )
    }

    static func getChartGradientPosition<T>(from points: [T], budget: Decimal, value: KeyPath<T, Decimal?>) -> Decimal? {
        getBudgetGradientPosition(
            amounts: points.compactMap { $0[keyPath: value] },
            budget: budget
        )
    }
    
    private static func getBudgetGradientPosition(amounts: [Decimal], budget: Decimal) -> Decimal? {
        
        let amounts = amounts.map { $0 * -1 }

        guard let minAmount = amounts.min(),
              let maxAmount = amounts.max(),
              minAmount != maxAmount
        else {
            return nil
        }

        let result = (budget - minAmount) / (maxAmount - minAmount)

        guard !result.isInfinite, !result.isNaN else {
            return nil
        }

        return min(max(result, 0), 1)
    }
}


func ??<T>(lhs: Binding<Optional<T>>, rhs: T) -> Binding<T> {
    Binding(
        get: { lhs.wrappedValue ?? rhs },
        set: { lhs.wrappedValue = $0 }
    )
}



