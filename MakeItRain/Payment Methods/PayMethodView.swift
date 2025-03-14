//
//  EditPaymentMethodView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/14/24.
//

import SwiftUI
import Charts

struct PayMethodView: View {
    enum Offset: Int {
        case dayBack0 = 0
        case dayBack1 = 1
        case dayBack2 = 2
    }
    
    enum ChartRange: Int {
        case year1 = 1
        case year2 = 2
        case year3 = 3
        case year4 = 4
        case year5 = 5
    }
    
    @AppStorage("useWholeNumbers") var useWholeNumbers = false
    @AppStorage("preferDarkMode") var preferDarkMode: Bool = true

    @Environment(\.dismiss) var dismiss
    @Environment(CalendarModel.self) private var calModel
    @Environment(CalendarViewModel.self) private var calViewModel
    @Environment(EventModel.self) private var eventModel
    
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
    
    @State private var isLoadingHistory = false
    @State private var startingAmounts: Array<CBStartingAmount> = []
    @State private var chartRange: ChartRange = .year1
    @State private var rawSelectedDate: Date?
    var selectedMonth: CBStartingAmount? {
        guard let rawSelectedDate else { return nil }
        return startingAmounts.first {
            Calendar.current.isDate(rawSelectedDate, equalTo: $0.date, toGranularity: .month)
        }
    }

        
    var deleteButton: some View {
        Button {
            showDeleteAlert = true
        } label: {
            Image(systemName: "trash")
        }
        .sensoryFeedback(.warning, trigger: showDeleteAlert) { !$0 && $1 }
    }
    
    var notificationButton: some View {
        Button {
            payMethod.notifyOnDueDate.toggle()
        } label: {
            Image(systemName: payMethod.notifyOnDueDate ? "bell.slash.fill" : "bell.fill")
        }
    }
    
    var header: some View {
        Group {
            if payMethod.accountType == .credit && payMethod.dueDate != nil {
                SheetHeader(
                    title: title,
                    close: { editID = nil; dismiss() },
                    view1: { notificationButton },
                    view3: { deleteButton }
                )
            } else {
                SheetHeader(
                    title: title,
                    close: { editID = nil; dismiss() },
                    view3: { deleteButton }
                )
            }
        }
    }
    
    
    var body: some View {
        SheetContainerView {
            LabeledRow("Name", labelWidth) {
                #if os(iOS)
                StandardUITextField("Name", text: $payMethod.title, toolbar: {
                    KeyboardToolbarView(focusedField: $focusedField)
                })
                .cbFocused(_focusedField, equals: 0)
                .cbClearButtonMode(.whileEditing)
                #else
                StandardTextField("Name", text: $payMethod.title, focusedField: $focusedField, focusValue: 0)
                #endif
            }
            
            LabeledRow("Type", labelWidth) {
                StandardRectangle {
                    Menu {
                        Button("Cash") { payMethod.accountType = AccountType.cash }
                        Button("Checking") { payMethod.accountType = AccountType.checking }
                        Button("Credit") { payMethod.accountType = AccountType.credit }
                        Button("Savings") { payMethod.accountType = AccountType.savings }
                        Button("401K") { payMethod.accountType = AccountType.k401 }
                        Button("Investment") { payMethod.accountType = AccountType.investment }
                    } label: {
                        HStack {
                            Text(payMethod.accountType.rawValue.capitalized)
                                .foregroundStyle(preferDarkMode ? .white : .black)
                            Spacer()
                        }                        
                    }
                    #if os(macOS)
                    /// Negate the native macOS padding on the menu
                    .padding(.leading, -2)
                    #endif
                    .chevronMenuOverlay()
                }
            }
            
            if payMethod.accountType == .checking || payMethod.accountType == .credit {
                HStack(alignment: .circleAndTitle) {
                    Text("Last 4")
                        .frame(minWidth: labelWidth, alignment: .leading)
                        .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
                    
                        /// This is the same as using `.maxLabelWidthObserver()`. But I did it this way to I could understand better when looking at this.
                        .background {
                            GeometryReader { geo in
                                Color.clear.preference(key: MaxSizePreferenceKey.self, value: geo.size.width)
                            }
                        }
                    
                    VStack(spacing: 0) {
                        Group {
                            #if os(iOS)
                            StandardUITextField("Last 4 Digits", text: $payMethod.last4 ?? "", toolbar: {
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
                        .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
                        
                        
                        Text("If you wish to use the smart receipt feature offered by ChatGPT, enter the last 4 digits of your card information. If not, you can leave this field blank.")
                        .foregroundStyle(.gray)
                        .font(.caption)
                        .multilineTextAlignment(.leading)
                        .padding(.leading, 6)
                        
                    }
                        
                }
                
//                        LabeledRow("Last 4 Digits", labelWidth) {
//                            VStack(spacing: 0) {
//                                Group {
//                                    #if os(iOS)
//                                    StandardUITextField("Last 4 Digits", text: $payMethod.last4 ?? "", toolbar: {
//                                        KeyboardToolbarView(focusedField: $focusedField)
//                                    })
//                                    .cbKeyboardType(.numberPad)
//                                    .cbFocused(_focusedField, equals: 1)
//                                    .cbClearButtonMode(.whileEditing)
//                                    .cbMaxLength(4)
//                                    #else
//                                    StandardTextField("Last 4 Digits", text: $payMethod.last4 ?? "", focusedField: $focusedField, focusValue: 1)
//                                    #endif
//                                }
//                                .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
//
//
//                                Text("No information will be collected. Enter the last 4 digits of your card information (if applicable) if you want to use the smart receipt upload feature offered by ChatGPT. If not, leave this field blank."
//                                )
//                                .foregroundStyle(.gray)
//                                .font(.caption)
//                                .multilineTextAlignment(.leading)
//                                .padding(.horizontal, 6)
//
//                            }
//
//                        }
            }
            
            if payMethod.accountType == .credit {
                StandardDivider()
                
                LabeledRow("Due Date", labelWidth) {
                    Group {
                        #if os(iOS)
                        StandardUITextField("(day number only)", text: $payMethod.dueDateString ?? "", onBeginEditing: {
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
                        StandardUITextField("Limit", text: $payMethod.limitString ?? "", toolbar: {
                            KeyboardToolbarView(focusedField: $focusedField)
                        })
                        .cbFocused(_focusedField, equals: 3)
                        .cbClearButtonMode(.whileEditing)
                        .cbKeyboardType(.decimalPad)
                        #else
                        StandardTextField("Limit", text: $payMethod.limitString ?? "", focusedField: $focusedField, focusValue: 3)
                        #endif
                    }
                    .formatCurrencyLiveAndOnUnFocus(
                        focusValue: 3,
                        focusedField: focusedField,
                        amountString: payMethod.limitString,
                        amountStringBinding: $payMethod.limitString ?? "",
                        amount: payMethod.limit
                    )
                    
//                            .onChange(of: payMethod.limitString) {
//                                Helpers.liveFormatCurrency(oldValue: $0, newValue: $1, text: $payMethod.limitString ?? "")
//                            }
//                            .onChange(of: focusedField) {
//                                payMethod.limitString = Helpers.formatCurrency(focusValue: 3, oldFocus: $0, newFocus: $1, amountString: payMethod.limitString, amount: payMethod.limit)
//                            }
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
                    Capsule()
                        .fill(payMethod.color)
                        .onTapGesture {
                            AppState.shared.showToast(title: "Color Picker", subtitle: "Click the circle to the left to change the color.", body: nil, symbol: "theatermask.and.paintbrush", symbolColor: payMethod.color)
                        }
                }
            }
            
            StandardDivider()
            
            Spacer()
                .frame(height: 30)
            
            Picker("", selection: $chartRange.animation()) {
                Text("1Y").tag(ChartRange.year1)
                Text("2Y").tag(ChartRange.year2)
                Text("3Y").tag(ChartRange.year3)
                Text("4Y").tag(ChartRange.year4)
                Text("5Y").tag(ChartRange.year5)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(.bottom, 10)
            
            Chart {
                if let selectedMonth {
                    //let _ = print(rawSelectedDate.month)
                    RuleMark(x: .value("Selected Date", selectedMonth.date, unit: .month))
                        .foregroundStyle(selectedMonth.payMethod.color)
                        .offset(yStart: -15)
                        .zIndex(-1)
//                                .annotation(position: .top, overflowResolution: .init(x: .fit(to: .chart), y: .disabled)) {
//                                    VStack {
//                                        Text("\(selectedStartingAmount.date, format: .dateTime.month(.wide)) \(String(selectedStartingAmount.date.year))")
//                                            .bold()
//                                        Text("\(selectedStartingAmount.amountString)")
//                                            .bold()
//                                    }
//                                    .foregroundStyle(.white)
//                                    .padding(12)
//                                    .frame(width: 160)
//                                    .background(RoundedRectangle(cornerRadius: 10)
//                                        .fill(selectedStartingAmount.payMethod.color.gradient))
//                                }
                }
                
                ForEach(startingAmounts) { start in
                    LineMark(
                        x: .value("Date", start.date, unit: .month),
                        y: .value("Amount", start.amount)
                    )
                    .foregroundStyle(start.payMethod.color)
                    .interpolationMethod(.catmullRom)
                    //.lineStyle(.init(lineWidth: 2))
                    .symbol {
                        Circle()
                            .fill(start.payMethod.color)
                            .frame(width: 6, height: 6)
                            //.opacity(rawSelectedDate == nil || start.date == selectedStartingAmount?.date ? 1 : 0.3)
                    }
                }
            }
            .frame(minHeight: 150)
            .chartScrollableAxes(.horizontal)
            .chartXVisibleDomain(length: 3600 * 24 * (365 * chartRange.rawValue))
            .chartScrollPosition(initialX: startingAmounts.last?.date ?? Date())
            .chartXSelection(value: $rawSelectedDate)
            //.chartXAxis { AxisMarks(values: .automatic(desiredCount: 12)) }
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    if let selectedMonth {
                        if let positionX = proxy.position(forX: selectedMonth.date) {
                            
                            VStack {
                                Text("\(selectedMonth.date, format: .dateTime.month(.wide)) \(String(selectedMonth.date.year))")
                                    .bold()
                                Text("\(selectedMonth.amountString)")
                                    .bold()
                            }
                            .foregroundStyle(.white)
                            .padding(12)
                            .frame(width: 160)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(selectedMonth.payMethod.color/*.gradient*/)
                            )
//                                    .position(
//                                        x: min(max(positionX, 80), geometry.size.width - 80), // Keep annotation within bounds horizontally
//                                        y: -40 // Fixed Y position to stay above the chart
//                                    )
                            .position(
                                x: geometry.frame(in: .local).midX,
                                y: -40
                            )
                        }
                    }
                }
            }
            .padding(.bottom, 10)
            .opacity(isLoadingHistory ? 0.5 : 1)
            .overlay { ProgressView("Loading Analytics…").tint(.none).opacity(isLoadingHistory ? 1 : 0) }
            
        } header: {
            header
        }
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
            
            isLoadingHistory = true
            if let amounts = await payModel.fetchStartingAmountsForDateRange(payMethod) {
                self.startingAmounts = amounts
                isLoadingHistory = false
            }
            
            
        }
       
        .confirmationDialog("Delete \"\(payMethod.title)\"?", isPresented: $showDeleteAlert, actions: {
            Button("Yes", role: .destructive) {
                Task {
                    dismiss()
                    await payModel.delete(payMethod, andSubmit: true, calModel: calModel, eventModel: eventModel)
                }
            }
            
            Button("No", role: .cancel) {
                showDeleteAlert = false
            }
        }, message: {
            #if os(iOS)
            Text("Delete \"\(payMethod.title)\"?\nThis will also delete all associated transactions and event transactions.")
            #else
            Text("This will also delete all associated transactions and event transactions.")
            #endif
        })
    }
}
