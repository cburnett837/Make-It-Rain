//
//  GlobalBudgetEditView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/14/26.
//


import SwiftUI
import Charts

struct GlobalBudgetEditView<T: IsEditableBudget & Observation.Observable>: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) var dismiss
    
    @Environment(CalendarModel.self) private var calModel
    @Environment(CategoryModel.self) private var catModel
    @Environment(BudgetModel.self) private var budgetModel
    @Environment(RepeatingTransactionModel.self) private var repModel
    @Environment(AppStore.self) private var store
    
    var title: String
    var footer: String?
    var obj: T
    var showCategories: Bool
    //var amount: Double
    //@Binding var amountString: String
            
    @FocusState private var focusedField: Int?
    @State private var transactions: [CBTransaction] = []
    @State private var editCategory: CBCategory?
    @State private var categoryEditID: CBCategory.ID?
    
    @State private var editGroup: CBCategoryGroup?
    @State private var groupEditID: CBCategoryGroup.ID?
    @State private var labelWidth: CGFloat = 20.0

    
    var catAndGroupBudgetAmount: Decimal {
        let catAmount = store.categories.map { $0.amount ?? 0 }.reduce(0, +)
        let groupAmount = store.categoryGroups.map { $0.amount ?? 0 }.reduce(0, +)
        return catAmount + groupAmount
    }
    
    var categoryBudgetIsGreater: Bool {
        return catAndGroupBudgetAmount > obj.amount
    }
    
    var budgetHeader: String {
        let month = calModel.sMonth
        if month.isPlaceholder {
            return "Budget"
        } else {
            let sub = calModel.isPlayground ? "\(month.name) (Playground)" : "\(month.name) \(String(month.year))"
            return "Budget for \(sub)"
        }
    }
    
    var monthlyIncome: Decimal {
        return store.repTransactions.reduce(0.0) { total, rep in
            guard rep.category?.isIncome == true else { return total }
            
            let dayOrDateCount = rep.when.count {
                [.dayOfMonth, .specificDate].contains($0.whenType) && $0.active
            }
            
            let weekdayCount = rep.when.count {
                $0.whenType == .weekday && $0.active
            }
            
            return total + (rep.amount * Decimal(dayOrDateCount)) + (rep.amount * 4.0 * Decimal(weekdayCount))
        }
    }
    
    var isValidToSave: Bool {
        obj.hasChanges()
    }
    

    var body: some View {
        #if os(iOS)
        NavigationStack {
            StandardContainerWithToolbar(.list) {
                
                Section {
                    titleRow
                } header: {
                    Text(budgetHeader)
                } footer: {
                    if let footer {
                        Text(footer)
                    }
                }
                
                Section {
                    HStack {
                        Text("Income")
                        Spacer()
                        Text(monthlyIncome.currencyWithDecimals())
                    }
                    .bold()
                    
                    ForEach(store.repTransactions.filter { $0.category?.isIncome == true && $0.active }) { repTrans in
                        RepeatingTransactionLine(repTrans: repTrans)
                    }
                } header: {
                    Text("Monthly Income")
                } footer: {
                    Text("The amount of monthly income as determined by your recurring transactions.")
                }
                
                if categoryBudgetIsGreater && showCategories {
                    Section {
                        HStack {
                            Text("Categorical Budget")
                            Spacer()
                            Text(catAndGroupBudgetAmount.currencyWithDecimals())
                                .foregroundStyle(LinearGradient(gradient: Gradient(colors: [.orange, .red]), startPoint: .top, endPoint: .bottom))
                        }
                    } header: {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundStyle(LinearGradient(gradient: Gradient(colors: [.orange, .red]), startPoint: .top, endPoint: .bottom))
                            Text("Warning!")
                        }
                    } footer: {
                        Text("Your overall budget is less than the amount your budgeted for individual categories.")
                    }
                    
                    Section("Groups & Categories") {
                        ForEach(store.categoryGroups.filter { $0.amount ?? 0 > 0 }) { group in
                            CategoryGroupLine(group: group)
                                .onTapGesture {
                                    groupEditID = group.id
                                }
                        }
                        
                        ForEach(store.categories.filter { $0.amount ?? 0 > 0 }) { cat in
                            CategoryLine(category: cat, labelWidth: labelWidth)
                                .onTapGesture {
                                    categoryEditID = cat.id
                                }
                        }
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: AppState.shared.isIphone ? .topBarTrailing : .topBarLeading) {
                    AnimatedCloseButton(isValidToSave: isValidToSave, closeButton: closeButton)
                }
            }
        }
        .onPreferenceChange(MaxSizePreferenceKey.self) { labelWidth = max(labelWidth, $0) }
        .task {
            obj.deepCopy(.create)
            obj.amountString = obj.amount.currencyWithDecimals()
        }
        .categoryEditSheetAndLogic(editId: $categoryEditID)
        .categoryGroupEditSheetAndLogic(editId: $groupEditID)
        #endif
    }
    
    
    var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: isValidToSave ? "checkmark" : "xmark")
                .schemeBasedForegroundStyle()
        }
    }
    
    
    @ViewBuilder
    var titleRow: some View {
        @Bindable var obj = obj
        HStack(spacing: 0) {
            Label("", systemImage: "t.circle")
                .foregroundStyle(.gray)
            
            #if os(iOS)
            UITextFieldWrapper(placeholder: "Budget", text: $obj.amountString, toolbar: {
                KeyboardToolbarView(focusedField: $focusedField)
            })
            .uiTag(0)
            .uiClearButtonMode(.whileEditing)
            .uiStartCursorAtEnd(true)
            .uiTextAlignment(.left)
            #else
            StandardTextField("Name", text: $obj.amountString, focusedField: $focusedField, focusValue: 0)
                .onSubmit { focusedField = 1 }
            #endif
        }
        .focused($focusedField, equals: 0)
    }
}



