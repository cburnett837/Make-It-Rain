//
//  CategoryViewMac.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/21/24.
//

import SwiftUI
import Charts


protocol IsEditableBudget: AnyObject {
    var amount: Double {get}
    var amountString: String {get set}
        
    func deepCopy(_ mode: ShadowCopyAction)
    func hasChanges() -> Bool
}



struct MonthlyBudgetEditView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) var dismiss
    
    @Environment(CalendarModel.self) private var calModel
    @Environment(CategoryModel.self) private var catModel
    @Environment(BudgetModel.self) private var budgetModel
    @Environment(RepeatingTransactionModel.self) private var repModel
    @Environment(AppStore.self) private var store
        
    @Bindable var month: CBMonth
            
    @FocusState private var focusedField: Int?
    @State private var transactions: [CBTransaction] = []
    @State private var editCategory: CBCategory?
    @State private var categoryEditID: CBCategory.ID?
    
    @State private var editGroup: CBCategoryGroup?
    @State private var groupEditID: CBCategoryGroup.ID?
    @State private var labelWidth: CGFloat = 20.0

    
    var catAndGroupBudgetAmount: Double {
        let catAmount = month.budgets.filter({ $0.type == .category }).compactMap({ $0.amount }).reduce(0, +)
        let groupAmount = month.budgets.filter({ $0.type == .categoryGroup }).compactMap({ $0.amount }).reduce(0, +)
        //let catAmount = month.budget.categories.map({ $0.amount ?? 0 }).reduce(0, +)
        //let groupAmount = month.budget.categoryGroups.map({ $0.amount ?? 0 }).reduce(0, +)
        return catAmount + groupAmount
    }
    
    var categoryBudgetIsGreater: Bool {
        return catAndGroupBudgetAmount > month.amount
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
    
    var monthlyIncome: Double {
        return store.repTransactions.reduce(0.0) { total, rep in
            guard rep.category?.isIncome == true else { return total }
            
            let count = rep.when.count {
                [.dayOfMonth, .weekday, .specificDate].contains($0.whenType) && $0.active
            }
            
            return total + rep.amount * Double(count)
        }
    }
    
    var isValidToSave: Bool {
        month.hasChanges()
    }
    

    var body: some View {
        #if os(iOS)
        NavigationStack {
            StandardContainerWithToolbar(.list) {
                
                Section {
                    titleRow
                } header: {
                    Text("Budget \(calModel.sMonth.name) \(String(calModel.sMonth.year))")
                }
                
                Section {
                    HStack {
                        Text("Monthly Income")
                        Spacer()
                        Text(monthlyIncome.currencyWithDecimals())
                    }
                } footer: {
                    Text("The amount of monthly income as determined by your recurring transactions.")
                }
                
                if categoryBudgetIsGreater {
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
            .navigationTitle("Edit Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: AppState.shared.isIphone ? .topBarTrailing : .topBarLeading) {
                    AnimatedCloseButton(isValidToSave: isValidToSave, closeButton: closeButton)
                }
            }
        }
        .onPreferenceChange(MaxSizePreferenceKey.self) { labelWidth = max(labelWidth, $0) }
        .task {
            month.deepCopy(.create)
            month.amountString = month.amount.currencyWithDecimals()
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
        HStack(spacing: 0) {
            Label("", systemImage: "t.circle")
                .foregroundStyle(.gray)
            
            #if os(iOS)
            UITextFieldWrapper(placeholder: "Budget", text: $month.amountString, toolbar: {
                KeyboardToolbarView(focusedField: $focusedField)
            })
            .uiTag(0)
            .uiClearButtonMode(.whileEditing)
            .uiStartCursorAtEnd(true)
            .uiTextAlignment(.left)
            #else
            StandardTextField("Name", text: $amountString, focusedField: $focusedField, focusValue: 0)
                .onSubmit { focusedField = 1 }
            #endif
        }
        .focused($focusedField, equals: 0)
    }
}




