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
        
//        var fetchMonth = -1
//        if month == 0 {
//            fetchMonth = 12
//        } else if month == 13 {
//            fetchMonth = 1
//        } else {
//            fetchMonth = month
//        }
//        
//        var fetchYear = 0
//        if month == 0 {
//            fetchYear = year - 1
//        } else if month == 13 {
//            fetchYear = year + 1
//        } else {
//            fetchYear = year
//        }
        
        
        
        
        
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
    
    @Environment(CalendarModel.self) var calModel; @Environment(CalendarViewModel.self) var calViewModel
    
    @Environment(PayMethodModel.self) var payModel
    
    @State private var model = ResetOptions()
    
    @State private var showResetMonthAlert = false
    
    var body: some View {
        SheetContainerView(.list) {
            paymentMethodSection
            budgetSection
            populatedStatusSection
        } header: {
            SheetHeader(title: "Reset Options", close: { dismiss() })
        } footer: {
            resetButton
        }
        .task {
            payModel.paymentMethods
                .filter { $0.accountType != .unifiedChecking && $0.accountType != .unifiedCredit }
                .forEach {
                model.paymentMethods.append(PayMethodRemoveOption(id: $0.id, title: $0.title, transactions: true, startingAmount: true))
            }
        }
        .alert("Reset \(calModel.sMonth.name) \(String(calModel.sMonth.year))", isPresented: $showResetMonthAlert) {
            Button("Reset", role: .destructive) {
                dismiss()
                calModel.resetMonth(model)
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
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
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
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
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
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
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
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
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
        }
        .padding(.bottom, 6)
        #if os(macOS)
        .foregroundStyle(.red)
        .buttonStyle(.codyStandardWithHover)
        #else
        .tint(.red)
        .buttonStyle(.borderedProminent)
        .sensoryFeedback(.warning, trigger: showResetMonthAlert) { oldValue, newValue in
            !oldValue && newValue
        }
        #endif
    
    }
}
