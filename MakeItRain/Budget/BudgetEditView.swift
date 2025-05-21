//
//  CategoryViewMac.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/21/24.
//

import SwiftUI

struct BudgetEditView: View {
    @Local(\.useWholeNumbers) var useWholeNumbers

    @Environment(\.dismiss) var dismiss
    @Bindable var budget: CBBudget
    @Bindable var calModel: CalendarModel
    
    @State private var showDeleteAlert = false
    @State private var labelWidth: CGFloat = 20.0
        
    var title: String { budget.action == .add ? "New Budget" : "Edit Budget" }
    
    @FocusState private var focusedField: Int?
    @State private var showKeyboardToolbar = false
    
    var transactions: Array<CBTransaction> {
        /// This will look at both the transaction, and its deepCopy.
        /// The reason being - in case we change a transction category or payment method from what is currently being viewed. This will allow the transaction sheet to remain on screen until we close it, at which point the save function will clear the deepCopy.
        calModel.sMonth.days.flatMap {
            $0.transactions.filter { trans in
                trans.categoryIdsInCurrentAndDeepCopy.contains(budget.category?.id)
            }
        }
    }

    var body: some View {
        StandardContainer {
            LabeledRow("Name", labelWidth) {
                Text(budget.category?.title ?? "")
            }
            
            LabeledRow("Budget", labelWidth) {
                StandardTextField("Monthly Amount", text: $budget.amountString, focusedField: $focusedField, focusValue: 0)
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif
                    //.focused($focusedField, equals: .amount)
            }
            
            
            StandardDivider()
            ForEach(transactions) { trans in
                VStack(spacing: 0) {
                    LineItemView(trans: trans, day: .init(date: Date()), isOnCalendarView: false)
                    Divider()
                }
            }
        } header: {
            SheetHeader(title: title, close: { dismiss() })
        }
        .onPreferenceChange(MaxSizePreferenceKey.self) { labelWidth = max(labelWidth, $0) }
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
