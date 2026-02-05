//
//  PaySection.swift
//  MakeItRain
//
//  Created by Cody Burnett on 2/4/26.
//


import SwiftUI


enum PaymentMethodSection: String, Identifiable {
    var id: PaymentMethodSection {return self}
    case debit = "Debit"
    case credit = "Credit"
    case other = "Other"
}

enum ApplicablePaymentMethods {
    case all, allExceptUnified, basedOnSelected, remainingAvailbleForPlaid
}





@Observable
class PaySection: Identifiable {
    let id = UUID()
    let kind: PaymentMethodSection
    var payMethods: [CBPaymentMethod]
    
    init(kind: PaymentMethodSection, payMethods: [CBPaymentMethod]) {
        self.kind = kind
        self.payMethods = payMethods
    }
    
    func doesExist(_ meth: CBPaymentMethod) -> Bool {
        return !payMethods.filter { $0.id == meth.id }.isEmpty
    }
    
    func upsert(_ payMethod: CBPaymentMethod) {
        if !doesExist(payMethod) {
            payMethods.append(payMethod)
        }
    }
    
    func getIndex(for payMethod: CBPaymentMethod) -> Int? {
        return payMethods.firstIndex(where: { $0.id == payMethod.id })
    }
}
