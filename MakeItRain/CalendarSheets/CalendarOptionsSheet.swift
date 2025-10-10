//
//  CalendarSidebarPhone.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/1/24.
//

import SwiftUI

#if os(iOS)
struct CalendarOptionsSheet: View {
    @AppStorage("tightenUpEodTotals") var tightenUpEodTotals = true
    @Local(\.useWholeNumbers) var useWholeNumbers
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Environment(FuncModel.self) var funcModel
    @Environment(CalendarModel.self) var calModel
    @Environment(PayMethodModel.self) var payModel
    @Environment(CategoryModel.self) var catModel
    @Environment(RepeatingTransactionModel.self) var repModel
        
    @State private var buzzForResetMonth = false
    @State private var showResetOptionsSheet = false
    
    @State private var buzzForPopulate = false
    @State private var showPopulateOptionsSheet = false
    
    @Binding var selectedDay: CBDay?
    @FocusState private var focusedField: Int?
    //var focusedField: FocusState<Int?>.Binding
    //@Binding var showKeyboardToolbar: Bool
    
        
    var body: some View {
        @Bindable var calModel = calModel
        
        NavigationStack {
            StandardContainerWithToolbar(.list) {
                Section {
                    populateButton
                } footer: {
                    if calModel.sMonth.hasBeenPopulated {
                        Label(title: {
                            Text("NOTE: This month has already been populated.")
                        }, icon: {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                        })
                    }
                }
                
                SettingsViewInsert(withDividers: true)
                resetButton
                
            }
            #if os(iOS)
            .navigationTitle("Monthly Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { closeButton }
            }
            #endif
        }
        
        
        .sheet(isPresented: $showResetOptionsSheet) {
            ResetMonthOptionSheet()
        }
        .sheet(isPresented: $showPopulateOptionsSheet) {
            PopulateMonthOptionsSheet()
        }
        
        //.frame(width: getRect().width - 90)
        //.frame(maxWidth: .infinity)
        
//        .alert("Woah!", isPresented: $showPopulateAlert) {
//            Button("Options") {
//                showPopulateOptionsSheet = true
//                //calModel.populate(repTransactions: repModel.repTransactions, categories: catModel.categories)
//            }
//            Button("Cancel", role: .cancel) {
//                
//            }
//        } message: {
//            Text("You have already created a budget and populated this month with reoccuring transactions. If you proceed, reoccuring transactions will be duplicated.")
//        }
        
//        .alert("Reset \(calModel.sMonth.name) \(String(calModel.sMonth.year))", isPresented: $showResetMonthAlert) {
//            Button("Options", role: .destructive) {
//                //calModel.resetMonth()
//                showResetOptionsSheet = true
//            }
//            Button("Cancel", role: .cancel) {}
//        } message: {
//            Text("You will be able to choose what to reset on the next page.")
//        }
    }
    
    
//    var startingAmount: some View {
//        Group {
//            @Bindable var calModel = calModel
//            
//            VStack(alignment: .leading, spacing: 2) {
//                Text("STARTING AMOUNT\(calModel.isUnifiedPayMethod ? " (read only)" : "")")
//                    .foregroundStyle(.gray)
//                    .font(.caption)
//                    .padding(.leading, 8)
//                                                                                                
//                let sMeth: CBPaymentMethod? = calModel.sPayMethod
//                
//                let creditLimit = Text(sMeth?.limit?.currencyWithDecimals(useWholeNumbers ? 0 : 2) ?? "0.0")
//                                                        
//                let doubleCreditLimits = payModel.paymentMethods.filter { $0.accountType == .credit }.map { $0.limit ?? 0.0 }.reduce(0.0, +)
//                let allCreditLimits = Text(doubleCreditLimits.currencyWithDecimals(useWholeNumbers ? 0 : 2))
//                
//                let doubleStartingAmounts = calModel.sMonth.startingAmounts.filter { $0.payMethod.id == sMeth?.id }.first?.amount
//                let allStartingAmounts = doubleStartingAmounts?.currencyWithDecimals(useWholeNumbers ? 0 : 2)
//                
//                let amountFieldTitle: String = calModel.sPayMethod?.accountType == .credit ? "Current Balance" : "Starting Amount"
//                //let bindingText: Binding<String> = $calModel.sMonth.startingAmounts.filter { $0.payMethod.id == sMeth?.id }.first?.amountString ?? .constant(CBStartingAmount().amountString)
//                
//                /// Disable the starting amount field if it's a unified account.
//                if calModel.isUnifiedPayMethod {
//                    StandardTextField(amountFieldTitle, text: .constant(allStartingAmounts ?? "0.0"), focusedField: $focusedField, focusValue: 0)
//                        .disabled(true)
//                    
//                } else {
//                    /// Show the standard starting amount text field.
//                    StandardTextField(amountFieldTitle, text: $calModel.sMonth.startingAmounts.filter { $0.payMethod.id == sMeth?.id }.first?.amountString ?? .constant(""), focusedField: $focusedField, focusValue: 0)
//                        //.submitLabel(.send)
//                        .keyboardType(.decimalPad)
//                        //.focused($focusedField, equals: .startingAmount)
////                        .onChange(of: focusedField) { oldValue, newValue in
////                            print(newValue, oldValue)
////                            if oldValue == .startingAmount {
////                                submitStartingAmount()
////                            }
////                        }
//                }
//                
//                /// Show a total limit field for credit or unified credit views.
//                if sMeth?.accountType == .credit || sMeth?.accountType == .unifiedCredit {
//                    HStack(spacing: 0) {
//                        Text("of ")
//                        if sMeth?.accountType == .credit { creditLimit } else { allCreditLimits }
//                    }
//                    .foregroundStyle(.gray)
//                    .font(.caption)
//                    .padding(.leading, 8)
//                    
//                }
//            }
//        }
//        
//    }
//    
//    var paymentMethodMenu: some View {
//        Group {
//            @Bindable var calModel = calModel
//            
//            VStack(alignment: .leading, spacing: 2) {
//                Text("PAYMENT METHOD")
//                    .foregroundStyle(.gray)
//                    .font(.caption)
//                    .padding(.leading, 8)
//                
//                RoundedRectangle(cornerRadius: 8)
//                    .fill(Color(.tertiarySystemFill))
//                    .frame(height: 34)
//                    .overlay {
//                        
//                        
//                        
//                        MenuOrListButton(title: calModel.sPayMethod?.title, alternateTitle: "Select Payment Method") {
//                            showPayMethodSheet = true
//                        }
////                        
////                        PayMethodMenu(payMethod: $calModel.sPayMethod, whichPaymentMethods: .all) {
////                            HStack {
////                                Text(calModel.sPayMethod?.title ?? "Select Payment Method")
////                                    .foregroundStyle(.primary)
////                                Spacer()
////                            }
////                            .padding(.leading, 8)
////                        }
////                        .focusable(false)
////                        .chevronMenuOverlay()
//                    }
//            }
//        }
//    }
//    
//    var categoryMenu: some View {
//        Group {
//            @Bindable var calModel = calModel
//            
//            VStack(alignment: .leading, spacing: 2) {
//                Text("CATEGORY")
//                    .foregroundStyle(.gray)
//                    .font(.caption)
//                    .padding(.leading, 8)
//                
//                RoundedRectangle(cornerRadius: 8)
//                    .fill(Color(.tertiarySystemFill))
//                    .frame(height: 34)
//                    .overlay {
//                        MenuOrListButton(title: calModel.filterCategory?.title, alternateTitle: "Select Categories") {
//                            showCategorySheet = true
//                        }
//                        
////                        CategoryMenu(category: $calModel.filterCategory) {
////                            HStack {
////                                Text(calModel.filterCategory?.title ?? "All Categories")
////                                    .foregroundStyle(.primary)
////                                Spacer()
////                            }
////                            .padding(.leading, 8)
////                        }
////                        .focusable(false)
////                        .chevronMenuOverlay()
//                    }
//            }
//        }
//    }
//    
    var populateButton: some View {
        Button {
            //buzzPhone(.warning)
            if calModel.sMonth.hasBeenPopulated {
                buzzForPopulate = true
                let buttonConfig = AlertConfig.ButtonConfig(text: "Options", role: .primary) { showPopulateOptionsSheet = true }
                let config = AlertConfig(
                    title: "Woah!",
                    subtitle: "You have already created a budget and populated this month with reoccuring transactions. If you proceed, reoccuring transactions will be duplicated.",
                    primaryButton: AlertConfig.AlertButton(config: buttonConfig)
                )
                
                AppState.shared.showAlert(config: config)
                
                
            } else {
                showPopulateOptionsSheet = true
                //calModel.populate(repTransactions: repModel.repTransactions, categories: catModel.categories)
            }
        } label: {
            Text("Prepare Month")
        }
        .sensoryFeedback(.warning, trigger: buzzForPopulate) { !$0 && $1 }
        .tint(calModel.sMonth.hasBeenPopulated ? .gray : Color.accentColor)
    }
        
    
    var resetButton: some View {
        Button {
            buzzForResetMonth = true
            
            let buttonConfig = AlertConfig.ButtonConfig(text: "Options", role: .primary) { showResetOptionsSheet = true }
            let config = AlertConfig(
                title: "Reset \(calModel.sMonth.name) \(String(calModel.sMonth.year))",
                subtitle: "You will be able to choose what to reset on the next page.",
                symbol: .init(name: "exclamationmark.triangle.fill", color: .red),
                primaryButton: AlertConfig.AlertButton(config: buttonConfig)
            )
            
            AppState.shared.showAlert(config: config)
            
            
        } label: {
            Text("Reset Month")
        }
        .tint(.red)
        .sensoryFeedback(.warning, trigger: buzzForResetMonth) { !$0 && $1 }        
    }
    
    var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "checkmark")
                .foregroundStyle(colorScheme == .dark ? .white : .black)
        }
    }
}





struct CalendarOptionsSheetOG: View {
    @Environment(\.dismiss) var dismiss
    
    @Local(\.useWholeNumbers) var useWholeNumbers
    @AppStorage("tightenUpEodTotals") var tightenUpEodTotals = true

    @Environment(FuncModel.self) var funcModel
    //@Environment(RootViewModelPhone.self) var vm
    @Environment(CalendarModel.self) var calModel
    
    @Environment(PayMethodModel.self) var payModel
    @Environment(CategoryModel.self) var catModel
    @Environment(RepeatingTransactionModel.self) var repModel
        
    @State private var showResetMonthAlert = false
    @State private var showResetOptionsSheet = false
    
    @State private var showPopulateAlert = false
    @State private var showPopulateOptionsSheet = false
    //@State private var showPayMethodSheet = false
    //@State private var showCategorySheet = false
    
    @Binding var selectedDay: CBDay?
    @FocusState private var focusedField: Int?
    //var focusedField: FocusState<Int?>.Binding
    //@Binding var showKeyboardToolbar: Bool
    
        
    var body: some View {
        @Bindable var calModel = calModel
        NavigationStack {
            VStack(spacing: 0) {
                SheetHeader(title: "Monthly Options", close: { dismiss() })
                    .padding()
                
                GeometryReader { geo in
                    ScrollView {
                        VStack {
//                            startingAmount
//                            Divider()
                            
//                            paymentMethodMenu
//                            Divider()
//
//                            categoryMenu
//                            Divider()
                            
                            HStack {
                                populateButton
                                refreshButton
                            }
                            .buttonStyle(.borderedProminent)
                                            
                            Divider()
                                //.padding(.bottom, 16)
                                                                       
                            SettingsViewInsert(withDividers: true)
                            
                            Spacer()
                            resetButton
                        }
                        .frame(minHeight: geo.size.height)
                        .padding()
                        
                    }
                }
            }
        }
        .sheet(isPresented: $showResetOptionsSheet) {
            ResetMonthOptionSheet()
        }
        .sheet(isPresented: $showPopulateOptionsSheet) {
            PopulateMonthOptionsSheet()
        }
//        .sheet(isPresented: $showPayMethodSheet) {
//            PayMethodSheet(payMethod: $calModel.sPayMethod, whichPaymentMethods: .all)
//            #if os(macOS)
//                .frame(minWidth: 300, minHeight: 500)
//                .presentationSizing(.fitted)
//            #endif
//        }
//        .sheet(isPresented: $showCategorySheet) {
//            CategorySheet(category: $calModel.sCategory)
//            #if os(macOS)
//                .frame(minWidth: 300, minHeight: 500)
//                .presentationSizing(.fitted)
//            #endif
//        }
        
        //.frame(width: getRect().width - 90)
        //.frame(maxWidth: .infinity)
        
        .alert("Woah!", isPresented: $showPopulateAlert) {
            Button("Options") {
                showPopulateOptionsSheet = true
                //calModel.populate(repTransactions: repModel.repTransactions, categories: catModel.categories)
            }
            Button("Cancel", role: .cancel) {
                
            }
        } message: {
            Text("You have already created a budget and populated this month with reoccuring transactions. If you proceed, reoccuring transactions will be duplicated.")
        }
        
        .alert("Reset \(calModel.sMonth.name) \(String(calModel.sYear))", isPresented: $showResetMonthAlert) {
            Button("Options", role: .destructive) {
                //calModel.resetMonth()
                showResetOptionsSheet = true
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You will be able to choose what to reset on the next page.")
        }
    }
    
    
//    var startingAmount: some View {
//        Group {
//            @Bindable var calModel = calModel
//
//            VStack(alignment: .leading, spacing: 2) {
//                Text("STARTING AMOUNT\(calModel.isUnifiedPayMethod ? " (read only)" : "")")
//                    .foregroundStyle(.gray)
//                    .font(.caption)
//                    .padding(.leading, 8)
//
//                let sMeth: CBPaymentMethod? = calModel.sPayMethod
//
//                let creditLimit = Text(sMeth?.limit?.currencyWithDecimals(useWholeNumbers ? 0 : 2) ?? "0.0")
//
//                let doubleCreditLimits = payModel.paymentMethods.filter { $0.accountType == .credit }.map { $0.limit ?? 0.0 }.reduce(0.0, +)
//                let allCreditLimits = Text(doubleCreditLimits.currencyWithDecimals(useWholeNumbers ? 0 : 2))
//
//                let doubleStartingAmounts = calModel.sMonth.startingAmounts.filter { $0.payMethod.id == sMeth?.id }.first?.amount
//                let allStartingAmounts = doubleStartingAmounts?.currencyWithDecimals(useWholeNumbers ? 0 : 2)
//
//                let amountFieldTitle: String = calModel.sPayMethod?.accountType == .credit ? "Current Balance" : "Starting Amount"
//                //let bindingText: Binding<String> = $calModel.sMonth.startingAmounts.filter { $0.payMethod.id == sMeth?.id }.first?.amountString ?? .constant(CBStartingAmount().amountString)
//
//                /// Disable the starting amount field if it's a unified account.
//                if calModel.isUnifiedPayMethod {
//                    StandardTextField(amountFieldTitle, text: .constant(allStartingAmounts ?? "0.0"), focusedField: $focusedField, focusValue: 0)
//                        .disabled(true)
//
//                } else {
//                    /// Show the standard starting amount text field.
//                    StandardTextField(amountFieldTitle, text: $calModel.sMonth.startingAmounts.filter { $0.payMethod.id == sMeth?.id }.first?.amountString ?? .constant(""), focusedField: $focusedField, focusValue: 0)
//                        //.submitLabel(.send)
//                        .keyboardType(.decimalPad)
//                        //.focused($focusedField, equals: .startingAmount)
////                        .onChange(of: focusedField) { oldValue, newValue in
////                            print(newValue, oldValue)
////                            if oldValue == .startingAmount {
////                                submitStartingAmount()
////                            }
////                        }
//                }
//
//                /// Show a total limit field for credit or unified credit views.
//                if sMeth?.accountType == .credit || sMeth?.accountType == .unifiedCredit {
//                    HStack(spacing: 0) {
//                        Text("of ")
//                        if sMeth?.accountType == .credit { creditLimit } else { allCreditLimits }
//                    }
//                    .foregroundStyle(.gray)
//                    .font(.caption)
//                    .padding(.leading, 8)
//
//                }
//            }
//        }
//
//    }
//
//    var paymentMethodMenu: some View {
//        Group {
//            @Bindable var calModel = calModel
//
//            VStack(alignment: .leading, spacing: 2) {
//                Text("PAYMENT METHOD")
//                    .foregroundStyle(.gray)
//                    .font(.caption)
//                    .padding(.leading, 8)
//
//                RoundedRectangle(cornerRadius: 8)
//                    .fill(Color(.tertiarySystemFill))
//                    .frame(height: 34)
//                    .overlay {
//
//
//
//                        MenuOrListButton(title: calModel.sPayMethod?.title, alternateTitle: "Select Payment Method") {
//                            showPayMethodSheet = true
//                        }
////
////                        PayMethodMenu(payMethod: $calModel.sPayMethod, whichPaymentMethods: .all) {
////                            HStack {
////                                Text(calModel.sPayMethod?.title ?? "Select Payment Method")
////                                    .foregroundStyle(.primary)
////                                Spacer()
////                            }
////                            .padding(.leading, 8)
////                        }
////                        .focusable(false)
////                        .chevronMenuOverlay()
//                    }
//            }
//        }
//    }
//
//    var categoryMenu: some View {
//        Group {
//            @Bindable var calModel = calModel
//
//            VStack(alignment: .leading, spacing: 2) {
//                Text("CATEGORY")
//                    .foregroundStyle(.gray)
//                    .font(.caption)
//                    .padding(.leading, 8)
//
//                RoundedRectangle(cornerRadius: 8)
//                    .fill(Color(.tertiarySystemFill))
//                    .frame(height: 34)
//                    .overlay {
//                        MenuOrListButton(title: calModel.filterCategory?.title, alternateTitle: "Select Categories") {
//                            showCategorySheet = true
//                        }
//
////                        CategoryMenu(category: $calModel.filterCategory) {
////                            HStack {
////                                Text(calModel.filterCategory?.title ?? "All Categories")
////                                    .foregroundStyle(.primary)
////                                Spacer()
////                            }
////                            .padding(.leading, 8)
////                        }
////                        .focusable(false)
////                        .chevronMenuOverlay()
//                    }
//            }
//        }
//    }
//
    var populateButton: some View {
        Button {
            //buzzPhone(.warning)
            if calModel.sMonth.hasBeenPopulated {
                showPopulateAlert = true
            } else {
                showPopulateOptionsSheet = true
                //calModel.populate(repTransactions: repModel.repTransactions, categories: catModel.categories)
            }
            
        } label: {
            Label {
                Text("Populate")
            } icon: {
                Image(systemName: "arrow.triangle.branch")
                    .rotationEffect(Angle(degrees: 180))
            }
            .frame(maxWidth: .infinity)
        }
        .sensoryFeedback(.warning, trigger: showPopulateAlert) { !$0 && $1 }        
        .tint(calModel.sMonth.hasBeenPopulated ? .gray : Color.accentColor)
    }
    
    var refreshButton: some View {
        Button {
            Task {
                calModel.prepareForRefresh()
                let targetDay = calModel.sMonth.days.filter { $0.dateComponents?.day == (calModel.sMonth.num == AppState.shared.todayMonth ? AppState.shared.todayDay : 1) }.first
                selectedDay = targetDay
                //vm.offset = .zero
                await funcModel.downloadEverything(setDefaultPayMethod: false, createNewStructs: true, refreshTechnique: .viaButton)
            }
        } label: {
            Label {
                Text("Refresh")
            } icon: {
                Image(systemName: "arrow.triangle.2.circlepath")
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    var resetButton: some View {
        Button {
            showResetMonthAlert = true
        } label: {
            Label {
                Text("Reset Month")
            } icon: {
                Image(systemName: "calendar.badge.exclamationmark")
            }
            .frame(maxWidth: .infinity)
        }
        .tint(.red)
        .buttonStyle(.borderedProminent)
        .sensoryFeedback(.warning, trigger: showResetMonthAlert) { !$0 && $1 }
        .padding(.bottom, 12)
    }
    
//    func submitStartingAmount() {
//        /// This logic happens via an onChange() in the root view on macOS
//        let _ = calModel.calculateTotal(for: calModel.sMonth)
//
//        let starting = calModel.sMonth.startingAmounts.filter { $0.payMethod.id == calModel.sPayMethod?.id }.first
//        if starting != nil {
//            if !calModel.isUnifiedPayMethod {
//                calModel.stopDelayedStartingAmountTimer()
//                calModel.startDelayedStartingAmountTimer()
//
//            }
//        }
//    }
}


#endif
