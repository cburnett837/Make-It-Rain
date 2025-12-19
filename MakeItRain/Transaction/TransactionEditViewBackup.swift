////
////  EditTransactionView.swift
////  MakeItRain
////
////  Created by Cody Burnett on 9/19/24.
////
//
//import SwiftUI
//import PhotosUI
//import SafariServices
//import TipKit
//import MapKit
//
//fileprivate let photoWidth: CGFloat = 125
//fileprivate let photoHeight: CGFloat = 200
//
//enum TitleSuggestionType: String {
//    case location, history
//}
//
//enum TransNavDestination: Hashable {
//    case options, logs, titleColorMenu
//}
//
//struct TransactionEditView: View {
//    @Local(\.lineItemIndicator) var lineItemIndicator
//    @Local(\.useWholeNumbers) var useWholeNumbers
//    
//    @AppStorage("transactionTitleSuggestionType") var transactionTitleSuggestionType: TitleSuggestionType = .location
//    //@Environment(\.fontResolutionContext) var fontResolutionContext
//
//    //@Environment(\.colorScheme) var colorScheme
//    @Environment(\.dismiss) var dismiss // <--- NO NICE THAT ONE WITH SHEETS IN A SHEET. BEWARE!.
//    #if os(macOS)
//    @Environment(\.openURL) var openURL
//    #endif
//    @Environment(CalendarModel.self) private var calModel
//    @Environment(PayMethodModel.self) private var payModel
//    @Environment(CategoryModel.self) private var catModel
//    @Environment(KeywordModel.self) private var keyModel
//    
//    @Bindable var trans: CBTransaction
//    @Binding var transEditID: String?
//    @Bindable var day: CBDay
//    
//    var isTemp: Bool
//    var transLocation: WhereToLookForTransaction = .normalList
//    var isWarmUp = false
//    let symbolWidth: CGFloat = 26
//        
//    @FocusState private var focusedField: Int?
//    @State private var mapModel = MapModel()
//    @State private var titleColorButtonHoverColor: Color = .gray
//    @State private var payMethodMenuColor: Color = Color(.tertiarySystemFill)
//    @State private var categoryMenuColor: Color = Color(.tertiarySystemFill)
//    @State private var showLogSheet = false
//    @State private var showTagSheet = false
//    @State private var showPayMethodSheet = false
//    @State private var showCategorySheet = false
//    @State private var showPaymentMethodChangeAlert = false
//    @State private var showDeleteAlert = false
//    @State private var blockUndoCommitOnLoad = true
//    @State private var blockKeywordChangeWhenViewLoads = true
//    @State private var blockSuggestionsFromPopulating = false
//    @State private var showTrackingOrderAndUrlFields = false
//    @State private var showCamera: Bool = false
//    @State private var showPhotosPicker: Bool = false
//    @State private var showTopTitles: Bool = false
//    @State private var showSplitSheet = false
//    @State private var titleChangedTask: Task<Void, Error>?
//    @State private var amountChangedTask: Task<Void, Error>?
//    @State private var showUndoRedoAlert = false
//    @State private var suggestedTitles: Array<CBSuggestedTitle> = []
//    @State private var navPath = NavigationPath()
//    @State private var isValidToSave = false
//    @State private var hasAnimatedBrain = false
//    /// These are just to control the animations in the options sheet. The are here so we don't see the option sheet "set up its state" when the view appears.
//    @State private var showBadgeBell = false
//    @State private var showHiddenEye = false
//    //@State private var selection = AttributedTextSelection()
//    //@State private var textCommands = TextViewCommands()
//
//
//        
//    let changeTransactionTitleColorTip = ChangeTransactionTitleColorTip()
//    
//    var title: String { trans.action == .add ? "New \(transTypeLingo)" : "Edit \(transTypeLingo)" }
//    
//    var transTypeLingo: String {
//        if trans.payMethod?.accountType == .credit || trans.payMethod?.accountType == .loan {
//            trans.amountString.contains("-")
//            ? "Payment"
//            : trans.christmasListGiftID != nil ? "Gift" : "Expense"
//        } else {
//            trans.amountString.contains("-")
//            ? trans.christmasListGiftID != nil ? "Gift" : "Expense"
//            : "Income"
//        }
//    }
//    
//    var linkedLingo: String? {
//        if trans.relatedTransactionID != nil {
////            if trans.relatedTransactionType == XrefModel.getItem(from: .relatedTransactionType, byEnumID: .transaction) {
////                return "(This transaction is linked to another)"
////            } else {
////                return "(This transaction is linked to an event)"
////            }
////
//            return "(Linked)"
//        } else if trans.christmasListGiftID != nil {
//            return "(Linked 🎄)"
//        } else {
//            return nil
//        }
//    }
//    
//    var paymentMethodMissing: Bool {
//        return !trans.title.isEmpty && !trans.amountString.isEmpty && trans.payMethod == nil
//    }
//        
//    var undoRedoValuesChanged: Int {
//        var hasher = Hasher()
//        hasher.combine(trans.title)
//        hasher.combine(trans.amountString)
//        hasher.combine(trans.payMethod)
//        hasher.combine(trans.category)
//        hasher.combine(trans.trackingNumber)
//        hasher.combine(trans.orderNumber)
//        hasher.combine(trans.url)
//        hasher.combine(trans.notes)
//        hasher.combine(trans.date)
//        return hasher.finalize()
//    }
//        
//    var transactionValuesChanged: Int {
//        var hasher = Hasher()
//        hasher.combine(trans.factorInCalculations)
//        hasher.combine(trans.notificationOffset)
//        hasher.combine(trans.notifyOnDueDate)
//        hasher.combine(trans.title)
//        hasher.combine(trans.amountString)
//        hasher.combine(trans.payMethod)
//        hasher.combine(trans.category)
//        hasher.combine(trans.date)
//        hasher.combine(trans.locations)
//        hasher.combine(trans.trackingNumber)
//        hasher.combine(trans.orderNumber)
//        hasher.combine(trans.url)
//        hasher.combine(trans.tags)
//        hasher.combine(trans.notes)
//        hasher.combine(trans.color.hashValue)
//        return hasher.finalize()
//    }
//    
//    var shouldShowSuggestions: Bool {
//        if (showTopTitles && !(trans.category?.topTitles ?? []).isEmpty) {
//            return true
//        } else {
//            switch transactionTitleSuggestionType {
//            case .location:
//                return !mapModel.completions.isEmpty
//            case .history:
//                return !suggestedTitles.isEmpty
//            }
//        }
//        //return false
//    }
//    
//    var disableInteractiveDismiss: Bool {
//        paymentMethodMissing || !navPath.isEmpty
//    }
//    
////    var isValidToSave: Bool {
////        if trans.title.isEmpty { return false }
////        if trans.payMethod == nil { return false }
////        if trans.date == nil && (trans.isSmartTransaction ?? false) { return false }
////        if !trans.hasChanges() { return false }
////        return true
////    }
//
//    
////    var header: some View {
////        Group {
////            SheetHeaderView(
////                title: title,
////                trans: trans,
////                transEditID: $transEditID,
////                focusedField: $focusedField,
////                showDeleteAlert: $showDeleteAlert
////            )
////            .padding()
////
////            Divider()
////                .padding(.horizontal)
////        }
////    }
//    
//    
//    @State private var showExpensiveSections = false
//
//    
//    
//    var body: some View {
//        //let _ = Self._printChanges()
//        @Bindable var calModel = calModel
//        @Bindable var payModel = payModel
//        @Bindable var catModel = catModel
//        @Bindable var keyModel = keyModel
//        @Bindable var appState = AppState.shared
//        
//        Group {
//            #if os(iOS)
//            NavigationStack(path: $navPath) {
//                //if showExpensiveSections {
//                    ScrollViewReader { scrollProxy in
//                        StandardContainerWithToolbar(.list) {
//                            content(scrollProxy)
//                        }
//                    }
//                    
//                    
//                    .if(trans.christmasListGiftID != nil) {
//                        $0
//                            .scrollContentBackground(.hidden)
//                            .background(SnowyBackground(blurred: false, withSnow: true))
//                    }
//                    .navigationTitle(title)
//                    .if(trans.relatedTransactionID != nil || trans.christmasListGiftID != nil) { $0.navigationSubtitle(linkedLingo!) }
//                    .navigationBarTitleDisplayMode(.inline)
//                    .toolbar { toolbar }
//                    .navigationDestination(for: TransNavDestination.self) { dest in
//                        switch dest {
//                        case .options:
//                            TransactionEditViewMoreOptions(
//                                trans: trans,
//                                showSplitSheet: $showSplitSheet,
//                                isTemp: isTemp,
//                                navPath: $navPath,
//                                showBadgeBell: $showBadgeBell,
//                                showHiddenEye: $showHiddenEye
//                            )
//                            
//                        case .logs:
//                            LogSheet(title: trans.title, itemID: trans.id, logType: .transaction)
//                            
//                        case .titleColorMenu:
//                            TitleColorList(trans: trans, saveOnChange: false, navPath: $navPath)
//                        }
//                    }
//                //}
//            }
//            #else
//            StandardContainer(.list) {
//                content
//            } header: {
//                MacSheetHeaderView(title: title, trans: trans, validateBeforeClosing: validateBeforeClosing, moreMenu: {
//                    moreMenu
//                }, deleteButton: {
//                    deleteButton
//                })
//            }
//            .navigationTitle(title)
//            #endif
//        }
//        
//        //.onDisappear { transEditID = nil }
//        .interactiveDismissDisabled(disableInteractiveDismiss)
//        .task {
//            if !isWarmUp {
//                prepareTransactionForEditing(isTemp: isTemp)
//                ChangeTransactionTitleColorTip.didOpenTransaction.sendDonation()
//            }
//            
//        }
//        .alert("Please change the selected account by right-clicking on the line item from the main view.", isPresented: $showPaymentMethodChangeAlert) {
//            Button("OK") {}
//        }
//        .sheet(isPresented: $showSplitSheet) {
//            TransactionSplitSheet(trans: trans, showSplitSheet: $showSplitSheet)
//        }
//        .environment(mapModel)
//        /// Check what color the save button should be.
//        .onChange(of: transactionValuesChanged) { checkIfTransactionIsValidToSave() }
//                                
//        #if os(iOS)
//        /// Prompt for undo/redo on shake.
//        .onShake {
//            UndodoManager.shared.getChangeFields(trans: trans)
//            UndodoManager.shared.showAlert = true
//        }
//        /// Handle undo and redo.
//        .onChange(of: undoRedoValuesChanged) { UndodoManager.shared.processChange(trans: trans) }
//        /// Handle undo and redo.
//        .onChange(of: UndodoManager.shared.returnMe) {
//            if let new = $1 {
//                trans.title = new.title ?? ""
//                trans.amountString = new.amount ?? ""
//                trans.payMethod = payModel.paymentMethods.filter { $0.id == new.payMethodID }.first
//                trans.category = catModel.categories.filter { $0.id == new.categoryID }.first
//                trans.date = new.date?.toDateObj(from: .serverDate)
//                trans.trackingNumber = new.trackingNumber ?? ""
//                trans.orderNumber = new.orderNumber ?? ""
//                trans.url = new.url ?? ""
//                trans.notes = new.notes ?? ""
//                /// Block the onChanges from running when undo or redo is invoked.
//                DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
//                    UndodoManager.shared.returnMe = nil
//                })
//            }
//        }
//        /// Handle undo and redo.
//        .onChange(of: focusedField) {
//            if $1 != nil {
//                if trans.action == .add && blockUndoCommitOnLoad {
//                    blockUndoCommitOnLoad = false
//                } else {
//                    UndodoManager.shared.changeTask?.cancel()
//                    UndodoManager.shared.commitChange(trans: trans)
//                }
//            }
//            
//            /// For titles.
//            /// Clear map suggestions when unfocusing from the title field.
//            if $0 == 1 && $1 != 1 {
//                //withAnimation {
//                suggestedTitles.removeAll()
//                mapModel.completions.removeAll()
//                //}
//            }
//        }
//        #endif
//        .onAppear {
//            /// Run this in dispatch queue since the inital render is expensive.
//            /// Subsequent renders should appear seamless.
//            DispatchQueue.main.async {
//                showExpensiveSections = true
//            }
//        }
//        
//    }
//    
//    @ToolbarContentBuilder
//    var toolbar: some ToolbarContent {
//        ToolbarItem(placement: .topBarLeading) { deleteButton }
//        ToolbarSpacer(.fixed, placement: .topBarLeading)
//        ToolbarItem(placement: .topBarLeading) {
//            moreMenu
//                .if(trans.notifyOnDueDate) {
//                    $0.badge(Text(""))
//                }
//        }
//        ToolbarItem(placement: .topBarTrailing) {
//            AnimatedCloseButton(isValidToSave: isValidToSave, closeButton: closeButton)
//        }
//        
//        ToolbarItem(placement: .bottomBar) {
//            NavigationLink(value: TransNavDestination.logs) {
//                EnteredByAndUpdatedByView(
//                    enteredBy: trans.enteredBy,
//                    updatedBy: trans.updatedBy,
//                    enteredDate: trans.enteredDate,
//                    updatedDate: trans.updatedDate
//                )
//            }
//        }
//    }
//
//    @ViewBuilder
//    func content(_ scrollProxy: ScrollViewProxy) -> some View {
//        //Text(trans.id)
//        Section {
//            titleRow
//            TransactionAmountRow(amountTypeLingo: trans.amountTypeLingo, amountString: $trans.amountString) {
//                amountRow
//            }
//            .overlay {
//                Color.red
//                    .frame(height: 2)
//                    .opacity(trans.factorInCalculations ? 0 : 1)
//            }
//        }
//        
//        Section {
//            PayMethodSheetButtonPhone(
//                text: "Account",
//                logoFallBackType: .customImage(.init(
//                    name: trans.payMethod?.fallbackImage,
//                    color: trans.payMethod?.color
//                )),
//                payMethod: $trans.payMethod,
//                whichPaymentMethods: .allExceptUnified
//            )
//            
//            CategorySheetButtonPhone(category: $trans.category)
//        }
//        
//        ruleSuggestionButton
//        
//        Section {
//            datePickerRow
//                .listRowInsets(EdgeInsets())
//                .padding(.horizontal, 16)
//            
//            if (trans.isSmartTransaction ?? false) &&
//                (trans.smartTransactionIssue?.enumID == .missingDate
//                 || trans.smartTransactionIssue?.enumID == .missingPaymentMethodAndDate
//                 || trans.smartTransactionIssue?.enumID == .funkyDate)
//                && !(trans.smartTransactionIsAcknowledged ?? true) {
//                
//                dateFixerRow
//                    .listRowInsets(EdgeInsets())
//                    .padding(.horizontal, 16)
//            }
//        }
//        
//        if !isTemp {
//            Section {
//                StandardMiniMap(
//                    locations: $trans.locations,
//                    parent: trans,
//                    parentID: trans.id,
//                    parentType: XrefEnum.transaction,
//                    addCurrentLocation: false
//                )
//                .listRowInsets(EdgeInsets())
//            }
//        }
//        
//        trackingAndOrderRow
//        
//        if !isTemp {
//            hashtagsRow
//        }
//        
//        if !isTemp {
//            Section("Photos & Documents") {
//                StandardFileSection(
//                    files: $trans.files,
//                    fileUploadCompletedDelegate: calModel,
//                    parentType: .transaction,
//                    showCamera: $showCamera,
//                    showPhotosPicker: $showPhotosPicker
//                )
//            }
//        }
//        StandardUITextEditor(text: $trans.notes, focusedField: _focusedField, focusID: 2, scrollProxy: scrollProxy)
////        StandardNoteTextEditor(notes: $trans.notes, symbolWidth: symbolWidth, focusedField: _focusedField, focusID: showTrackingOrderAndUrlFields ? 5 : 2, showSymbol: true)
////                    .id(showTrackingOrderAndUrlFields ? 5 : 2)
//    }
//    
//    
//    // MARK: - SubViews
//    
//    
//    @ViewBuilder
//    var categoryTitleSuggestions: some View {
//        let titleSuggestions = trans.category?.topTitles ?? []
//        ScrollView(.horizontal) {
//            HStack {
//                ForEach(titleSuggestions, id: \.self) { title in
//                    Button {
//                        trans.title = title.capitalized
//                        showTopTitles = false
//                    } label: {
//                        Text("\(title.capitalized)?")
//                        .foregroundStyle(.gray)
//                        .font(.subheadline)
//                    }
//                    .padding(8)
//                    .background(Capsule().foregroundStyle(.thickMaterial))
//                }
//            }
//        }
//        .scrollIndicators(.hidden)
//        .contentMargins(.vertical, 5, for: .scrollContent)
//    }
//    
//        
//    @ViewBuilder
//    var historyTitleSuggestions: some View {
//        ScrollView(.horizontal) {
//            HStack {
//                ForEach(suggestedTitles.sorted { $0.transactionCount > $1.transactionCount }.prefix(3), id: \.id) { opt in
//                    Button {
//                        blockSuggestionsFromPopulating = true
//                        trans.title = opt.title.capitalized
//                        showTopTitles = false
//                        suggestedTitles.removeAll()
//                    } label: {
//                        Text("\(opt.title.capitalized)?")
//                        .foregroundStyle(.gray)
//                        .font(.subheadline)
//                    }
//                    .padding(8)
//                    .background(Capsule().foregroundStyle(.thickMaterial))
//                }
//            }
//        }
//        .scrollIndicators(.hidden)
//        //.contentMargins(.vertical, 5, for: .scrollContent)
//    }
//    
//    @State private var isHilighting = false
//    @State private var hideHilight = false
//    @ViewBuilder private func smartIndicatorView() -> some View {
//        
//        ZStack {
//            let shape = Capsule()
//            shape
//                .stroke(
//                    //Color.theme.gradient,
//                    AngularGradient(gradient: Gradient(colors: [.red, .yellow, .green, .blue, .purple, .red]), center: .center),
//                    style: .init(lineWidth: 2, lineCap: .round, lineJoin: .round)
//                )
//                .mask {
//                    let clearColors: [Color] = Array(repeating: .clear, count: 4)
//                    shape
//                        .fill(AngularGradient(
//                            colors: clearColors + [.red, .yellow, .green, .blue, .purple, .red] + clearColors,
//                            center: .center,
//                            angle: .init(degrees: isHilighting ? 360 : 0)
//                        ))
//                        .opacity(hideHilight ? 0 : 1)
//                }
//                .padding(-2)
//                .blur(radius: 0)
//                .onAppear {
//                    withAnimation(.linear(duration: 2).repeatCount(1, autoreverses: false)) {
//                        isHilighting = true
//                    }
//                    
//                    // fade out starting 1.5s into the final spin (slightly before the end)
//                    let totalDuration = 2.0 // 2s per spin * 1 repeats
//                    let fadeDuration = 1.0
//                    let fadeStart = totalDuration - fadeDuration
//                    
//                    DispatchQueue.main.asyncAfter(deadline: .now() + fadeStart) {
//                        withAnimation(.easeOut(duration: fadeDuration)) {
//                            hideHilight = true
//                        }
//                    }
//                }
//                .onDisappear {
//                    isHilighting = false
//                    hideHilight = false
//                }
//        }
//    }
//    
//    
//    
//    var mapLocationSuggestions: some View {
//        HStack {
//            ScrollView(.horizontal) {
//                HStack {
//                    ForEach(mapModel.completions.prefix(3), id: \.self) { completion in
//                        Button {
//                            mapModel.blockCompletion = true
//                            trans.title = completion.title
//                            suggestedTitles.removeAll()
//                            Task {
//                                if let location = await mapModel.getMapItem(from: completion, parentID: trans.id, parentType: XrefEnum.transaction) {
//                                    trans.upsert(location)
//                                    mapModel.focusOnFirst(locations: trans.locations)
//                                }
//                            }
//                        } label: {
//                            VStack(alignment: .leading) {
//                                Text(AttributedString(completion.highlightedTitleStringForDisplay))
//                                    .font(.caption2)
//                                    .foregroundStyle(.gray)
//                                
//                                Text(AttributedString(completion.truncatedHighlightedSubtitleStringForDisplay))
//                                    .font(.caption2)
//                                    .foregroundStyle(.gray)
//                            }
//                        }
//                        .padding(8)
//                        .background(Capsule().foregroundStyle(.thickMaterial))
//                    }
//                    
//                    mapLocationCurrentButton
//                    mapLocationClearButton
//                }
//            }
//            .scrollIndicators(.hidden)
//            .contentMargins(.vertical, 5, for: .scrollContent)
//        }
//    }
//
//    
//    var mapLocationCurrentButton: some View {
//        Button {
//            //withAnimation {
//                mapModel.completions.removeAll()
//            //}
//            Task {
//                if let location = await mapModel.saveCurrentLocation(parentID: trans.id, parentType: XrefEnum.transaction) {
//                    trans.upsert(location)
//                }
//            }
//        } label: {
//            Image(systemName: "location.fill")
//        }
//        .padding(8)
//        .background(Capsule().foregroundStyle(.thickMaterial))
//        .focusable(false)
//        .bold(true)
//        .font(.subheadline)
//    }
//    
//    
//    var mapLocationClearButton: some View {
//        Button {
//            //withAnimation {
//                mapModel.completions.removeAll()
//            //}
//        } label: {
//            Image(systemName: "xmark")
//        }
//        .padding(8)
//        .background(Capsule().foregroundStyle(.thickMaterial))
//        .focusable(false)
//        .bold(true)
//        .font(.subheadline)
//    }
//    
//    
//    @ViewBuilder
//    var titleRow: some View {
//        VStack {
//            HStack(spacing: 0) {
//                Label {
//                    Text("")
//                } icon: {
//                    Image(systemName: "t.circle")
//                        .foregroundStyle(.gray)
//                }
//                
//                titleTextField
//            }
//            
//            suggestionsRow
//                .padding(.bottom, -7)
//        }
//    }
//    
//    
//    @ViewBuilder
//    var titleTextField: some View {
//        Group {
//            #if os(iOS)
//            UITextFieldWrapper(placeholder: "Title", text: $trans.title, onSubmit: {
//                focusedField = 1
//            }, toolbar: {
//                KeyboardToolbarView(focusedField: $focusedField, disableUp: true)
//            })
//            .uiTag(0)
//            .uiClearButtonMode(.whileEditing)
//            .uiStartCursorAtEnd(true)
//            .uiTextAlignment(.left)
//            .uiReturnKeyType(.next)
//            .uiTextColor(UIColor(trans.color))
//            #else
//            StandardTextField("Title", text: $trans.title, focusedField: $focusedField, focusValue: 0)
//                .onSubmit { focusedField = 1 }
//            #endif
//        }
//        .focused($focusedField, equals: 0)
//        .overlay {
//            Color.red
//                .frame(height: 2)
//                .opacity(trans.factorInCalculations ? 0 : 1)
//        }
//        
//        /// Suggest top titles associated with a category if the title has not yet been entered when the category is selected.
//        .onChange(of: trans.category) {
//            if let newValue = $1 {
//                if trans.action == .add && trans.title.isEmpty && !newValue.isNil {
//                    showTopTitles = true
//                }
//            }
//        }
//        .onChange(of: trans.title) {
//            let new = $1
//            
//            /// Handle search suggestions
//            if !showTopTitles {
//                mapModel.getAutoCompletions(for: new)
//            }
//            if !new.isEmpty {
//                showTopTitles = false
//            }
//            ///
//            
//            /// Suggest adding a new keyword for common titles that may not have one.
//            if new.isEmpty {
//                suggestedTitles.removeAll()
//                mapModel.completions.removeAll()
//            } else {
//                if !blockSuggestionsFromPopulating {
//                    suggestedTitles = calModel.suggestedTitles.filter {
//                        $0.title//.localizedCaseInsensitiveContains(new)
//                            .range(of: new, options: [.caseInsensitive, .diacriticInsensitive, .anchored]) != nil
//                    }//.prefix(3)
//                } else {
//                    blockSuggestionsFromPopulating = false
//                }
//            }
//            
//            if !blockKeywordChangeWhenViewLoads {
//                let upVal = new.uppercased()
//                
//                for key in keyModel.keywords {
//                    let upKey = key.keyword.uppercased()
//                    
//                    switch key.triggerType {
//                    case .equals:
//                        if upVal == upKey { trans.category = key.category }
//                    case .contains:
//                        if upVal.contains(upKey) { trans.category = key.category }
//                    }
//                }
//            } else {
//                blockKeywordChangeWhenViewLoads = false
//            }
//        }
//    }
//    
//        
//    @ViewBuilder
//    var suggestionsRow: some View {
//        if shouldShowSuggestions {
//            HStack(spacing: 0) {
//                Label {
//                    Text("")
//                } icon: {
//                    AiAnimatedAliveSymbol(symbol: "brain", withGlow: true)
//                    //AiAnimatedSwishSymbol(symbol: "brain", hasAnimated: $hasAnimatedBrain)
//                }
//                                    
//                VStack(alignment: .leading) {
//                    if showTopTitles && !(trans.category?.topTitles ?? []).isEmpty {
//                        categoryTitleSuggestions
//                    } else {
//                        switch transactionTitleSuggestionType {
//                        case .location:
//                            if !mapModel.completions.isEmpty {
//                                mapLocationSuggestions
//                            }
//                        case .history:
//                            if !suggestedTitles.isEmpty {
//                                historyTitleSuggestions
//                            }
//                        }
//                    }
//                }
//            }
//            .padding(.top, 7)
//        }
//    }
//    
//    
//    @ViewBuilder
//    var amountRow: some View {
//        HStack(spacing: 0) {
//            Label {
//                Text("")
//            } icon: {
//                Image(systemName: "dollarsign.circle")
//                    .foregroundStyle(.gray)
//            }
//            
//            Group {
//                #if os(iOS)
//                
//                UITextFieldWrapper(placeholder: "Amount", text: $trans.amountString, toolbar: {
//                    KeyboardToolbarView(
//                        focusedField: $focusedField,
//                        //disableUp: 0,
//                        disableDown: true,
////                        focusDownExtraFunction: {
////                           // withAnimation(.easeInOut(duration: 5)) {
////                                scrollProxy.scrollTo(showTrackingOrderAndUrlFields ? 5 : 2)
////                            //} completion: {
////                                //focusedField = showTrackingOrderAndUrlFields ? 5 : 2
////                            //}
////                        },
//                        accessoryImage3: "plus.forwardslash.minus",
//                        accessoryFunc3: {
//                            Helpers.plusMinus($trans.amountString)
//                        })
//                })
//                
////                UITextFieldWrapper(placeholder: "Amount", text: $trans.amountString, toolbar: {
////                    KeyboardToolbarView(
////                        focusedField: $focusedField,
////                        accessoryImage3: "plus.forwardslash.minus",
////                        accessoryFunc3: {
////                            Helpers.plusMinus($trans.amountString)
////                        })
////                })
//                .uiTag(1)
//                .uiClearButtonMode(.whileEditing)
//                .uiStartCursorAtEnd(true)
//                .uiTextAlignment(.left)
//                //.uiKeyboardType(.numpad)
//                .uiKeyboardType(.custom(.numpad))
//                //.uiKeyboardType(AppState.shared.isIpad ? .default : useWholeNumbers ? .numberPad : .decimalPad)
//                //.uiTextColor(.secondaryLabel)
//                //.uiFont(UIFont.systemFont(ofSize: 24.0))
//                #else
//                StandardTextField("Amount", text: $trans.amountString, focusedField: $focusedField, focusValue: 1)
//                #endif
//            }
//            .focused($focusedField, equals: 1)
//            .formatCurrencyLiveAndOnUnFocus(
//                focusValue: 1,
//                focusedField: focusedField,
//                amountString: trans.amountString,
//                amountStringBinding: $trans.amountString,
//                amount: trans.amount
//            )
//            .onChange(of: focusedField) { oldValue, newValue in
//                if newValue == 1 && trans.amountString.isEmpty && (trans.payMethod ?? CBPaymentMethod()).isDebit {
//                    trans.amountString = "-"
//                }
//                
//                
////                if newValue == 1 {
////                    Helpers.formatCurrency(
////                        focusValue: focusValue,
////                        oldFocus: oldValue,
////                        newFocus: newValue,
////                        amountString: amountStringBinding,
////                        amount: amount
////                    )
////                }
//            }
//            /// Keep the amount in sync with the payment method at the time the payment method was changed.
//            .onChange(of: trans.payMethod) { oldValue, newValue in
//                if let oldValue, let newValue {
//                    if (oldValue.isDebit && newValue.isCreditOrLoan) || (oldValue.isCreditOrLoan && newValue.isDebit) {
//                        Helpers.plusMinus($trans.amountString)
//                    }
//                }
//            }
//        }
//    }
//   
//    
//    @ViewBuilder
//    var datePickerRow: some View {
//        HStack {
//            Label {
//                Text("Date")
//            } icon: {
//                Image(systemName: trans.date != nil ? "calendar" : "exclamationmark.circle.fill")
//                    .foregroundColor(trans.date != nil ? .gray : Color.theme == Color.red ? Color.orange : Color.red)
//                    //.frame(width: symbolWidth)
//            }
//
//            Spacer()
//            if trans.date == nil && (trans.isSmartTransaction ?? false) {
//                Button("A Date Is Required") {
//                    trans.date = day.date!
//                }
//                .buttonStyle(.borderedProminent)
//                .tint(Color.theme == Color.red ? Color.orange : Color.red)
//                
//            } else {
//                #if os(iOS)
////                UIKitDatePicker(date: $trans.date, alignment: .trailing) // Have to use because of reformatting issue
////                    .frame(height: 40)
//                
//                DatePicker("", selection: $trans.date ?? Date(), displayedComponents: [.date])
//                    .frame(maxWidth: .infinity, alignment: .trailing)
//                    .labelsHidden()
//                
//                
//                #else
//                DatePicker("", selection: $trans.date ?? Date(), displayedComponents: [.date])
//                    .frame(maxWidth: .infinity, alignment: .leading)
//                    .labelsHidden()
//                #endif
//            }
//        }
//        .onChange(of: trans.date) { old, new in
//            if old != nil { /// Date is nil when creating a new transaction.
//                focusedField = nil /// Clear any focused text field when changing the date.
//                UndodoManager.shared.processChange(trans: trans)
//            }
//        }
//    }
//    
//    
//    @State private var dateFixerTicker = 0
//    
//    var dateFixerRow: some View {
//        HStack {
//            Label {
//                Text("Fix Date")
//            } icon: {
//                Image(systemName: "calendar.badge.exclamationmark")
//                    .foregroundColor(Color.theme == Color.red ? Color.orange : Color.red)
//            }
//
//            Spacer()
//            
//            
//            ControlGroup {
//                Button {
//                    dateFixerTicker -= 1
//                    trans.date = Calendar.current.date(byAdding: DateComponents(day: dateFixerTicker), to: Date())
//                } label: {
//                    Image(systemName: "chevron.left")
//                }
//                
//                Button("Today") {
//                    dateFixerTicker = 0
//                    trans.date = Date()
//                }
//                
//                Button {
//                    dateFixerTicker += 1
//                    trans.date = Calendar.current.date(byAdding: DateComponents(day: dateFixerTicker), to: Date())
//                } label: {
//                    Image(systemName: "chevron.right")
//                }
//            }
//            
//            
//            .buttonStyle(.borderedProminent)
//        }
//    }
//    
//    
//    var reminderRow: some View {
//        Section {
//            ReminderPicker(notificationOffset: $trans.notificationOffset)
////            Picker("", selection: $trans.notificationOffset) {
////                Text("2 days before")
////                    .tag(2)
////                Text("1 day before")
////                    .tag(1)
////                Text("Day of")
////                    .tag(0)
////            }
////            .labelsHidden()
////            .pickerStyle(.palette)
////        } header: {
////            Text("Reminder")
//        } footer: {
//            Text("Alerts will be sent out at 9:00 AM")
//                .foregroundStyle(.gray)
//                .font(.caption)
//                .multilineTextAlignment(.leading)
//                .padding(.horizontal, 6)
//        }
//    }
//
//    
//    var trackingAndOrderRow: some View {
//        Section {
//            if showTrackingOrderAndUrlFields {
//                trackingNumberTextField
//                orderNumberTextField
//                StandardUrlTextField(url: $trans.url, symbolWidth: symbolWidth, focusedField: _focusedField, focusID: 4, showSymbol: true)
//            } else {
//                
//                Button {
//                    withAnimation { showTrackingOrderAndUrlFields = true }
//                } label: {
//                    Label {
//                        Text("add fields")
//                            .schemeBasedForegroundStyle()
//                    } icon: {
//                        Image(systemName: "plus.circle.fill")
//                            .foregroundStyle(.gray)
//                    }
//                }
//                
////                HStack {
////                    Image(systemName: "shippingbox.fill")
////                        .foregroundColor(.gray)
////                        .frame(width: symbolWidth)
////
////                    Button {
////                        withAnimation { showTrackingOrderAndUrlFields = true }
////                    } label: {
////                        HStack {
////                            Text("Add Fields")
////                            Spacer()
////                            Image(systemName: "chevron.right")
////                        }
////                        .foregroundStyle(.gray)
////                        .contentShape(Rectangle())
////                    }
////                    .buttonStyle(.plain)
////                }
//            }
//        } header: {
//            Text("Tracking, Order, & Link")
//        } footer: {
//            if trans.trackingNumber.isEmpty && trans.orderNumber.isEmpty && trans.url.isEmpty {
//                if showTrackingOrderAndUrlFields {
//                    Button {
//                        withAnimation { showTrackingOrderAndUrlFields = false }
//                    } label: {
//                        Text("Hide")
//                    }
//                    .tint(Color.theme)
//                    //.buttonStyle(.borderedProminent)
//                }
//            }
//            
//        }
//    }
//    
//    
//    var trackingNumberTextField: some View {
//        HStack {
//            Label {
//                Text("Tracking #")
//            } icon: {
//                Image(systemName: "truck.box.fill")
//                    .foregroundStyle(.gray)
//            }
//                                    
//            Group {
//                #if os(iOS)
//                UITextFieldWrapper(placeholder: "ABC123", text: $trans.trackingNumber, onSubmit: {
//                    focusedField = 3
//                }, toolbar: {
//                    KeyboardToolbarView(focusedField: $focusedField)
//                })
//                .uiTag(2)
//                .uiClearButtonMode(.whileEditing)
//                .uiStartCursorAtEnd(true)
//                .uiTextAlignment(.right)
//                .uiReturnKeyType(.next)
//                .uiAutoCorrectionDisabled(true)
//                #else
//                StandardTextField("Tracking Number", text: $trans.trackingNumber, focusedField: $focusedField, focusValue: 2)
//                    .autocorrectionDisabled(true)
//                    .onSubmit { focusedField = 3 }
//                #endif
//            }
//            .focused($focusedField, equals: 2)
//        }
//        .padding(.bottom, 6)
//    }
//    
//    
//    var orderNumberTextField: some View {
//        HStack {
//            Label {
//                Text("Order #")
//            } icon: {
//                Image(systemName: "shippingbox.fill")
//                    .foregroundStyle(.gray)
//            }
//                        
//            Group {
//                #if os(iOS)
//                UITextFieldWrapper(placeholder: "ABC123", text: $trans.orderNumber, onSubmit: {
//                    focusedField = 4
//                }, toolbar: {
//                    KeyboardToolbarView(focusedField: $focusedField)
//                })
//                .uiTag(3)
//                .uiClearButtonMode(.whileEditing)
//                .uiStartCursorAtEnd(true)
//                .uiTextAlignment(.right)
//                .uiReturnKeyType(.next)
//                .uiAutoCorrectionDisabled(true)
//                
////                StandardUITextField("Order Number", text: $trans.orderNumber, onSubmit: {
////                    focusedField = 4
////                }, toolbar: {
////                    KeyboardToolbarView(focusedField: $focusedField)
////                })
////                .cbClearButtonMode(.whileEditing)
////                .cbFocused(_focusedField, equals: 3)
////                .cbAutoCorrectionDisabled(true)
////                .cbSubmitLabel(.next)
//                #else
//                StandardTextField("Order Number", text: $trans.orderNumber, focusedField: $focusedField, focusValue: 3)
//                    .autocorrectionDisabled(true)
//                    .onSubmit { focusedField = 4 }
//                #endif
//            }
//            .focused($focusedField, equals: 3)
//        }
//        .padding(.bottom, 6)
//    }
//    
//    
//    var urlTextField: some View {
//        VStack(alignment: .leading) {
//            StandardUrlTextField(url: $trans.url, symbolWidth: symbolWidth, focusedField: _focusedField, focusID: 4, showSymbol: true)
//            if trans.trackingNumber.isEmpty && trans.orderNumber.isEmpty && trans.url.isEmpty {
//                HStack {
//                    Text("")
//                        .frame(width: symbolWidth)
//                    
//                    Button {
//                        withAnimation {
//                            showTrackingOrderAndUrlFields = false
//                        }
//                    } label: {
//                        Text("Hide")
//                    }
//                    .tint(Color.theme)
//                    .buttonStyle(.borderedProminent)
//                }
//                
//            }
//        }
//        .focused($focusedField, equals: 4)
//    }
//     
//    
//    var hashtagsRow: some View {
//        Section {
//            HStack {
//                Button {
//                    showTagSheet = true
//                } label: {
//                    if trans.tags.isEmpty {
//                        Label {
//                            Text("Tags")
//                                .schemeBasedForegroundStyle()
//                        } icon: {
//                            Image(systemName: "number")
//                                .foregroundStyle(.gray)
//                        }
//                    } else {
//                        TagLayout(alignment: .leading, spacing: 5) {
//                            ForEach(trans.tags.sorted(by: { $0.tag < $1.tag })) { tag in
//                                Text("#\(tag.tag)")
//                                    .foregroundStyle(Color.theme)
//                                    .bold()
//                            }
//                        }
//                        .contentShape(Rectangle())
//                    }
//                }
//            }
//        }
//        .sheet(isPresented: $showTagSheet) {
//            TagView(trans: trans)
//            #if os(macOS)
//                .frame(minWidth: 300, minHeight: 500)
//                .presentationSizing(.fitted)
//            #endif
//        }
//    }
//    
//  
//    var alteredBy: some View {
//        HStack {
//            Image(systemName: "person.fill")
//                .foregroundColor(.gray)
//                .frame(width: symbolWidth)
//                        
//            VStack(alignment: .leading) {
//                Text("Created")
//                Text("Updated")
//            }
//            //.frame(maxWidth: .infinity)
//            .font(.caption)
//            .foregroundColor(.gray)
//            
//            Divider()
//            
//            VStack(alignment: .leading) {
//                Text(trans.enteredDate.string(to: .monthDayYearHrMinAmPm))
//                Text(trans.updatedDate.string(to: .monthDayYearHrMinAmPm))
//            }
//            //.frame(maxWidth: .infinity)
//            .font(.caption)
//            .foregroundColor(.gray)
//            
//            Divider()
//            
//            VStack(alignment: .leading) {
//                Text(trans.enteredBy.name.isEmpty ? "N/A" : trans.enteredBy.name)
//                Text(trans.updatedBy.name.isEmpty ? "N/A" : trans.updatedBy.name)
//            }
//            //.frame(maxWidth: .infinity)
//            .font(.caption)
//            .foregroundColor(.gray)
//            
//            //Spacer()
//        }
//        .frame(maxWidth: .infinity)
//        #if os(macOS)
//        .padding(.bottom, 12)
//        #else
//        .if(AppState.shared.isIpad) {
//            $0.padding(.bottom, 12)
//        }
//        #endif
//    }
//    
//    
//    var closeButton: some View {
//        Button {
//            if !isValidToSave {
//                trans.status = nil
//            }
//            validateBeforeClosing()
//        } label: {
//            Image(systemName: isValidToSave ? "checkmark" : "xmark")
//                .schemeBasedForegroundStyle()
//        }
//    }
//    
//        
//    var moreMenu: some View {
////        NavigationLink(value: "MOREMENU") {
////            Image(systemName: "ellipsis")
////                .schemeBasedForegroundStyle()
////        }
//        
//        NavigationLink(value: TransNavDestination.options) {
//            Image(systemName: "ellipsis")
//                .schemeBasedForegroundStyle()
//        }
//    }
//        
//    
//    var deleteButton: some View {
//        Button {
//            showDeleteAlert = true
//        } label: {
//            Image(systemName: "trash")
//        }
//        .sensoryFeedback(.warning, trigger: showDeleteAlert) { !$0 && $1 }
//        .tint(.none)
//        .confirmationDialog("Delete \"\(trans.title)\"?", isPresented: $showDeleteAlert) {
//            /// There's a bug in dismiss() that causes the photo sheet to open, close, and then open again. By moving the dismiss variable into a seperate view, it doesn't affect the photo sheet anymore.
//            DeleteYesButton(trans: trans, transEditID: $transEditID, isTemp: isTemp)
//                        
//            Button("No", role: .close) {
//                showDeleteAlert = false
//            }
//        } message: {
//            Text("Delete \"\(trans.title)\"?")
//        }
//    }
//    
//        
//    @ViewBuilder var ruleSuggestionButton: some View {
//        if trans.category != nil && !(trans.category?.isNil ?? false) {
//            let existingCount = calModel.justTransactions
//                .filter {
//                    $0.title.localizedCaseInsensitiveContains(trans.title)
//                    && $0.category?.id == trans.category!.id
//                }
//                .count
//            
//            let comboExists = existingCount >= 3 && !trans.wasAddedFromPopulate
//            
//            let ruleDoesNotExist = keyModel
//                .keywords
//                .filter {
//                    $0.keyword.localizedCaseInsensitiveContains(trans.title)
//                    && $0.category?.id == trans.category!.id
//                }
//                .isEmpty
//            
//            if comboExists && ruleDoesNotExist {
//                Section {
//                    Button {
//                        createRule()
//                    } label: {
//                        //AiLabel(text: "Add Rule")
//                        //AiLabel2(text: "Add Rule")
//                        //LiquidAliveTextForReal(text: "Add Rule")
//                        
//                        AiAnimatedAliveLabel("Create New Rule", systemImage: "brain", withGlow: true)
//                    }
//                } footer: {
//                    let message: LocalizedStringKey = "**\(trans.title)** was categorized as **\(trans.category!.title)** at least \(existingCount) times this year. Consider creating a rule to auto-categorize in the future."
//                    
//                    Text(message)
//                }
//            }
//        }
//    }
//    
//    
//    
//    #if os(macOS)
//    struct MacSheetHeaderView<MoreMenu: View, DeleteButton: View>: View {
//        @Environment(\.dismiss) var dismiss
//        @Environment(CalendarModel.self) private var calModel
//            
//        var title: String
//        @Bindable var trans: CBTransaction
//        var validateBeforeClosing: () -> ()
//        @ViewBuilder var moreMenu: MoreMenu
//        @ViewBuilder var deleteButton: DeleteButton
//        
//        var linkedLingo: String? {
//            if trans.relatedTransactionType == XrefModel.getItem(from: .relatedTransactionType, byEnumID: .transaction) {
//                return "(Linked to transaction)"
//            } else {
//                return "(Linked to event)"
//            }
//        }
//        
//        var body: some View {
//            SheetHeader(
//                title: title,
//                //subtitle: trans.relatedTransactionID == nil ? nil : linkedLingo,
//                close: { validateBeforeClosing() },
//                view1: { moreMenu },
//                view3: { deleteButton }
//            )
//        }
//    }
//    #endif
//    
//    
//    struct DeleteYesButton: View {
//        @Environment(CalendarModel.self) private var calModel
//    
//        @Environment(\.dismiss) var dismiss
//        @Bindable var trans: CBTransaction
//        @Binding var transEditID: String?
//        var isTemp: Bool
//        
//        var body: some View {
//            Button("Yes", role: .destructive, action: delete)
//        }
//        
//        func delete() {
//            if isTemp {
//                dismiss()
//                calModel.tempTransactions.removeAll { $0.id == trans.id }
//                //let _ = DataManager.shared.delete(type: TempTransaction.self, predicate: .byId(.string(trans.id)))
//                
//                Task {
//                    let context = DataManager.shared.createContext()
//                    context.perform {
//                        if let entity = DataManager.shared.getOne(context: context, type: TempTransaction.self, predicate: .byId(.string(trans.id)), createIfNotFound: true) {
//                            entity.action = TransactionAction.delete.rawValue
//                            entity.tempAction = TransactionAction.delete.rawValue
//                            let _ = DataManager.shared.save(context: context)
//                        }
//                    }
//                }
//                
//            } else {
//                //transEditID = nil
//                trans.action = .delete
//                dismiss()
//                
//                //calModel.saveTransaction(id: trans.id, day: day)
//            }
//        }
//    }
//    
//    
//    
//    // MARK: - Functions
//    func validateBeforeClosing() {
//        if !trans.title.isEmpty && !trans.amountString.isEmpty && trans.payMethod == nil {
//            
//            if trans.payMethod == nil && (trans.isSmartTransaction ?? false) {
//                focusedField = nil
//                //transEditID = nil
//                dismiss()
//            } else {
//                let config = AlertConfig(
//                    title: "Missing Payment Method",
//                    subtitle: "Please assign an account or delete this transaction.",
//                    symbol: .init(name: "creditcard.trianglebadge.exclamationmark.fill", color: .orange)
//                )
//                AppState.shared.showAlert(config: config)
//            }
//            
//        } else {
//            focusedField = nil
//            //transEditID = nil
//            dismiss()
//        }
//    }
//    
//    
//    func checkIfTransactionIsValidToSave() {
//        if trans.title.isEmpty {
//            isValidToSave = false; return
//        }
//        if trans.payMethod == nil {
//            isValidToSave = false; return
//        }
//        if trans.date == nil && (trans.isSmartTransaction ?? false) {
//            isValidToSave = false; return
//        }
//        if !trans.hasChanges(shouldLog: false) {
//            //print("Transaction does not have changes")
//            isValidToSave = false; return
//        } else {
//            //print("Transaction does! have changes")
//            isValidToSave = true; return
//        }
//    }
//    
//        
//    func prepareTransactionForEditing(isTemp: Bool) {
//        print("-- \(#function)")
//        /// Clear undo history.
//        UndodoManager.shared.clearHistory()
//        UndodoManager.shared.commitChange(trans: trans)
//        
//        //calModel.hilightTrans = nil
//            
//        /// Determine the title button color.
//        titleColorButtonHoverColor = trans.color == .primary ? .gray : trans.color
//        
//        /// Set the transaction date to the date of the passed in day.
//        if trans.date == nil && !(trans.isSmartTransaction ?? false) {
//            trans.date = day.date!
//        }
//                
//        /// Format the dollar amount.
//        if trans.action != .add && trans.tempAction != .add {
//            trans.amountString = trans.amount.currencyWithDecimals(useWholeNumbers ? 0 : 2)
//        }
//                
//        /// Set a reference to the transactions ID so photos know where to go.
//        FileModel.shared.fileParent = FileParent(id: trans.id, type: XrefModel.getItem(from: .fileTypes, byEnumID: .transaction))
//
//        /// If the transaction is new.
//        if trans.action == .add && !isTemp {
//            trans.amountString = ""
//            
//            /// Set the dummy nil category to the trans so it's not a real nil.
//            trans.category = catModel.getNil()
//            
//            /// If the unified editing payment method is set, use it.
//            if calModel.sPayMethod?.accountType == .unifiedChecking && payModel.editingDefaultAccountType == .checking {
//                trans.payMethod = payModel.getEditingDefault()
//            
//            /// If the unified editing payment method is set, use it.
//            } else if calModel.sPayMethod?.accountType == .unifiedCredit && [.credit, .loan].contains(payModel.editingDefaultAccountType) {
//                trans.payMethod = payModel.getEditingDefault()
//                
//            } else {
//                /// Add the selected viewing payment method to the transaction.
//                trans.payMethod = calModel.sPayMethod
//            }
//                        
//            #if os(iOS)
//            Task {
//                /// Wait a split second before adding to the day so we don't see it happen.
//                try await Task.sleep(for: .seconds(0.5))
//                /// Pre-add the transaction to the day so we can add photos to it before saving. Get's removed on cancel if title and payment method are blank.
//                day.upsert(trans)
//            }
//            #else
//            /// Pre-add the transaction to the day so we can add photos to it before saving. Get's removed on cancel if title and payment method are blank.
//            day.upsert(trans)
//            #endif
//            
//            
//        } else if trans.tempAction == .add && isTemp {
//            /// Set the dummy nil category to the trans so it's not a real nil.
//            trans.category = catModel.getNil()
//            
//            calModel.tempTransactions.append(trans)
//            trans.amountString = ""
//            trans.payMethod = payModel.getEditingDefault()
//            trans.action = .add
//        }
//        
//        /// Show the tracking / url fields if there is a value in them.
//        if !trans.trackingNumber.isEmpty || !trans.orderNumber.isEmpty || !trans.url.isEmpty {
//            showTrackingOrderAndUrlFields = true
//        }
//                        
//        /// Copy it so we can compare for smart saving.
//        trans.deepCopy(.create)
//                
//        #if os(macOS)
//        /// Focus on the title textfield.
//        focusedField = 0
//        #else
//        if (trans.action == .add && !isTemp) || (trans.tempAction == .add && isTemp) {
//            Task {
//                /// Wait a split second so the view isn't clunky.
//                //try? await Task.sleep(nanoseconds: UInt64(0.5 * Double(NSEC_PER_SEC)))
//                try? await Task.sleep(for: .seconds(0.5))
//                focusedField = 0
//            }
//        }
//        #endif
//        
//        checkIfTransactionIsValidToSave()
//        
//        
//        /// Remove the date from the deepCopy if editing from a smart transaction that has a date as a problem.
//        /// Today's date gets assigned by default when the trans date is nil, so if the date is the only issue, the save function won't see the trans as being valid to save.
//        /// By removing the date from the deepCopy, it causes the trans and it's deep copy to fail the equatble check, which will make the app save the transaction.
////        if (trans.isSmartTransaction ?? false) && (trans.smartTransactionIssue?.enumID == .missingDate || trans.smartTransactionIssue?.enumID == .missingPaymentMethodAndDate)  {
////            trans.deepCopy?.date = nil
////        }
//        
//        /// Protect the transaction from being updated via scene changes if it is open.
//        /// Ignore this transaction if it's open and you're coming back to the app from another app (ie if bouncing back and forth between this app and a banking app).
//        //calModel.transEditID = transEditID
//        
//        /// These are just to control the animations in the options sheet. The are here so we don't see the option sheet "set up its state" when the view appears.
//        if !trans.factorInCalculations { showHiddenEye = true }
//        if trans.notifyOnDueDate { showBadgeBell = true }
//    }
//        
//    
//    func createRule() {
//        let keyword = CBKeyword()
//        withAnimation {
//            keyword.keyword = trans.title
//            keyword.category = trans.category!
//            keyword.triggerType = .contains
//            
//            keyword.deepCopy(.create)
//            keyModel.upsert(keyword)
//            keyModel.keywords.sort { $0.keyword < $1.keyword }
//            
//            AppState.shared.showToast(title: "Rule Created", subtitle: trans.title, body: "\(trans.category!.title)", symbol: "ruler", symbolColor: .green)
//        }
//        
//        Task { await keyModel.submit(keyword) }
//    }
//    
////    func deletePicture() {
////        Task {
////            vm.isDeletingPic = true
////            let _ = await calModel.delete(picture: vm.deletePic!)
////            vm.isDeletingPic = false
////            vm.deletePic = nil
////        }
////    }
//}
//
//
//
//
