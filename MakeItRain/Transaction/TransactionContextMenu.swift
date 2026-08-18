//
//  TransactionContextMenu.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/28/24.
//

import SwiftUI

struct TransactionContextMenu: View {
    @Environment(CalendarModel.self) private var calModel
    @Environment(CalendarProps.self) private var calProps
    
    @Bindable var trans: CBTransaction
    @Binding var showDeleteAlert: Bool
    
    @Binding var showPayMethodSheet: Bool
    @Binding var showCategorySheet: Bool
    
    var body: some View {
        Section {
            Button { calProps.transEditID = trans.id } label: { Label("Edit", systemImage: "square.and.pencil") }
            Button { calModel.createCopy(of: trans) } label: { Label("Copy", systemImage: "document.on.document") }
            
            Button {
                trans.factorInCalculations.toggle()
                Task { await calModel.saveTransaction(id: trans.id) }
            } label: {
                Label(trans.factorInCalculations ? "Exclude from totals" : "Include in totals", systemImage: trans.factorInCalculations ? "eye.slash" : "eye")
            }
        }
            
        Section {
            TitleColorMenu(transactions: [trans], saveOnChange: true) {
                Label("Title Color", systemImage: "paintpalette")
            }
            
            Button {
                trans.deepCopy(.create)
                showPayMethodSheet = true
            } label: {
                Label("Account", systemImage: "wallet.bifold")
            }
            
            Button {
                trans.deepCopy(.create)
                showCategorySheet = true
            } label: {
                Label("Categories", systemImage: "books.vertical")
            }            
        }
            
        Button(role: .destructive) {
            showDeleteAlert = true
        } label: {
            Label("Delete", systemImage: "trash")
                .foregroundColor(.red)
        }
    }
}
