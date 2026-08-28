//
//  EditTransactionView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/19/24.
//

import SwiftUI
import PhotosUI
import SafariServices
import TipKit
import MapKit
import WebKit

fileprivate let photoWidth: CGFloat = 125
fileprivate let photoHeight: CGFloat = 200

enum TitleSuggestionType: String {
    case location, history, byCategoryFrequency
    
}

enum TransNavDest: Hashable {
    case options, logs, titleColorMenu, tracking, tags
}

struct TransactionEditView: View {
    @Local(\.lineItemIndicator) var lineItemIndicator
    
    
    @AppStorage("shouldWarmUpTransactionViewDuringSplash") var shouldWarmUpTransactionViewDuringSplash: Bool = false
    @AppStorage("transactionTitleSuggestionType") var transactionTitleSuggestionType: TitleSuggestionType = .location
    //@Environment(\.fontResolutionContext) var fontResolutionContext

    //@Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss // <--- NO NICE THAT ONE WITH SHEETS IN A SHEET. BEWARE!.
    #if os(macOS)
    @Environment(\.openURL) var openURL
    #endif
    @Environment(CalendarModel.self) private var calModel
    @Environment(PayMethodModel.self) private var payModel
    @Environment(CategoryModel.self) private var catModel
    @Environment(KeywordModel.self) private var keyModel
    @Environment(AppStore.self) private var store
    
    @Bindable var trans: CBTransaction
    //@Binding var transEditID: String?
    @Bindable var day: CBDay
    /// Add the tag to the transaction if adding a new transaction from the tag budget view.
    var tag: CBTag?
    
    var isTemp: Bool
    var transLocation: WhereToLookForTransaction = .normalList
    var isWarmUp = false
    let symbolWidth: CGFloat = 26
    let converter = CurrencyConverter()
        
    @FocusState private var focusedField: Int?
    @State private var mapModel = MapModel()
    @State private var titleColorButtonHoverColor: Color = .gray
    @State private var payMethodMenuColor: Color = Color(.tertiarySystemFill)
    @State private var categoryMenuColor: Color = Color(.tertiarySystemFill)
    //@State private var showLogSheet = false
    //@State private var showTagSheet = false
    //@State private var showPayMethodSheet = false
    //@State private var showCategorySheet = false
    @State private var showPaymentMethodChangeAlert = false
    //@State private var showDeleteAlert = false
    @State private var blockUndoCommitOnLoad = true
    //@State private var blockKeywordChangeWhenViewLoads = true
    //@State private var blockSuggestionsFromPopulating = false
    //@State private var showTrackingOrderAndUrlFields = false
    @State private var showCamera: Bool = false
    @State private var showPhotosPicker: Bool = false
    //@State private var showTopTitles: Bool = false
    @State private var showSplitSheet = false
    @State private var showInvoiceGeneratorSheet = false
    //@State private var showConverterSheet = false

    //@State private var titleChangedTask: Task<Void, Error>?
    //@State private var amountChangedTask: Task<Void, Error>?
    @State private var showUndoRedoAlert = false
    //@State private var suggestedTitles: Array<CBSuggestedTitle> = []
    @State private var navPath = NavigationPath()
    @State private var isValidToSave = false
    //@State private var hasAnimatedBrain = false
    /// These are just to control the animations in the options sheet. The are here so we don't see the option sheet "set up its state" when the view appears.
    @State private var showBadgeBell = false
    @State private var showHiddenEye = false
    @State private var showContent = false
    @State private var showExpensiveViews = false
    @State private var suggestedCategories: Array<CBCategory> = []
    @State private var shouldDismissOnMac: Bool = false
    @State private var showCountrySheet = false
    //@State private var selection = AttributedTextSelection()
    //@State private var textCommands = TextViewCommands()
    
    @State private var shouldSuggestAddingNewRule = false
    @State private var existingRuleCount: Int = 0
    @State private var editOriginalAmount = false
    
    @State private var showUseCurrentLocationButton = true
//    @State private var suggestedLocations: Array<CBSuggestedLocation> = []
    @State private var shouldShowLocationSuggestions = false
    @State private var suggestedLocations: Array<CBSuggestedLocation> = []

        
    let changeTransactionTitleColorTip = ChangeTransactionTitleColorTip()
    
    var title: String { trans.action == .add ? "New \(transTypeLingo)" : "Edit \(transTypeLingo)" }
    
    var transTypeLingo: String {
        if trans.payMethod?.accountType == .credit || trans.payMethod?.accountType == .loan {
            trans.amountString.contains("-") 
            ? "Payment"
            : trans.christmasListGiftID != nil ? "Gift" : "Expense"
        } else {
            trans.amountString.contains("-") 
            ? trans.christmasListGiftID != nil ? "Gift" : "Expense"
            : "Income"
        }
    }
    
    var linkedLingo: String? {
        if trans.relatedTransactionID != nil {
            return "(Linked)"
        } else if trans.christmasListGiftID != nil {
            return "(Linked 🎄)"
        } else {
            return nil
        }
    }
    
    
    var accountLabelLingo: String {
        //let type = trans.relatedTransactionID == nil ? "" : trans.isOrigin ? " (Pay-From)" : " (Pay-To)"
        //return "Account\(type)"
        
        if trans.relatedTransactionID == nil {
            return "Account"
        } else if trans.isPaymentOrigin {
            return "Paid From"
        } else if trans.isTransferOrigin {
            return "Transferred From"
        } else if trans.isPaymentDest {
            return "Paid To"
        } else if trans.isTransferDest {
            return "Transferred To"
        } else {
            return trans.isOrigin ? "Pay-From" : "Pay-To"
        }
    }
    
    
    var secondaryAccountLabelLingo: String {
        if trans.relatedTransactionID == nil {
            return ""
        } else if trans.isPaymentOrigin {
            return "Paid To"
        } else if trans.isTransferOrigin {
            return "Transferred To"
        } else if trans.isPaymentDest {
            return "Paid From"
        } else if trans.isTransferDest {
            return "Transferred From"
        } else {
            return trans.isOrigin ? "Pay-To" : "Pay-From"
        }
    }
    
    
    var paymentMethodMissing: Bool {
        return !trans.title.isEmpty && !trans.amountString.isEmpty && trans.payMethod == nil
    }
    
    var topThreeMeths: Array<CBPaymentMethod>.SubSequence {
        payModel.paymentMethods.sorted { $0.recentTransactionCount > $1.recentTransactionCount }.prefix(3)
    }
        
    
    var undoRedoValuesChanged: Int {
        var hasher = Hasher()
        hasher.combine(trans.title)
        hasher.combine(trans.amountString)
        hasher.combine(trans.payMethod)
        hasher.combine(trans.category)
        hasher.combine(trans.trackingNumber)
        hasher.combine(trans.orderNumber)
        hasher.combine(trans.url)
        hasher.combine(trans.notes)
        hasher.combine(trans.date)
        return hasher.finalize()
    }
    
    
    var body: some View {
        //let _ = Self._printChanges()
        NavigationStack(path: $navPath) {
            if showContent {
                ScrollViewReader { scrollProxy in
                    #if os(iOS)
                    StandardContainerWithToolbar(.list) {
                        content(scrollProxy)
                    }
                    #else
                    Form {
                        content(scrollProxy)
                    }
                    .formStyle(.grouped)
                    #endif
                }
                .navigationTitle(title)
                .if(trans.relatedTransactionID != nil || trans.christmasListGiftID != nil) { $0.navigationSubtitle(linkedLingo!) }
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .toolbar { toolbar }
                .navigationDestination(for: TransNavDest.self) { determineNavDest(for: $0) }
                .scrollContentBackground(trans.christmasListGiftID == nil ? .visible : .hidden)
                .background(
                    SnowyBackground(blurred: true, withSnow: true)
                        .opacity(trans.christmasListGiftID == nil ? 0 : 1)
                )
            }
            else if !calModel.transactionViewHasBeenWarmedUp && !shouldWarmUpTransactionViewDuringSplash {
                ProgressView()
                    .tint(.none)
            }
        }
        .interactiveDismissDisabled(paymentMethodMissing || !navPath.isEmpty)
        .onAppear { handleWarmUpAndExpensiveViews() }
        .task {
            if !isWarmUp {
                prepareTransactionForEditing(isTemp: isTemp)
                ChangeTransactionTitleColorTip.didOpenTransaction.sendDonation()
            }
        }
        .alert("Please change the selected account by right-clicking on the line item from the main view.", isPresented: $showPaymentMethodChangeAlert) { Button("OK") {} }
        .sheet(isPresented: $showSplitSheet) {
            TevSplitSheet(trans: trans, showSplitSheet: $showSplitSheet)
                #if os(macOS)
                .presentationSizing(.page)
                #endif
        }
        .sheet(isPresented: $showInvoiceGeneratorSheet) {
            PdfInvoiceCreatorSheet(trans: trans)
                #if os(macOS)
                .presentationSizing(.page)
                #endif
        }
        .sheet(isPresented: $showCountrySheet, onDismiss: {
            if !editOriginalAmount {
                trans.condataOriginalAmountString = trans.amountString
                converter.convert(obj: trans, calModel: calModel)
            }
        }) {
            CountryPicker(country: $trans.condataOriginalCountry)
        }
//        .sheet(isPresented: $showConverterSheet) {
//            CurrencyConverterSheet(trans: trans, day: day)
//        }
        .environment(mapModel)
//        /// Check what color the save button should be.
//        .onChange(of: transactionValuesChanged) { checkIfTransactionIsValidToSave() }
                   
        #if os(macOS)
        .onChange(of: shouldDismissOnMac) {
            if $1 {
                dismiss()
            }
        }
        #endif
        
        #if os(iOS)
        /// Prompt for undo/redo on shake.
        .onShake {
            UndodoManager.shared.getChangeFields(trans: trans)
            UndodoManager.shared.showAlert = true
        }
        /// Handle undo and redo.
        .onChange(of: undoRedoValuesChanged) { UndodoManager.shared.processChange(trans: trans) }
        /// Handle undo and redo.
        .onChange(of: UndodoManager.shared.returnMe) { handleUndoRedo(new: $1) }
        /// Convert foreign currency when the date changes.
        .onChange(of: trans.date) {
            if trans.condataOriginalCountry != nil {
                converter.convert(obj: trans, calModel: calModel)
            }
        }
        /// Convert foreign currency when the original amount changes.
        .onChange(of: trans.condataOriginalAmountString) {
            if trans.condataOriginalCountry != nil {
                converter.convert(obj: trans, calModel: calModel)
            }
        }
        /// Handle undo and redo.
        .onChange(of: focusedField) { oldFocus, newFocus in
            if newFocus != nil {
                if trans.action == .add && blockUndoCommitOnLoad {
                    blockUndoCommitOnLoad = false
                } else {
                    UndodoManager.shared.changeTask?.cancel()
                    UndodoManager.shared.commitChange(trans: trans)
                }
            }
            
            let setCur = AppState.shared.country.currencyCode
            let didFocusAmount = newFocus == 1
            let didUnfocusAmount = oldFocus == 1
            
            if didUnfocusAmount {
                /// Clear out the negative symbol if that's all that is there.
                if trans.amountString == "-" {
                    trans.amountString = ""
                }
                
                if !trans.amountString.isEmpty {
                    /// When unfocusing the field, format the currency with symbol & commas.
                    trans.amountString = trans.amount.currencyWithDecimals(currencyCode: setCur)
                }
                                
            } else if didFocusAmount {
                /// When focusing the field, remove the currency symbol and commas.
                trans.amountString = CurrencyHelpers.cleanAmountString(trans.amountString, currencyCode: setCur)
                
                /// If the field is blank, when switching between payment methods, toggle the "-" if applicable to respect an expense/payment.
                if trans.amountString.isEmpty && trans.payMethod?.isDebitOrCash == true {
                    trans.amountString = "-"
                }
            }
            
            
            /// Handle when leaving the foreign currency field, and the country sheet is not showing.
            /// When accessing the country sheet, and using its search field, it will mess up with focus of the main textfield.
            /// This seems to be an issue with sheets specifically, as that behavior does not happen with a navdest.
            if (oldFocus == 10 || (oldFocus == 10 && newFocus == nil)) && !showCountrySheet {
                converter.convert(obj: trans, calModel: calModel)
                withAnimation {
                    //print(oldFocus, newFocus)
                    //print("CHANGING VIA FOCUS")
                    editOriginalAmount = false
                }
            }
        }
        #endif
        .onChange(of: trans.payMethod) { oldMeth, newMeth in
            if trans.condataOriginalCountry != nil {
                converter.convert(obj: trans, calModel: calModel)
            }
            
            guard let oldMeth, let newMeth else { return }
            if (oldMeth.isDebitOrCash && newMeth.isCreditOrLoan) || (oldMeth.isCreditOrLoan && newMeth.isDebitOrCash) {
                Helpers.plusMinus($trans.amountString)
                Helpers.plusMinus($trans.condataOriginalAmountString)
                Helpers.plusMinus($trans.condataPayMethodAmountString)
            }
        }
//        .onChange(of: trans.title) {
//            if trans.action == .add, !trans.title.isEmpty, trans.locations.isEmpty {
//                print(store.suggestedLocations)
//                suggestedLocations = store.suggestedLocations.filter {$0.transTitle.localizedCaseInsensitiveContains(trans.title)}
//                if !suggestedLocations.isEmpty {
//                    shouldShowLocationSuggestions = true
//                }
//            }
//        }
    }
        
    
    @ViewBuilder
    func content(_ scrollProxy: ScrollViewProxy) -> some View {
        Section {
            TevTitle(
                trans: trans,
                mapModel: mapModel,
                suggestedCategories: $suggestedCategories,
                shouldShowLocationSuggestions: $shouldShowLocationSuggestions,
                suggestedLocations: $suggestedLocations,
                focusedField: $focusedField,
            )
            
            TevAmount(
                trans: trans,
                showCountrySheet: $showCountrySheet,
                focusedField: $focusedField
            )
            .opacity(editOriginalAmount ? 0 : 1)
            .overlay {
                ForeignAmountTextField(
                    obj: trans,
                    showCountrySheet: $showCountrySheet,
                    focusedField: $focusedField,
                    editOriginalAmount: editOriginalAmount
                )
            }
        } footer: {
            if trans.condataOriginalCountry != AppState.shared.country || trans.payMethod?.country != AppState.shared.country {
                ForeignAmountToolsScroller(
                    obj: trans,
                    editOriginalAmount: $editOriginalAmount,
                    showCountrySheet: $showCountrySheet,
                    focusedField: $focusedField
                )
            }
        }
                
        paymentMethodAndCategorySection
        
        if showExpensiveViews {
            TevRuleSuggestionButton(
                trans: trans,
                shouldSuggestAddingNewRule: $shouldSuggestAddingNewRule,
                existingCount: existingRuleCount
            )
        }
        
        Section {
            TevDatePicker(
                trans: trans,
                day: day,
                focusedField: $focusedField
            )
        }
        
        if !isTemp {
            TevMap(
                trans: trans,
                mapModel: mapModel,
                suggestedLocations: $suggestedLocations,
                showUseCurrentLocationButton: $showUseCurrentLocationButton,
                shouldShowLocationSuggestions: $shouldShowLocationSuggestions,
                showExpensiveViews: showExpensiveViews
            )
        }
        
        if trans.christmasListGiftID != nil {
            Section("Gift Status 🎄") {
                christmasListGiftStatusPicker
            }
        }
        
        
        TevTrackingAndOrder(
            symbolWidth: symbolWidth,
            trackingNumber: $trans.trackingNumber,
            orderNumber: $trans.orderNumber,
            url: $trans.url,
            focusedField: $focusedField
        )
        
        if showExpensiveViews {
            if !isTemp {
                TevHashtags(tags: trans.tags)
            }
        } else {
            ProgressView()
                .frame(maxWidth: .infinity)
                .tint(.none)
        }
        
        if !isTemp {
            fileSection
        }
        
        #if os(iOS)
        if showExpensiveViews {
            StandardUITextEditor(text: $trans.notes, focusedField: _focusedField, focusID: 2, scrollProxy: scrollProxy)
        } else {
            ProgressView()
                .frame(maxWidth: .infinity)
                .frame(height: 100)
                .tint(.none)
        }
        #endif
        
        Section {
            deleteButton
        }
    }
    
    
    
    
    // MARK: - SubViews
    
    
    @State private var showDeleteAlert = false
    
    var deleteButton: some View {
        Button {
            showDeleteAlert = true
        } label: {
            Text("Delete Transaction")
                .frame(maxWidth: .infinity, alignment: .center)
                .foregroundStyle(.red)
//            Image(systemName: "trash")
//                #if os(macOS)
//                    .foregroundStyle(.red)
//                #endif
        }
        #if os(macOS)
        .buttonStyle(.roundMacButton)
        #endif
        .sensoryFeedback(.warning, trigger: showDeleteAlert) { !$0 && $1 }
        .tint(.none)
        .confirmationDialog("Are you sure you want to delete this transaction?", isPresented: $showDeleteAlert) {
            Button(role: .destructive) {
                delete(.delete)
            } label: {
                Text(deleteLingo(.delete))
            }
            
            
            if trans.christmasListGiftID != nil {
                Button(role: .destructive) {
                    delete(.resetStatusToIdea)
                } label: {
                    Text(deleteLingo(.resetStatusToIdea))
                }
            }
        } message: {
            Text("Are you sure you want to delete this transaction?")
        }
    }
    
    
//    struct DeleteYesButton: View {
//        @Environment(CalendarModel.self) private var calModel
//    
//        @Environment(\.dismiss) var dismiss
//        @Bindable var trans: CBTransaction
//        @Binding var shouldDismissOnMac: Bool
//        //@Binding var transEditID: String?
//        var isTemp: Bool
//        var christmasListDeletePeference: ChristmasListDeletePreference
//        
//        var body: some View {
//            Button(deleteLingo, role: .destructive, action: delete)
//        }
//    }
    
    
    func deleteLingo(_ christmasListDeletePeference: ChristmasListDeletePreference) -> String {
        if trans.christmasListGiftID == nil {
            "Delete Transaction"
        } else {
            switch christmasListDeletePeference {
            case .delete:
                "Delete Transaction & Gift"
            case .resetStatusToIdea:
                "Delete Transaction & Set Gift As Idea"
            }
        }
    }
    
    func delete(_ christmasListDeletePeference: ChristmasListDeletePreference) {
        if isTemp {
            #if os(iOS)
            dismiss()
            #else
            shouldDismissOnMac = true
            #endif
            calModel.tempTransactions.removeAll { $0.id == trans.id }
            //let _ = DataManager.shared.delete(type: TempTransaction.self, predicate: .byId(.string(trans.id)))
            
            Task {
                let context = DataManager.shared.createContext()
                context.perform {
                    if let entity = DataManager.shared.getOne(context: context, type: TempTransaction.self, predicate: .byId(.string(trans.id)), createIfNotFound: true) {
                        entity.action = TransactionAction.delete.rawValue
                        entity.tempAction = TransactionAction.delete.rawValue
                        let _ = DataManager.shared.save(context: context)
                    }
                }
            }
            
        } else {
            /// Prevent from going to the server and trying to delete something that isn't there.
            if trans.action == .add {
                Task {
                    await calModel.delete(trans, andSubmit: false)
                }
            } else {
                trans.christmasListDeletePreference = christmasListDeletePeference
                trans.action = .delete
            }
            
            //dismiss()
            
            
            //transEditID = nil
            //trans.christmasListDeletePreference = christmasListDeletePeference
            //trans.action = .delete
            #if os(iOS)
            dismiss()
            #else
            shouldDismissOnMac = true
            #endif
            
            //calModel.saveTransaction(id: trans.id, day: day)
        }
    }
    
    
    @ViewBuilder
    func determineNavDest(for dest: TransNavDest) -> some View {
        switch dest {
        case .options:
            TevMoreOptions(
                trans: trans,
                showSplitSheet: $showSplitSheet,
                showInvoiceGeneratorSheet: $showInvoiceGeneratorSheet,
                isTemp: isTemp,
                navPath: $navPath,
                showBadgeBell: $showBadgeBell,
                showHiddenEye: $showHiddenEye
            )
            .if(trans.christmasListGiftID != nil) {
                $0
                .scrollContentBackground(.hidden)
                .background(SnowyBackground(blurred: true, withSnow: true))
            }
            
        case .logs:
            TevLogSheet(title: trans.title, itemID: trans.serverID, logType: .transaction)
                .if(trans.christmasListGiftID != nil) {
                    $0
                    .scrollContentBackground(.hidden)
                    .background(SnowyBackground(blurred: true, withSnow: true))
                }
            
        case .titleColorMenu:
            TitleColorList(color: $trans.color, navPath: $navPath)
            //TitleColorList(trans: trans, saveOnChange: false, navPath: $navPath)
                .if(trans.christmasListGiftID != nil) {
                    $0
                    .scrollContentBackground(.hidden)
                    .background(SnowyBackground(blurred: true, withSnow: true))
                }
        case .tracking:
            #if os(iOS)
            TevTrackingNumberView(trackingNumber: $trans.trackingNumber)
            #else
            Text("Not available on this platform")
            #endif
            
        case .tags:
            TagView(tags: $trans.tags)
        }
    }
    
    
    var toolbar: some ToolbarContent {
        TevToolbar(
            trans: trans,
            //transEditID: $transEditID,
            isTemp: isTemp,
            showExpensiveViews: showExpensiveViews,
            focusedField: $focusedField,
            shouldDismissOnMac: $shouldDismissOnMac
        )
    }
    
    
    @ViewBuilder
    var categoryLine: some View {
        #if os(iOS)
        if showExpensiveViews {
            CategorySheetButton(category: $trans.category)
                .listRowSeparator(suggestedCategories.isEmpty ? .automatic : .hidden)
        } else {
            ProgressView()
                .frame(maxWidth: .infinity)
                .tint(.none)
        }
        #else
        CategorySheetButton(category: $trans.category)
        #endif
        
    }
    
    
    @ViewBuilder
    var categorySuggestionLine: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(suggestedCategories) { cat in
                    Button {
                        trans.category = cat
                        self.suggestedCategories.removeAll()
                    } label: {
                        Text("\(cat.title)?")
                            .foregroundStyle(.gray)
                            .font(.subheadline)
                    }
                    .padding(8)
                    .background(Capsule().foregroundStyle(.thickMaterial))
                }
            }
        }
        .scrollIndicators(.hidden)
    }
    
    
    @ViewBuilder
    var paymentMethodQuickPick: some View {
        //if trans.action == .add {
            HStack {
                ScrollView(.horizontal) {
                    HStack {
//                            Label {
//                                Text("")
//                            } icon: {
//                                AiAnimatedAliveSymbol(symbol: "brain", withGlow: false)
//                                    .font(.title2)
//                            }
//                            .padding(.trailing, -16)
                        
                        ForEach(topThreeMeths) { meth in
                            Button {
                                trans.payMethod = meth
                            } label: {
                                HStack {
//                                    BusinessLogo(config: .init(
//                                        parent: meth,
//                                        fallBackType: .customImage(.init(name: meth.fallbackImage, color: meth.color)),
//                                        size: 20
//                                    ))
                                    
                                    Text("\(meth.title)?")
                                        .foregroundStyle(.gray)
                                        .font(.subheadline)
                                }
                                
                            }
                            #if os(iOS)
                            .padding(8)
                            .background(Capsule().foregroundStyle(.thickMaterial))
                            //.background(Capsule().foregroundStyle(Color(.tertiarySystemFill)))
                            #else
                            .buttonStyle(.roundMacButton(horizontalPadding: 10))
                            #endif
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
            //.listRowInsets(EdgeInsets()) /// use without the brain, kill with
            //.padding(.leading, -2) /// use with the brain, kill without
            //.padding(.leading, -5) /// use without the brain, kill with
            
            
//        } else {
//            EmptyView()
//        }
    }
    
    
    @ViewBuilder
    var paymentMethodAndCategorySection: some View {
        
        if trans.category?.isIncome == true && trans.payMethod?.isCreditOrLoan == true {
            Section {
                Text("The category you assigned seems weird. An income category should not be assigned on a credit transaction.")
                    .foregroundStyle(.orange)
            } header: {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(LinearGradient(gradient: Gradient(colors: [.orange, .red]), startPoint: .top, endPoint: .bottom))
                    Text("Hmm…")
                }
            }
            
        }
        
        if !suggestedCategories.isEmpty {
            Section {
                categoryLine
            } footer: {
                categorySuggestionLine
            }
        }
        
        Section {
            //if showExpensiveViews {
                if suggestedCategories.isEmpty {
                    categoryLine
                }
                
                
                /// Main payment method picker.
                PayMethodSheetButton(
                    text: accountLabelLingo,
                    logoFallBackType: .customImage(.init(
                        name: trans.payMethod?.fallbackImage,
                        color: trans.payMethod?.color
                    )),
                    payMethod: $trans.payMethod,
                    whichPaymentMethods: .allExceptUnified
                )
                
                /// Related payment method picker.
                if let relatedID = trans.relatedTransactionID, let method = calModel.getTransaction(by: relatedID)?.payMethod {
                    PayMethodSheetButton(
                        text: secondaryAccountLabelLingo,
                        logoFallBackType: .customImage(.init(
                            name: method.fallbackImage,
                            color: method.color,
                        )),
                        isDisabled: true,
                        payMethod: .constant(method),
                        whichPaymentMethods: .allExceptUnified
                    )
                    .onTapGesture {
                        AppState.shared.showAlert("To change this, please edit the related transaction instead.")
                    }
                }
//            } else {
//                ProgressView()
//                    .frame(maxWidth: .infinity)
//                    .tint(.none)
//            }
        } footer: {
            paymentMethodQuickPick
        }
    }
    
        
//    var mapSection: some View {
//        Section {
//            if showExpensiveViews {
//                StandardMiniMap(
//                    locations: $trans.locations,
//                    parent: trans,
//                    parentID: trans.id,
//                    parentType: .transaction,
//                    addCurrentLocation: false
//                )
//                .listRowInsets(EdgeInsets())
//                .overlay {
//                    if trans.action == .add && showUseCurrentLocationButton {
//                        VStack {
//                            Button {
//                                mapModel.completions.removeAll()
//                                Task {
//                                    if let location = await mapModel.saveCurrentLocation(parentID: trans.id, parentType: .transaction) {
//                                        trans.upsert(location)
//                                    }
//                                }
//                                showUseCurrentLocationButton = false
//                            } label: {
//                                Image(systemName: "heart")
////                                ZStack {
////                                    Image(systemName: "heart")
////                                        .font(.title)
////                                    Image(systemName: "location.fill")
////                                        .font(.caption2)
////                                }
//                            }
//                            .clipShape(.circle)
//                            #if os(iOS)
//                            .buttonStyle(.glass)
//                            #endif
//                            
////                            Button("Use Current") {
////                                
////                            }
////                            .buttonStyle(.glass)
//                        }
//                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
//                        .padding(.bottom, 5)
//                        .padding(.trailing, 5)
//                        
//                    }
//                }
//            } else {
//                ProgressView()
//                    .listRowInsets(EdgeInsets())
//                    .frame(maxWidth: .infinity)
//                    .frame(height: 150)
//                    .tint(.none)
//            }
//        } header: {
//            Text("Transaction Location")
//        } footer: {
//            if shouldShowLocationSuggestions {
//                HStack {
//                    ScrollView(.horizontal) {
//                        HStack {
//                            ForEach(suggestedLocations.prefix(3)) {
//                                mapSuggestionButton(for: $0)
//                                //mapSuggestionButton(for: $0)
//                            }
//                        }
//                    }
//                    .scrollIndicators(.hidden)
//                }
//            }
//        }
//    }
//    
//    
//    @ViewBuilder
//    func mapSuggestionButton(for location: CBSuggestedLocation) -> some View {
//        Button {
//            shouldShowLocationSuggestions = false
//            Task {
//                if let location = await mapModel.addLocationViaTouchAndHold(coordinate: location.coordinates, parentID: trans.id, parentType: .transaction) {
//                    trans.upsert(location)
//                    mapModel.focusOnFirst(locations: trans.locations)
//                }
//                
//            }
//        } label: {
//            Text(location.locationTitle)
//                //.font(.caption2)
//                .foregroundStyle(.gray)
////            VStack(alignment: .leading) {
////                Text(AttributedString(completion.highlightedTitleStringForDisplay))
////                    .font(.caption2)
////                    .foregroundStyle(.gray)
////                
////                Text(AttributedString(completion.truncatedHighlightedSubtitleStringForDisplay))
////                    .font(.caption2)
////                    .foregroundStyle(.gray)
////            }
//        }
//        #if os(iOS)
//        .padding(8)
//        .background(Capsule().foregroundStyle(.thickMaterial))
//        #else
//        .buttonStyle(.roundMacButton(horizontalPadding: 10))
//        #endif
//    }
//    
//    
//    @ViewBuilder
//    func mapSuggestionButtonOG(for completion: MKLocalSearchCompletion) -> some View {
//        Button {
//            //mapModel.blockCompletion = true
//            //trans.title = completion.title
//            store.suggestedLocations.removeAll()
//            //resetLocalTitleSuggestionType()
//            Task {
//                if let location = await mapModel.getMapItem(
//                    from: completion,
//                    parentID: trans.id,
//                    parentType: .transaction
//                ) {
//                    trans.upsert(location)
//                    mapModel.focusOnFirst(locations: trans.locations)
//                }
//            }
//        } label: {
//            VStack(alignment: .leading) {
//                Text(AttributedString(completion.highlightedTitleStringForDisplay))
//                    .font(.caption2)
//                    .foregroundStyle(.gray)
//                
//                Text(AttributedString(completion.truncatedHighlightedSubtitleStringForDisplay))
//                    .font(.caption2)
//                    .foregroundStyle(.gray)
//            }
//        }
//        #if os(iOS)
//        .padding(8)
//        .background(Capsule().foregroundStyle(.thickMaterial))
//        #else
//        .buttonStyle(.roundMacButton(horizontalPadding: 10))
//        #endif
//    }
//    
    
    var fileSection: some View {
        Section("Photos & Documents") {
            if showExpensiveViews {
                StandardFileSection(
                    files: $trans.files,
                    fileUploadCompletedDelegate: calModel,
                    parentType: .transaction,
                    showCamera: $showCamera,
                    showPhotosPicker: $showPhotosPicker
                )
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .frame(height: (250 / 3))
                    .tint(.none)
            }
        }
    }
    
    
    var christmasListGiftStatusPicker: some View {
        Picker("", selection: $trans.christmasListStatus.animation()) {
            ForEach(GiftStatus.allCases) {
                Text($0.prettyValue)
                    .tag($0)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
    }
    
    
    var reminderRow: some View {
        Section {
            ReminderPicker(notificationOffset: $trans.notificationOffset)
        } footer: {
            Text("Alerts will be sent out at 9:00 AM")
                .foregroundStyle(.gray)
                .font(.caption)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 6)
        }
    }
    
    
    #if os(macOS)
    struct MacSheetHeaderView<MoreMenu: View, DeleteButton: View>: View {
        @Environment(\.dismiss) var dismiss
        @Environment(CalendarModel.self) private var calModel
            
        var title: String
        @Bindable var trans: CBTransaction
        var validateBeforeClosing: () -> ()
        @ViewBuilder var moreMenu: MoreMenu
        @ViewBuilder var deleteButton: DeleteButton
        
        var linkedLingo: String? {
            if trans.relatedTransactionType == .transaction {
                return "(Linked to transaction)"
            } else {
                return "(Linked to event)"
            }        
        }
        
        var body: some View {
            SheetHeader(
                title: title,
                //subtitle: trans.relatedTransactionID == nil ? nil : linkedLingo,
                close: { validateBeforeClosing() },
                view1: { moreMenu },
                view3: { deleteButton }
            )
        }
    }
    #endif
    

        
    
    // MARK: - Functions
    func prepareTransactionForEditing(isTemp: Bool) {
        print("-- \(#function)")
        /// Clear undo history.
        UndodoManager.shared.clearHistory()
        UndodoManager.shared.commitChange(trans: trans)
        Task {
            LocationManager.shared.requestLocation()
        }
        
        //calModel.hilightTrans = nil
            
        /// Determine the title button color.
        titleColorButtonHoverColor = trans.color == .primary ? .gray : trans.color
        
        /// Set the transaction date to the date of the passed in day.
        if trans.date == nil && !(trans.isSmartTransaction ?? false) {
            trans.date = day.date!
        }
                
//        let setCode = AppState.shared.country.currencyCode
//        let methCode = trans.payMethod?.country?.currencyCode
//        let cuntCode = trans.country?.currencyCode
//        
//        if methCode != cuntCode || methCode != setCode  {
//            trans.requiresConversion = true
//        }
        
        //trans.requiresConversion = true
        
        /// Format the currency amount.
        if trans.action != .add /*&& trans.tempAction != .add */{
            
            
            //trans.amountString = trans.amount.currencyWithDecimals(currencyCode: trans.country?.currencyCode)
            
            /// Use the original amount in the textfield for editing.
//            if let code = trans.country?.currencyCode,
//               let ogAmount = trans.originalUnconvertedAmount {
//                trans.amountString = ogAmount.currencyWithDecimals(currencyCode: code)
////                trans.amountString = CurrencyHelpers.formatAmountText(
////                    amount: ogAmount,
////                    currencyCode: code
////                )
//                
//                //trans.requiresConversion = true
//            } else {
//                trans.amountString = trans.amount.currencyWithDecimals()
//            }
            
            trans.amountString = trans.amount.currencyWithDecimals()
            
            
//            if let code = trans.country?.currencyCode {
//                trans.amountString = trans.amount.currencyWithDecimals(currencyCode: code)
//            } else {
//                trans.amountString = trans.amount.currencyWithDecimals()
//            }
            
        }
        
        /// Set a reference to the transactions ID so photos know where to go.
//        if let intId = Int(trans.serverID) {
//            FileModel.shared.fileParent = FileParent(id: trans.serverID, type: .transaction)
//        } else {
//            FileModel.shared.fileParent = FileParent(id: trans.uuid == nil ? trans.serverID : trans.id, type: .transaction)
//        }
        
        
        FileModel.shared.fileParent = FileParent(id: trans.uuid == nil ? trans.serverID : trans.id, type: .transaction)
        
        
        

        /// If the transaction is new.
        if trans.action == .add && !isTemp {
            trans.amountString = ""
            trans.country = Countries.homeCountry
            
            /// Set the dummy nil category to the trans so it's not a real nil.
            trans.category = catModel.getNil()
            
            
            if calModel.sPayMethod?.accountType == .unifiedChecking || calModel.sPayMethod?.accountType == .unifiedCredit {
                trans.payMethod = payModel.getEditingDefault()
                
            } else if let meth = calModel.sPayMethod, !meth.isUnified {
                /// Add the selected viewing payment method to the transaction. (But only if it's not unified.)
                trans.payMethod = meth
            } else {
                trans.payMethod = payModel.getEditingDefault()
            }
            
            if transLocation == .tagBudgetList, let tag = self.tag {
                trans.tags.append(tag)
            }
            
//            /// If the unified editing payment method is set, use it.
//            if calModel.sPayMethod?.accountType == .unifiedChecking && payModel.editingDefaultAccountType == .checking {
//                trans.payMethod = payModel.getEditingDefault()
//            
//            /// If the unified editing payment method is set, use it.
//            } else if calModel.sPayMethod?.accountType == .unifiedCredit && [.credit, .loan].contains(payModel.editingDefaultAccountType) {
//                trans.payMethod = payModel.getEditingDefault()
//                
//            } else if let meth = calModel.sPayMethod, !meth.isUnified {
//                /// Add the selected viewing payment method to the transaction. (But only if it's not unified.)
//                trans.payMethod = calModel.sPayMethod
//            }
                        
            #if os(iOS)
            Task {
                /// Wait a split second before adding to the day so we don't see it happen.
                try await Task.sleep(for: .seconds(0.5))
                /// Pre-add the transaction to the day so we can add photos to it before saving. Get's removed on cancel if title and payment method are blank.
                //day.upsert(trans)
                
                
                switch transLocation {
                case .normalList:       day.upsert(trans)
                case .tempList:         break /// Handled above store.tempTransactions.append(trans)
                case .tagBudgetList:    store.tagBudgetTransactions.append(trans)
                case .searchResultList,
                     .smartList,
                     .receiptsList,
                     .dashboardList:    break /// Can't manually add a transaction via those pages.
                }
                
                
            }
            #else
            /// Pre-add the transaction to the day so we can add photos to it before saving. Get's removed on cancel if title and payment method are blank.
            day.upsert(trans)
            #endif
            
            
        } else if trans.tempAction == .add && isTemp {
            /// Set the dummy nil category to the trans so it's not a real nil.
            trans.category = catModel.getNil()
            
            store.tempTransactions.append(trans)
            trans.amountString = ""
            trans.payMethod = payModel.getEditingDefault()
            trans.action = .add
        }
        
        /// Copy it so we can compare for smart saving.
        trans.deepCopy(.create)
                
        #if os(macOS)
        /// Focus on the title textfield.
        focusedField = 0
        #else
        if (trans.action == .add && !isTemp) || (trans.tempAction == .add && isTemp) {
            Task {
                /// Wait a split second so the view isn't clunky.
                //try? await Task.sleep(nanoseconds: UInt64(0.5 * Double(NSEC_PER_SEC)))
                try? await Task.sleep(for: .seconds(0.5))
                focusedField = 0
            }
        }
        #endif
        
        #warning("WARNING!")
        //checkIfTransactionIsValidToSave()
        
        
        /// Remove the date from the deepCopy if editing from a smart transaction that has a date as a problem.
        /// Today's date gets assigned by default when the trans date is nil, so if the date is the only issue, the save function won't see the trans as being valid to save.
        /// By removing the date from the deepCopy, it causes the trans and it's deep copy to fail the equatble check, which will make the app save the transaction.
//        if (trans.isSmartTransaction ?? false) && (trans.smartTransactionIssue?.enumID == .missingDate || trans.smartTransactionIssue?.enumID == .missingPaymentMethodAndDate)  {
//            trans.deepCopy?.date = nil
//        }
        
        /// Protect the transaction from being updated via scene changes if it is open.
        /// Ignore this transaction if it's open and you're coming back to the app from another app (ie if bouncing back and forth between this app and a banking app).
        //calModel.transEditID = transEditID
        
        /// These are just to control the animations in the options sheet. The are here so we don't see the option sheet "set up its state" when the view appears.
        if !trans.factorInCalculations { showHiddenEye = true }
        if trans.notifyOnDueDate { showBadgeBell = true }
        determineIfShouldSuggestAddingNewRule()
    }
    
    
    func handleUndoRedo(new: UndoTransactionSnapshot?) {
        if let new = new {
            trans.title = new.title ?? ""
            trans.amountString = new.amount ?? ""
            trans.payMethod = payModel.paymentMethods.filter { $0.id == new.payMethodID }.first
            trans.category = catModel.categories.filter { $0.id == new.categoryID }.first
            trans.date = new.date?.toDateObj(from: .serverDate)
            trans.trackingNumber = new.trackingNumber ?? ""
            trans.orderNumber = new.orderNumber ?? ""
            trans.url = new.url ?? ""
            trans.notes = new.notes ?? ""
            /// Block the onChanges from running when undo or redo is invoked.
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                UndodoManager.shared.returnMe = nil
            })
        }
    }
    
    
    func handleWarmUpAndExpensiveViews() {
        // MARK: - Technique 1 - View warmed up in splash screen
        if shouldWarmUpTransactionViewDuringSplash {
            if isWarmUp {
                /// Run this in dispatch queue since the inital render is expensive.
                /// Subsequent renders should appear seamless.
                DispatchQueue.main.async {
                    showContent = true
                    showExpensiveViews = true
                }
            } else {
                showContent = true
                //DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                DispatchQueue.main.async {
                    showExpensiveViews = true
                }
            }
        }
        
        // MARK: - Technique 2 - view warmed up on first appearance.
        else {
            if calModel.transactionViewHasBeenWarmedUp {
                showContent = true
                //DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                DispatchQueue.main.async {
                    showExpensiveViews = true
                }
            } else {
                /// Run this in dispatch queue since the inital render is expensive.
                /// Subsequent renders should appear seamless.
                DispatchQueue.main.async {
                    showContent = true
                    showExpensiveViews = true
                    calModel.transactionViewHasBeenWarmedUp = true
                }
            }
        }
    }
    
    
    func determineIfShouldSuggestAddingNewRule() {
        
        guard keyModel.keywords.filter({ $0.isIgnoredSuggestion && $0.keyword == trans.title && $0.category?.id == trans.category?.id }).isEmpty else { return }
        
        let existingCount = calModel.justTransactions
            .filter {
                $0.title.localizedCaseInsensitiveContains(trans.title)
                && $0.category?.id == trans.category?.id
            }
            .count
        
        let comboExists = existingCount >= 3 && !trans.wasAddedFromPopulate
        
        let ruleDoesNotExist = keyModel
            .keywords
            .filter {
                $0.keyword.localizedCaseInsensitiveContains(trans.title)
                && $0.category?.id == trans.category?.id
                && !$0.isIgnoredSuggestion
            }
            .isEmpty
        
        if comboExists && ruleDoesNotExist {
            self.existingRuleCount = existingCount
            shouldSuggestAddingNewRule = true
        }
    }
}




