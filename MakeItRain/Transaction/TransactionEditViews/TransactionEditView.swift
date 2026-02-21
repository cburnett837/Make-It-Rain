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

enum TransNavDestination: Hashable {
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
    
    @Bindable var trans: CBTransaction
    //@Binding var transEditID: String?
    @Bindable var day: CBDay
    
    var isTemp: Bool
    var transLocation: WhereToLookForTransaction = .normalList
    var isWarmUp = false
    let symbolWidth: CGFloat = 26
        
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
    //@State private var selection = AttributedTextSelection()
    //@State private var textCommands = TextViewCommands()


        
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
            return "Transferred from"
        } else {
            return trans.isOrigin ? "Pay-To" : "Pay-From"
        }
    }
    
    
    var paymentMethodMissing: Bool {
        return !trans.title.isEmpty && !trans.amountString.isEmpty && trans.payMethod == nil
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
                .navigationDestination(for: TransNavDestination.self) { determineNavDest(for: $0) }
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
        /// Handle undo and redo.
        .onChange(of: focusedField) {
            if $1 != nil {
                if trans.action == .add && blockUndoCommitOnLoad {
                    blockUndoCommitOnLoad = false
                } else {
                    UndodoManager.shared.changeTask?.cancel()
                    UndodoManager.shared.commitChange(trans: trans)
                }
            }
        }
        #endif
    }
    
    

    @State private var shouldSuggestAddingNewRule = false
    @State private var existingRuleCount: Int = 0
    
    @ViewBuilder
    func content(_ scrollProxy: ScrollViewProxy) -> some View {
        Section {
            TevTitle(
                trans: trans,
                mapModel: mapModel,
                suggestedCategories: $suggestedCategories,
                focusedField: $focusedField
            )
            
            TevAmount(
                trans: trans,
                focusedField: $focusedField
            )
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
            mapSection
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
                TevHashtags(trans: trans)
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
    }
    
    
    
    
    // MARK: - SubViews
    
    @ViewBuilder
    func determineNavDest(for dest: TransNavDestination) -> some View {
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
            TagView(trans: trans)
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
    
    
    var topThreeMeths: Array<CBPaymentMethod>.SubSequence {
        payModel.paymentMethods.sorted { $0.recentTransactionCount > $1.recentTransactionCount }.prefix(3)
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
                if let relatedID = trans.relatedTransactionID, let method = calModel.getTransaction(by: relatedID).payMethod {
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
    
    
    @State private var showUseCurrentLocationButton = true
    var mapSection: some View {
        Section {
            if showExpensiveViews {
                StandardMiniMap(
                    locations: $trans.locations,
                    parent: trans,
                    parentID: trans.id,
                    parentType: XrefEnum.transaction,
                    addCurrentLocation: false
                )
                .listRowInsets(EdgeInsets())
                .overlay {
                    if trans.action == .add && showUseCurrentLocationButton {
                        VStack {
                            Button {
                                mapModel.completions.removeAll()
                                Task {
                                    if let location = await mapModel.saveCurrentLocation(parentID: trans.id, parentType: XrefEnum.transaction) {
                                        trans.upsert(location)
                                    }
                                }
                                showUseCurrentLocationButton = false
                            } label: {
                                Image(systemName: "heart")
//                                ZStack {
//                                    Image(systemName: "heart")
//                                        .font(.title)
//                                    Image(systemName: "location.fill")
//                                        .font(.caption2)
//                                }
                            }
                            .clipShape(.circle)
                            #if os(iOS)
                            .buttonStyle(.glass)
                            #endif
                            
//                            Button("Use Current") {
//                                
//                            }
//                            .buttonStyle(.glass)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                        .padding(.bottom, 5)
                        .padding(.trailing, 5)
                        
                    }
                }
            } else {
                ProgressView()
                    .listRowInsets(EdgeInsets())
                    .frame(maxWidth: .infinity)
                    .frame(height: 150)
                    .tint(.none)
            }
        }
    }
    
    
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
            if trans.relatedTransactionType == XrefModel.getItem(from: .relatedTransactionType, byEnumID: .transaction) {
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
        
        //calModel.hilightTrans = nil
            
        /// Determine the title button color.
        titleColorButtonHoverColor = trans.color == .primary ? .gray : trans.color
        
        /// Set the transaction date to the date of the passed in day.
        if trans.date == nil && !(trans.isSmartTransaction ?? false) {
            trans.date = day.date!
        }
                
        /// Format the dollar amount.
        if trans.action != .add && trans.tempAction != .add {
            trans.amountString = trans.amount.currencyWithDecimals()
        }
                
        /// Set a reference to the transactions ID so photos know where to go.
        FileModel.shared.fileParent = FileParent(id: trans.id, type: XrefModel.getItem(from: .fileTypes, byEnumID: .transaction))

        /// If the transaction is new.
        if trans.action == .add && !isTemp {
            trans.amountString = ""
            
            /// Set the dummy nil category to the trans so it's not a real nil.
            trans.category = catModel.getNil()
            
            
            if calModel.sPayMethod?.accountType == .unifiedChecking || calModel.sPayMethod?.accountType == .unifiedCredit {
                trans.payMethod = payModel.getEditingDefault()
                
            } else if let meth = calModel.sPayMethod, !meth.isUnified {
                /// Add the selected viewing payment method to the transaction. (But only if it's not unified.)
                trans.payMethod = calModel.sPayMethod
            } else {
                trans.payMethod = payModel.getEditingDefault()
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
                day.upsert(trans)
            }
            #else
            /// Pre-add the transaction to the day so we can add photos to it before saving. Get's removed on cancel if title and payment method are blank.
            day.upsert(trans)
            #endif
            
            
        } else if trans.tempAction == .add && isTemp {
            /// Set the dummy nil category to the trans so it's not a real nil.
            trans.category = catModel.getNil()
            
            calModel.tempTransactions.append(trans)
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
                && $0.category?.id == trans.category!.id
            }
            .count
        
        let comboExists = existingCount >= 3 && !trans.wasAddedFromPopulate
        
        let ruleDoesNotExist = keyModel
            .keywords
            .filter {
                $0.keyword.localizedCaseInsensitiveContains(trans.title)
                && $0.category?.id == trans.category!.id
                && !$0.isIgnoredSuggestion
            }
            .isEmpty
        
        if comboExists && ruleDoesNotExist {
            self.existingRuleCount = existingCount
            shouldSuggestAddingNewRule = true
        }
    }
}




