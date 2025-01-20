//
//  RepeatingTransactionViewMac.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/21/24.
//

import SwiftUI

struct RepeatingTransactionView: View {
    @AppStorage("useWholeNumbers") var useWholeNumbers = false    
    @Environment(\.dismiss) var dismiss
    
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
        
    var title: String { repTransaction.action == .add ? "New Rep. Transaction" : "Edit Rep. Transaction" }
    
    @FocusState private var focusedField: Int?
    @State private var showKeyboardToolbar = false
    
    @State private var showPaymentMethodSheet = false
    @State private var showCategorySheet = false
    
    var deleteButton: some View {
        Button {
            showDeleteAlert = true
        } label: {
            Image(systemName: "trash")
        }
        .sensoryFeedback(.warning, trigger: showDeleteAlert) { !$0 && $1 }
    }
    
    var header: some View {
        Group {
            SheetHeader(
                title: title,
                close: { editID = nil; dismiss() },
                view3: { deleteButton }
            )
            .padding()
            
            Divider()
                .padding(.horizontal)
        }
    }
        
    var body: some View {
        VStack(spacing: 0) {
            #if os(iOS)
            if !AppState.shared.isLandscape { header }
            #else
            header
            #endif
            ScrollView {
                #if os(iOS)
                if AppState.shared.isLandscape { header }
                #endif
                VStack(spacing: 6) {
                    LabeledRow("Name", labelWidth) {
                        #if os(iOS)
                        StandardUITextFieldFancy("Amount", text: $repTransaction.title, onSubmit: {
                            focusedField = 1
                        }, toolbar: {
                            KeyboardToolbarView(focusedField: $focusedField)
                        })
                        .cbFocused(_focusedField, equals: 0)
                        .cbClearButtonMode(.whileEditing)
                        .cbSubmitLabel(.next)
                        #else
                        StandardTextField("Title", text: $repTransaction.title, focusedField: $focusedField, focusValue: 0)
                            .onSubmit { focusedField = 1 }
                        #endif
                    }
                    
                    LabeledRow("Amount", labelWidth) {
                        Group {
                            #if os(iOS)
                            StandardUITextFieldFancy("Amount", text: $repTransaction.amountString, toolbar: {
                                KeyboardToolbarView(focusedField: $focusedField, accessoryImage3: "plus.forwardslash.minus", accessoryFunc3: {
                                    Helpers.plusMinus($repTransaction.amountString)
                                })
                            })
                            .cbKeyboardType(.decimalPad)
                            .cbClearButtonMode(.whileEditing)
                            .cbFocused(_focusedField, equals: 1)
#else
                            StandardTextField("Amount", text: $repTransaction.amountString, focusedField: $focusedField, focusValue: 1)
#endif
                        }
                        .onChange(of: repTransaction.amountString) { oldValue, newValue in
                            if repTransaction.amountString != "-" {
                                if repTransaction.amount == 0.0 {
                                    repTransaction.amountString = ""
                                } else {
                                    repTransaction.amountString = repTransaction.amount.currencyWithDecimals(useWholeNumbers ? 0 : 2)
                                }
                            }
                        }
                    }
                    
                    StandardDivider()
                    
                    LabeledRow("Pay Meth", labelWidth) {
                        PaymentMethodSheetButton(payMethod: $repTransaction.payMethod, whichPaymentMethods: .allExceptUnified)
                    }
                    
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
                        //ColorPickerButton(color: $repTransaction.color)
                        
                        HStack {
                            ColorPicker("", selection: $repTransaction.color, supportsOpacity: false)
                                .labelsHidden()
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 12)
            }
            .scrollDismissesKeyboard(.immediately)
            .transaction { $0.animation = .none } /// stops a floater view above the keyboard toolbar
        }
        #if os(macOS)
        .padding(.bottom, 10)
        #endif
//        #if os(iOS)
//        .keyboardToolbar(amountString: $repTransaction.amountString, focusedField: _focusedField, fields: [.title, .amount])
//        #endif
        .onPreferenceChange(MaxSizePreferenceKey.self) { labelWidth = max(labelWidth, $0) }
//        #if os(macOS)
//        .presentationSizing(.fitted)
//        .frame(minWidth: 750)
//        #endif
        .task {
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
        .alert("Delete \"\(repTransaction.title)\"?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                Task {
                    dismiss()
                    await repModel.delete(repTransaction, andSubmit: true)
                }
            }
            
            Button("Cancel", role: .cancel) {
                showDeleteAlert = false
            }
        }
        
        
        .confirmationDialog("Delete \"\(repTransaction.title)\"?", isPresented: $showDeleteAlert, actions: {
            Button("Yes", role: .destructive) {
                Task {
                    dismiss()
                    await repModel.delete(repTransaction, andSubmit: true)
                }
            }
            
            Button("No", role: .cancel) {
                showDeleteAlert = false
            }
        }, message: {
            #if os(iOS)
            Text("Delete \"\(repTransaction.title)\"?")
            #endif
        })
        
        
        
        /// Just for formatting.
        .onChange(of: focusedField) { oldValue, newValue in
            if newValue == 1 {
                if repTransaction.amount == 0.0 {
                    repTransaction.amountString = ""
                }
            } else {
                if oldValue == 1 {
                    repTransaction.amountString = repTransaction.amount.currencyWithDecimals(useWholeNumbers ? 0 : 2)
                }
            }
        }
    }
    
    
    
    struct WeekdayToggles: View {
        @AppStorage("appColorTheme") var appColorTheme: String = Color.green.description
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
                            .foregroundStyle(isAll ? Color.fromName(appColorTheme) : Color.primary)
                            .background(isAll ? Color.fromName(appColorTheme).opacity(0.2) : Color.clear)
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
                                .foregroundStyle(when.active ? Color.fromName(appColorTheme) : Color.primary)
                                .background(when.active ? Color.fromName(appColorTheme).opacity(0.2) : Color.clear)
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
        @AppStorage("appColorTheme") var appColorTheme: String = Color.green.description
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
                            .foregroundStyle(isAll ? Color.fromName(appColorTheme) : Color.primary)
                            .background(isAll ? Color.fromName(appColorTheme).opacity(0.2) : Color.clear)
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
                                .foregroundStyle(when.active ? Color.fromName(appColorTheme) : Color.primary)
                                .background(when.active ? Color.fromName(appColorTheme).opacity(0.2) : Color.clear)
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
        @AppStorage("appColorTheme") var appColorTheme: String = Color.green.description
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
                        .background(day.active ? Color.fromName(appColorTheme) : .clear)
                        .border(Color(.gray))
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}
