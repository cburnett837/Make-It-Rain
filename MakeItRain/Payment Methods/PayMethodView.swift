//
//  EditPaymentMethodView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/14/24.
//

import SwiftUI


struct PayMethodView: View {
    enum Offset: Int {
        case dayBack0 = 0
        case dayBack1 = 1
        case dayBack2 = 2
    }
    
    @AppStorage("useWholeNumbers") var useWholeNumbers = false
    @AppStorage("preferDarkMode") var preferDarkMode: Bool = true

    @Environment(\.dismiss) var dismiss
    @Environment(CalendarModel.self) private var calModel
    @Bindable var payMethod: CBPaymentMethod
    @Bindable var payModel: PayMethodModel
    
    /// This is only here to blank out the selection hilight on the iPhone list
    @Binding var editID: String?
        
    @State private var showDeleteAlert = false
    @State private var labelWidth: CGFloat = 20.0
    
    @FocusState private var focusedField: Int?
    @State private var showKeyboardToolbar = false
    
    @State private var accountTypeMenuColor: Color = Color(.tertiarySystemFill)

    var title: String { payMethod.action == .add ? "New Payment Method" : "Edit Payment Method" }
        
    var deleteButton: some View {
        Button {
            showDeleteAlert = true
        } label: {
            Image(systemName: "trash")
        }
    }
    
    var notificationButton: some View {
        Button {
            payMethod.notifyOnDueDate.toggle()
        } label: {
            Image(systemName: payMethod.notifyOnDueDate ? "bell.slash.fill" : "bell.fill")
        }
    }
    
    
    
    var body: some View {
        VStack(spacing: 0) {
            if payMethod.accountType == .credit && payMethod.dueDate != nil {
                SheetHeader(
                    title: title,
                    close: { editID = nil; dismiss() },
                    view1: { notificationButton },
                    view3: { deleteButton }
                )
                .padding()
            } else {
                SheetHeader(
                    title: title,
                    close: { editID = nil; dismiss() },
                    view3: { deleteButton }
                )
                .padding()
            }
            
            Divider()
                .padding(.horizontal)
            
            ScrollView {
                VStack(spacing: 6) {
                    LabeledRow("Name", labelWidth) {
                        #if os(iOS)
                        StandardUITextFieldFancy("Name", text: $payMethod.title, toolbar: {
                            KeyboardToolbarView(focusedField: $focusedField)
                        })
                        .cbFocused(_focusedField, equals: 0)
                        .cbClearButtonMode(.whileEditing)
                        #else
                        StandardTextField("Name", text: $payMethod.title, focusedField: $focusedField, focusValue: 0)
                        #endif
                    }
                    
                    LabeledRow("Account Type", labelWidth) {
                        Menu {
                            Button("Cash") { payMethod.accountType = AccountType.cash }
                            Button("Checking") { payMethod.accountType = AccountType.checking }
                            Button("Credit") { payMethod.accountType = AccountType.credit }
                            Button("Savings") { payMethod.accountType = AccountType.savings }
                            Button("401K") { payMethod.accountType = AccountType.k401 }
                            Button("Investment") { payMethod.accountType = AccountType.investment }
                        } label: {
                            RoundedRectangle(cornerRadius: 8)
                            //.stroke(.gray, lineWidth: 1)
                                .fill(accountTypeMenuColor)
                                #if os(macOS)
                                .frame(height: 27)
                                #else
                                .frame(height: 34)
                                #endif
                                .overlay {
                                    HStack {
                                        Text(payMethod.accountType.rawValue.capitalized)
                                            .foregroundStyle(preferDarkMode ? .white : .black)
                                        Spacer()
                                    }
                                    .contentShape(Rectangle())
                                    .padding(.leading, 2)
                                    .focusable(false)
                                    .chevronMenuOverlay()
                                }
                                .onHover { accountTypeMenuColor = $0 ? Color(.systemFill) : Color(.tertiarySystemFill) }
                        }
                    }
                    
                    if payMethod.accountType == .checking || payMethod.accountType == .credit {
                        LabeledRow("Last 4 Digits", labelWidth) {
                            #if os(iOS)
                            StandardUITextFieldFancy("Last 4 Digits", text: $payMethod.last4 ?? "", toolbar: {
                                KeyboardToolbarView(focusedField: $focusedField)
                            })
                            .cbKeyboardType(.numberPad)
                            .cbFocused(_focusedField, equals: 1)
                            .cbClearButtonMode(.whileEditing)
                            .cbMaxLength(4)
                            #else
                            StandardTextField("Last 4 Digits", text: $payMethod.last4 ?? "", focusedField: $focusedField, focusValue: 1)
                            #endif
                        }
                    }
                    
                    if payMethod.accountType == .credit {
                        StandardDivider()
                        
                        LabeledRow("Due Date", labelWidth) {
                            Group {
                                #if os(iOS)
                                StandardUITextFieldFancy("(day number only)", text: $payMethod.dueDateString ?? "", onBeginEditing: {
                                    payMethod.dueDateString = payMethod.dueDateString?.replacing(/[a-z]+/, with: "", maxReplacements: 1)
                                }, toolbar: {
                                    KeyboardToolbarView(focusedField: $focusedField)
                                })
                                .cbFocused(_focusedField, equals: 2)
                                .cbClearButtonMode(.whileEditing)
                                .cbKeyboardType(.numberPad)
                                .cbMaxLength(2)
                                #else
                                StandardTextField("(day number only)", text: $payMethod.dueDateString ?? "", focusedField: $focusedField, focusValue: 2)
                                #endif
                            }
                            .onChange(of: focusedField) { oldValue, newValue in
                                if newValue == 2 {
                                    if payMethod.dueDate == 0 {
                                        payMethod.dueDateString = ""
                                    }
                                } else {
                                    if oldValue == 2 && !(payMethod.dueDateString ?? "").isEmpty {
                                        payMethod.dueDateString = (payMethod.dueDate ?? 0).withOrdinal()
                                    }
                                }
                            }
                        }
                        
                        LabeledRow("Limit", labelWidth) {
                            Group {
                                #if os(iOS)
                                StandardUITextFieldFancy("Limit", text: $payMethod.limitString ?? "", toolbar: {
                                    KeyboardToolbarView(focusedField: $focusedField)
                                })
                                .cbFocused(_focusedField, equals: 3)
                                .cbClearButtonMode(.whileEditing)
                                .cbKeyboardType(.decimalPad)
                                #else
                                StandardTextField("Limit", text: $payMethod.limitString ?? "", focusedField: $focusedField, focusValue: 3)
                                #endif
                            }
                            .onChange(of: focusedField) { oldValue, newValue in
                                if newValue == 3 {
                                    if payMethod.limit == 0.0 {
                                        payMethod.limitString = ""
                                    }
                                } else {
                                    if oldValue == 2 && !(payMethod.limitString ?? "").isEmpty {
                                        if payMethod.limitString == "$" || payMethod.limitString == "-$" {
                                            payMethod.limitString = ""
                                        } else {
                                            payMethod.limitString = payMethod.limit?.currencyWithDecimals(useWholeNumbers ? 0 : 2)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    if payMethod.accountType == .credit && payMethod.dueDate != nil && payMethod.notifyOnDueDate {
                        StandardDivider()
                        //.padding(.top, 12)
                        
                        /// Can't use the labled row due to the need for the alignment guide.
                        /// Alignment guide centers the label with the picker, and pushes the 9:00 am text down.
                        HStack(alignment: .circleAndTitle) {
                            Text("Reminder")
                                .frame(minWidth: labelWidth, alignment: .leading)
                                .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
                            
                            /// This is the same as using `.maxLabelWidthObserver()`. But I did it this way to I could understand better when looking at this.
                                .background {
                                    GeometryReader { geo in
                                        Color.clear.preference(key: MaxSizePreferenceKey.self, value: geo.size.width)
                                    }
                                }
                            
                            VStack(alignment: .leading) {
                                Picker("", selection: $payMethod.notificationOffset) {
                                    Text("2 days before")
                                        .tag(2)
                                    Text("1 day before")
                                        .tag(1)
                                    Text("Day of")
                                        .tag(0)
                                }
                                .labelsHidden()
                                .pickerStyle(.palette)
                                .tint(payMethod.color)
                                .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
                                
                                Text("Alerts will be sent out at 9:00 AM")
                                    .foregroundStyle(.gray)
                                    .font(.caption)
                            }
                        }
                    }
                    
                    StandardDivider()
                    
                    LabeledRow("Color", labelWidth) {
                        //ColorPickerButton(color: $payMethod.color)
                        HStack {
                            ColorPicker("", selection: $payMethod.color, supportsOpacity: false)
                                .labelsHidden()
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 12)
            }
            .scrollDismissesKeyboard(.immediately)
            //.transaction { $0.animation = .none } /// stops a floater view above the keyboard toolbar
        }
        #if os(macOS)
        .padding(.bottom, 10)
        #endif
        .onPreferenceChange(MaxSizePreferenceKey.self) { labelWidth = max(labelWidth, $0) }
        .task {
            payMethod.deepCopy(.create)
            /// Just for formatting.
            payMethod.limitString = payMethod.limit?.currencyWithDecimals(useWholeNumbers ? 0 : 2)
            payMethod.dueDateString = (payMethod.dueDate ?? 0).withOrdinal()
            payModel.upsert(payMethod)
            
            #if os(macOS)
            /// Focus on the title textfield.
            focusedField = 0
            #else
            if payMethod.action == .add {
                focusedField = 0
            }
            #endif
        }
       
        .confirmationDialog("Delete \"\(payMethod.title)\"?", isPresented: $showDeleteAlert, actions: {
            Button("Yes", role: .destructive) {
                Task {
                    dismiss()
                    await payModel.delete(payMethod, andSubmit: true, calModel: calModel)
                }
            }
            
            Button("No", role: .cancel) {
                showDeleteAlert = false
            }
        }, message: {
            #if os(iOS)
            Text("Delete \"\(payMethod.title)\"?\nThis will also delete all associated transactions.")
            #else
            Text("This will also delete all associated transactions.")
            #endif
        })
    }
}
