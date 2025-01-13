//
//  Helpers.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/25/24.
//

import Foundation
import SwiftUI

struct Helpers {
    #if os(iOS)
    static func buzzPhone(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
    
    #endif
    

    static func getTempID() -> Int {
        let lastUsedTempID: Int = UserDefaults.standard.integer(forKey: "lastUsedTempID")
        UserDefaults.standard.set(lastUsedTempID + 1, forKey: "lastUsedTempID")
        return lastUsedTempID
    }
    
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
    
    
}

func ??<T>(lhs: Binding<Optional<T>>, rhs: T) -> Binding<T> {
    Binding(
        get: { lhs.wrappedValue ?? rhs },
        set: { lhs.wrappedValue = $0 }
    )
}
