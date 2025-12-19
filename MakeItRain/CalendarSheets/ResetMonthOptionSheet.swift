//
//  ResetMonthOptionSheet.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/5/24.
//

import SwiftUI

struct PayMethodRemoveOption: Identifiable, Encodable {
    var id: String
    var title: String
    var transactions: Bool
    var startingAmount: Bool
        
    enum CodingKeys: CodingKey { case payment_method_id, transactions, starting_amounts }
        
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .payment_method_id)
        try container.encode(transactions ? 1 : 0, forKey: .transactions)
        try container.encode(startingAmount ? 1 : 0, forKey: .starting_amounts)
    }
    
    
}

@Observable
class ResetOptions: Encodable {
    var paymentMethods: [PayMethodRemoveOption] = []
    var budget: Bool = true
    var hasBeenPopulated: Bool = true
    var month: Int = 0
    var year: Int = 0
    
    
    enum CodingKeys: CodingKey { case payment_methods, budget, has_been_populated, user_id, account_id, device_uuid, month, year }
    
    
    func encode(to encoder: Encoder) throws {
        let formatter = NumberFormatter()
        formatter.minimumIntegerDigits = 2
     
        let optionalString = formatter.string(from: month as NSNumber)!
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(optionalString, forKey: .month)
        try container.encode(String(year), forKey: .year)
        
        try container.encode(paymentMethods, forKey: .payment_methods)
        try container.encode(budget ? 1 : 0, forKey: .budget)
        try container.encode(hasBeenPopulated ? 1 : 0, forKey: .has_been_populated)
        try container.encode(AppState.shared.user?.id, forKey: .user_id)
        try container.encode(AppState.shared.user?.accountID, forKey: .account_id)
        try container.encode(AppState.shared.deviceUUID, forKey: .device_uuid)
    }
    
    
}

struct ResetMonthOptionSheet: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    @Environment(CalendarModel.self) var calModel
    @Environment(PayMethodModel.self) var payModel
    @Environment(FuncModel.self) var funcModel
    
    @State private var model = ResetOptions()
    
    @State private var showResetMonthAlert = false
    
    var body: some View {
        NavigationStack {
            StandardContainerWithToolbar(.list) {
                paymentMethodSection
                budgetSection
                populatedStatusSection
            }
            #if os(iOS)
            .navigationTitle("Reset Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { closeButton }
                ToolbarItem(placement: .bottomBar) { resetButton }
            }
            #endif
        }
        .task {
            payModel.paymentMethods
                .filter { $0.accountType != .unifiedChecking && $0.accountType != .unifiedCredit }
                .forEach {
                model.paymentMethods.append(PayMethodRemoveOption(id: $0.id, title: $0.title, transactions: true, startingAmount: true))
            }
        }
        .alert("Reset \(calModel.sMonth.prettyName)", isPresented: $showResetMonthAlert) {
            Button("Reset", role: .destructive) {
                dismiss()
                calModel.resetMonth(model)
                funcModel.prepareStartingAmounts(for: calModel.sMonth)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This cannot be reversed. Are you sure you want to reset this month?")
        }
    }
    
    var paymentMethodSection: some View {
        ForEach($model.paymentMethods) { $meth in
            Section(meth.title) {
                #if os(macOS)
                Toggle(isOn: $meth.transactions) { Text("Transactions") }
                Toggle(isOn: $meth.startingAmount) { Text("Starting Amount") }
                #else
                Button {
                    meth.transactions.toggle()
                } label: {
                    HStack {
                        Image(systemName: meth.transactions ? "checkmark.circle.fill" : "circle")
                            .contentTransition(.symbolEffect(.replace))
                            .foregroundStyle(Color.accentColor)
                        Text("Transactions")
                            .schemeBasedForegroundStyle()
                        Spacer()
                    }
                }
                
                Button {
                    meth.startingAmount.toggle()
                } label: {
                    HStack {
                        Image(systemName: meth.startingAmount ? "checkmark.circle.fill" : "circle")
                            .contentTransition(.symbolEffect(.replace))
                            .foregroundStyle(Color.accentColor)
                        Text("Starting Amount")
                            .schemeBasedForegroundStyle()
                        Spacer()
                        
                    }
                }
                #endif
            }
        }
    }
    
    var budgetSection: some View {
        Section("Budget") {
            #if os(macOS)
            Toggle(isOn: $model.budget) { Text("Budget") }
            #else
            Button {
                model.budget.toggle()
            } label: {
                HStack {
                    Image(systemName: model.budget ? "checkmark.circle.fill" : "circle")
                        .contentTransition(.symbolEffect(.replace))
                        .foregroundStyle(Color.accentColor)
                    Text("Budget")
                        .schemeBasedForegroundStyle()
                    Spacer()
                }
            }
            #endif
        }
    }
    
    var populatedStatusSection: some View {
        Section("Populated Status") {
            #if os(macOS)
            Toggle(isOn: $model.hasBeenPopulated) { Text("Populated Status") }
            #else
            Button {
                model.hasBeenPopulated.toggle()
            } label: {
                HStack {
                    Image(systemName: model.hasBeenPopulated ? "checkmark.circle.fill" : "circle")
                        .contentTransition(.symbolEffect(.replace))
                        .foregroundStyle(Color.accentColor)
                    Text("Populated Status")
                        .schemeBasedForegroundStyle()
                    Spacer()
                }
            }
            #endif
        }
    }
    
    var resetButton: some View {
        Button {
            showResetMonthAlert = true
        } label: {
            Text("Reset")
                .schemeBasedForegroundStyle()
        }
        #if os(macOS)
        .foregroundStyle(.red)
        .buttonStyle(.codyStandardWithHover)
        #else
        .tint(.red)
        .buttonStyle(.glassProminent)
        .sensoryFeedback(.warning, trigger: showResetMonthAlert) { !$0 && $1 }
        #endif
    
    }
    
    var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .schemeBasedForegroundStyle()
        }
    }
}
