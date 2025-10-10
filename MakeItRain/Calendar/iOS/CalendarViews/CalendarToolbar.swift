//
//  CalendarToolbar.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/3/25.
//

import SwiftUI

struct CalendarToolbar: ToolbarContent {
    @Local(\.useWholeNumbers) var useWholeNumbers
    @Local(\.colorTheme) var colorTheme
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Environment(DataChangeTriggers.self) var dataChangeTriggers
    @Environment(CalendarProps.self) private var calProps
    @Environment(CalendarModel.self) private var calModel
    @Environment(FuncModel.self) private var funcModel
    @Environment(PlaidModel.self) private var plaidModel
    
    @Namespace var paymentMethodMenuButtonNamespace
    @Namespace var refreshButtonNamespace
    
    var monthText: String {
        calModel.isPlayground ? "\(calModel.sMonth.name) Playground" : "\(calModel.sMonth.name) \(calModel.sMonth.year)"
    }
    
    var isCurrentMonth: Bool {
        calModel.sMonth.actualNum == AppState.shared.todayMonth && calModel.sMonth.year == AppState.shared.todayYear
    }
    
    var body: some ToolbarContent {
        if AppState.shared.isIphone || (AppState.shared.isIpad && calModel.isShowingFullScreenCoverOnIpad) {
            ToolbarItem(placement: .topBarLeading) {
                backButton
                    .tint(.none)
            }
        }
        
        if AppState.shared.isIpad {
            ToolbarItem(placement: .title) {
                Text(monthText)
                    //.padding(12)
                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                    //.glassEffect()
            }
        }
        
//        if funcModel.isLoading {
//        
//            ToolbarItemGroup(placement: .topBarTrailing) {
//            
//                Image(systemName: "arrow.triangle.2.circlepath")
//                    .foregroundStyle(.gray)
//                    .symbolEffect(.rotate, options: SymbolEffectOptions.repeat(.continuous).speed(3), isActive: funcModel.isLoading)
//            }
//            
//            ToolbarSpacer(.fixed, placement: .topBarTrailing)
//        }
        
        ToolbarItemGroup(placement: .topBarTrailing) {
            
                
            if calModel.showLoadingSpinner {
                ProgressView()
                    .tint(.none)
            }
            
            ToolbarLongPollButton()
            smartTransactionWithIssuesButton
            plaidTransactionButton
        }
        
        ToolbarSpacer(.fixed, placement: .topBarTrailing)
        
        ToolbarItem(placement: .topBarTrailing) {
            payMethodButtonAndMenu
        }
        .matchedTransitionSource(id: "myButton", in: paymentMethodMenuButtonNamespace)
        
        ToolbarSpacer(.fixed, placement: .topBarTrailing)
        
        if !calModel.sCategories.isEmpty && AppState.shared.isIpad {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    withAnimation {
                        calModel.sCategories.removeAll()
                    }
                } label: {
                    Text("Reset Cats.")
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                }
            }
                
            ToolbarSpacer(.fixed, placement: .topBarTrailing)
        }
        
        
        if funcModel.isLoading {
            ToolbarItemGroup(placement: .topBarTrailing) {
                GlassEffectContainer {
                    Button {
                        
                    } label: {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            //.foregroundStyle(.gray)
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                            .symbolEffect(.rotate, options: SymbolEffectOptions.repeat(.continuous).speed(3), isActive: funcModel.isLoading)
                    }
                    .glassEffectID("refresh", in: refreshButtonNamespace)
                }
            }
            
            //ToolbarSpacer(.fixed, placement: .topBarTrailing)
        }
        
        
        ToolbarItem(placement: .topBarTrailing) {
            GlassEffectContainer {
                CalendarMoreMenu()
                    .glassEffectID("moreMenu", in: refreshButtonNamespace)
            }
        }
    }
    
    var smartTransactionWithIssuesButton: some View {
        Group {
            if !calModel.tempTransactions.filter({ $0.isSmartTransaction ?? false }).isEmpty {
                Button {
                    if AppState.shared.isIphone {
                        /// Bottom panel is in ``CalendarViewPhone``.
                        withAnimation {
                            calProps.bottomPanelContent = .smartTransactionsWithIssues
                        }
                    } else {
                        /// Inspector is in ``RootViewPad``.
                        calProps.inspectorContent = .smartTransactionsWithIssues
                        calProps.showInspector = true
                    }
                } label: {
                    Image(systemName: "brain")
                        .foregroundStyle(Color.fromName(colorTheme) == .orange ? .red : .orange)
                }
            }
        }
    }
    
    
    @ViewBuilder
    var plaidTransactionButton: some View {
        let plaidListIsEmpty = plaidModel.trans.filter({ !$0.isAcknowledged }).isEmpty
        var color: Color { plaidListIsEmpty ? Color.secondary : Color.fromName(colorTheme) == .orange ? .red : .orange }
        
        if !plaidListIsEmpty {
            Button {
                if AppState.shared.isIphone {
                    /// Bottom panel is in ``CalendarViewPhone``.
                    withAnimation {
                        calProps.bottomPanelContent = .plaidTransactions
                    }
                } else {
                    /// Inspector is in ``RootViewPad``.
                    calProps.inspectorContent = .plaidTransactions
                    calProps.showInspector = true
                }
            } label: {
                Image(systemName: "dollarsign.bank.building")
                    .foregroundStyle(color)
                    .contentShape(Rectangle())
            }
        }
    }
    
    
    var backButton: some View {
        Group {
            Button {
                if calModel.isShowingFullScreenCoverOnIpad {
                    /// Blank out the selection otherwise the app can try and change to the calendar section in the nav and cause the category sheet to close when leaving the month sheet.
                    NavigationManager.shared.selectedMonth = nil
                    calModel.isShowingFullScreenCoverOnIpad = false
                }
                dismiss()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text(calModel.isPlayground ? "Playground" : String(calModel.sYear))
                }
            }
        }
    }
    
    
    @ViewBuilder var payMethodButtonAndMenu: some View {
        @Bindable var calProps = calProps
        @Bindable var calModel = calModel
        Menu {
            Section("Accounts") {
                Button(calModel.sPayMethod?.title ?? "Select Account") {
                    calProps.showPayMethodSheet = true
                }
            }
            
            Section("Optional Filter By Categories") {
                Button(calModel.sCategory?.title ?? "Select Categories") {
                    calProps.showCategorySheet = true
                    //TouchAndHoldMonthToFilterCategoriesTip.didSelectCategoryFilter = true
                    //touchAndHoldMonthToFilterCategoriesTip.invalidate(reason: .actionPerformed)
                }
                
                if !calModel.sCategories.isEmpty {
                    Button("Reset", role: .destructive) {
                        calModel.sCategories.removeAll()
                    }
                }
            }
        } label: {
            Group {
                if AppState.shared.isIphone {
                    Image(systemName: "creditcard")
                } else {
                    if isCurrentMonth {
                        var balanceText: String {
                            if let meth = calModel.sPayMethod {
                                if meth.isUnified {
                                    if meth.isDebit {
                                        return " \(funcModel.getPlaidDebitSums().currencyWithDecimals(useWholeNumbers ? 0 : 2))"
                                    } else {
                                        return " \(funcModel.getPlaidCreditSums().currencyWithDecimals(useWholeNumbers ? 0 : 2))"
                                    }
                                } else {
                                    if let balance = funcModel.getPlaidBalance() {
                                        return " \(balance.amount.currencyWithDecimals(useWholeNumbers ? 0 : 2)) (\(calProps.timeSinceLastBalanceUpdate))"
                                    }
                                }
                            }
                            return ""
                        }
                        
                        let finalText: String = "\(calModel.sPayMethod?.title ?? "Select Account")\(balanceText)"
                        Text(finalText)
                    } else {
                        Text("\(calModel.sPayMethod?.title ?? "Select Account")")
                    }
                }
            }
            .allowsHitTesting(false)
            .foregroundStyle(colorScheme == .dark ? .white : .black)
            
        } primaryAction: {
            calProps.showPayMethodSheet = true
        }
        .sheet(isPresented: $calProps.showPayMethodSheet) {
            //TouchAndHoldMonthToFilterCategoriesTip.didTouchMonthName.sendDonation()
            startingAmountSheetDismissed()
        } content: {
            PayMethodSheet(payMethod: $calModel.sPayMethod, whichPaymentMethods: .all, showStartingAmountOption: true)
                .navigationTransition(.zoom(sourceID: "myButton", in: paymentMethodMenuButtonNamespace))
        }
        .sheet(isPresented: $calProps.showCategorySheet) {
            MultiCategorySheet(categories: $calModel.sCategories)
        }
    }
    
    
//    @ViewBuilder var showPayMethodSheetButton: some View {
//        @Bindable var calProps = calProps
//        @Bindable var calModel = calModel
//        Button {
//            calProps.showPayMethodSheet = true
//        } label: {
//            Text("\(calModel.sPayMethod?.title ?? "")")
//        }
//        .sheet(isPresented: $calProps.showPayMethodSheet) {
//            //TouchAndHoldMonthToFilterCategoriesTip.didTouchMonthName.sendDonation()
//            startingAmountSheetDismissed()
//        } content: {
//            PayMethodSheet(payMethod: $calModel.sPayMethod, whichPaymentMethods: .all, showStartingAmountOption: true)
//                .navigationTransition(.zoom(sourceID: "myButton", in: paymentMethodMenuButtonNamespace))
//        }
//    }
//    
    
    func startingAmountSheetDismissed() {
        let _ = calModel.calculateTotal(for: calModel.sMonth)
        
        /// If the dashboard is open in the inspector on iPad, it won't be recalculate its data on its own.
        /// So we use the ``DataChangeTriggers`` class to send a notification to the view to tell it to recalculate.
        DataChangeTriggers.shared.viewDidChange(.calendar)
        
        Task {
            await withTaskGroup(of: Void.self) { group in
                let starts = calModel.sMonth.startingAmounts.filter { !$0.payMethod.isUnified }
                for start in starts {
                    if start.hasChanges() {
                        group.addTask {
                            await calModel.submit(start)
                        }
                    } else {
                        //print("No Starting amount Changes for \(start.payMethod.title)")
                    }
                }
            }
        }
    }
}
