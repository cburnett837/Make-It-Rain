//
//  TagBudgetEditView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/10/26.
//


import SwiftUI
import Charts

struct TagBudgetEditView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) var dismiss
    @Environment(PayMethodModel.self) private var payModel
    @Environment(BudgetModel.self) private var budgetModel
    @Environment(TagModel.self) private var tagModel
    @Environment(AppStore.self) private var store
    
    @Bindable var budget: CBBudgetItem
    @Bindable var calModel: CalendarModel
    
    @State private var showDeleteAlert = false
    @FocusState private var focusedField: Int?
    
    @State private var tags: [CBTag] = []
    
    var title: String {
        budget.item?.title ?? "N/A"
    }
    
    var isValidToSave: Bool {
        guard budget.type == .tag else { return false }
        guard let item = budget.item else { return false }
        
        return budget.hasChanges() || (budget.action == .add && !item.title.isEmpty)
    }
    

    var body: some View {
        #if os(iOS)
        NavigationStack {
            StandardContainerWithToolbar(.list) {
                Section("Budget") {
                    titleRow
                }
                
                TevHashtags(
                    tags: tags,
                    header: "Tag",
                    footer: "Choose a tag to associate with the budget. Any transactions that use this tag will factor into the overall expenses."
                )
                
                StandardDeleteButton(type: .budget, delete: deleteBudget)
            }
            .navigationDestination(for: TransNavDest.self) { dest in
                TagView(tags: $tags, tagLimit: 1)
                    .onDisappear {
                        /// Note: If no tag is selected, the budget.tag will be set to nil, which will cause the budget to be deleted.
                        budget.tag = self.tags.first
                    }
            }
            //.searchable(text: $searchText, prompt: Text("Search"))
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                //ToolbarItem(placement: .topBarLeading) { deleteButton }
                ToolbarItem(placement: AppState.shared.isIphone ? .topBarTrailing : .topBarLeading) {
                    AnimatedCloseButton(isValidToSave: isValidToSave, closeButton: closeButton)
                }
            }
        }
        .task { prepareView() }
        .onChange(of: focusedField) {
            let setCur = AppState.shared.country.currencyCode
            if $1 == nil {
                if !budget.amount.isZero {
                    budget.amountString = budget.amount.currencyWithDecimals()
                }
                
            } else {
                budget.amountString = CurrencyHelpers.cleanAmountString(budget.amountString, currencyCode: setCur)
            }
        }
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
    
    
    var titleRow: some View {
        HStack(spacing: 0) {
            Label("", systemImage: "t.circle")
                .foregroundStyle(.gray)
            
            #if os(iOS)
            UITextFieldWrapper(placeholder: "Enter a budget", text: $budget.amountString, toolbar: {
                KeyboardToolbarView(focusedField: $focusedField)
            })
            .uiTag(0)
            .uiClearButtonMode(.whileEditing)
            .uiStartCursorAtEnd(true)
            .uiTextAlignment(.left)
            //.uiReturnKeyType(.next)
            //.uiFont(UIFont.systemFont(ofSize: 24.0))
            //.uiTextColor(.secondaryLabel)
            #else
            StandardTextField("Name", text: $budget.amountString, focusedField: $focusedField, focusValue: 0)
                .onSubmit { focusedField = 1 }
            #endif
        }
        .focused($focusedField, equals: 0)
    }
    
    
    func prepareView() {
        budget.deepCopy(.create)
        
        if budget.action == .add {
            store.budgets.append(budget)
        } else {
            /// Just for formatting.
            budget.amountString = budget.amount.currencyWithDecimals()
            
            if let tag = budget.tag {
                tags.append(tag)
            }
        }
    }
    
    
    func deleteBudget() {
        /// Prevent from going to the server and trying to delete something that isn't there.
        if budget.action == .add {
            budgetModel.delete(budget, andSubmit: false)
        } else {
            budget.action = .delete
            budgetModel.delete(budget, andSubmit: true)
        }
        
        dismiss()
    }
}
