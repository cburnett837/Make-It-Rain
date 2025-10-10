//
//  RepeatingTransactionViewMac.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/21/24.
//

import SwiftUI

struct RepeatingTransactionView: View {
    @Local(\.useWholeNumbers) var useWholeNumbers
    @Local(\.colorTheme) var colorTheme
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme

    
    @Bindable var repTransaction: CBRepeatingTransaction
    @Bindable var repModel: RepeatingTransactionModel
    @Bindable var catModel: CategoryModel
    @Bindable var payModel: PayMethodModel
    
    /// This is only here to blank out the selection hilight on the iPhone list
    @Binding var editID: String?
    
    @State private var payMethodMenuColor: Color = Color(.tertiarySystemFill)
    @State private var categoryMenuColor: Color = Color(.tertiarySystemFill)
    
    @State private var showDeleteAlert = false
    @State private var labelWidth: CGFloat = 20.0
        
    var title: String { repTransaction.action == .add ? "New Reoccuring" : "Edit Reoccuring" }
    
    @FocusState private var focusedField: Int?
    @State private var showKeyboardToolbar = false
    
    @State private var showPayMethodSheet = false
    @State private var showCategorySheet = false
    @State private var showColorPicker = false
    
    var deleteButton: some View {
        Button {
            showDeleteAlert = true
        } label: {
            Image(systemName: "trash")
        }
        .sensoryFeedback(.warning, trigger: showDeleteAlert) { !$0 && $1 }
        .tint(.none)
        .confirmationDialog("Delete \"\(repTransaction.title)\"?", isPresented: $showDeleteAlert, actions: {
            Button("Yes", role: .destructive) {
                Task {
                    dismiss()
                    await repModel.delete(repTransaction, andSubmit: true)
                }
            }
            
            //Button("No", role: .cancel) { showDeleteAlert = false }
        }, message: {
            #if os(iOS)
            Text("Delete \"\(repTransaction.title)\"?")
            #endif
        })
    }
    
    var paymentMethodTitle: String {
        if repTransaction.repeatingTransactionType.enumID == .payment {
            "Pay From"
        } else if repTransaction.repeatingTransactionType.enumID == .transfer {
             "Transfer From"
        } else {
            "Pay Meth"
        }
    }
    
    
    var paymentMethod2Title: String {
        if repTransaction.repeatingTransactionType.enumID == .payment {
            "Pay To"
        } else if repTransaction.repeatingTransactionType.enumID == .transfer {
             "Transfer To"
        } else {
            "Pay Meth"
        }
    }
    
    var isRegularTransaction: Bool {
        repTransaction.repeatingTransactionType.enumID == .regular
    }
    
    var isValidToSave: Bool {
        (repTransaction.action == .add && !repTransaction.title.isEmpty && repTransaction.payMethod != nil)
        || (repTransaction.hasChanges() && (!repTransaction.title.isEmpty && repTransaction.payMethod != nil))
    }
    
    
//    var header: some View {
//        Group {
//            SheetHeader(
//                title: title,
//                close: { editID = nil; dismiss() },
//                view3: { deleteButton }
//            )
//            .padding()
//        }
//    }
        
    var body: some View {
        Group {
            #if os(iOS)
            bodyPhone
            #else
            bodyMac
            #endif
        }
        .onPreferenceChange(MaxSizePreferenceKey.self) { labelWidth = max(labelWidth, $0) }
        .task {
            if repTransaction.action == .add {
                repTransaction.category = catModel.categories.filter { $0.isNil }.first!
            }
            
            repTransaction.deepCopy(.create)
            /// Just for formatting.
            repTransaction.amountString = repTransaction.amount.currencyWithDecimals(useWholeNumbers ? 0 : 2)
            repModel.upsert(repTransaction)
                        
            #if os(macOS)
            /// Focus on the title textfield.
            focusedField = 0
            #else
            if repTransaction.action == .add {
                focusedField = 0
            }
            #endif
        }
    }
    
    
    var bodyMac: some View {
        StandardContainer {
            LabeledRow("Name", labelWidth) {
                StandardTextField("Title", text: $repTransaction.title, focusedField: $focusedField, focusValue: 0)
                    .onSubmit { focusedField = 1 }
            }
            
            LabeledRow("Amount", labelWidth) {
                StandardAmountTextField(focusedField: _focusedField, focusID: 1, showSymbol: false, obj: repTransaction)
            }
            
            StandardDivider()
                                    
            LabeledRow(paymentMethodTitle, labelWidth) {
                PayMethodSheetButton(payMethod: $repTransaction.payMethod, whichPaymentMethods: .allExceptUnified)
            }
                        
            if !isRegularTransaction {
                LabeledRow(paymentMethod2Title, labelWidth) {
                    PayMethodSheetButton(payMethod: $repTransaction.payMethodPayTo, whichPaymentMethods: .allExceptUnified)
                }
            }
            
            LabeledRow("Type", labelWidth) {
                Picker("", selection: $repTransaction.repeatingTransactionType) {
                    Text("Regular")
                        .tag(XrefModel.getItem(from: .repeatingTransactionType, byEnumID: .regular))
                    Text("Payment")
                        .tag(XrefModel.getItem(from: .repeatingTransactionType, byEnumID: .payment))
                    Text("Transfer")
                        .tag(XrefModel.getItem(from: .repeatingTransactionType, byEnumID: .transfer))
                }
                .labelsHidden()
                .pickerStyle(.segmented)
            }
            
            StandardDivider()
                                    
            LabeledRow("Category", labelWidth) {
                CategorySheetButton(category: $repTransaction.category)
            }
            
            StandardDivider()
                                
            LabeledRow("Weekdays", labelWidth) {
                WeekdayToggles(repTransaction: repTransaction)
            }
            
            StandardDivider()
            
            LabeledRow("Months", labelWidth) {
                MonthToggles(repTransaction: repTransaction)
            }
            
            StandardDivider()
            
            LabeledRow("Days", labelWidth) {
                DayToggles(repTransaction: repTransaction)
            }
            
            StandardDivider()
            
            LabeledRow("Color", labelWidth) {
                HStack {
                    ColorPicker("", selection: $repTransaction.color, supportsOpacity: false)
                        .labelsHidden()
                    Capsule()
                        .fill(repTransaction.color)
                        .onTapGesture {
                            AppState.shared.showToast(title: "Color Picker", subtitle: "Click the circle to the left to change the color.", body: nil, symbol: "theatermask.and.paintbrush", symbolColor: repTransaction.color)
                        }
                }
            }
            
        } header: {
            SheetHeader(title: title, close: { editID = nil; dismiss() }, view3: { deleteButton })
        }
    }
    
    
    var bodyPhone: some View {
        NavigationStack {
            StandardContainerWithToolbar(.list) {
                Section {
                    titleRow
                    amountRow
                } header: {
                    Text("Title & Amount")
                } footer: {
                    TransactionTypeButton(amountTypeLingo: repTransaction.amountTypeLingo, amountString: $repTransaction.amountString)
                }
                
                Section {
                    payFromRow
                    if !isRegularTransaction { payToRow }
                    typeRow
                } header: {
                    Text("Transaction Details")
                } footer: {
                    Text("Specify a transaction type to organize your transactions. For example, categorizing as a **payment** will allow you specify a pay-to account and will influence the anaytics in the account page.")
                }
                
                Section("Additional Details") {
                    CategorySheetButton3(category: $repTransaction.category)
                    colorRow
                }
                
                Section {
                    VStack(alignment: .leading) {
                        Text("On Specific Weekdays")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                        WeekdayToggles(repTransaction: repTransaction)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("During Specific Months")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                        MonthToggles(repTransaction: repTransaction)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("On Specific Days")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                        DayToggles(repTransaction: repTransaction)
                    }
                    
                } header: {
                    Text("Repeating Schedule")
                } footer: {
                    Text("Select a combo of weekdays, months, and days to repeat the transaction. For example, selecting **Sunday**, **January**, and **15** will create this transaction on every Sunday in January, **and** on January 15th.")
                }
            }
            #if os(iOS)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { deleteButton }
                ToolbarSpacer(.fixed, placement: .topBarLeading)
                ToolbarItem(placement: .topBarTrailing) {
                    if isValidToSave {
                        closeButton
                            #if os(iOS)
                            .buttonStyle(.glassProminent)
                            #endif
                    } else {
                        closeButton
                    }
                }
                
                ToolbarItem(placement: .bottomBar) {
                    EnteredByAndUpdatedByView(enteredBy: repTransaction.enteredBy, updatedBy: repTransaction.updatedBy, enteredDate: repTransaction.enteredDate, updatedDate: repTransaction.updatedDate)
                }
                .sharedBackgroundVisibility(.hidden)
            }
            #endif
        }
    }
    
    
    var closeButton: some View {
        Button {
            editID = nil; dismiss()
        } label: {
            Image(systemName: isValidToSave ? "checkmark" : "xmark")
                .foregroundStyle(colorScheme == .dark ? .white : .black)
        }
    }
    
    
    var titleRow: some View {
        HStack(spacing: 0) {
            Label {
                Text("")
            } icon: {
                Image(systemName: "t.circle")
                    .foregroundStyle(.gray)
            }
            
            #if os(iOS)
            UITextFieldWrapper(placeholder: "Title", text: $repTransaction.title, onSubmit: {
                focusedField = 1
            }, toolbar: {
                KeyboardToolbarView(focusedField: $focusedField)
            })
            .uiTag(0)
            .uiClearButtonMode(.whileEditing)
            .uiStartCursorAtEnd(true)
            .uiTextAlignment(.left)
            .uiReturnKeyType(.next)
            //.uiTextColor(.secondaryLabel)
            //.uiFont(UIFont.systemFont(ofSize: 24.0))
            #else
            StandardTextField("Title", text: $repTransaction.title, focusedField: $focusedField, focusValue: 0)
                .onSubmit { focusedField = 1 }
            #endif
        }
        .focused($focusedField, equals: 0)
    }
    
    
    var amountRow: some View {
        HStack(spacing: 0) {
            Label {
                Text("")
            } icon: {
                Image(systemName: "dollarsign.circle")
                    .foregroundStyle(.gray)
            }
            Group {
                #if os(iOS)
                UITextFieldWrapper(placeholder: "Amount", text: $repTransaction.amountString, toolbar: {
                    KeyboardToolbarView(
                        focusedField: $focusedField,
                        accessoryImage3: "plus.forwardslash.minus",
                        accessoryFunc3: {
                            Helpers.plusMinus($repTransaction.amountString)
                        })
                })
                .uiTag(1)
                .uiClearButtonMode(.whileEditing)
                .uiStartCursorAtEnd(true)
                .uiTextAlignment(.left)
                .uiKeyboardType(useWholeNumbers ? .numberPad : .decimalPad)
                //.uiTextColor(.secondaryLabel)
                //.uiFont(UIFont.systemFont(ofSize: 24.0))
                #else
                StandardTextField("Amount", text: $repTransaction.amountString, focusedField: $focusedField, focusValue: 1)
                #endif
            }
            .focused($focusedField, equals: 1)
            .formatCurrencyLiveAndOnUnFocus(
                focusValue: 1,
                focusedField: focusedField,
                amountString: repTransaction.amountString,
                amountStringBinding: $repTransaction.amountString,
                amount: repTransaction.amount
            )
            .onChange(of: focusedField) { oldValue, newValue in
                if newValue == 1 && repTransaction.amountString.isEmpty {
                    repTransaction.amountString = "-"
                }
            }
            
            //StandardAmountTextField(focusedField: _focusedField, focusID: 1, showSymbol: false, obj: repTransaction)
        }
    }
    
    
    var payFromRow: some View {
        PayMethodSheetButton2(text: "Pay From", image: repTransaction.payMethod?.accountType == .checking ? "banknote.fill" : "creditcard.fill", payMethod: $repTransaction.payMethod, whichPaymentMethods: .allExceptUnified)
    }
    
    
    var payToRow: some View {
        PayMethodSheetButton2(text: "Pay From", image: repTransaction.payMethodPayTo?.accountType == .checking ? "banknote.fill" : "creditcard.fill", payMethod: $repTransaction.payMethodPayTo, whichPaymentMethods: .allExceptUnified)
    }
    
    
    var typeRow: some View {
        Picker(selection: $repTransaction.repeatingTransactionType) {
            Text("Regular")
                .tag(XrefModel.getItem(from: .repeatingTransactionType, byEnumID: .regular))
            Text("Payment")
                .tag(XrefModel.getItem(from: .repeatingTransactionType, byEnumID: .payment))
            Text("Transfer")
                .tag(XrefModel.getItem(from: .repeatingTransactionType, byEnumID: .transfer))
        } label: {
            Label {
                Text("Transaction Type")
            } icon: {
                Image(systemName: "dollarsign.bank.building")
                    .foregroundStyle(.gray)
            }
        }
        .pickerStyle(.menu)
        .tint(.secondary)
    }
    
    
//    var categoryRow: some View {
//        HStack {
//            Text("Category")
//            Spacer()
//            CategorySheetButton2(category: $repTransaction.category)
//        }
//    }
    
    
    var colorRow: some View {
        HStack {
            #if os(iOS)
            //StandardColorPicker(color: $repTransaction.color)
            Button {
                showColorPicker = true
            } label: {
                HStack {
                    Label {
                        Text("Title Color")
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                    } icon: {
                        Image(systemName: "lightspectrum.horizontal")
                            .foregroundStyle(.gray)
                    }
                    Spacer()
                    //StandardColorPicker(color: $payMethod.color)
                    Image(systemName: "circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(repTransaction.color.gradient)
                }
            }
            .colorPickerSheet(isPresented: $showColorPicker, selection: $repTransaction.color, supportsAlpha: false)
            #else
            Text("Title Color")
            Spacer()
            HStack {
                ColorPicker("", selection: $repTransaction.color, supportsOpacity: false)
                    .labelsHidden()
                Capsule()
                    .fill(repTransaction.color)
                    .onTapGesture {
                        AppState.shared.showToast(title: "Color Picker", subtitle: "Click the circle to the left to change the color.", body: nil, symbol: "theatermask.and.paintbrush", symbolColor: repTransaction.color)
                    }
            }
            #endif
        }
    }
    
    
//    
//    var transactionTypeButton: some View {
//        HStack(spacing: 1) {
//            Text("Transaction Type: ")
//                .foregroundStyle(.gray)
//            
//            Text(repTransaction.amountTypeLingo)
//                .bold(true)
//                .foregroundStyle(Color.fromName(colorTheme))
//                .onTapGesture {
//                    Helpers.plusMinus($repTransaction.amountString)                    
//                }
//        }
//        .validate(repTransaction.amountString, rules: .regex(.currency, "The field contains invalid characters"))
//        .disabled(repTransaction.amountString.isEmpty)
//    }
//    
//    
//    
//    
//    
    
    
    
    struct WeekdayToggles: View {
        @Local(\.colorTheme) var colorTheme
        @Environment(RepeatingTransactionModel.self) private var repModel
        @Bindable var repTransaction: CBRepeatingTransaction
        
        var body: some View {
            ScrollView(.horizontal, showsIndicators: true) {
                HStack {
                    let isAll = repTransaction.when.filter { $0.whenType == .weekday }.filter { $0.active }.count == 7
                    Button {
                        repTransaction.when.filter { $0.whenType == .weekday }.forEach { $0.active.toggle() }
                    } label: {
                        Text("All")
                            .frame(width: 40, height: 40)
                            .foregroundStyle(isAll ? Color.fromName(colorTheme) : Color.primary)
                            .background(isAll ? Color.fromName(colorTheme).opacity(0.2) : Color.clear)
                            .clipShape(Circle())
                            .font(.caption)
                            .bold()
                            .contentShape(Circle())
                    }
                    .buttonStyle(.borderless)
                                        
                    Divider()
                    
                    ForEach($repTransaction.when.filter { $0.whenType.wrappedValue == .weekday }) { $when in
                        Button {
                            when.active.toggle()
                        } label: {
                            Text(when.displayTitle)
                                .frame(width: 40, height: 40)
                                .foregroundStyle(when.active ? Color.fromName(colorTheme) : Color.primary)
                                .background(when.active ? Color.fromName(colorTheme).opacity(0.2) : Color.clear)
                                .clipShape(Circle())
                                .font(.caption)
                                .bold()
                                .contentShape(Circle())
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }
            .scrollIndicators(.hidden)
            //.contentMargins(.bottom, 10, for: .scrollContent)
        }
    }
    
    
    struct MonthToggles: View {
        @Local(\.colorTheme) var colorTheme
        @Environment(RepeatingTransactionModel.self) private var repModel
        @Bindable var repTransaction: CBRepeatingTransaction
        
        var body: some View {
            ScrollView(.horizontal, showsIndicators: true) {
                HStack {
                    let isAll = repTransaction.when.filter { $0.whenType == .month }.filter { $0.active }.count == 12
                    Button {
                        repTransaction.when.filter { $0.whenType == .month }.forEach { $0.active.toggle() }
                    } label: {
                        Text("All")
                            .frame(width: 40, height: 40)
                            .foregroundStyle(isAll ? Color.fromName(colorTheme) : Color.primary)
                            .background(isAll ? Color.fromName(colorTheme).opacity(0.2) : Color.clear)
                            .clipShape(Circle())
                            .font(.caption)
                            .bold()
                            .contentShape(Circle())
                    }
                    .buttonStyle(.borderless)
                                        
                    Divider()
                                                            
                    ForEach($repTransaction.when.filter { $0.whenType.wrappedValue == .month }) { $when in
                        Button {
                            when.active.toggle()
                        } label: {
                            Text(when.displayTitle)
                                .frame(width: 40, height: 40)
                                .foregroundStyle(when.active ? Color.fromName(colorTheme) : Color.primary)
                                .background(when.active ? Color.fromName(colorTheme).opacity(0.2) : Color.clear)
                                .clipShape(Circle())
                                .font(.caption)
                                .bold()
                                .contentShape(Circle())
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }
            .scrollIndicators(.hidden)
            //.contentMargins(.bottom, 10, for: .scrollContent)
        }
    }
    
    
    struct DayToggles: View {
        @Local(\.colorTheme) var colorTheme
        @Environment(RepeatingTransactionModel.self) private var repModel
        @Bindable var repTransaction: CBRepeatingTransaction
        
        let sevenColumnGrid = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
        
        var body: some View {
            HStack {
                LazyVGrid(columns: sevenColumnGrid, spacing: 0) {
                    ForEach($repTransaction.when.filter { $0.whenType.wrappedValue == .dayOfMonth }) { $day in
                        Button {
                            day.active.toggle()
                        } label: {
                            VStack(alignment: .leading) {
                                HStack {
                                    Text(day.displayTitle)
                                    Spacer()
                                }
                                Spacer().frame(height: 30)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .background(day.active ? Color.fromName(colorTheme) : .clear)
                        .border(Color(.gray))
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}
