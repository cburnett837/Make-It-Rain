//
//  PopulateMonthOptionsSheet.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/6/24.
//

import SwiftUI

struct PayMethodPopulateOption: Identifiable {
    var id: String
    var title: String
    var doIt: Bool
}


@Observable
class PopulateOptions {
    var paymentMethods: [PayMethodPopulateOption] = []
    var budget: Bool = true
}

struct PopulateMonthOptionsSheet: View {
    //@Local(\.colorTheme) var colorTheme
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    @Environment(CalendarModel.self) var calModel
    
    @Environment(PayMethodModel.self) var payModel
    @Environment(CategoryModel.self) var catModel
    @Environment(RepeatingTransactionModel.self) var repModel
    
    @State private var model = PopulateOptions()
    
    var body: some View {
        NavigationStack {
            StandardContainerWithToolbar(.list) {
                paymentMethodSection
                budgetSection
            }
            #if os(iOS)
            .navigationTitle("Populate Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { closeButton }
                ToolbarItem(placement: .bottomBar) { populateButton }
            }
            #endif
        }
        .task {
            payModel.paymentMethods
                .filter { $0.accountType != .unifiedChecking && $0.accountType != .unifiedCredit }
                .forEach {
                model.paymentMethods.append(PayMethodPopulateOption(id: $0.id, title: $0.title, doIt: true))
            }
        }
    }
    
    var paymentMethodSection: some View {
        Section("Populate Transactions From") {
            ForEach($model.paymentMethods) { $meth in
                #if os(macOS)
                Toggle(isOn: $meth.doIt) { Text(meth.title) }
                #else
                Button {
                    meth.doIt.toggle()
                } label: {
                    HStack {
                        Image(systemName: meth.doIt ? "checkmark.circle.fill" : "circle")
                            .contentTransition(.symbolEffect(.replace))
                            .foregroundStyle(Color.accentColor)
                        Text(meth.title)
                            .schemeBasedForegroundStyle()
                        Spacer()
                    }
                }
                #endif
            }
        }
    }
    
    var budgetSection: some View {
        Section("Create A Budget") {
            #if os(macOS)
            Toggle(isOn: $model.budget) { Text("Yes") }
            #else
            Button {
                model.budget.toggle()
            } label: {
                HStack {
                    Image(systemName: model.budget ? "checkmark.circle.fill" : "circle")
                        .contentTransition(.symbolEffect(.replace))
                        .foregroundStyle(Color.accentColor)
                    Text("Yes")
                        .schemeBasedForegroundStyle()
                    Spacer()
                }
            }
            #endif
        }
    }
    
    var populateButton: some View {
        Button {
            dismiss()
            calModel.populate(options: model, repTransactions: repModel.repTransactions, categories: catModel.categories, categoryGroups: catModel.categoryGroups)
        } label: {
            Text("Populate")
                .schemeBasedForegroundStyle()
        }
        #if os(macOS)
        .foregroundStyle(Color.theme)
        .buttonStyle(.codyStandardWithHover)
        #else
        .tint(Color.theme)
        .buttonStyle(.glassProminent)
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
