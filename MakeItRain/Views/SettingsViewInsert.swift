//
//  SettingsViewInsert.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/25/24.
//

import SwiftUI

struct SettingsViewInsert: View {
    @AppStorage("showPaymentMethodIndicator") var showPaymentMethodIndicator = false
    @AppStorage("incomeColor") var incomeColor: String = Color.blue.description
    @AppStorage("useWholeNumbers") var useWholeNumbers = false
    @AppStorage("tightenUpEodTotals") var tightenUpEodTotals = true
    @AppStorage("phoneLineItemDisplayItem") var phoneLineItemDisplayItem: PhoneLineItemDisplayItem = .both
    @AppStorage("preferDarkMode") var preferDarkMode: Bool = true
    @AppStorage("lineItemIndicator") var lineItemIndicator: LineItemIndicator = .emoji
    @AppStorage("creditEodView") var creditEodView: CreditEodView = .remainingBalance
    @AppStorage("appColorTheme") var appColorTheme: String = Color.blue.description
    
    @AppStorage("threshold") var threshold: Double = 500.00
    @State private var thresholdString: String = "500.00"

    //@AppStorage("macCategoryDisplayMode") var macCategoryDisplayMode: MacCategoryDisplayMode = .emoji
    
    @AppStorage("updatedByOtherUserDisplayMode") var updatedByOtherUserDisplayMode: UpdatedByOtherUserDisplayMode = .full
    @AppStorage("phoneLineItemTotalPosition") var phoneLineItemTotalPosition: PhoneLineItemTotalPosition = .below
    @AppStorage("categorySortMode") var categorySortMode: CategorySortMode = .title
    @AppStorage("transactionSortMode") var transactionSortMode: TransactionSortMode = .title
    
    @AppStorage("showHashTagsOnLineItems") var showHashTagsOnLineItems: Bool = true
    @Environment(CategoryModel.self) var catModel
    @Environment(CalendarModel.self) var calModel
    

    
    @State private var demoDay = CBDay(date: Date())
    
    
    @State private var phoneLineItemDisplayItemWhenSettingsWasOpened: PhoneLineItemDisplayItem?
    
    @FocusState private var focusedField: Int?
    
    
    var withDividers: Bool = false
        
    var body: some View {
        Group {
            Section("Options") {
                if phoneLineItemDisplayItem != .both {
                    paymentMethodIndicatorToggle
                }
                
                useWholeNumbersToggle
                tightenUpEodTotalsToggle
                showShowHashTagToggle
                incomeColorPicker
            }
            
            creditEodPicker
            
            #if os(iOS)
            phoneLineItemDisplay
            
            Section("Demo Day View") {
                HStack {
                    DemoDay(dayNum: 8)
                        .frame(maxWidth: .infinity)
                    DemoDay(dayNum: 9)
                        .frame(maxWidth: .infinity)
                    DemoDay(dayNum: 10)
                        .frame(maxWidth: .infinity)
                    DemoDay(dayNum: 11)
                        .frame(maxWidth: .infinity)
                }
            }
            
            #endif
            
            lineItemIndicatorPicker
            
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
                        .uiKeyboardType(useWholeNumbers ? .numberPad : .decimalPad)
                        /// Format the amount field

                        #else
                        TextField("Amount", text: $thresholdString)
                            .textFieldStyle(.roundedBorder)
                        #endif
                    }
                    .focused($focusedField, equals: 1)
                    .onChange(of: thresholdString) {
                        threshold = Double($1.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")) ?? 0.0
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
                    Text("Any EOD total under \(threshold.currencyWithDecimals(useWholeNumbers ? 0 : 2)) will be hilighted in ")
                        .foregroundStyle(.gray)
                        .font(.footnote)
                    + Text("orange")
                        .foregroundStyle(.orange)
                        .font(.footnote)
                    + Text(".")
                    + Text(" Any EOD total under \(0.currencyWithDecimals(useWholeNumbers ? 0 : 2)) will be hilighted in ")
                        .foregroundStyle(.gray)
                        .font(.footnote)
                    + Text("red")
                        .foregroundStyle(.red)
                        .font(.footnote)
                }
            }
        }
        .tint(Color.fromName(appColorTheme))
        
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
                Text("Show Tags")
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
    
    
    // MARK: - Line Item Indicator Picker
    var lineItemIndicatorPicker: some View {
        Group {
            #if os(macOS)
            LabeledContent {
                Picker("", selection: $lineItemIndicator) {
                    ForEach(LineItemIndicator.allCases, id: \.self) { opt in
                        Text(opt.prettyValue)
                            .tag(opt)
                    }
                }
            } label: {
                VStack(alignment: .leading) {
                    Text("Display what next to line item")
                    lineItemIndicatorPickerAddendum
                        .foregroundStyle(.gray)
                        .font(.footnote)
                }
            }
            #else
            Section {
                SettingsMenuPickerContainer(title: "Display as…", selectedTitle: lineItemIndicator.prettyValue) {
                    Picker("", selection: $lineItemIndicator) {
                        ForEach(LineItemIndicator.allCases, id: \.self) { opt in
                            Text(opt.prettyValue)
                                .tag(opt)
                        }
                    }
                }
                
            } header: {
                Text("Category / Payment Method Indicator")
            } footer: {
                VStack(alignment: .leading) {
                    lineItemIndicatorPickerAddendum
                }
            }
            #endif
        }
    }
    
    
    var lineItemIndicatorPickerAddendum: some View {
        Group {
            Text("If viewing the calendar as ")
            +
            Text("full").italic(true).bold(true)
            +
            Text(", choose how to indicate categories.")
            
            if lineItemIndicator == .emoji {
                Text("Note: Symbols will be displayed as dots when viewing as ")
                +
                Text("full").italic(true).bold(true)
                +
                Text(" due to space constraints.")
            }
            
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
            Text("Edits from others")
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
                                .foregroundStyle(color, .primary, .secondary)
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
                    .foregroundStyle(preferDarkMode ? .white : .black)
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
                    calModel.calculateTotalForMonth(month: calModel.sMonth)
                }
            }
        } header: {
            Text("Credit Account EOD's")
        } footer: {
            VStack(alignment: .leading) {
                Group {
                    Text("If viewing ")
                    +
                    Text("credit").italic(true).bold(true)
                    +
                    Text(" transactions, choose how the EOD's are displayed.")
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
                        
            if phoneLineItemDisplayItem == .both {
                SettingsMenuPickerContainer(title: "Display totals…", selectedTitle: phoneLineItemTotalPosition.prettyValue) {
                    Picker("Display totals…", selection: $phoneLineItemTotalPosition) {
                        ForEach(PhoneLineItemTotalPosition.allCases, id: \.self) { opt in
                            Text(opt.prettyValue)
                                .tag(opt)
                        }
                    }
                }
            }
        } header: {
            Text("Line Items")
        } footer: {
            VStack(alignment: .leading) {
                Group {
                    Text("If viewing the calendar as ")
                    +
                    Text("full").italic(true).bold(true)
                    +
                    Text(", choose what to display for the line items.")
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
                        ForEach(CategorySortMode.allCases, id: \.self) { opt in
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



#if os(iOS)
struct DemoDay: View {
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("appColorTheme") var appColorTheme: String = Color.blue.description
    @AppStorage("updatedByOtherUserDisplayMode") var updatedByOtherUserDisplayMode = UpdatedByOtherUserDisplayMode.full
    @AppStorage("useWholeNumbers") var useWholeNumbers = false
    @AppStorage("tightenUpEodTotals") var tightenUpEodTotals = true
    @AppStorage("threshold") var threshold = "500.0"
    @AppStorage("lineItemIndicator") var lineItemIndicator: LineItemIndicator = .emoji
    
    
    @AppStorage("phoneLineItemDisplayItem") var phoneLineItemDisplayItem: PhoneLineItemDisplayItem = .both
    
    let dayNum: Int
    @State private var day = CBDay(date: Date())

    
    let columnGrid = Array(repeating: GridItem(.flexible(), spacing: 3), count: 2)
   
    var body: some View {
        VStack(spacing: 5) {
            dayNumber
            dailyTransactionList
            eodText
        }
        .padding(.vertical, 2)
        .task {
            let trans1 = CBTransaction()
            let cat1 = CBCategory()
            cat1.color = .red
            trans1.title = "Apples"
            trans1.amountString = "-$5.69"
            trans1.category = cat1
            
            let trans2 = CBTransaction()
            let cat2 = CBCategory()
            cat2.color = .orange
            trans2.title = "Bananas"
            trans2.amountString = "-$10.80"
            trans2.category = cat2
            
            let trans3 = CBTransaction()
            let cat3 = CBCategory()
            cat3.color = .green
            trans3.title = "Income"
            trans3.amountString = "$912.12"
            trans3.category = cat3
            
            day.transactions = [
                trans1, trans2, trans3
            ]
        }

    }
    
   
        
    var dayNumber: some View {
        Text("\(dayNum)")
            .frame(maxWidth: .infinity)
            .foregroundColor(.primary)
            .contentShape(Rectangle())
    }
    
    var dailyTransactionList: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(day.transactions) { trans in
                LineItemMiniView(
                    transEditID: .constant(nil),
                    trans: trans,
                    day: day
                    //putBackToBottomPanelViewOnRotate: .constant(false),
                    //transHeight: .constant(40)
                )
                .padding(.vertical, 0)
            }
        }
    }
        
    
    var eodText: some View {
        Group {
            if useWholeNumbers && tightenUpEodTotals {
                Text("\(String(format: "%.00f", day.eodTotal).replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: ""))")
                
            } else if useWholeNumbers {
                Text(day.eodTotal.currencyWithDecimals(0))
                
            } else if !useWholeNumbers && tightenUpEodTotals {
                Text(day.eodTotal.currencyWithDecimals(2).replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: ""))
                
            } else {
                Text(day.eodTotal.currencyWithDecimals(2))
            }
        }
        .font(.caption2)
        .foregroundColor(.gray)
        .frame(maxWidth: .infinity, alignment: .center) /// This causes each day to be the same size
        .minimumScaleFactor(0.5)
        .lineLimit(1)
    }
}


#endif

//
//
//
//
//struct SettingsViewInsertOG: View {
//    @AppStorage("showPaymentMethodIndicator") var showPaymentMethodIndicator = false
//    @AppStorage("useWholeNumbers") var useWholeNumbers = false
//    @AppStorage("tightenUpEodTotals") var tightenUpEodTotals = true
//    @AppStorage("lineItemInteractionMode") var lineItemInteractionMode: LineItemInteractionMode = .open
//    @AppStorage("phoneLineItemDisplayItem") var phoneLineItemDisplayItem: PhoneLineItemDisplayItem = .both
//    
//    @AppStorage("lineItemIndicator") var lineItemIndicator: LineItemIndicator = .emoji
//    //@AppStorage("macCategoryDisplayMode") var macCategoryDisplayMode: MacCategoryDisplayMode = .emoji
//    
//    @AppStorage("updatedByOtherUserDisplayMode") var updatedByOtherUserDisplayMode: UpdatedByOtherUserDisplayMode = .full
//    @AppStorage("phoneLineItemTotalPosition") var phoneLineItemTotalPosition: PhoneLineItemTotalPosition = .below
//    @AppStorage("categorySortMode") var categorySortMode: CategorySortMode = .title
//    @AppStorage("transactionSortMode") var transactionSortMode: TransactionSortMode = .title
//    
//    @AppStorage("showHashTagsOnLineItems") var showHashTagsOnLineItems: Bool = true
//
//
//    
//    var withDividers: Bool = false
//    
//    
//    var body: some View {
//        Toggle(isOn: $showPaymentMethodIndicator) {
//            VStack(alignment: .leading) {
//                Text("Show Payment Method Indicator")
//                Text("Show an indicator when in a unified payment view to show which payment method was used on the transaction.")
//                    .foregroundStyle(.gray)
//                    .font(.footnote)
//            }
//        }
//        
//        if withDividers { Divider() }
//        
//        
//        Toggle(isOn: $useWholeNumbers) {
//            VStack(alignment: .leading) {
//                Text("Only whole numbers")
//                Text("Round all dollar amounts and remove their decimals.")
//                    .foregroundStyle(.gray)
//                    .font(.footnote)
//                
//            }
//        }
//        if withDividers { Divider() }
//        
//        
//        
//        
//        #if os(iOS)
//        Toggle(isOn: $tightenUpEodTotals) {
//            VStack(alignment: .leading) {
//                Text("Trim totals")
//                Text("Remove dollar signs and commas from totals.")
//                    .foregroundStyle(.gray)
//                    .font(.footnote)
//            }
//        }
//        if withDividers { Divider() }
//        
//        #endif
//        
//        Toggle(isOn: $showHashTagsOnLineItems) {
//            VStack(alignment: .leading) {
//                Text("Show Tags")
//                Text("Display tags belows the transaction title.")
//                    .foregroundStyle(.gray)
//                    .font(.footnote)
//            }
//        }
//        
//        if withDividers { Divider() }
//        
//        
//        
//        
//        #if os(iOS)
//        
//        
//        LabeledContent {
//            Picker("", selection: $transactionSortMode) {
//                Text("Titles")
//                    .tag(TransactionSortMode.title)
//                Text("Categories")
//                    .tag(TransactionSortMode.category)
//            }
//        } label: {
//            Text("Sort transactions by...")
//        }
//        
//        if withDividers { Divider() }
//        
//        LabeledContent {
//            Picker("", selection: $categorySortMode) {
//                Text("Titles")
//                    .tag(CategorySortMode.title)
//                Text("Manually")
//                    .tag(CategorySortMode.listOrder)
//            }
//        } label: {
//            Text("Sort categories by...")
//        }
//        
//        if withDividers { Divider() }
//        
//        LabeledContent {
//            Picker("", selection: $phoneLineItemDisplayItem.animation()) {
//                Text("Titles")
//                    .tag(PhoneLineItemDisplayItem.title)
//                Text("Totals")
//                    .tag(PhoneLineItemDisplayItem.total)
//                Text("Title & Total")
//                    .tag(PhoneLineItemDisplayItem.both)
//            }
//            .onChange(of: phoneLineItemDisplayItem) { oldValue, newValue in
//                if newValue == .both {
//                    lineItemInteractionMode = .open
//                }
//            }
//        } label: {
//            VStack(alignment: .leading) {
//                Text("Display what on line items")
//                Group {
//                    Text("If viewing the calendar as ")
//                    +
//                    Text("details").italic(true).bold(true)
//                    +
//                    Text(" or ")
//                    +
//                    Text("full").italic(true).bold(true)
//                    +
//                    Text(", choose what to display for the line items.")
//                }
//                .foregroundStyle(.gray)
//                .font(.footnote)
//                
//            }
//        }
//        
//        if withDividers { Divider() }
//        
//        if phoneLineItemDisplayItem != .both {
//            LabeledContent {
//                Picker("", selection: $lineItemInteractionMode) {
//                    Text("Open")
//                        .tag(LineItemInteractionMode.open)
//                    Text("Preview")
//                        .tag(LineItemInteractionMode.preview)
//                }
//            } label: {
//                VStack(alignment: .leading) {
//                    Text("Do what when touching a line item")
//                    Group {
//                        Text("If ")
//                        +
//                        Text("preview").italic(true).bold(true)
//                        +
//                        Text(", touch the preview, or the line item again open it.")
//                    }
//                    .foregroundStyle(.gray)
//                    .font(.footnote)
//                }
//            }
//            if withDividers { Divider() }
//        }
//        
//        
//        LabeledContent {
//            Picker("", selection: $phoneLineItemTotalPosition) {
//                Text("Next to title")
//                    .tag(PhoneLineItemTotalPosition.inline)
//                Text("Below title")
//                    .tag(PhoneLineItemTotalPosition.below)
//            }
//        } label: {
//            VStack(alignment: .leading) {
//                Text("Display totals…")
//            }
//        }
//        if withDividers { Divider() }
//        
//        
//        
//        
//        
//        
//        
//        #endif
//
//        
//        
//        LabeledContent {
//            Picker("", selection: $lineItemIndicator) {
//                Text("Category Dot")
//                    .tag(LineItemIndicator.dot)
//                Text("Category Symbol")
//                    .tag(LineItemIndicator.emoji)
//                #if os(iOS)
//                Text("Payment Method")
//                    .tag(LineItemIndicator.paymentMethod)
////                Text("None")
////                    .tag(LineItemIndicator.none)
//                #endif
//            }
//        } label: {
//            VStack(alignment: .leading) {
//                Text("Display what next to line item")
//                Group {
//                    Text("If viewing the calendar as ")
//                    +
//                    Text("details").italic(true).bold(true)
//                    +
//                    Text(" or ")
//                    +
//                    Text("full").italic(true).bold(true)
//                    +
//                    Text(", choose how to indicate categories.")
//                    
//                    Text("Note: Symbols will be displayed as dots when viewing as ")
//                    +
//                    Text("details").italic(true).bold(true)
//                    +
//                    Text(" or ")
//                    +
//                    Text("full").italic(true).bold(true)
//                    +
//                    Text(" due to space constraints.")
//                }
//                .foregroundStyle(.gray)
//                .font(.footnote)
//            }
//        }
//
//        if withDividers { Divider() }
//        
//        
//        LabeledContent {
//            Picker("", selection: $updatedByOtherUserDisplayMode) {
//                Text("Bold & italic title")
//                    .tag(UpdatedByOtherUserDisplayMode.concise)
//                Text("Their name")
//                    .tag(UpdatedByOtherUserDisplayMode.full)
//            }
//        } label: {
//            Text("Display transactions edited by someone else as…")
//        }
//        
//        if withDividers { Divider() }
//        
//    }
//}
