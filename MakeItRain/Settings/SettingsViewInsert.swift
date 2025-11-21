//
//  SettingsViewInsert.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/25/24.
//

import SwiftUI

struct SettingsViewInsert: View {
    @Local(\.categoryIndicatorAsSymbol) var categoryIndicatorAsSymbol
    @Local(\.categorySortMode) var categorySortMode
    @Local(\.creditEodView) var creditEodView
    @Local(\.incomeColor) var incomeColor
    @Local(\.lineItemIndicator) var lineItemIndicator
    @Local(\.phoneLineItemDisplayItem) var phoneLineItemDisplayItem
    @Local(\.showHashTagsOnLineItems) var showHashTagsOnLineItems
    @Local(\.showPaymentMethodIndicator) var showPaymentMethodIndicator
    @Local(\.threshold) var threshold
    @Local(\.tightenUpEodTotals) var tightenUpEodTotals
    @Local(\.transactionSortMode) var transactionSortMode
    @Local(\.updatedByOtherUserDisplayMode) var updatedByOtherUserDisplayMode
    @Local(\.useWholeNumbers) var useWholeNumbers
    @Local(\.useBusinessLogos) var useBusinessLogos
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(CategoryModel.self) var catModel
    @Environment(CalendarModel.self) var calModel
    
    @State private var thresholdString: String = "500.00"
    @State private var demoDay = CBDay(date: Date())
    @State private var phoneLineItemDisplayItemWhenSettingsWasOpened: PhoneLineItemDisplayItem?
    @FocusState private var focusedField: Int?
        
    var withDividers: Bool = false
        
    var body: some View {
        Group {
            Section("Options") {
//                if phoneLineItemDisplayItem != .both {
//                    paymentMethodIndicatorToggle
//                }
//
                useWholeNumbersToggle
                tightenUpEodTotalsToggle
                showShowHashTagToggle
                useCategorySymbolsToggle
                useBusinessLogosToggle
                incomeColorPicker
            }
            
            creditEodPicker
            
            Section {
                #if os(iOS)
                SettingsMenuPickerContainer(title: "Display line item as…", selectedTitle: phoneLineItemDisplayItem.prettyValue) {
                    Picker("", selection: $phoneLineItemDisplayItem.animation()) {
                        ForEach(PhoneLineItemDisplayItem.allCases, id: \.self) { opt in
                            Text(opt.prettyValue)
                                .tag(opt)
                        }
                    }
                }
                #endif

                //lineItemIndicatorPicker
                #if os(iOS)
                SettingsMenuPickerContainer(title: "Display indicator as…", selectedTitle: lineItemIndicator.mobilePrettyValue) {
                    Picker("", selection: $lineItemIndicator) {
                        ForEach(LineItemIndicator.mobileCases, id: \.self) { opt in
                            Text(opt.mobilePrettyValue)
                                .tag(opt)
                        }
                    }
                }
                #else
                SettingsMenuPickerContainer(title: "Display indicator as…", selectedTitle: lineItemIndicator.macPrettyValue) {
                    Picker("", selection: $lineItemIndicator) {
                        ForEach(LineItemIndicator.macCases, id: \.self) { opt in
                            Text(opt.macPrettyValue)
                                .tag(opt)
                        }
                    }
                }
                #endif
            } header: {
                Text("Line Items")
            } footer: {
                Text("Choose how you want to display line items.")
            }
            
            
//            #if os(iOS)
//            Section("Demo Day View") {
//                HStack {
//                    DemoDay(dayNum: 8)
//                        .frame(maxWidth: .infinity)
//                    DemoDay(dayNum: 9)
//                        .frame(maxWidth: .infinity)
//                    DemoDay(dayNum: 10)
//                        .frame(maxWidth: .infinity)
//                    DemoDay(dayNum: 11)
//                        .frame(maxWidth: .infinity)
//                }
//            }
//            
//            #endif
//            
            #if os(macOS)
            paymentMethodIndicatorToggle
            #endif
                        
            
            updatedByOtherPerson
                    
            sortingOptions            
            
            Section {
                VStack(alignment: .leading) {
                    Group {
                        #if os(iOS)
                        UITextFieldWrapper(placeholder: "Amount", text: $thresholdString, toolbar: {
                            KeyboardToolbarView(focusedField: $focusedField, removeNavButtons: true)
                        })
                        .uiClearButtonMode(.whileEditing)
                        .uiTag(1)
                        //.uiKeyboardType(useWholeNumbers ? .numberPad : .decimalPad)
                        .uiKeyboardType(.custom(.numpad))
                        /// Format the amount field

                        #else
                        TextField("Amount", text: $thresholdString)
                            .textFieldStyle(.roundedBorder)
                        #endif
                    }
                    .focused($focusedField, equals: 1)
                    .onChange(of: thresholdString) {
                        threshold = Double($1.replacing("$", with: "").replacing(",", with: "")) ?? 0.0
                        Helpers.liveFormatCurrency(oldValue: $0, newValue: $1, text: $thresholdString)
                    }
                    .onChange(of: focusedField) {
                        if let string = Helpers.formatCurrency(focusValue: 1, oldFocus: $0, newFocus: $1, amountString: thresholdString, amount: threshold) {
                            thresholdString = string
                        }
                    }
                    .task {
                        thresholdString = threshold.currencyWithDecimals(useWholeNumbers ? 0 : 2)
                    }
                    
                }
            } header: {
                Text("Low Balance Threshold")
            } footer: {
                Group {
                    let text1 = Text("Any EOD total under \(threshold.currencyWithDecimals(useWholeNumbers ? 0 : 2)) will be hilighted in ")
                        .foregroundStyle(.gray)
                        .font(.footnote)
                    let text2 = Text("orange")
                        .foregroundStyle(.orange)
                        .font(.footnote)
                    let text3 = Text(".")
                    let text4 = Text(" Any EOD total under \(0.currencyWithDecimals(useWholeNumbers ? 0 : 2)) will be hilighted in ")
                        .foregroundStyle(.gray)
                        .font(.footnote)
                    let text5 = Text("red")
                        .foregroundStyle(.red)
                        .font(.footnote)
                    
                    Text("\(text1)\(text2)\(text3)\(text4)\(text5)")
                    
//                    Text("Any EOD total under \(threshold.currencyWithDecimals(useWholeNumbers ? 0 : 2)) will be hilighted in ")
//                        .foregroundStyle(.gray)
//                        .font(.footnote)
//                    + Text("orange")
//                        .foregroundStyle(.orange)
//                        .font(.footnote)
//                    + Text(".")
//                    + Text(" Any EOD total under \(0.currencyWithDecimals(useWholeNumbers ? 0 : 2)) will be hilighted in ")
//                        .foregroundStyle(.gray)
//                        .font(.footnote)
//                    + Text("red")
//                        .foregroundStyle(.red)
//                        .font(.footnote)
                }
            }
        }
        .tint(Color.theme)
        
        .task {
            let trans1 = CBTransaction()
            let cat1 = CBCategory()
            cat1.color = .red
            trans1.title = "Apples"
            trans1.category = cat1
            
            let trans2 = CBTransaction()
            let cat2 = CBCategory()
            cat2.color = .orange
            trans2.title = "Bananas"
            trans2.category = cat2
            
            let trans3 = CBTransaction()
            let cat3 = CBCategory()
            cat3.color = .green
            trans3.title = "Coconuts"
            trans3.category = cat3
            
            demoDay.transactions = [
                trans1, trans2, trans3
            ]
            
            phoneLineItemDisplayItemWhenSettingsWasOpened = phoneLineItemDisplayItem
        }
    }
    
    
    // MARK: - Toggles
    var paymentMethodIndicatorToggle: some View {
        Toggle(isOn: $showPaymentMethodIndicator) {
            VStack(alignment: .leading) {
                Text("Show payment method indicator")
                Text("Show an indicator when in a unified payment view to show which payment method was used on the transaction.")
                    .foregroundStyle(.gray)
                    .font(.footnote)
            }
        }
    }
    
    var useWholeNumbersToggle: some View {
        Toggle(isOn: $useWholeNumbers) {
            VStack(alignment: .leading) {
                Text("Only whole numbers")
                Text("Round all dollar amounts and remove their decimals.")
                    .foregroundStyle(.gray)
                    .font(.footnote)
                
            }
        }
    }
    
    var showShowHashTagToggle: some View {
        Toggle(isOn: $showHashTagsOnLineItems) {
            VStack(alignment: .leading) {
                Text("Show tags")
                Text("Display tags belows the transaction title.")
                    .foregroundStyle(.gray)
                    .font(.footnote)
            }
        }
        
    }
    
    var tightenUpEodTotalsToggle: some View {
        Group {
            Toggle(isOn: $tightenUpEodTotals) {
                VStack(alignment: .leading) {
                    Text("Trim totals")
                    Text("Remove dollar signs and commas from totals.")
                        .foregroundStyle(.gray)
                        .font(.footnote)
                }
            }
        }
    }
    
    var useBusinessLogosToggle: some View {
        Toggle(isOn: $useBusinessLogos) {
            VStack(alignment: .leading) {
                Text("Use business logos")
                Text("Choose to use logos from banks / businesses or colored dots for transactions & accounts.")
                    .foregroundStyle(.gray)
                    .font(.footnote)
                
            }
        }
    }
    
    var useCategorySymbolsToggle: some View {
        Toggle(isOn: $categoryIndicatorAsSymbol) {
            VStack(alignment: .leading) {
                Text("Show categories as symbols")
                Text("Choose to use your assigned symbols or colored dots for category lists.")
                    .foregroundStyle(.gray)
                    .font(.footnote)
            }
        }
    }
    
    
    // MARK: - Line Item Indicator Picker
//    var lineItemIndicatorPicker: some View {
//        Group {
//            #if os(macOS)
//            LabeledContent {
//                Picker("", selection: $lineItemIndicator) {
//                    ForEach(LineItemIndicator.allCases, id: \.self) { opt in
//                        Text(opt.prettyValue)
//                            .tag(opt)
//                    }
//                }
//            } label: {
//                VStack(alignment: .leading) {
//                    Text("Display what next to line item")
//                    lineItemIndicatorPickerAddendum
//                        .foregroundStyle(.gray)
//                        .font(.footnote)
//                }
//            }
//            #else
//            Section {
//                SettingsMenuPickerContainer(title: "Display as…", selectedTitle: lineItemIndicator.prettyValue) {
//                    Picker("", selection: $lineItemIndicator) {
//                        ForEach(LineItemIndicator.allCases, id: \.self) { opt in
//                            Text(opt.prettyValue)
//                                .tag(opt)
//                        }
//                    }
//                }
//                
//            } header: {
//                Text("Category / Account Indicator")
//            } footer: {
//                VStack(alignment: .leading) {
//                    lineItemIndicatorPickerAddendum
//                }
//            }
//            #endif
//        }
//    }
    
    
    var lineItemIndicatorPickerAddendum: some View {
        Group {
            let text1 = Text("If viewing the calendar as ")
            let text2 = Text("full").italic(true).bold(true)
            let text3 = Text(", choose how to indicate categories.")
            Text("\(text1)\(text2)\(text3)")
            
            if lineItemIndicator == .emoji {
                let text4 = Text("Note: Symbols will be displayed as dots when viewing as ")
                let text5 = Text("full").italic(true).bold(true)
                let text6 = Text(" due to space constraints.")
                Text("\(text4)\(text5)\(text6)")
            }
            
//            Text("If viewing the calendar as ")
//            +
//            Text("full").italic(true).bold(true)
//            +
//            Text(", choose how to indicate categories.")
//            
//            if lineItemIndicator == .emoji {
//                Text("Note: Symbols will be displayed as dots when viewing as ")
//                +
//                Text("full").italic(true).bold(true)
//                +
//                Text(" due to space constraints.")
//            }
            
        }
    }
             
    
    var updatedByOtherPerson: some View {
        #if os(macOS)
        LabeledContent {
            Picker("", selection: $updatedByOtherUserDisplayMode) {
                ForEach(UpdatedByOtherUserDisplayMode.allCases, id: \.self) { opt in
                    Text(opt.prettyValue)
                        .tag(opt)
                }
            }
        } label: {
            Text("Display transactions edited by someone else as…")
        }
        #else
        Section {
            SettingsMenuPickerContainer(title: "Display as…", selectedTitle: updatedByOtherUserDisplayMode.prettyValue) {
                Picker("", selection: $updatedByOtherUserDisplayMode) {
                    ForEach(UpdatedByOtherUserDisplayMode.allCases, id: \.self) { opt in
                        Text(opt.prettyValue)
                            .tag(opt)
                    }
                }
            }
        } header: {
            Text("Edits From Others")
        } footer: {
            Text("Choose how to indicate that transactions have been edited by someone else.")
        }
        #endif
    }
            
    
    var incomeColorPicker: some View {
        /// Wrap in a menu so we can style the colors properly.
        Menu {
            /// Using a picker so we get the checkmark on the selected item.
            Picker("", selection: $incomeColor) {
                ForEach(AppState.shared.colorMenuOptions, id: \.self) { color in
                    Button {
                        incomeColor = color.description
                    } label: {
                        HStack {
                            Text(color.description.capitalized)
                            Image(systemName: "circle.fill")
                                .tint(color)
                                //.foregroundStyle(color, .primary, .secondary)
                        }
                    }
                    .tag(color.description)
                }
            }
            .labelsHidden()
            .pickerStyle(.inline)
            
        } label: {
            HStack {
                Text("Income color")
                    .schemeBasedForegroundStyle()
                Spacer()
                HStack(spacing: 4) {
                    Text(incomeColor.capitalized)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.footnote)
                }
                .foregroundStyle(Color.fromName(incomeColor))
            }
            
        }
    }
    
    
    var creditEodPicker: some View {
        Section {
            SettingsMenuPickerContainer(title: "Display as…", selectedTitle: creditEodView.prettyValue) {
                Picker("", selection: $creditEodView) {
                    ForEach(CreditEodView.allCases, id: \.self) { opt in
                        Text(opt.prettyValue)
                            .tag(opt)
                    }
                }
                .onChange(of: creditEodView) {
                    let _ = calModel.calculateTotal(for: calModel.sMonth)
                }
            }
        } header: {
            Text("Credit Account EOD's")
        } footer: {
            VStack(alignment: .leading) {
                Group {
                    let text1 = Text("If viewing ")
                    let text2 = Text("credit").italic(true).bold(true)
                    let text3 = Text(" transactions, choose how the EOD's are displayed.")
                    Text("\(text1)\(text2)\(text3)")
                    
//                    Text("If viewing ")
//                    +
//                    Text("credit").italic(true).bold(true)
//                    +
//                    Text(" transactions, choose how the EOD's are displayed.")
                }
                .foregroundStyle(.gray)
                .font(.footnote)
            }
        }
    }
    
    
    #if os(iOS)
    var phoneLineItemDisplay: some View {
        Section {
            SettingsMenuPickerContainer(title: "Display as…", selectedTitle: phoneLineItemDisplayItem.prettyValue) {
                Picker("", selection: $phoneLineItemDisplayItem.animation()) {
                    ForEach(PhoneLineItemDisplayItem.allCases, id: \.self) { opt in
                        Text(opt.prettyValue)
                            .tag(opt)
                    }
                }
            }
            
        } header: {
            Text("Line Items")
        } footer: {
            VStack(alignment: .leading) {
                Group {
//                    let text1 = Text("If viewing the calendar as ")
//                    let text2 = Text("full").italic(true).bold(true)
//                    let text3 = Text(", choose what to display for the line items.")
//                    Text("\(text1)\(text2)\(text3)")
                    
                    Text("Choose how line items are displayed on the calendar.")
                    
//                    Text("If viewing the calendar as ")
//                    +
//                    Text("full").italic(true).bold(true)
//                    +
//                    Text(", choose what to display for the line items.")
                }
                .foregroundStyle(.gray)
                .font(.footnote)
            }
        }
    }
    #endif
    
    
    var sortingOptions: some View {
        Section {
            SettingsMenuPickerContainer(title: "Sort transactions by…", selectedTitle: transactionSortMode.prettyValue) {
                Picker("", selection: $transactionSortMode) {
                    ForEach(TransactionSortMode.allCases, id: \.self) { opt in
                        Text(opt.prettyValue)
                            .tag(opt)
                    }
                }
            }
            
            
            
            if transactionSortMode == .category {
                SettingsMenuPickerContainer(title: "Sort categories by…", selectedTitle: categorySortMode.prettyValue) {
                    Picker("", selection: $categorySortMode) {
                        ForEach(SortMode.allCases, id: \.self) { opt in
                            Text(opt.prettyValue)
                                .tag(opt)
                        }
                    }
                    /// Only needed if we change the sort order from the settings modal, while on the category page in macOS
                    #if os(macOS)
                    .onChange(of: categorySortMode) { oldValue, newValue in
                        catModel.categories.sort {
                            categorySortMode == .title
                            ? ($0.title).lowercased() < ($1.title).lowercased()
                            : $0.listOrder ?? 1000000000 < $1.listOrder ?? 1000000000
                        }
                    }
                    #endif
                }
            }
            
            
        } header: {
            Text("Sorting Options")
        } footer: {
            EmptyView()
        }
    }
}



//#if os(iOS)
//struct DemoDay: View {
//    @Environment(\.colorScheme) var colorScheme
//    //@Local(\.colorTheme) var colorTheme
//    @Local(\.updatedByOtherUserDisplayMode) var updatedByOtherUserDisplayMode
//    @Local(\.useWholeNumbers) var useWholeNumbers
//    @Local(\.tightenUpEodTotals) var tightenUpEodTotals
//    @AppStorage("threshold") var threshold = "500.0"
//    @Local(\.lineItemIndicator) var lineItemIndicator
//    
//    
//    @Local(\.phoneLineItemDisplayItem) var phoneLineItemDisplayItem
//    
//    let dayNum: Int
//    @State private var day = CBDay(date: Date())
//
//    
//    let columnGrid = Array(repeating: GridItem(.flexible(), spacing: 3), count: 2)
//   
//    var body: some View {
//        VStack(spacing: 5) {
//            dayNumber
//            dailyTransactionList
//            eodText
//        }
//        .padding(.vertical, 2)
//        .task {
//            let trans1 = CBTransaction()
//            let cat1 = CBCategory()
//            cat1.color = .red
//            trans1.title = "Apples"
//            trans1.amountString = "-$5.69"
//            trans1.category = cat1
//            
//            let trans2 = CBTransaction()
//            let cat2 = CBCategory()
//            cat2.color = .orange
//            trans2.title = "Bananas"
//            trans2.amountString = "-$10.80"
//            trans2.category = cat2
//            
//            let trans3 = CBTransaction()
//            let cat3 = CBCategory()
//            cat3.color = .green
//            trans3.title = "Income"
//            trans3.amountString = "$912.12"
//            trans3.category = cat3
//            
//            day.transactions = [
//                trans1, trans2, trans3
//            ]
//        }
//
//    }
//    
//   
//        
//    var dayNumber: some View {
//        Text("\(dayNum)")
//            .frame(maxWidth: .infinity)
//            .foregroundColor(.primary)
//            .contentShape(Rectangle())
//    }
//    
//    var dailyTransactionList: some View {
//        VStack(alignment: .leading, spacing: 2) {
//            ForEach(day.transactions) { trans in
//                LineItemMiniView(
//                    trans: trans,
//                    day: day,
//                    tightenUpEodTotals: tightenUpEodTotals,
//                    lineItemIndicator: lineItemIndicator,
//                    phoneLineItemDisplayItem: phoneLineItemDisplayItem
//                    //putBackToBottomPanelViewOnRotate: .constant(false),
//                    //transHeight: .constant(40)
//                )
//                .padding(.vertical, 0)
//            }
//        }
//    }
//        
//    
//    var eodText: some View {
//        Group {
//            if useWholeNumbers && tightenUpEodTotals {
//                Text("\(String(format: "%.00f", day.eodTotal).replacing("$", with: "").replacing(",", with: ""))")
//                
//            } else if useWholeNumbers {
//                Text(day.eodTotal.currencyWithDecimals(0))
//                
//            } else if !useWholeNumbers && tightenUpEodTotals {
//                Text(day.eodTotal.currencyWithDecimals(2).replacing("$", with: "").replacing(",", with: ""))
//                
//            } else {
//                Text(day.eodTotal.currencyWithDecimals(2))
//            }
//        }
//        .font(.caption2)
//        .foregroundColor(.gray)
//        .frame(maxWidth: .infinity, alignment: .center) /// This causes each day to be the same size
//        .minimumScaleFactor(0.5)
//        .lineLimit(1)
//    }
//}
//
//
//#endif
