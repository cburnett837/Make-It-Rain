//
//  CBTransfer.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/25/24.
//

import Foundation

@Observable
class CBTransfer {
    var from: CBPaymentMethod?
    var to: CBPaymentMethod?
    var category: CBCategory?
    var amount: Decimal {
        CurrencyHelpers.parseAmountStringToDecimal(amountString) ?? 0.0
        //Decimal(amountString.replacing("$", with: "").replacing(",", with: "")) ?? 0.0
    }
    var amountString: String
    
    var exchangeRate: Decimal {
        CurrencyHelpers.parseAmountStringToDecimal(exchangeRateString ?? "0.0") ?? 0.0
        //Decimal((exchangeRateString ?? "").replacing("$", with: "").replacing(",", with: "")) ?? 0.0
    }
    var exchangeRateString: String?
    
    init() {
        //self.from = CBPaymentMethod.empty
        //self.to = CBPaymentMethod.empty
        self.amountString = ""
    }
}
