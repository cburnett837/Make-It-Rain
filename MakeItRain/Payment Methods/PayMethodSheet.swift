//
//  PayMethodSheet.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/21/24.
//

import SwiftUI

//
//struct PayMethodSheetLite: View {
//    private enum WhichView: String { case select, edit }
//    @AppStorage("paymentMethodSheetViewMode") private var paymentMethodSheetViewMode: WhichView = .select
//    @Local(\.useWholeNumbers) var useWholeNumbers
//    @Local(\.useBusinessLogos) var useBusinessLogos
//
//    @Environment(\.layoutDirection) private var layoutDirection: LayoutDirection
//    @Environment(\.colorScheme) private var colorScheme
//    @Environment(\.dismiss)private var dismiss
//    @Environment(CalendarModel.self) private var calModel
//    @Environment(PayMethodModel.self) private var payModel
//    @Environment(PlaidModel.self) private var plaidModel
//    
//    @Environment(FuncModel.self) private var funcModel
//    
//    @FocusState private var focusedField: Int?
//    @State private var searchText = ""
//    @State private var sections: Array<PaySection> = []
//    //@State private var hoveredID: String?
//    
//    @Binding var payMethod: CBPaymentMethod?
//    let whichPaymentMethods: ApplicablePaymentMethods = .all
//    var showStartingAmountOption: Bool = true
//    var showNoneOption: Bool = true
//    
//    
//    var monthText: String {
//        if calModel.isPlayground {
//            "\(calModel.sMonth.name) Playground"
//        } else {
//            "\(calModel.sMonth.actualNum)/\(String(calModel.sMonth.year))"
//        }
//        
//    }
//    
//    var body: some View {
//        let _ = Self._printChanges()
//        NavigationStack {
//            if showStartingAmountOption {
//                pagePicker
//            }
//            
//            StandardContainerWithToolbar(.list, scrollDismissesKeyboard: .never) {
//                if sections.flatMap({ $0.payMethods }).isEmpty {
//                    ContentUnavailableView("No accounts found", systemImage: "exclamationmark.magnifyingglass")
//                } else {
//                    if paymentMethodSheetViewMode == .select {
//                        content
//                        if showNoneOption {
//                            noneSection
//                        }
//                        
//                    } else {
//                        startingAmounts
//                    }
//                }
//            }
//            .task { prepareView() }
//            .searchable(text: $searchText, prompt: Text("Search"))
//            .navigationTitle(paymentMethodSheetViewMode == .select ? "Accounts" : "Starting Amounts \(monthText)")
//            #if os(iOS)
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .topBarLeading) { moreMenu }
//                DefaultToolbarItem(kind: .search, placement: .bottomBar)
//                
//                ToolbarSpacer(.flexible, placement: AppState.shared.isIpad ? .topBarLeading : .bottomBar)
//                ToolbarItem(placement: AppState.shared.isIpad ? .topBarLeading : .bottomBar) { PayMethodSortMenu(sections: $sections) }
//                
//                ToolbarItem(placement: .topBarTrailing) { closeButton }
//            }
//            .onChange(of: searchText) { populateSections() }
//            /// Update the sheet if viewing and something changes on another device.
//            .onChange(of: payModel.paymentMethods.filter { !$0.isHidden && !$0.isPrivate}.count) {
//                populateSections()
//            }
//            #endif
//        }
//        .background(Color(.systemBackground))
//    }
//    
//    
//    var content: some View {
//        ForEach(sections) { section in
//            if !section.payMethods.isEmpty {
//                Section(section.kind.rawValue) {
//                    ForEach(section.payMethods) { meth in
//                        methLine(meth)
//                            .onTapGesture {
//                                selectPaymentMethod(meth)
//                            }
//                    }
//                }
//            }
//        }
//    }
//    
//    
//    var moreMenu: some View {
//        Menu {
//            useBusinessLogosToggle
//        } label: {
//            Image(systemName: "ellipsis")
//                .schemeBasedForegroundStyle()
//        }
//    }
//    
//    
//    var useBusinessLogosToggle: some View {
//        Toggle(isOn: $useBusinessLogos) {
//            Text("Use Business Logos")
//        }
//    }
//    
//    
//    var noneSection: some View {
//        Section {
//            HStack {
//                Text("None")
//                Spacer()
//                if payMethod == nil {
//                    Image(systemName: "checkmark")
//                }
//            }
//            .schemeBasedForegroundStyle()
//            .contentShape(Rectangle())
//            .onTapGesture {
//                payMethod = nil
//                dismiss()
//            }
//        } footer: {
//            Text("Show all transactions and their daily sum.")
//        }
//    }
//    
//    
//    var pagePicker: some View {
//        Picker("", selection: $paymentMethodSheetViewMode) {
//            Text("Select Account")
//                .tag(WhichView.select)
//            Text("Edit Starting Amounts")
//                .tag(WhichView.edit)
//        }
//        .labelsHidden()
//        .pickerStyle(.segmented)
//        .scenePadding(.horizontal)
//        //.padding(.bottom, 5)
//        .background(Color(.systemBackground)) // force matching
//    }
//    
//    
//    @ViewBuilder func methLine(_ meth: CBPaymentMethod) -> some View {
//        HStack {
//            Label {
//                VStack(alignment: .leading) {
//                    Text(meth.title)
//                    plaidBalance(meth)
//                }
//            } icon: {
//                //methColorCircle(meth)
//                BusinessLogo(parent: meth, fallBackType: meth.isUnified ? .gradient : .color)
//            }
//                                            
//            Spacer()
//            
//            transactionCountBadge(meth)
//                                 
//            if payMethod?.id == meth.id {
//                Image(systemName: "checkmark")
//            }
//        }
//        .contentShape(Rectangle())
//    }
//   
//    
//    @ViewBuilder func transactionCountBadge(_ meth: CBPaymentMethod) -> some View {
//        let count = calModel.getTransCount(for: meth, and: calModel.sMonth)
//        if count > 0 {
//            TextWithCircleBackground(text: "\(count)")
//        }
//    }
//    
//    
//    @ViewBuilder func plaidBalance(_ meth: CBPaymentMethod) -> some View {
//        if meth.isUnified {
//            if meth.isDebit {
//                Text("\(funcModel.getPlaidDebitSums().currencyWithDecimals(useWholeNumbers ? 0 : 2))")
//                    .foregroundStyle(.gray)
//                    .font(.caption)
//            } else {
//                Text("\(funcModel.getPlaidCreditSums().currencyWithDecimals(useWholeNumbers ? 0 : 2))")
//                    .foregroundStyle(.gray)
//                    .font(.caption)
//            }
//        } else {
//            if let balance = plaidModel.balances.filter({ $0.payMethodID == meth.id }).first {
//                Text("\(balance.amount.currencyWithDecimals(useWholeNumbers ? 0 : 2)) (\(Date().timeSince(balance.enteredDate)))")
//                    .foregroundStyle(.gray)
//                    .font(.caption)
//            }
//        }
//    }
//    
//    
//    @ViewBuilder var startingAmounts: some View {
//        ForEach(sections) { section in
//            Section(section.kind.rawValue) {
//                ForEach(section.payMethods) { meth in
//                    if let amount = calModel.sMonth.startingAmounts.filter ({ $0.payMethod.id == meth.id }).first {
//                        StartingAmountLine(startingAmount: amount, payMethod: amount.payMethod) { meth in
//                            selectPaymentMethod(meth)
//                        }
//                    }
//                }
//            }
//        }
//    }
//    
//    var closeButton: some View {
//        Button {
//            dismiss()
//        } label: {
//            Image(systemName: "xmark")
//                .schemeBasedForegroundStyle()
//        }
//    }
//        
//    
//    func prepareView() {
//        populateSections()
//        if showStartingAmountOption {
//            for each in calModel.sMonth.startingAmounts {
//                each.deepCopy(.create)
//            }
//        }
//    }
//    
//    
//    func populateSections() {
//        sections = payModel.getApplicablePayMethods(
//            type: whichPaymentMethods,
//            calModel: calModel,
//            plaidModel: plaidModel,
//            searchText: $searchText
//        )
//    }
//    
//    
//    func selectPaymentMethod(_ meth: CBPaymentMethod) {
//        payMethod = meth
//        dismiss()
//    }
//}
//

public enum PaymentMethodFilterMode: String, CaseIterable {
    case all, justPrimary, primaryAndSecondary
    
    var prettyValue: String {
        switch self {
        case .all:
            "All Accounts"
        case .justPrimary:
            "Primary Accounts"
        case .primaryAndSecondary:
            "Primary & Secondary Accounts"
        }
    }
    
    static func fromString(_ theString: String) -> Self {
        switch theString {
        case "all": return .all
        case "justPrimary": return .justPrimary
        case "primaryAndSecondary": return .primaryAndSecondary
        default: return .all
        }
    }
}

struct PayMethodSheet: View {
    private enum WhichView: String { case select, edit }
        
    @AppStorage("paymentMethodSheetViewMode") private var paymentMethodSheetViewMode: WhichView = .select
    @Local(\.paymentMethodFilterMode) var paymentMethodFilterMode
    @Local(\.useWholeNumbers) var useWholeNumbers
    @Local(\.useBusinessLogos) var useBusinessLogos

    @Environment(\.layoutDirection) private var layoutDirection: LayoutDirection
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss)private var dismiss
    @Environment(CalendarModel.self) private var calModel
    @Environment(PayMethodModel.self) private var payModel
    @Environment(PlaidModel.self) private var plaidModel
    @Environment(FuncModel.self) private var funcModel
    
    @FocusState private var focusedField: Int?
    @State private var searchText = ""
    @State private var sections: Array<PaySection> = []
    //@State private var hoveredID: String?
    
    @Binding var payMethod: CBPaymentMethod?
    //var trans: CBTransaction?
    //let calcAndSaveOnChange: Bool
    let whichPaymentMethods: ApplicablePaymentMethods
    var isPendingSmartTransaction: Bool
    var showStartingAmountOption: Bool
    var showNoneOption: Bool
    
//    init(
//        payMethod: Binding<CBPaymentMethod?>,
//        whichPaymentMethods: ApplicablePaymentMethods,
//        showStartingAmountOption: Bool = false,
//        showNoneOption: Bool = false
//    ) {
//        //print("-- \(#function)")
//        self._payMethod = payMethod
//        //self.trans = nil
//        //self.calcAndSaveOnChange = false
//        self.whichPaymentMethods = whichPaymentMethods
//        self.isPendingSmartTransaction = false
//        self.showStartingAmountOption = showStartingAmountOption
//        self.showNoneOption = showNoneOption
//        
//        if !showStartingAmountOption {
//            self.paymentMethodSheetViewMode = .select
//        }
//    }
    
    init(
        payMethod: Binding<CBPaymentMethod?>,
        //trans: CBTransaction?,
        //calcAndSaveOnChange: Bool,
        whichPaymentMethods: ApplicablePaymentMethods,
        isPendingSmartTransaction: Bool = false,
        showStartingAmountOption: Bool = false,
        showNoneOption: Bool = false
    ) {
        //print("-- \(#function)")
        self._payMethod = payMethod
        //self.trans = trans
        //self.calcAndSaveOnChange = calcAndSaveOnChange
        self.whichPaymentMethods = whichPaymentMethods
        self.isPendingSmartTransaction = isPendingSmartTransaction
        self.showStartingAmountOption = showStartingAmountOption
        self.showNoneOption = showNoneOption
        
        if !showStartingAmountOption {
            self.paymentMethodSheetViewMode = .select
        }
    }
    
    //    var filteredSections: Array<PaySection> {
    //        if searchText.isEmpty {
    //            return sections
    //        } else {
    //            return sections
    //                .filter { !$0.payMethods.filter { $0.title.localizedCaseInsensitiveContains(searchText) }.isEmpty }
    //        }
    //    }
    
    var monthText: String {
        if calModel.isPlayground {
            "\(calModel.sMonth.name) Playground"
        } else {
            "\(calModel.sMonth.actualNum)/\(String(calModel.sMonth.year))"
        }
        
    }
    
    //    var debitMethods: [CBPaymentMethod] {
    //        payModel.paymentMethods
    //            .filter { $0.accountType == .checking }
    //            .filter { $0.isPermitted }
    //            .filter { !$0.isHidden }
    //            .filter { searchText.isEmpty ? true : $0.title.localizedCaseInsensitiveContains(searchText) }
    //    }
    //
    //    var creditMethods: [CBPaymentMethod] {
    //        payModel.paymentMethods
    //            .filter { $0.accountType == .credit || $0.accountType == .loan }
    //            .filter { $0.isPermitted }
    //            .filter { !$0.isHidden }
    //            .filter { searchText.isEmpty ? true : $0.title.localizedCaseInsensitiveContains(searchText) }
    //    }
    //
    //    var otherMethods: [CBPaymentMethod] {
    //        payModel.paymentMethods
    //            .filter { $0.accountType != .checking && $0.accountType != .credit && $0.accountType != .loan && !$0.isUnified }
    //            .filter { $0.isPermitted }
    //            .filter { !$0.isHidden }
    //            .filter { searchText.isEmpty ? true : $0.title.localizedCaseInsensitiveContains(searchText) }
    //    }
    
    
    var body: some View {
        //let _ = Self._printChanges()
        NavigationStack {
//            if showStartingAmountOption {
//                pagePicker
//                    .background(Color(uiColor: .systemGroupedBackground))
//            }
            
            Group {
                if sections.flatMap({ $0.payMethods }).isEmpty && !searchText.isEmpty {
                    ContentUnavailableView("No accounts found", systemImage: "exclamationmark.magnifyingglass")
                } else {
                    StandardContainerWithToolbar(.list, scrollDismissesKeyboard: .never) {
                        if sections.flatMap({ $0.payMethods }).isEmpty && !searchText.isEmpty {
                            ContentUnavailableView("No accounts found", systemImage: "exclamationmark.magnifyingglass")
                        } else {
                            if paymentMethodSheetViewMode == .select {
                                if showNoneOption {
                                    noneSection
                                }
                                
                                content
                                                                
                            } else {
                                startingAmounts
                            }
                        }
                    }
                }
            }
            .if(AppState.shared.isIphone) {
                $0.safeAreaBar(edge: .top) {
                    if showStartingAmountOption {
                        pagePicker
                            //.background(Color(uiColor: .systemGroupedBackground))
                    }
                }
            }
            
            
                        
            .task { prepareView() }
            .onChange(of: paymentMethodFilterMode) { populateSections() }
            .searchable(text: $searchText, prompt: Text("Search"))
            .navigationTitle(paymentMethodSheetViewMode == .select ? "Accounts" : "Starting Amounts \(monthText)")
            .if(AppState.shared.isIpad) {
                $0.toolbarTitleMenu {
                    Picker("", selection: $paymentMethodSheetViewMode) {
                        Text("Accounts")
                            .tag(WhichView.select)
                        Text("Starting Amounts")
                            .tag(WhichView.edit)
                    }
                    .labelsHidden()
                }
            }
                
            
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { moreMenu }
                if AppState.shared.isIphone {
                    ToolbarItem(placement: .bottomBar) { PayMethodFilterMenu() }
                }
                
                ToolbarSpacer(.flexible, placement: AppState.shared.isIpad ? .topBarLeading : .bottomBar)
                
                //if AppState.shared.isIphone {
                    DefaultToolbarItem(kind: .search, placement: .bottomBar)
                //}
                
                ToolbarSpacer(.flexible, placement: AppState.shared.isIpad ? .topBarLeading : .bottomBar)
                ToolbarItem(placement: AppState.shared.isIpad ? .topBarLeading : .bottomBar) { PayMethodSortMenu(sections: $sections) }
                
                if AppState.shared.isIpad {
                    ToolbarSpacer(.flexible, placement: .topBarLeading)
                    ToolbarItem(placement: .topBarLeading) { PayMethodFilterMenu() }
                
//                    ToolbarItem(placement: .topBarTrailing) {
//                        Picker("", selection: $paymentMethodSheetViewMode) {
//                            Text("Accounts")
//                                .tag(WhichView.select)
//                            Text("Starting Amounts")
//                                .tag(WhichView.edit)
//                        }
//                        .labelsHidden()
//                        //.pickerStyle(.segmented)
//                    }
//                    ToolbarSpacer(.flexible, placement: .topBarTrailing)
                }
                ToolbarItem(placement: .topBarTrailing) { closeButton }
            }
            .onChange(of: searchText) { populateSections() }
            /// Update the sheet if viewing and something changes on another device.
            .onChange(of: payModel.paymentMethods.filter { !$0.isHidden && !$0.isPrivate }.count) {
                populateSections()
            }
            #endif
        }
        .background(Color(uiColor: .systemGroupedBackground))
        //.background(Color(.systemBackground))
    }
    
    
    var content: some View {
        ForEach(sections) { section in
            if !section.payMethods.isEmpty {
                Section(section.kind.rawValue) {
                    ForEach(section.payMethods) { meth in
                        methLine(meth)
                            .onTapGesture {
                                selectPaymentMethod(meth)
                            }
                    }
                }
            }
        }
    }
    
    
    var moreMenu: some View {
        Menu {
            useBusinessLogosToggle
        } label: {
            Image(systemName: "ellipsis")
                .schemeBasedForegroundStyle()
        }
    }
    
    
    var useBusinessLogosToggle: some View {
        Toggle(isOn: $useBusinessLogos) {
            Text("Use Business Logos")
        }
    }
    
    
    var noneSection: some View {
        Section {
            HStack {
                Text("None")
                Spacer()
                if payMethod == nil {
                    Image(systemName: "checkmark")
                }
            }
            .schemeBasedForegroundStyle()
            .contentShape(Rectangle())
            .onTapGesture {
                payMethod = nil
                dismiss()
            }
        } footer: {
            Text("Show all transactions and their daily sum.")
        }
    }
    
    
    var pagePicker: some View {
        Picker("", selection: $paymentMethodSheetViewMode) {
            Text("Accounts")
                .tag(WhichView.select)
            Text("Starting Amounts")
                .tag(WhichView.edit)
        }
        .labelsHidden()
        .pickerStyle(.segmented)
        .scenePadding(.horizontal)
        //.padding(.bottom, 5)
        .background(Color(uiColor: .systemGroupedBackground))
        //.background(Color(.systemBackground)) // force matching
    }
    
    
    @ViewBuilder
    func methLine(_ meth: CBPaymentMethod) -> some View {
        HStack {
            Label {
                VStack(alignment: .leading) {
                    Text(meth.title)
                    if showStartingAmountOption
                        && AppState.shared.todayMonth == calModel.sMonth.actualNum
                        && AppState.shared.todayYear == calModel.sMonth.year {
                        Text(funcModel.getPlaidBalancePrettyString(meth, useWholeNumbers: useWholeNumbers) ?? "N/A")
                            .foregroundStyle(.gray)
                            .font(.caption)
                    }
                }
            } icon: {
                //methColorCircle(meth)
                //BusinessLogo(parent: meth, fallBackType: meth.isUnified ? .gradient : .color)
                BusinessLogo(config: .init(
                    parent: meth,
                    fallBackType: meth.isUnified ? .gradient : .color
                ))
            }
                                            
            Spacer()
            if showStartingAmountOption {
                transactionCountBadge(meth)
            }
            
                                 
            if payMethod?.id == meth.id {
                Image(systemName: "checkmark")
            }
        }
        .contentShape(Rectangle())
    }
   
    
    @ViewBuilder
    func transactionCountBadge(_ meth: CBPaymentMethod) -> some View {
        //if trans == nil {
            let count = calModel.getTransCount(for: meth, and: calModel.sMonth)
            if count > 0 {
                TextWithCircleBackground(text: "\(count)")
            }
        //}
    }
    
    
//    @ViewBuilder
//    func plaidBalance(_ meth: CBPaymentMethod) -> some String? {
//        if /*trans == nil &&*/ calModel.sMonth.actualNum == AppState.shared.todayMonth && calModel.sMonth.year == AppState.shared.todayYear {
//            var result: String? {
//                if meth.isUnified {
//                    if meth.isDebit {
//                        return "\(funcModel.getPlaidDebitSums().currencyWithDecimals(useWholeNumbers ? 0 : 2))"
//                    } else {
//                        return "\(funcModel.getPlaidCreditSums().currencyWithDecimals(useWholeNumbers ? 0 : 2))"
//                    }
//                } else if meth.accountType == .cash {
//                    let bal = calModel.calculateChecking(for: calModel.sMonth, using: meth, and: .giveMeEodAsOfToday)
//                    let balStr = bal.currencyWithDecimals(useWholeNumbers ? 0 : 2)
//                    return "\(balStr) (Manually)"
//                    
//                } else if let balance = plaidModel.balances.filter({ $0.payMethodID == meth.id }).first {
//                    return "\(balance.amount.currencyWithDecimals(useWholeNumbers ? 0 : 2)) (\(Date().timeSince(balance.enteredDate)))"
//                }
//                
//                return nil
//            }
//            
//            return result
//            
////            if let result {
////                Text(result)
////                    .foregroundStyle(.gray)
////                    .font(.caption)
////            }
//            
//        }
//    }
//    
    
    @ViewBuilder var startingAmounts: some View {
        ForEach(sections) { section in
            Section(section.kind.rawValue) {
                ForEach(section.payMethods) { meth in
                    if let amount = calModel.sMonth.startingAmounts.filter ({ $0.payMethod.id == meth.id }).first {
                        StartingAmountLine(startingAmount: amount, payMethod: amount.payMethod) { meth in
                            selectPaymentMethod(meth)
                        }
                    }
                }
            }
        }
    }
    
    
//    @ViewBuilder var startingAmountsOG: some View {
//        let debitMethods = sections.filter({ $0.kind == .debit }).first?.payMethods
//        let creditMethods = sections.filter({ $0.kind == .credit }).first?.payMethods
//        let otherMethods = sections.filter({ $0.kind == .other }).first?.payMethods
//        
//        Group {
//            if let debitMethods = debitMethods, !debitMethods.isEmpty {
//                Section("Debit") {
//                    ForEach(debitMethods.startIndex..<debitMethods.endIndex, id: \.self) { i in
//                        if let amount = calModel.sMonth.startingAmounts
//                        .filter ({ $0.payMethod.id == debitMethods[i].id })
//                        .filter ({ $0.payMethod.isPermitted && !$0.payMethod.isHidden })
//                        .first {
//                            let focusID = (i + 1)
//                            StartingAmountLine(startingAmount: amount, payMethod: amount.payMethod, focusedField: _focusedField, focusID: focusID)
//                        }
//                    }
//                }
//            }
//                                
//            if let creditMethods = creditMethods,
//            let debitMethods = debitMethods,
//            !creditMethods.isEmpty  {
//                Section("Credit") {
//                    ForEach(creditMethods.startIndex..<creditMethods.endIndex, id: \.self) { i in
//                        if let amount = calModel.sMonth.startingAmounts
//                        .filter ({ $0.payMethod.id == creditMethods[i].id })
//                        .filter ({ $0.payMethod.isPermitted && !$0.payMethod.isHidden })
//                        .first {
//                            let focusID = (i + debitMethods.count + 1)
//                            StartingAmountLine(startingAmount: amount, payMethod: amount.payMethod, focusedField: _focusedField, focusID: focusID)
//                        }
//                    }
//                }
//            }
//            
//            if let otherMethods = otherMethods,
//            let debitMethods = debitMethods,
//            let creditMethods = creditMethods,
//            !otherMethods.isEmpty {
//                Section("Other") {
//                    ForEach(otherMethods.startIndex..<otherMethods.endIndex, id: \.self) { i in
//                        if let amount = calModel.sMonth.startingAmounts
//                        .filter ({ $0.payMethod.id == otherMethods[i].id })
//                        .filter ({ $0.payMethod.isPermitted && !$0.payMethod.isHidden })
//                        .first {
//                            let focusID = (i + debitMethods.count + creditMethods.count + 1)
//                            StartingAmountLine(startingAmount: amount, payMethod: amount.payMethod, focusedField: _focusedField, focusID: focusID)
//                        }
//                    }
//                }
//            }
//        }
//    }
//    
    var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .schemeBasedForegroundStyle()
        }
    }
    
    
//    var header: some View {
//        Group {
//            if showStartingAmountOption {
//                SheetHeader(
//                    title: paymentMethodSheetViewMode == .select ? "Select Account" : "Edit Starting Amounts",
//                    close: { dismiss() },
//                    view1: { editButton }
//                )
//            } else {
//                SheetHeader(
//                    title: "Select Account",
//                    close: { dismiss() }
//                )
//            }
//        }
//    }
//    
//    
//    var footer: some View {
//        Group {
//            if paymentMethodSheetViewMode == .edit {
//                Text("\(calModel.sMonth.name) \(String(calModel.sMonth.year))")
//                   .font(.caption2)
//                   .foregroundStyle(.gray)
//            } else {
//                EmptyView()
//            }
//        }
//    }
    
        
    
    func prepareView() {
        populateSections()
        if showStartingAmountOption {
            for each in calModel.sMonth.startingAmounts {
                each.deepCopy(.create)
            }
            
            //funcModel.prepareStartingAmounts()
            
//            for payMethod in payModel.paymentMethods {
//                calModel.prepareStartingAmount(for: payMethod)
//                if payMethod.isUnified {
//                    let _ = calModel.updateUnifiedStartingAmount(month: calModel.sMonth, for: payMethod.accountType)
//                }
//            }
        }
    }
    
    
    func populateSections() {
        sections = payModel.getApplicablePayMethods(
            type: whichPaymentMethods,
            calModel: calModel,
            plaidModel: plaidModel,
            searchText: $searchText
        )
    }
    
    
    func selectPaymentMethod(_ meth: CBPaymentMethod) {
        payMethod = meth
        
//        if calcAndSaveOnChange && trans != nil {
//            trans!.log(field: .payMethod, old: trans!.payMethod?.id, new: meth.id, groupID: UUID().uuidString)
//            
//            payMethod = meth
//            
//            trans!.action = .edit
//            //calModel.saveTransaction(id: trans!.id, isPendingSmartTransaction: isPendingSmartTransaction)
//            Task {
//                await calModel.saveTransaction(id: trans!.id, location: isPendingSmartTransaction ? .smartList : .normalList)
//            }            
//            calModel.tempTransactions.removeAll()
//        } else {
//            payMethod = meth
//        }
        dismiss()
    }
}


fileprivate struct StartingAmountLine: View {
    @Local(\.useWholeNumbers) var useWholeNumbers
    @Environment(\.layoutDirection) private var layoutDirection: LayoutDirection
    @Environment(CalendarModel.self) var calModel
    @Environment(PayMethodModel.self) var payModel
    
    @Bindable var startingAmount: CBStartingAmount
    var payMethod: CBPaymentMethod
    
    var selectPaymentMethod: (CBPaymentMethod) -> ()
    
    @State private var showDialog = false
    @FocusState private var focusedField: Int?
    
    var body: some View {
        HStack {
            Label {
                Text("\(payMethod.title)")
            } icon: {
                //BusinessLogo(parent: payMethod, fallBackType: payMethod.isUnified ? .gradient : .color)
                BusinessLogo(config: .init(
                    parent: payMethod,
                    fallBackType: payMethod.isUnified ? .gradient : .color
                ))
            }
            .contentShape(Rectangle())
            .onTapGesture {
                selectPaymentMethod(payMethod)
            }
            
            Spacer()
            
            Group {
                #if os(iOS)
                if payMethod.isUnified {
                    Text(startingAmount.amountString.isEmpty ? (useWholeNumbers ? "$0" : "$0.00") : startingAmount.amountString)
                        .foregroundStyle(.secondary)
                } else {
                    iPhoneTextField
                }
                
                #else
                macTextField
                #endif
            }
            .focused($focusedField, equals: 0)
            .formatCurrencyLiveAndOnUnFocus(
                focusValue: 0,
                focusedField: focusedField,
                amountString: startingAmount.amountString,
                amountStringBinding: $startingAmount.amountString,
                amount: startingAmount.amount
            )
            .task {
                startingAmount.amountString = startingAmount.amount.currencyWithDecimals(useWholeNumbers ? 0 : 2)
            }
        }
    }
    
    #if os(iOS)
    var iPhoneTextField: some View {
        /// WARNING!: Can't use the focus arrows because the textfields won't focus unless they are visible on screen. Veriified with apples dummy project.
        /// https://developer.apple.com/documentation/swiftui/focus-cookbook-sample
        UITextFieldWrapper(placeholder: "Starting Amount", text: $startingAmount.amountString, toolbar: {
            KeyboardToolbarView(
                focusedField: $focusedField,
                accessoryText1: "AutoFill",
                accessoryFunc1: { autoFillAmount() },
                accessoryImage3: "plus.forwardslash.minus",
                accessoryFunc3: { Helpers.plusMinus($startingAmount.amountString) })
        })
        .uiKeyboardType(.custom(.numpad))
        //.uiKeyboardType(useWholeNumbers ? .numberPad : .decimalPad)
        .uiTag(0)
        .uiTextAlignment(layoutDirection == .leftToRight ? .right : .left)
        .uiClearButtonMode(.whileEditing)
        .uiStartCursorAtEnd(true)
    }
    #endif
    
    #if os(macOS)
    var macTextField: some View {
        TextField("Starting Amount", text: $startingAmount.amountString)
            .multilineTextAlignment(.trailing)
            .contextMenu {
                Button("AutoFill") {
                    if calModel.sMonth.num != 0 {
                        let targetMonth = calModel.months.filter { $0.num == calModel.sMonth.num - 1 }.first!
                        let _ = calModel.calculateTotal(for: targetMonth, using: payMethod)
                        let eodTotal = targetMonth.days.last!.eodTotal
                        startingAmount.amountString = eodTotal.currencyWithDecimals(useWholeNumbers ? 0 : 2)
                    }
                }
            }
    }
    #endif
    
    func autoFillAmount() {
        if calModel.sMonth.num != 0 {
            let targetMonth = calModel.months.filter { $0.num == calModel.sMonth.num - 1 }.first!            
            let eod = calModel.calculateTotal(for: targetMonth, using: payMethod, and: .giveMeLastDayEod)
            let eodTotal = eod//targetMonth.days.last!.eodTotal
            startingAmount.amountString = eodTotal.currencyWithDecimals(useWholeNumbers ? 0 : 2)
        }
    }
}

