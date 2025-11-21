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
    var amount: Double {
        Double(amountString.replacing("$", with: "").replacing(",", with: "")) ?? 0.0
    }
    var amountString: String
    
    init() {
        //self.from = CBPaymentMethod.empty
        //self.to = CBPaymentMethod.empty
        self.amountString = ""
    }
}
