//
//  RepeatingTransactionViewMac.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/21/24.
//

import SwiftUI

enum RepTransNavDestination: Hashable {
    case titleColorMenu
}


struct RepeatingTransactionView: View {
    
    //@Local(\.colorTheme) var colorTheme
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
    #if os(iOS)
    @State private var selection = AttributedTextSelection()
    #endif
    @State private var textCommands = TextViewCommands()
    @State private var navPath = NavigationPath()
    
    var paymentMethodTitle: String {
        if repTransaction.repeatingTransactionType.enumID == .payment {
            "Pay From"
        } else if repTransaction.repeatingTransactionType.enumID == .transfer {
             "Transfer From"
        } else {
            "Account"
        }
    }
    
    
    var paymentMethod2Title: String {
        if repTransaction.repeatingTransactionType.enumID == .payment {
            "Pay To"
        } else if repTransaction.repeatingTransactionType.enumID == .transfer {
             "Transfer To"
        } else {
            "Account"
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
            repTransaction.amountString = repTransaction.amount.currencyWithDecimals()
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
    
    #if os(macOS)
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
                PayMethodSheetButtonMac(payMethod: $repTransaction.payMethod, whichPaymentMethods: .allExceptUnified)
            }
                        
            if !isRegularTransaction {
                LabeledRow(paymentMethod2Title, labelWidth) {
                    PayMethodSheetButtonMac(payMethod: $repTransaction.payMethodPayTo, whichPaymentMethods: .allExceptUnified)
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
                CategorySheetButtonMac(category: $repTransaction.category)
            }
            
            StandardDivider()
                                
            LabeledRow("Weekdays", labelWidth) {
                weekdayToggles
            }
            
            StandardDivider()
            
            LabeledRow("Months", labelWidth) {
                monthToggles
            }
            
            StandardDivider()
            
            LabeledRow("Days", labelWidth) {
                dayToggles
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
    #endif
    
    
    #if os(iOS)
    @ViewBuilder
    var bodyPhone: some View {
        NavigationStack(path: $navPath) {
            ScrollViewReader { scrollProxy in
                StandardContainerWithToolbar(.list) {
                    Section {
                        titleRow
                        
                        TransactionAmountRow(amountTypeLingo: repTransaction.amountTypeLingo, amountString: $repTransaction.amountString) {
                            amountRow
                        }
                    } header: {
                        Text("Title & Amount")
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
                        CategorySheetButtonPhone(category: $repTransaction.category)
                        colorRow
                    }
                    
                    Section {
                        includeRow
                    } footer: {
                        Text("Choose if this transaction should be added to the calendar when preparing a month.")
                    }
                    
                    Section {
                        factorInCalculationsRow
                    } footer: {
                        Text("Choose if this transaction should be included in the calculations for the month.")
                    }
                    
                    
                    Section {
                        VStack(alignment: .leading) {
                            Text("On Specific Weekdays")
                                .foregroundStyle(.secondary)
                                .font(.subheadline)
                            weekdayToggles
                        }
                        
                        VStack(alignment: .leading) {
                            Text("During Specific Months")
                                .foregroundStyle(.secondary)
                                .font(.subheadline)
                            monthToggles
                        }
                        
                        VStack(alignment: .leading) {
                            Text("On Specific Days")
                                .foregroundStyle(.secondary)
                                .font(.subheadline)
                            dayToggles
                        }
                        
                    } header: {
                        Text("Repeating Schedule")
                    } footer: {
                        Text("Select a combo of weekdays, months, and days to repeat this transaction. For example, selecting **Sunday**, **January**, and **15** will create this transaction on every Sunday in January, **and** on January 15th.")
                    }
                    
                    //                Section {
                    //                    StandardNoteTextEditor(notes: $repTransaction.notes, symbolWidth: 0, focusedField: _focusedField, focusID: 3, showSymbol: true)
                    //                }
                    
                    StandardUITextEditor(text: $repTransaction.notes, focusedField: _focusedField, focusID: 2, scrollProxy: scrollProxy)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: RepTransNavDestination.self) { _ in
                TitleColorList(color: $repTransaction.color, navPath: $navPath)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { deleteButton }
                ToolbarSpacer(.fixed, placement: .topBarLeading)
                ToolbarItem(placement: .topBarTrailing) {
                    AnimatedCloseButton(isValidToSave: isValidToSave, closeButton: closeButton)                    
                }
                
                ToolbarItem(placement: .bottomBar) {
                    EnteredByAndUpdatedByView(enteredBy: repTransaction.enteredBy, updatedBy: repTransaction.updatedBy, enteredDate: repTransaction.enteredDate, updatedDate: repTransaction.updatedDate)
                }
                .sharedBackgroundVisibility(.hidden)
            }
        }
    }
    #endif
    
    
    var closeButton: some View {
        Button {
            if repTransaction.action == .add && !repTransaction.title.isEmpty && repTransaction.payMethod == nil {
                AppState.shared.showAlert("Please select an account.")
                return
            }
            
            editID = nil
            dismiss()
        } label: {
            Image(systemName: isValidToSave ? "checkmark" : "xmark")
                .schemeBasedForegroundStyle()
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
                .uiKeyboardType(.custom(.numpad))
                //.uiKeyboardType(useWholeNumbers ? .numberPad : .decimalPad)
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
    
    #if os(iOS)
    var payFromRow: some View {
        PayMethodSheetButtonPhone(
            text: "Pay From",
            logoFallBackType:.customImage(.init(name: repTransaction.payMethod?.fallbackImage, color: repTransaction.color)),
            payMethod: $repTransaction.payMethod,
            whichPaymentMethods: .allExceptUnified
        )
    }
    
    
    var payToRow: some View {
        PayMethodSheetButtonPhone(
            text: "Pay To",
            logoFallBackType:.customImage(.init(name: repTransaction.payMethodPayTo?.fallbackImage, color: repTransaction.color)),
            payMethod: $repTransaction.payMethodPayTo,
            whichPaymentMethods: .allExceptUnified
        )
    }
    #endif
    
    
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
        NavigationLink(value: RepTransNavDestination.titleColorMenu) {
            HStack {
                Label {
                    Text("Title Color")
                } icon: {
                    //Image(systemName: "paintbrush")
                    Image(systemName: "paintpalette")
                        .symbolRenderingMode(.multicolor)
                        //.foregroundStyle(trans.color)
                        .foregroundStyle(.gray)
                }
                
                Spacer()
                Circle()
                    .fill(repTransaction.color)
                    .frame(width: 25, height: 25)
//                        Text(titleColorDescription)
//                            .foregroundStyle(trans.color)
            }
        }
        
        
//        HStack {
//            #if os(iOS)
//            //StandardColorPicker(color: $repTransaction.color)
//            Button {
//                showColorPicker = true
//            } label: {
//                HStack {
//                    Label {
//                        Text("Title Color")
//                            .schemeBasedForegroundStyle()
//                    } icon: {
//                        Image(systemName: "lightspectrum.horizontal")
//                            .foregroundStyle(.gray)
//                    }
//                    Spacer()
//                    //StandardColorPicker(color: $payMethod.color)
//                    Image(systemName: "circle.fill")
//                        .font(.system(size: 24))
//                        .foregroundStyle(repTransaction.color.gradient)
//                }
//            }
//            .colorPickerSheet(isPresented: $showColorPicker, selection: $repTransaction.color, supportsAlpha: false)
//            #else
//            Text("Title Color")
//            Spacer()
//            HStack {
//                ColorPicker("", selection: $repTransaction.color, supportsOpacity: false)
//                    .labelsHidden()
//                Capsule()
//                    .fill(repTransaction.color)
//                    .onTapGesture {
//                        AppState.shared.showToast(title: "Color Picker", subtitle: "Click the circle to the left to change the color.", body: nil, symbol: "theatermask.and.paintbrush", symbolColor: repTransaction.color)
//                    }
//            }
//            #endif
//        }
    }
    
    
    
    var includeRow: some View {
        HStack {
            Image(systemName: "checkmark")
                .foregroundStyle(.gray)
            
            Toggle(isOn: $repTransaction.include) {
                Text("Add to Calendar")
            }
        }
    }
    
    
    var factorInCalculationsRow: some View {
        HStack {
            Image(systemName: "checkmark")
                .foregroundStyle(.gray)
            
            Toggle(isOn: $repTransaction.factorInCalculations) {
                Text("Include in Calculations")
            }
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
//                .foregroundStyle(Color.theme)
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
                //Task {
                    repTransaction.action = .delete
                    dismiss()
                    //await repModel.delete(repTransaction, andSubmit: true)
                //}
            }
            #if os(iOS)
            Button("No", role: .close) { showDeleteAlert = false }
            #else
            Button("No") { showDeleteAlert = false }
            #endif
        }, message: {
            #if os(iOS)
            Text("Delete \"\(repTransaction.title)\"?")
            #endif
        })
    }
    
    
    var weekdayToggles: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            HStack {
                let isAll = repTransaction.when.filter { $0.whenType == .weekday }.filter { $0.active }.count == 7
                Button {
                    repTransaction.when.filter { $0.whenType == .weekday }.forEach { $0.active.toggle() }
                } label: {
                    optionLabel(title: "All", active: isAll)
                }
                .buttonStyle(.borderless)
                                    
                Divider()
                
                ForEach($repTransaction.when.filter { $0.whenType.wrappedValue == .weekday }) { $when in
                    Button {
                        when.active.toggle()
                    } label: {
                        optionLabel(title: when.displayTitle, active: when.active)
                    }
                    .buttonStyle(.borderless)
                }
            }
        }
        .scrollIndicators(.hidden)
    }
    
    
    
    
    var monthToggles: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            HStack {
                let isAll = repTransaction.when.filter { $0.whenType == .month }.filter { $0.active }.count == 12
                Button {
                    repTransaction.when.filter { $0.whenType == .month }.forEach { $0.active.toggle() }
                } label: {
                    optionLabel(title: "All", active: isAll)
                }
                .buttonStyle(.borderless)
                                    
                Divider()
                                                        
                ForEach($repTransaction.when.filter { $0.whenType.wrappedValue == .month }) { $when in
                    Button {
                        when.active.toggle()
                    } label: {
                        optionLabel(title: when.displayTitle, active: when.active)
                    }
                    .buttonStyle(.borderless)
                }
            }
        }
        .scrollIndicators(.hidden)
    }
    
    
    @ViewBuilder
    var dayToggles: some View {
        let sevenColumnGrid = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
        HStack {
            LazyVGrid(columns: sevenColumnGrid, spacing: 4) {
                ForEach($repTransaction.when.filter { $0.whenType.wrappedValue == .dayOfMonth }) { $when in
                    Button {
                        when.active.toggle()
                    } label: {
                        optionLabel(title: when.displayTitle, active: when.active)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity)
        
    }
    
    @ViewBuilder func optionLabel(title: String, active: Bool) -> some View {
        Text(title)
            .schemeBasedForegroundStyle()
            .frame(width: 40, height: 40)
            .background(active ? Color.theme : Color.gray.opacity(0.2))
            .clipShape(Circle())
            .font(.caption)
            .bold()
            .contentShape(Circle())
    }
}
