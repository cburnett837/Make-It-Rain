//
//  CalendarToolbar.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/3/25.
//

import SwiftUI

#if os(iOS)
struct CalendarToolbar: ToolbarContent {
    @Local(\.useWholeNumbers) var useWholeNumbers
    //@Local(\.colorTheme) var colorTheme
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Environment(DataChangeTriggers.self) var dataChangeTriggers
    @Environment(CalendarProps.self) private var calProps
    @Environment(CalendarModel.self) private var calModel
    @Environment(FuncModel.self) private var funcModel
    @Environment(PlaidModel.self) private var plaidModel
    
    @Namespace var paymentMethodMenuButtonNamespace
    @Namespace var refreshButtonNamespace
    @Namespace var plaidButtonNamespace
    
    @Namespace var customMenuButtonNamespace
    
    @State private var showPopover = false
    
    //@Binding var navPath: NavigationPath
    
//    @State private var temp = false
    
    
    
    var monthText: String {
        calModel.isPlayground ? "\(calModel.sMonth.name) Playground" : "\(calModel.sMonth.name) \(calModel.sMonth.year)"
    }
    
    var isCurrentMonth: Bool {
        calModel.sMonth.actualNum == AppState.shared.todayMonth && calModel.sMonth.year == AppState.shared.todayYear
    }
    
    var body: some ToolbarContent {
        @Bindable var calProps = calProps
        
        if AppState.shared.isIphone || (AppState.shared.isIpad && calModel.isShowingFullScreenCoverOnIpad) {
            ToolbarItem(placement: .topBarLeading) {
                backButton
                    .tint(.none)
            }
        }
        
        if AppState.shared.isIpad {
            ToolbarItem(placement: .title) {
                Text(monthText)
                    .schemeBasedForegroundStyle()
            }
        }
        
        Group {
            ToolbarItemGroup(placement: .topBarTrailing) {
                ToolbarLongPollButton()
                smartTransactionWithIssuesButton
            }
            ToolbarSpacer(.fixed, placement: .topBarTrailing)
        }
        
        Group {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if !plaidModel.trans.filter({ !$0.isAcknowledged }).isEmpty {
                    GlassEffectContainer {
                        plaidTransactionButton
                            .glassEffectID("plaidTransactionButton", in: plaidButtonNamespace)
                    }
                }
            }
            
            //if AppState.shared.isIpad {
                ToolbarSpacer(.fixed, placement: .topBarTrailing)
                
                ToolbarItem(placement: .topBarTrailing) {
                    GlassEffectContainer {
                        payMethodButtonAndMenu
                            .glassEffectID("paymentMethodButton", in: plaidButtonNamespace)
                    }
                }
                .matchedTransitionSource(id: "paymentMethodButton", in: paymentMethodMenuButtonNamespace)
            //}
            
            
            
            ToolbarSpacer(.fixed, placement: .topBarTrailing)
        }
        
        if !calModel.sCategories.isEmpty && AppState.shared.isIpad {
            ToolbarItem(placement: .topBarTrailing) {
                resetCategoriesButton
            }
                
            ToolbarSpacer(.fixed, placement: .topBarTrailing)
        }
        
        if AppState.shared.isIpad {
            ToolbarItem(placement: .topBarTrailing) {
                NewTransactionMenuButton(
                    transEditID: $calProps.transEditID,
                    showTransferSheet: $calProps.showTransferSheet,
                    showPhotosPicker: $calProps.showPhotosPicker,
                    showCamera: $calProps.showCamera
                )
            }
            ToolbarSpacer(.fixed, placement: .topBarTrailing)
        }
        
        
        
        if funcModel.isLoading {
//        if temp {
            ToolbarItemGroup(placement: .topBarTrailing) {
                GlassEffectContainer {
                    refeshingIndicator
                }
            }
        }
        
        if AppState.shared.isIpad {
            ToolbarItem(placement: .topBarTrailing) { analysisSheetButton }
        }
        
        
        ToolbarItem(placement: .topBarTrailing) {
            GlassEffectContainer {
                
                
//                Button {
//                    showPopover = true
//                } label: {
//                    Image(systemName: "circle.fill")
//                        .matchedTransitionSource(id: "MENUCONTENT", in: customMenuButtonNamespace)
//                }
//                .popover(
//                    isPresented: $showPopover, arrowEdge: .bottom
//                ) {
//                    PopOverHelper {
//                        VStack {
//                            RoundedRectangle(cornerRadius: 4)
//                                .frame(height: 20)
//                            RoundedRectangle(cornerRadius: 4)
//                                .frame(height: 20)
//                            RoundedRectangle(cornerRadius: 4)
//                                .frame(height: 20)
//                            
//                            Text("Open Something")
//                        }
//                        .frame(height: 250)
//                    }
//                    .navigationTransition(.zoom(sourceID: "MENUCONTENT", in: customMenuButtonNamespace))
//                }
                
                CalendarMoreMenu(navPath: $calProps.navPath)
                    .glassEffectID("moreMenu", in: refreshButtonNamespace)
            }
        }
        
        if AppState.shared.isIphone {
            Group {
                
//                ToolbarItem(placement: .bottomBar) {
//                    payMethodButtonAndMenu
//                }
//                .matchedTransitionSource(id: "paymentMethodButton", in: paymentMethodMenuButtonNamespace)
                
//                ToolbarSpacer(.flexible, placement: .bottomBar)
                
                ToolbarItem(placement: .bottomBar) { analysisSheetButton }
                ToolbarSpacer(.fixed, placement: .bottomBar)
                DefaultToolbarItem(kind: .search, placement: .bottomBar)
                ToolbarSpacer(.fixed, placement: .bottomBar)
                ToolbarItem(placement: .bottomBar) {
                    NewTransactionMenuButton(
                        transEditID: $calProps.transEditID,
                        showTransferSheet: $calProps.showTransferSheet,
                        showPhotosPicker: $calProps.showPhotosPicker,
                        showCamera: $calProps.showCamera
                    )
                    //.matchedTransitionSource(id: "myButton", in: newTransactionMenuButtonNamespace)
                }
            }
        }
        
    }
    
//    struct PopOverHelper<Content: View>: View {
//        @ViewBuilder var content: Content
//        @State private var isVisible = false
//        var body: some View {
//            content
//                .opacity(isVisible ? 1 : 0)
//                .task {
//                    try? await Task.sleep(for: .seconds(0.1))
//                    withAnimation(.snappy(duration: 0.3, extraBounce: 0)) {
//                        isVisible = true
//                    }
//                }
//                .presentationCompactAdaptation(.popover)
//        }
//    }
    
    
    
    var analysisSheetButton: some View {
        Button {
            if AppState.shared.isIphone {
                
                calProps.navPath.append(CalendarNavDest.categoryInsights)
                
                /// Sheet is in ``CalendarMoreMenu``.
                //calProps.showAnalysisSheet = true
            } else {
                /// Inspector is in ``RootViewPad``.
                calProps.inspectorContent = .analysisSheet
                calProps.showInspector = true
            }
        } label: {
            Label("Insights", systemImage: "chart.pie")
        }
        .schemeBasedTint()
        //.schemeBasedForegroundStyle()
    }
    
    
    var refeshingIndicator: some View {
        Image(systemName: "arrow.triangle.2.circlepath")
            //.foregroundStyle(.gray)
            .schemeBasedForegroundStyle()
            .symbolEffect(.rotate, options: SymbolEffectOptions.repeat(.continuous).speed(3), isActive: funcModel.isLoading)
            .glassEffectID("refresh", in: refreshButtonNamespace)
    }
    
    
    var resetCategoriesButton: some View {
        Button {
            withAnimation {
                calModel.sCategories.removeAll()
            }
        } label: {
            Text("Reset Cats.")
                .schemeBasedForegroundStyle()
        }
    }
    
    
    @ViewBuilder
    var smartTransactionWithIssuesButton: some View {
        let smartTrans = calModel.tempTransactions.filter({ $0.isSmartTransaction ?? false })
        if !smartTrans.isEmpty {
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
                //AiAnimatedSwishSymbol(symbol: "brain", baseColor: colorScheme == .dark ? .white : .black,hasAnimated: .constant(false))
                AiAnimatedAliveSymbol(symbol: "brain")
//                    let colors: [Color] = [.orange, .pink, .purple]
//                    Image(systemName: "brain")
//                        .foregroundStyle(LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing))
//                        //.foregroundStyle(Color.theme == .orange ? .red : .orange)
            }
            .badge(smartTrans.count)
            .id(smartTrans.count)
            
        }
    }
    
    
    @ViewBuilder
    var plaidTransactionButton: some View {
        let plaidTrans = plaidModel.trans.filter({ !$0.isAcknowledged })
        if !plaidTrans.isEmpty {
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
                    .schemeBasedForegroundStyle()
                    .contentShape(Rectangle())
            }
            .badge(plaidTrans.count)
            .id(plaidTrans.count)
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
                /// Don't use dismiss here since it causes a big delete in the onChange()'s in  ``RootView``.
                //dismiss()
                calModel.showMonth = false
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
        
        var balanceText: String {
            if let meth = calModel.sPayMethod {
                if meth.isUnified {
                    if meth.isDebit {
                        return " \(funcModel.getPlaidDebitSums().currencyWithDecimals(useWholeNumbers ? 0 : 2))"
                    } else {
                        return " \(funcModel.getPlaidCreditSums().currencyWithDecimals(useWholeNumbers ? 0 : 2))"
                    }
                } else {
                    if let balance = funcModel.getPlaidBalance(matching: calModel.sPayMethod) {
                        return " \(balance.amount.currencyWithDecimals(useWholeNumbers ? 0 : 2)) (\(calProps.timeSinceLastBalanceUpdate))"
                    }
                }
            }
            return ""
        }
        
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
                        withAnimation {
                            calModel.sCategories.removeAll()
                        }
                    }
                }
            }
        } label: {
            Group {
                if AppState.shared.isIphone {
                    Image(systemName: "creditcard")
                } else {
                    if isCurrentMonth {
                        let finalText: String = "\(calModel.sPayMethod?.title ?? "Select Account")\(balanceText)"
                        Text(finalText)
                    } else {
                        Text("\(calModel.sPayMethod?.title ?? "Select Account")")
                    }
                }
            }
            .allowsHitTesting(false)
            .schemeBasedForegroundStyle()
            
        } primaryAction: {
            calProps.showPayMethodSheet = true
        }
        .sheet(isPresented: $calProps.showPayMethodSheet) {
            //TouchAndHoldMonthToFilterCategoriesTip.didTouchMonthName.sendDonation()
            startingAmountSheetDismissed()
        } content: {
            PayMethodSheet(payMethod: $calModel.sPayMethod, whichPaymentMethods: .all, showStartingAmountOption: true, showNoneOption: true)
                //.navigationTransition(.zoom(sourceID: "paymentMethodButton", in: paymentMethodMenuButtonNamespace))
        }
        .sheet(isPresented: $calProps.showCategorySheet) {
            MultiCategorySheet(categories: $calModel.sCategories, categoryGroup: .constant([]))
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
#endif
