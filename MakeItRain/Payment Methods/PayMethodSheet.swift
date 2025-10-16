//
//  PayMethodSheet.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/21/24.
//

import SwiftUI

struct PayMethodSheet: View {
    private enum WhichView: String { case select, edit }
    @AppStorage("paymentMethodSheetViewMode") private var paymentMethodSheetViewMode: WhichView = .select
    @Local(\.useWholeNumbers) var useWholeNumbers

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
    var trans: CBTransaction?
    let calcAndSaveOnChange: Bool
    let whichPaymentMethods: ApplicablePaymentMethods
    var isPendingSmartTransaction: Bool
    var showStartingAmountOption: Bool
    
    init(payMethod: Binding<CBPaymentMethod?>, whichPaymentMethods: ApplicablePaymentMethods, showStartingAmountOption: Bool = false) {
        //print("-- \(#function)")
        self._payMethod = payMethod
        self.trans = nil
        self.calcAndSaveOnChange = false
        self.whichPaymentMethods = whichPaymentMethods
        self.isPendingSmartTransaction = false
        self.showStartingAmountOption = showStartingAmountOption
        
        if !showStartingAmountOption {
            self.paymentMethodSheetViewMode = .select
        }
    }
    
    init(payMethod: Binding<CBPaymentMethod?>, trans: CBTransaction?, calcAndSaveOnChange: Bool, whichPaymentMethods: ApplicablePaymentMethods, isPendingSmartTransaction: Bool = false, showStartingAmountOption: Bool = false) {
        //print("-- \(#function)")
        self._payMethod = payMethod
        self.trans = trans
        self.calcAndSaveOnChange = calcAndSaveOnChange
        self.whichPaymentMethods = whichPaymentMethods
        self.isPendingSmartTransaction = isPendingSmartTransaction
        self.showStartingAmountOption = showStartingAmountOption
        
        if !showStartingAmountOption {
            self.paymentMethodSheetViewMode = .select
        }
    }
    
    var filteredSections: Array<PaySection> {
        if searchText.isEmpty {
            return sections
        } else {
            return sections
                .filter { !$0.payMethods.filter { $0.title.localizedStandardContains(searchText) }.isEmpty }
        }
    }
    
    var monthText: String {
        if calModel.isPlayground {
            "\(calModel.sMonth.name) Playground"
        } else {
            "\(calModel.sMonth.actualNum)/\(String(calModel.sMonth.year))"
        }
        
    }
    
    var debitMethods: [CBPaymentMethod] {
        payModel.paymentMethods
            .filter { $0.accountType == .checking }
            .filter { $0.isAllowedToBeViewedByThisUser }
            .filter { !$0.isHidden }
            .filter { searchText.isEmpty ? true : $0.title.localizedStandardContains(searchText) }
    }
    
    var creditMethods: [CBPaymentMethod] {
        payModel.paymentMethods
            .filter { $0.accountType == .credit || $0.accountType == .loan }
            .filter { $0.isAllowedToBeViewedByThisUser }
            .filter { !$0.isHidden }
            .filter { searchText.isEmpty ? true : $0.title.localizedStandardContains(searchText) }
    }
    
    var otherMethods: [CBPaymentMethod] {
        payModel.paymentMethods
            .filter { $0.accountType != .checking && $0.accountType != .credit && $0.accountType != .loan && !$0.isUnified }
            .filter { $0.isAllowedToBeViewedByThisUser }
            .filter { !$0.isHidden }
            .filter { searchText.isEmpty ? true : $0.title.localizedStandardContains(searchText) }
    }
    
    
    var body: some View {
        NavigationStack {
            StandardContainerWithToolbar(.list, scrollDismissesKeyboard: .never) {
                if filteredSections.isEmpty {
                    ContentUnavailableView("No accounts found", systemImage: "exclamationmark.magnifyingglass")
                } else {
                    if paymentMethodSheetViewMode == .select {
                        content
                    } else {
                        startingAmounts
                    }
                }
            }
            //.scrollEdgeEffectStyle(.hard, for: .all)
            .task { prepareView() }
            .searchable(text: $searchText, prompt: Text("Search"))
            .navigationTitle(paymentMethodSheetViewMode == .select ? "Select Account" : "Starting Amounts \(monthText)")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            //.navigationSubtitle(paymentMethodSheetViewMode == .edit ? "\(calModel.sMonth.name) \(String(calModel.sMonth.year))" : "")
//            .if(paymentMethodSheetViewMode == .edit) {
//                $0.navigationSubtitle("\(calModel.sMonth.name) \(String(calModel.sMonth.year))")
//            }
            .toolbar {
                if showStartingAmountOption {
                    ToolbarItem(placement: .topBarLeading) { editButton }
                }
                
                ToolbarItem(placement: .topBarTrailing) { closeButton }
            }
            #endif
        }
    }
        
    
    var content: some View {
        ForEach(filteredSections) { section in
            if !section.payMethods.isEmpty {
                Section(section.kind.rawValue) {
                    ForEach(searchText.isEmpty ? section.payMethods : section.payMethods.filter { $0.title.localizedStandardContains(searchText) }) { meth in
                        HStack {
                            Image(systemName: "circle.fill")
                                .if(meth.isUnified) {
                                    $0.foregroundStyle(AngularGradient(gradient: Gradient(colors: [.red, .yellow, .green, .blue, .purple, .red]), center: .center))
                                }
                                .if(!meth.isUnified) {
                                    $0.foregroundStyle(meth.color)
                                }
                            Text(meth.title)
                                //.bold(meth.isUnified)
                            Spacer()
                            
                            if trans == nil {
                                let count = calModel.getTransCount(for: meth, and: calModel.sMonth)
                                if count > 0 {
                                    TextWithCircleBackground(text: "\(count)")
                                }
                            }
                                                        
                            if payMethod?.id == meth.id {
                                Image(systemName: "checkmark")
                            }
                        }
                        //.background(hoveredID == meth.id ? Color(.systemFill) : Color.clear)

                        .contentShape(Rectangle())
                        .onTapGesture {
                            if calcAndSaveOnChange && trans != nil {
                                trans!.log(field: .payMethod, old: trans!.payMethod?.id, new: meth.id, groupID: UUID().uuidString)
                                
                                payMethod = meth
                                
                                trans!.action = .edit
                                //calModel.saveTransaction(id: trans!.id, isPendingSmartTransaction: isPendingSmartTransaction)
                                calModel.saveTransaction(id: trans!.id, location: isPendingSmartTransaction ? .smartList : .normalList)
                                calModel.tempTransactions.removeAll()
                                
//                                if isPendingSmartTransaction {
//                                    calModel.pendingSmartTransaction = nil
//                                }
                            } else {
                                payMethod = meth
                            }
                            dismiss()
                        }
                        #if os(macOS)
//                        .onHover {
//                            if $0 {
//                                hoveredID = meth.id
//                            } else {
//                                hoveredID = nil
//                            }
//                        }
                        #endif
                    }
                }
            }
        }
    }
    
    
    var startingAmounts: some View {
        Group {
            if !debitMethods.isEmpty {
                Section("Debit") {
                    if searchText.isEmpty {
                        let amount = calModel.sMonth.startingAmounts.filter { $0.payMethod.accountType == .unifiedChecking }.first
                        StartingAmountLineUneditable(startingAmount: amount!, payMethod: amount!.payMethod)
                        
                    }
                    
                    ForEach(debitMethods.startIndex..<debitMethods.endIndex, id: \.self) { i in
                        let amount = calModel.sMonth.startingAmounts.filter { $0.payMethod.id == debitMethods[i].id }.first
                        let focusID = (i + 1)
                        StartingAmountLine(startingAmount: amount!, payMethod: amount!.payMethod, focusedField: _focusedField, focusID: focusID)
                    }
                }
            }
                                
            if !creditMethods.isEmpty {
                Section("Credit") {
                    if searchText.isEmpty {
                        let amount = calModel.sMonth.startingAmounts.filter { $0.payMethod.accountType == .unifiedCredit }.first
                        StartingAmountLineUneditable(startingAmount: amount!, payMethod: amount!.payMethod)
                    }
                    
                    ForEach(creditMethods.startIndex..<creditMethods.endIndex, id: \.self) { i in
                        let amount = calModel.sMonth.startingAmounts.filter { $0.payMethod.id == creditMethods[i].id }.first
                        let focusID = (i + debitMethods.count + 1)
                        StartingAmountLine(startingAmount: amount!, payMethod: amount!.payMethod, focusedField: _focusedField, focusID: focusID)
                    }
                }
            }
            
            if !otherMethods.isEmpty {
                Section("Other") {
                    ForEach(otherMethods.startIndex..<otherMethods.endIndex, id: \.self) { i in
                        let amount = calModel.sMonth.startingAmounts.filter { $0.payMethod.id == otherMethods[i].id }.first
                        let focusID = (i + debitMethods.count + creditMethods.count + 1)
                        StartingAmountLine(startingAmount: amount!, payMethod: amount!.payMethod, focusedField: _focusedField, focusID: focusID)
                    }
                }
            }
        }
    }
    
    
    var editButton: some View {
        Button {
            paymentMethodSheetViewMode = paymentMethodSheetViewMode == .select ? .edit : .select
        } label: {
            //Image(systemName: paymentMethodSheetViewMode == .select ? "dollarsign" : "checklist")
            Image(systemName: paymentMethodSheetViewMode == .select ? "square.and.pencil" : "list.bullet")
                .foregroundStyle(colorScheme == .dark ? .white : .black)
        }
        .contentTransition(.symbolEffect(.replace))
        //.buttonStyle(.glassProminent)
    }
    
    
    var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .foregroundStyle(colorScheme == .dark ? .white : .black)
        }
        //.buttonStyle(.glassProminent)
        //.tint(confirmButtonTint)
        //.background(confirmButtonTint)
        //.foregroundStyle(confirmButtonTint)
        //}
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
    
        
    struct StartingAmountLine: View {
        @Local(\.useWholeNumbers) var useWholeNumbers
        @Environment(\.layoutDirection) private var layoutDirection: LayoutDirection
        @Environment(CalendarModel.self) var calModel
        
        @Bindable var startingAmount: CBStartingAmount
        var payMethod: CBPaymentMethod
        @State private var showDialog = false
        var focusedField: FocusState<Int?>
        var focusID: Int
        
        var body: some View {
            HStack {
                Image(systemName: "circle.fill")
                    .foregroundStyle(payMethod.color)
                
                Text("\(payMethod.title)")
                Spacer()
                
                Group {
                    #if os(iOS)
                    /// WARNING!: Can't use the focus arrows because the textfields won't focus unless they are visible on screeb. Veriified with apples dummy project.
                    /// https://developer.apple.com/documentation/swiftui/focus-cookbook-sample
                    UITextFieldWrapper(placeholder: "Starting Amount", text: $startingAmount.amountString, toolbar: {
                        KeyboardToolbarView(
                            focusedField: focusedField.projectedValue,
                            accessoryText1: "AutoFill",
                            accessoryFunc1: {
                                if calModel.sMonth.num != 0 {
                                    let targetMonth = calModel.months.filter { $0.num == calModel.sMonth.num - 1 }.first!
                                    let _ = calModel.calculateTotal(for: targetMonth, using: payMethod)
                                    let eodTotal = targetMonth.days.last!.eodTotal
                                    startingAmount.amountString = eodTotal.currencyWithDecimals(useWholeNumbers ? 0 : 2)
                                }
                            },
                            accessoryImage3: "plus.forwardslash.minus",
                            accessoryFunc3: {
                                Helpers.plusMinus($startingAmount.amountString)
                            })
                    })
                    .uiKeyboardType(useWholeNumbers ? .numberPad : .decimalPad)
                    .uiTag(focusID)
                    .uiTextAlignment(layoutDirection == .leftToRight ? .right : .left)
                    .uiClearButtonMode(.whileEditing)
                    .uiStartCursorAtEnd(true)
                    #else
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
                    #endif
                }
                .focused(focusedField.projectedValue, equals: focusID)
                .formatCurrencyLiveAndOnUnFocus(
                    focusValue: focusID,
                    focusedField: focusedField.wrappedValue,
                    amountString: startingAmount.amountString,
                    amountStringBinding: $startingAmount.amountString,
                    amount: startingAmount.amount
                )
            }
        }
    }
    
    
    struct StartingAmountLineUneditable: View {
        @Local(\.useWholeNumbers) var useWholeNumbers
        
        @Bindable var startingAmount: CBStartingAmount
        var payMethod: CBPaymentMethod
        
        var body: some View {
            HStack {
                Image(systemName: "circle.fill")
                    .foregroundStyle(AngularGradient(gradient: Gradient(colors: [.red, .yellow, .green, .blue, .purple, .red]), center: .center))
                
                Text("\(payMethod.title)")
                Spacer()
                
                Text(startingAmount.amountString.isEmpty ? (useWholeNumbers ? "$0" : "$0.00") : startingAmount.amountString)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    
    func getApplicablePayMethods(type: ApplicablePaymentMethods) -> Array<PaySection> {
        switch type {
        case .all:
            return [
                //PaySection(kind: .combined, payMethods: payModel.paymentMethods.filter { $0.accountType == .unifiedCredit || $0.accountType == .unifiedChecking }),
                PaySection(
                    kind: .debit,
                    payMethods: payModel.paymentMethods
                        .filter { $0.accountType == .checking || $0.accountType == .unifiedChecking }
                        .filter { $0.isAllowedToBeViewedByThisUser }
                        .filter { !$0.isHidden }
                ),
                PaySection(
                    kind: .credit,
                    payMethods: payModel.paymentMethods
                        .filter { $0.accountType == .credit || $0.accountType == .loan || $0.accountType == .unifiedCredit }
                        .filter { $0.isAllowedToBeViewedByThisUser }
                        .filter { !$0.isHidden }
                ),
                PaySection(
                    kind: .other,
                    payMethods: payModel.paymentMethods
                        .filter { ![.unifiedCredit, .unifiedChecking, .credit, .checking, .loan].contains($0.accountType) }
                        .filter { $0.isAllowedToBeViewedByThisUser }
                        .filter { !$0.isHidden }
                )
            ]
            
        case .allExceptUnified:
            return [
                PaySection(
                    kind: .debit,
                    payMethods: payModel.paymentMethods
                        .filter { $0.accountType == .checking }
                        .filter { $0.isAllowedToBeViewedByThisUser }
                        .filter { !$0.isHidden }
                ),
                PaySection(
                    kind: .credit,
                    payMethods: payModel.paymentMethods
                        .filter { $0.accountType == .credit || $0.accountType == .loan }
                        .filter { $0.isAllowedToBeViewedByThisUser }
                        .filter { !$0.isHidden }
                ),
                PaySection(
                    kind: .other,
                    payMethods: payModel.paymentMethods
                        .filter { ![.unifiedCredit, .unifiedChecking, .credit, .checking, .loan].contains($0.accountType) }
                        .filter { $0.isAllowedToBeViewedByThisUser }
                        .filter { !$0.isHidden }
                )
            ]
            
        case .basedOnSelected:
            if calModel.sPayMethod?.accountType == .unifiedChecking {
                return [
                    PaySection(
                    kind: .debit,
                    payMethods: payModel.paymentMethods
                        .filter { $0.accountType == .checking }
                        .filter { $0.isAllowedToBeViewedByThisUser }
                        .filter { !$0.isHidden }
                    )
                ]
    
            } else if calModel.sPayMethod?.accountType == .unifiedCredit {
                return [
                    PaySection(
                    kind: .credit,
                    payMethods: payModel.paymentMethods
                        .filter { $0.accountType == .credit || $0.accountType == .loan }
                        .filter { $0.isAllowedToBeViewedByThisUser }
                        .filter { !$0.isHidden }
                    )
                ]
    
            } else {
                return [
                    PaySection(
                    kind: .other,
                    payMethods: payModel.paymentMethods
                        .filter { ![.unifiedCredit, .unifiedChecking, .credit, .checking, .loan].contains($0.accountType) }
                        .filter { $0.isAllowedToBeViewedByThisUser }
                        .filter { !$0.isHidden }
                    )
                ]
            }
            
        case .remainingAvailbleForPlaid:
            let taken: Array<String> = plaidModel.banks.flatMap ({ $0.accounts.compactMap({ $0.paymentMethodID }) })
            print(taken)
                //.map({ $0.paymentMethodID != nil })
            return [
                PaySection(
                    kind: .debit,
                    payMethods: payModel.paymentMethods
                        .filter { $0.accountType == .checking && !taken.contains($0.id) }
                        .filter { $0.isAllowedToBeViewedByThisUser }
                        .filter { !$0.isHidden }
                ),
                PaySection(
                    kind: .credit,
                    payMethods: payModel.paymentMethods
                        .filter { ($0.accountType == .credit || $0.accountType == .loan) && !taken.contains($0.id) }
                        .filter { $0.isAllowedToBeViewedByThisUser }
                        .filter { !$0.isHidden }
                ),
                PaySection(
                    kind: .other,
                    payMethods: payModel.paymentMethods
                        .filter { ![.unifiedCredit, .unifiedChecking, .credit, .checking].contains($0.accountType) && !taken.contains($0.id) }
                        .filter { $0.isAllowedToBeViewedByThisUser }
                        .filter { !$0.isHidden }
                )
            ]
        }
    }
    
    
    func prepareView() {
        sections = getApplicablePayMethods(type: whichPaymentMethods)
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
}



