//
//  TransactionContextMenu.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/28/24.
//

import SwiftUI

struct TransactionContextMenu: View {
    @Environment(CalendarModel.self) private var calModel
    
    
    @Bindable var trans: CBTransaction
    @Binding var transEditID: String?
    @Binding var showDeleteAlert: Bool
    
    var body: some View {
        Section {
            Button { transEditID = trans.id } label: { Text("Edit") }
            Button { calModel.createCopy(of: trans) } label: { Text("Copy") }
            
            Button {
                trans.log(field: .factorInCalculations, old: trans.factorInCalculations ? "true" : "false", new: trans.factorInCalculations ? "false" : "true", groupID: UUID().uuidString)
                
                trans.factorInCalculations.toggle()
                calModel.saveTransaction(id: trans.id)
            } label: {
                Text(trans.factorInCalculations ? "❌ Exclude from totals" : "✅ Include in totals")
            }
        }
            
        Section {
            TitleColorMenu(trans: trans, saveOnChange: true) {
                Text("Title Color")
            }
            
            PaymentMethodMenu(payMethod: $trans.payMethod, trans: trans, calcAndSaveOnChange: true, whichPaymentMethods: .allExceptUnified) {
                Text("Payment Method")
            }
            
            CategoryMenu(category: $trans.category, trans: trans, saveOnChange: true) {
                Text("Categories")
            }
        }
            
        Button(role: .destructive) {
            showDeleteAlert = true
        } label: {
            Text("Delete")
                .foregroundColor(.red)
        }
    }
}
