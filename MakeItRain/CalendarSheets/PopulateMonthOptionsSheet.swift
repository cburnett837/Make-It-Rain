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
    @AppStorage("appColorTheme") var appColorTheme: String = Color.blue.description
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    @Environment(CalendarModel.self) var calModel
    
    @Environment(PayMethodModel.self) var payModel
    @Environment(CategoryModel.self) var catModel
    @Environment(RepeatingTransactionModel.self) var repModel
    
    @State private var model = PopulateOptions()
    
    var body: some View {
        SheetContainerView(.list) {
            paymentMethodSection
            budgetSection
        } header: {
            SheetHeader(title: "Populate Options", close: { dismiss() })
        } footer: {
            populateButton
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
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
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
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                    Spacer()
                }
            }
            #endif
        }
    }
    
    var populateButton: some View {
        Button {
            dismiss()
            calModel.populate(options: model, repTransactions: repModel.repTransactions, categories: catModel.categories)
        } label: {
            Text("Populate")
        }
        .padding(.bottom, 6)
        #if os(macOS)
        .foregroundStyle(Color.fromName(appColorTheme))
        .buttonStyle(.codyStandardWithHover)
        #else
        .tint(Color.fromName(appColorTheme))
        .buttonStyle(.borderedProminent)
        #endif
    
    }
}
