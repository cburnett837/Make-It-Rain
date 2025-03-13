//
//  CategoryViewMac.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/21/24.
//

import SwiftUI

struct BudgetEditView: View {
    @AppStorage("useWholeNumbers") var useWholeNumbers = false

    @Environment(\.dismiss) var dismiss
    @Bindable var budget: CBBudget
    @Bindable var calModel: CalendarModel
    
    @State private var showDeleteAlert = false
    @State private var labelWidth: CGFloat = 20.0
        
    var title: String { budget.action == .add ? "New Budget" : "Edit Budget" }
    
    @FocusState private var focusedField: Int?
    @State private var showKeyboardToolbar = false

    var body: some View {
        VStack {
            VStack {
                SheetHeader(title: title, close: { dismiss() })
                Divider()
                
                LabeledRow("Name", labelWidth) {
                    Text(budget.category?.title ?? "")
                }
                
                LabeledRow("Budget", labelWidth) {
                    StandardTextField("Montly Amount", text: $budget.amountString, focusedField: $focusedField, focusValue: 0)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                        //.focused($focusedField, equals: .amount)
                }
                
//                LabeledRow("Emoji", labelWidth) {
//                    StandardTextField("Emoji", text: $category.emoji ?? "", keyboardType: .text)
//                        .focused($focusedField, equals: .emoji)
//                        .onChange(of: category.emoji ?? "") { oldValue, newValue in
//                            if newValue.count > 1 {
//                                category.emoji! = newValue.first?.description ?? ""
//                            }
//                        }
//                }
            }
            .padding()
            .transaction { $0.animation = .none } /// stops a floater view above the keyboard toolbar
            
            List(calModel.sMonth.days.flatMap{$0.transactions.filter {$0.category?.id == budget.category?.id}}) { trans in
                
                LineItemView(trans: trans, day: .init(date: Date()))
//                
//                HStack {
//                    Text(trans.title)
//                    Spacer()
//                    Text(trans.amount.currencyWithDecimals(useWholeNumbers ? 0 : 2))
//                }
            }
            
        }
//        #if os(iOS)
//        .keyboardToolbar(amountString: .constant(""), focusedField: _focusedField, fields: [.title, .emoji])
//        #endif
        .onPreferenceChange(MaxSizePreferenceKey.self) { labelWidth = max(labelWidth, $0) }
        //.frame(maxWidth: .infinity)
        
        .task {
            budget.deepCopy(.create)
            /// Just for formatting.
            budget.amountString = budget.amount.currencyWithDecimals(useWholeNumbers ? 0 : 2)
        }
//        .alert("Delete \(budget.category?.title)?", isPresented: $showDeleteAlert, actions: {
//            Button("Yes", role: .destructive) {
//                Task {
//                    calModel.months.forEach { month in
//                        month.days.forEach { day in
//                            day.transactions.filter { $0.budget?.id == budget.id }.forEach { trans in
//                                trans.category = nil
//                            }
//                        }
//                    }
//                    dismiss()
//                    await catModel.delete(category)
//                }
//            }
//            
//            Button("Cancel", role: .cancel) {
//                showDeleteAlert = false
//            }
//        }, message: {
//            Text("This will not delete any associated transactions.")
//        })
    }
}
