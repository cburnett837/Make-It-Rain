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

fileprivate let photoWidth: CGFloat = 125
fileprivate let photoHeight: CGFloat = 200


struct TransactionEditView: View {
//    @Observable
//    class ViewModel {
//        var hoverPic: CBPicture?
//        var deletePic: CBPicture?
//        var isDeletingPic = false
//        var showDeletePicAlert = false
//    }
    
    //@Environment(\.dismiss) var dismiss <--- NO NICE THAT ONE WITH SHEETS IN A SHEET.
    @Environment(\.colorScheme) var colorScheme
    @Local(\.colorTheme) var colorTheme
    @AppStorage("lineItemIndicator") var lineItemIndicator: LineItemIndicator = .emoji
    @Local(\.useWholeNumbers) var useWholeNumbers

    #if os(macOS)
    @Environment(\.openURL) var openURL
    #endif
    @Environment(CalendarModel.self) private var calModel
    
    @Environment(PayMethodModel.self) private var payModel
    @Environment(CategoryModel.self) private var catModel
    @Environment(KeywordModel.self) private var keyModel
    //@Environment(MapModel.self) private var mapModel
    
    @State private var mapModel = MapModel()
    //@Environment(TagModel.self) private var tagModel
    
    //@State private var vm = ViewModel()
    
    @State private var titleColorButtonHoverColor: Color = .gray
    @State private var payMethodMenuColor: Color = Color(.tertiarySystemFill)
    @State private var categoryMenuColor: Color = Color(.tertiarySystemFill)
    //@State private var addPhotoButtonHoverColor: Color = .gray
    //@State private var addPhotoButtonHoverColor2: Color = Color(.tertiarySystemFill)
        
    @FocusState private var focusedField: Int?
    
    @Bindable var trans: CBTransaction
    @Binding var transEditID: String?
    @Bindable var day: CBDay
    var isTemp: Bool
    var transLocation: WhereToLookForTransaction = .normalList
    
    var title: String { trans.action == .add ? "New Transaction" : "Edit Transaction" }
    let symbolWidth: CGFloat = 26
        
    //@State private var safariUrl: URL?
    
    //@State private var totalHeight = CGFloat.zero
    @State private var showLogSheet = false
    @State private var showTagSheet = false
    @State private var showPayMethodSheet = false
    @State private var showCategorySheet = false
    @State private var showPaymentMethodChangeAlert = false
    @State private var showDeleteAlert = false
    
    @State private var blockUndoCommitOnLoad = true
    @State private var blockKeywordChangeWhenViewLoads = true
    @State private var showTrackingOrderAndUrlFields = false
    @State private var showCamera: Bool = false
    @State private var showPhotosPicker: Bool = false
    @State private var showTopTitles: Bool = false
    //@State private var showPhotosPicker = false
    //@State private var showCamera = false
    
    @State private var titleChangedTask: Task<Void, Error>?
    @State private var amountChangedTask: Task<Void, Error>?
    //@State private var position: MapCameraPosition = .userLocation(followsHeading: true, fallback: .userLocation(fallback: .automatic))
    @State private var showUndoRedoAlert = false
        
    let changeTransactionTitleColorTip = ChangeTransactionTitleColorTip()
    
    var transTypeLingo: String {
        if trans.payMethod?.accountType == .credit {
            trans.amountString.contains("-") ? "Payment" : "Expense"
        } else {
            trans.amountString.contains("-") ? "Expense" : "Income"
        }
    }
    
    var linkedLingo: String? {
        if trans.relatedTransactionID != nil {
            if trans.relatedTransactionType == XrefModel.getItem(from: .relatedTransactionType, byEnumID: .transaction) {
                return "(This is linked to another transaction)"
            } else {
                return "(This is linked to an event transaction)"
            }
        } else {
            return nil
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

    
//    var header: some View {
//        Group {
//            SheetHeaderView(
//                title: title,
//                trans: trans,
//                transEditID: $transEditID,
//                focusedField: $focusedField,
//                showDeleteAlert: $showDeleteAlert
//            )
//            .padding()
//            
//            Divider()
//                .padding(.horizontal)
//        }
//    }
    
    var body: some View {
        //let _ = Self._printChanges()
        @Bindable var calModel = calModel
        @Bindable var payModel = payModel
        @Bindable var catModel = catModel
        @Bindable var keyModel = keyModel
        @Bindable var appState = AppState.shared
        
        StandardContainer {
            //titleTextField
            StandardTitleTextField(symbolWidth: symbolWidth, focusedField: _focusedField, focusID: 0, showSymbol: true, parentType: XrefEnum.transaction, showTitleSuggestions: $showTopTitles, titleSuggestions: trans.category?.topTitles ?? [], obj: trans)
                .onChange(of: trans.category) { oldValue, newValue in
                    if let newValue {
                        if trans.action == .add && trans.title.isEmpty && !newValue.isNil {
                            showTopTitles = true
                        }
                    }
                }

            
            StandardAmountTextField(symbolWidth: symbolWidth, focusedField: _focusedField, focusID: 1, showSymbol: true, negativeOnFocusIfEmpty: trans.payMethod?.accountType != .credit, obj: trans)
            StandardDivider()
            
            paymentMethodMenu
            categoryMenu
            
            StandardDivider()
            
            #if os(iOS)
            datePickerSection
            StandardDivider()
            #endif
            
            if !isTemp {
                HStack(alignment: .top) {
                    Image(systemName: "map.fill")
                        .foregroundColor(.gray)
                        .frame(width: symbolWidth)
                    
                    StandardMiniMap(locations: $trans.locations, parent: trans, parentID: trans.id, parentType: XrefEnum.transaction, addCurrentLocation: trans.action == .add)
                        .cornerRadius(8)
                }
                .padding(.bottom, 6)
                
                StandardDivider()
            }
            
            
            if trans.notifyOnDueDate {
                if !isTemp {
                    reminderSection
                    StandardDivider()
                }
            }
            
            trackingAndOrderSection
            StandardDivider()
            
            if !isTemp {
                hashtags
                StandardDivider()
            }
                                                            
            if !isTemp {
//                photoSection
                StandardPhotoSection(
                    pictures: $trans.pictures,
                    photoUploadCompletedDelegate: calModel,
                    parentType: .transaction,
                    showCamera: $showCamera,
                    showPhotosPicker: $showPhotosPicker
                )
                StandardDivider()
            }
                                    
            StandardNoteTextEditor(notes: $trans.notes, symbolWidth: symbolWidth, focusedField: _focusedField, focusID: showTrackingOrderAndUrlFields ? 5 : 2, showSymbol: true)
            
            StandardDivider()
            
            if !isTemp {
                logs
                StandardDivider()
            }
                                    
            alteredBy
        } header: {
            SheetHeaderView(title: title, trans: trans, transEditID: $transEditID, focusedField: $focusedField, showDeleteAlert: $showDeleteAlert, isTemp: isTemp)
        } footer: {
            if let linkedLingo {
                Text(linkedLingo)
                   .font(.caption2)
                   .foregroundStyle(.gray)
            }
        }
        .onDisappear {
            transEditID = nil
        }
        .interactiveDismissDisabled(paymentMethodMissing)
        .environment(mapModel)
        .task {
            prepareTransactionForEditing(isTemp: isTemp)
            ChangeTransactionTitleColorTip.didOpenTransaction.sendDonation()
        }
        .alert("Please change the payment method by right-clicking on the line item from the main view.", isPresented: $showPaymentMethodChangeAlert) {
            Button("OK") {}
        }
        .confirmationDialog("Delete \"\(trans.title)\"?", isPresented: $showDeleteAlert) {
            /// There's a bug in dismiss() that causes the photo sheet to open, close, and then open again. By moving the dismiss variable into a seperate view, it doesn't affect the photo sheet anymore.
            DeleteYesButton(trans: trans, transEditID: $transEditID, isTemp: isTemp)
                        
            Button("No", role: .cancel) {
                showDeleteAlert = false
            }
        } message: {
            Text("Delete \"\(trans.title)\"?")
        }
        // MARK: - Undo Stuff
        #if os(iOS)
        .onShake {
            UndodoManager.shared.getChangeFields(trans: trans)            
            UndodoManager.shared.showAlert = true
        }
        .onChange(of: UndodoManager.shared.returnMe) {
            if let new = $1 {
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
        .onChange(of: undoRedoValuesChanged) { UndodoManager.shared.processChange(trans: trans) }
//        .onChange(of: trans.title) { UndodoManager.shared.processChange(trans: trans) }
//        .onChange(of: trans.amountString) { UndodoManager.shared.processChange(trans: trans) }
//        .onChange(of: trans.payMethod) { UndodoManager.shared.processChange(trans: trans) }
//        .onChange(of: trans.category) { UndodoManager.shared.processChange(trans: trans) }
//        //.onChange(of: trans.date) { UndodoManager.shared.commitChange(trans: trans) }
//        .onChange(of: trans.trackingNumber) { UndodoManager.shared.processChange(trans: trans) }
//        .onChange(of: trans.orderNumber) { UndodoManager.shared.processChange(trans: trans) }
//        .onChange(of: trans.url) { UndodoManager.shared.processChange(trans: trans) }
//        .onChange(of: trans.notes) { UndodoManager.shared.processChange(trans: trans) }
        .onChange(of: trans.date) { oldValue, newValue in
            if oldValue != nil { /// Date is nil when creating a new transaction.
                focusedField = nil /// Clear any focused text field when changing the date.
                UndodoManager.shared.processChange(trans: trans)
            }
        }
        .onChange(of: focusedField) { oldValue, newValue in
            if newValue != nil {
                if trans.action == .add && blockUndoCommitOnLoad {
                    blockUndoCommitOnLoad = false
                } else {
                    UndodoManager.shared.changeTask?.cancel()
                    UndodoManager.shared.commitChange(trans: trans)
                }
            }
        }
        
        //.onChange(of: mapModel.position) { self.position = $1 }
        #endif
        
        .onChange(of: trans.title) { oldValue, newValue in
            if !blockKeywordChangeWhenViewLoads {
                let upVal = newValue.uppercased()
                
                for key in keyModel.keywords {
                    let upKey = key.keyword.uppercased()
                    
                    switch key.triggerType {
                    case .equals:
                        if upVal == upKey { trans.category = key.category }
                    case .contains:
                        if upVal.contains(upKey) { trans.category = key.category }
                    }
                }
            } else {
                blockKeywordChangeWhenViewLoads = false
            }
        }
    }
               
    
    
    
    // MARK: - SubViews
//    var titleTextField: some View {
//        HStack {
//            #if os(macOS)
//            Image(systemName: "bag.fill")
//            //Image(systemName: trans.color == .primary ? "lightspectrum.horizontal" : "bag.fill")
//                .foregroundColor(titleColorButtonHoverColor)
//                .frame(width: symbolWidth)
//                //.symbolRenderingMode(.multicolor)
//                .contentShape(Rectangle())
//                .overlay {
//                    TitleColorMenu(trans: trans, saveOnChange: false) {
//                        EmptyView()
//                    }
//                    .menuStyle(.borderlessButton)
//                    .menuIndicator(.hidden)
//                    .onTapGesture {
//                        ChangeTransactionTitleColorTip.didTouchColorChangeButton = true
//                    }
//                    //.padding(.leading, 4)
//                }
//                .onHover { isHovering in titleColorButtonHoverColor = isHovering ? (trans.color == Color.accentColor ? .white : Color.accentColor) : ((trans.color == .white || trans.color == .primary) ? .gray : trans.color) }
//                .padding(.leading, 1)
//                .popoverTip(changeTransactionTitleColorTip)
//                //.focusEffectDisabled(true)
//            
//            #else
//            TitleColorMenu(trans: trans, saveOnChange: false) {
//                Image(systemName: "bag.fill")
//                //Image(systemName: trans.color == .primary ? "lightspectrum.horizontal" :"bag.fill")
//                    .foregroundColor(trans.color == .primary ? .gray : trans.color)
//                    .frame(width: symbolWidth)
//                    .onTapGesture {
//                        ChangeTransactionTitleColorTip.didTouchColorChangeButton = true
//                    }
//                    //.symbolRenderingMode(.multicolor)
//            }
//            .popoverTip(changeTransactionTitleColorTip)
//            #endif
//            
//            Group {
//                #if os(iOS)
//                
//                StandardUITextField("Title", text: $trans.title, onSubmit: {
//                    focusedField = 1
//                }, toolbar: {
//                    KeyboardToolbarView(focusedField: $focusedField)
//                })
//                .cbClearButtonMode(.whileEditing)
//                .cbFocused(_focusedField, equals: 0)
//                .cbSubmitLabel(.next)
//                .overlay {
//                    if !trans.factorInCalculations {
//                        RoundedRectangle(cornerRadius: 8)
//                            .stroke(.red, lineWidth: 4)
//                    }
//                }
//                
//                #else
//                StandardTextField("Title", text: $trans.title, focusedField: $focusedField, focusValue: 0)
//                    .onSubmit { focusedField = 1 }
//                    .overlay {
//                        if !trans.factorInCalculations {
//                            RoundedRectangle(cornerRadius: 8)
//                                .stroke(.red, lineWidth: 4)
//                        }
//                    }
//                #endif
//            }
//            .onChange(of: trans.title) { oldValue, newValue in
//                if !blockKeywordChangeWhenViewLoads {
//                    let upVal = newValue.uppercased()
//                    
//                    for key in keyModel.keywords {
//                        let upKey = key.keyword.uppercased()
//                        
//                        switch key.triggerType {
//                        case .equals:
//                            if upVal == upKey { trans.category = key.category }
//                        case .contains:
//                            if upVal.contains(upKey) { trans.category = key.category }
//                        }
//                    }
//                } else {
//                    blockKeywordChangeWhenViewLoads = false
//                }
//            }
//        }
//    }
    
//    
//    var amountTextField: some View {
//        HStack(alignment: .circleAndTitle) {
//            Image(systemName: "dollarsign.circle.fill")
//                .foregroundColor(.gray)
//                .frame(width: symbolWidth)
//                .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
//            
//            VStack(alignment: .leading, spacing: 0) {
//                Group {
//                    #if os(iOS)
//                    StandardUITextField("Amount", text: $trans.amountString, toolbar: {
//                        KeyboardToolbarView(
//                            focusedField: $focusedField,
//                            accessoryImage3: "plus.forwardslash.minus",
//                            accessoryFunc3: {
//                                Helpers.plusMinus($trans.amountString)
//                            })
//                    })
//                    .cbClearButtonMode(.whileEditing)
//                    .cbFocused(_focusedField, equals: 1)
//                    .cbKeyboardType(useWholeNumbers ? .numberPad : .decimalPad)
//                    //.cbTextfieldInputType(.currency)                    
////                    .onChange(of: trans.amountString) {
////                        Helpers.liveFormatCurrency(oldValue: $0, newValue: $1, text: $trans.amountString)
////                    }
////                    .onChange(of: focusedField) {
////                        if let string = Helpers.formatCurrency(focusValue: 1, oldFocus: $0, newFocus: $1, amountString: trans.amountString, amount: trans.amount) {
////                            trans.amountString = string
////                        }
////                    }
////
////
////                    .onChange(of: focusedField) { oldValue, newValue in
////                        if newValue == 1 {
////                            if trans.amount == 0.0 {
////                                trans.amountString = ""
////                            }
////                        } else {
////                            if oldValue == 1 && !trans.amountString.isEmpty {
////                                if trans.amountString == "$" || trans.amountString == "-$" {
////                                    trans.amountString = ""
////                                } else {
////                                    trans.amountString = trans.amount.currencyWithDecimals(useWholeNumbers ? 0 : 2)
////                                }
////                            }
////                        }
////                    }
////                    .onChange(of: trans.amountString) { oldValue, newValue in
////                        if trans.amountString != "-" {
////                            if trans.amount == 0.0 {
////                                trans.amountString = ""
////                            } else {
////                                trans.amountString = trans.amount.currencyWithDecimals(useWholeNumbers ? 0 : 2)
////                            }
////                        }
////                    }
//                    #else
//                    StandardTextField("Amount", text: $trans.amountString, focusedField: $focusedField, focusValue: 1)
//                    #endif
//                }
//                .formatCurrencyLiveAndOnUnFocus(
//                    focusValue: 1,
//                    focusedField: focusedField,
//                    amountString: trans.amountString,
//                    amountStringBinding: $trans.amountString,
//                    amount: trans.amount
//                )
//                .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
//                
//                (Text("Transaction Type: ") + Text(transTypeLingo).bold(true).foregroundStyle(Color.fromName(colorTheme)))
//                    .foregroundStyle(.gray)
//                    .font(.caption)
//                    .multilineTextAlignment(.leading)
//                    .padding(.leading, 6)
//                    .disabled(trans.amountString.isEmpty)
//                    .onTapGesture {
//                        Helpers.plusMinus($trans.amountString)
//                        
//                        /// Just do on Mac because the calendar view is still visable.
//                        #if os(macOS)
//                        let _ = calModel.calculateTotal(for: calModel.sMonth)
//                        #endif
//                    }
//            }
//        }
//    }
//    
//    
    var datePickerSection: some View {
        HStack {
            Image(systemName: trans.date != nil ? "calendar" : "exclamationmark.circle.fill")
                .foregroundColor(trans.date != nil ? .gray : Color.fromName(colorTheme) == Color.red ? Color.orange : Color.red)
                .frame(width: symbolWidth)
            
            
            if trans.date == nil && (trans.isSmartTransaction ?? false) {
                Button("A Date Is Required") {
                    trans.date = day.date!
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.fromName(colorTheme) == Color.red ? Color.orange : Color.red)
                
            } else {
                #if os(iOS)
                UIKitDatePicker(date: $trans.date, alignment: .leading) // Have to use because of reformatting issue
                    .frame(height: 40)
                #else
                DatePicker("", selection: $trans.date ?? Date(), displayedComponents: [.date])
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .labelsHidden()
                #endif
            }
        }
    }
    
    
    var trackingAndOrderSection: some View {
        Group {
            if showTrackingOrderAndUrlFields {
                VStack(alignment: .leading) {
                    trackingNumberTextField
                    orderNumberTextField
                    urlTextField
                }
            } else {
                HStack {
                    Image(systemName: "shippingbox.fill")
                        .foregroundColor(.gray)
                        .frame(width: symbolWidth)
                    
                    Button {
                        withAnimation {
                            showTrackingOrderAndUrlFields = true
                        }
                        
                    } label: {
                        HStack {
                            Text("Tracking, Order, Link…")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .foregroundStyle(.gray)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    
    var trackingNumberTextField: some View {
        HStack {
            Image(systemName: "truck.box.fill")
                .foregroundColor(.gray)
                .frame(width: symbolWidth)
                                    
            Group {
                #if os(iOS)
                StandardUITextField("Tracking Number", text: $trans.trackingNumber, onSubmit: {
                    focusedField = 3
                }, toolbar: {
                    KeyboardToolbarView(focusedField: $focusedField)
                })
                .cbClearButtonMode(.whileEditing)
                .cbFocused(_focusedField, equals: 2)
                .cbAutoCorrectionDisabled(true)
                .cbSubmitLabel(.next)
                #else
                StandardTextField("Tracking Number", text: $trans.trackingNumber, focusedField: $focusedField, focusValue: 2)
                    .autocorrectionDisabled(true)
                    .onSubmit { focusedField = 3 }
                #endif
            }
        }
        .padding(.bottom, 6)
    }
    
    
    var orderNumberTextField: some View {
        HStack {
            Image(systemName: "shippingbox.fill")
                .foregroundColor(.gray)
                .frame(width: symbolWidth)
                        
            Group {
                #if os(iOS)
                StandardUITextField("Order Number", text: $trans.orderNumber, onSubmit: {
                    focusedField = 4
                }, toolbar: {
                    KeyboardToolbarView(focusedField: $focusedField)
                })
                .cbClearButtonMode(.whileEditing)
                .cbFocused(_focusedField, equals: 3)
                .cbAutoCorrectionDisabled(true)
                .cbSubmitLabel(.next)
                #else
                StandardTextField("Order Number", text: $trans.orderNumber, focusedField: $focusedField, focusValue: 3)
                    .autocorrectionDisabled(true)
                    .onSubmit { focusedField = 4 }
                #endif
            }
        }
        .padding(.bottom, 6)
    }
    
    
    var urlTextField: some View {
        VStack(alignment: .leading) {
            StandardUrlTextField(url: $trans.url, symbolWidth: symbolWidth, focusedField: _focusedField, focusID: 4, showSymbol: true)
            if trans.trackingNumber.isEmpty && trans.orderNumber.isEmpty && trans.url.isEmpty {
                HStack {
                    Text("")
                        .frame(width: symbolWidth)
                    
                    Button {
                        withAnimation {
                            showTrackingOrderAndUrlFields = false
                        }
                    } label: {
                        Text("Hide")
                    }
                    .tint(Color.fromName(colorTheme))
                    .buttonStyle(.borderedProminent)
                }
                
            }
        }
    }
        
    
    var reminderSection: some View {
        HStack(alignment: .circleAndTitle) {
            Image(systemName: "bell.fill")
                .foregroundColor(.gray)
                .frame(width: symbolWidth)
                .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
                                                    
                VStack(alignment: .leading) {
                    Picker("", selection: $trans.notificationOffset) {
                        Text("2 days before")
                            .tag(2)
                        Text("1 day before")
                            .tag(1)
                        Text("Day of")
                            .tag(0)
                    }
                    .labelsHidden()
                    .pickerStyle(.palette)
                    .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
                    
                    Text("Alerts will be sent out at 9:00 AM")
                        .foregroundStyle(.gray)
                        .font(.caption)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, 6)
                }
        }
    }

    
    var paymentMethodMenu: some View {
        HStack {
            Image(systemName: trans.payMethod?.accountType == .checking ? "banknote.fill" : "creditcard.fill")
                .foregroundStyle(trans.payMethod == nil ? Color.gray.gradient : trans.payMethod!.color.gradient)
                .frame(width: symbolWidth)
            
            PayMethodSheetButton(payMethod: $trans.payMethod, trans: trans, saveOnChange: false, whichPaymentMethods: .allExceptUnified)
        }        
    }
    
    
    var categoryMenu: some View {
        HStack(alignment: .circleAndTitle) {
            Group {
                if lineItemIndicator == .dot {
                    Image(systemName: "books.vertical.fill")
                        .foregroundStyle((trans.category?.isNil ?? false ? .gray : trans.category?.color ?? .gray).gradient)
                    
                } else if let emoji = trans.category?.emoji {
                    Image(systemName: emoji)
                        .foregroundStyle((trans.category?.isNil ?? false ? .gray : trans.category?.color ?? .gray).gradient)
                        //.foregroundStyle((trans.category?.color ?? .gray).gradient)
                    //Text(emoji)
                } else {
                    Image(systemName: "books.vertical.fill")
                        .foregroundStyle(.gray.gradient)
                }
            }
            .frame(width: symbolWidth)
            .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
            
            VStack(alignment: .leading, spacing: 0) {
                CategorySheetButton(category: $trans.category)
                    /// Initial undo handled inside the button.
                    .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
                
                if trans.category != nil && !(trans.category?.isNil ?? false) {
                    let isRelevant = calModel.justTransactions
                        .filter { $0.title.localizedStandardContains(trans.title) && $0.category?.id == trans.category!.id }
                        .count >= 3 && !trans.wasAddedFromPopulate
                    
                    if isRelevant {
                        let alsoIsRelevant = keyModel.keywords.filter { $0.keyword.localizedStandardContains(trans.title) && $0.category?.id == trans.category!.id }.isEmpty
                        if alsoIsRelevant {
                            VStack(alignment: .leading) {
                                Button {
                                    let keyword = CBKeyword()
                                    keyword.keyword = trans.title
                                    keyword.category = trans.category!
                                    keyword.triggerType = .contains
                                    
                                    keyword.deepCopy(.create)
                                    keyModel.upsert(keyword)
                                    keyModel.keywords.sort { $0.keyword < $1.keyword }
                                    
                                    AppState.shared.showToast(title: "Keyword Created", subtitle: trans.title, body: "\(trans.category!.title)", symbol: "textformat.abc.dottedunderline", symbolColor: .green)
                                    
                                    Task {
                                        await keyModel.submit(keyword)
                                    }
                                } label: {
                                    HStack(alignment: .top, spacing: 0) {
//                                        Image(systemName: "exclamationmark.bubble.circle.fill")
//                                            .symbolRenderingMode(.multicolor)
//                                            .foregroundStyle(.purple, .primary)
                                        Text("You seem to have the combo of \"\(trans.title)\" & \"\(trans.category!.title)\" often. Touch here to create a trigger to automatically assign the category.")
                                            .foregroundStyle(.gray)
                                            .font(.caption)
                                            .multilineTextAlignment(.leading)
                                            .padding(.horizontal, 6)
                                    }
                                    
                                }
                            }
                            .padding(.top, 2)
                        }
                    }
                }
            }
        }
    }
    
    
    var hashtags: some View {
        HStack {
            Image(systemName: "number")
                .foregroundColor(.gray)
                .frame(width: symbolWidth)
                        
            if isTemp {
                Text("Tags are unavailable without internet connection.")
                    .italic(true)
                    .foregroundStyle(.gray)
                Spacer()
            } else {
                
                Button {
                    showTagSheet = true
                } label: {
                    Group {
                        if trans.tags.isEmpty {
                            HStack {
                                Text("Tags...")
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            .foregroundStyle(.gray)
                            .contentShape(Rectangle())
                        } else {
                            TagLayout(alignment: .leading, spacing: 5) {
                                ForEach(trans.tags) { tag in
                                    Text("#\(tag.tag)")
                                        .foregroundStyle(Color.fromName(colorTheme))
                                        .bold()
                                }
                            }
                            .contentShape(Rectangle())
                        }
                    }
                }
                .buttonStyle(.plain)
                
            }
        }
        .sheet(isPresented: $showTagSheet) {
            TagView(trans: trans)
            #if os(macOS)
                .frame(minWidth: 300, minHeight: 500)
                .presentationSizing(.fitted)
            #endif
        }
        
            
    }
    
    var logs: some View {
        HStack {
            Image(systemName: "list.clipboard.fill")
                .foregroundColor(.gray)
                .frame(width: symbolWidth)
                        
            if isTemp {
                Text("Logs are unavailable without internet connection.")
                    .foregroundStyle(.gray)
                    .italic(true)
                Spacer()
            } else {
                Button {
                    withAnimation {
                        showLogSheet = true
                    }
                } label: {
                    HStack {
                        Text("Change Logs")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .foregroundStyle(.gray)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .sheet(isPresented: $showLogSheet) {
            LogSheet(itemID: trans.id, logType: .transaction)
                #if os(macOS)
                .frame(minWidth: 300, minHeight: 500)
                .presentationSizing(.fitted)
                #endif
        }
    }
    
                
    var alteredBy: some View {
        HStack {
            Image(systemName: "person.fill")
                .foregroundColor(.gray)
                .frame(width: symbolWidth)
                        
            VStack(alignment: .leading) {
                Text("Created")
                Text("Updated")
            }
            //.frame(maxWidth: .infinity)
            .font(.caption)
            .foregroundColor(.gray)
            
            Divider()
            
            VStack(alignment: .leading) {
                Text(trans.enteredDate.string(to: .monthDayYearHrMinAmPm))
                Text(trans.updatedDate.string(to: .monthDayYearHrMinAmPm))
            }
            //.frame(maxWidth: .infinity)
            .font(.caption)
            .foregroundColor(.gray)
            
            Divider()
            
            VStack(alignment: .leading) {
                Text(trans.enteredBy.name.isEmpty ? "N/A" : trans.enteredBy.name)
                Text(trans.updatedBy.name.isEmpty ? "N/A" : trans.updatedBy.name)
            }
            //.frame(maxWidth: .infinity)
            .font(.caption)
            .foregroundColor(.gray)
            
            Spacer()
        }
        #if os(macOS)
        .padding(.bottom, 12)
        #else
        .if(AppState.shared.isIpad) {
            $0.padding(.bottom, 12)
        }
        #endif
    }
    
    
    struct TransactionSplitSheet: View {
        @AppStorage("lineItemIndicator") var lineItemIndicator: LineItemIndicator = .emoji

        
        @Environment(\.dismiss) var dismiss
        @Environment(CalendarModel.self) private var calModel
        @Local(\.useWholeNumbers) var useWholeNumbers
        
        @Bindable var trans: CBTransaction
        @Binding var showSplitSheet: Bool
        
        @State private var additionalTrans: Array<CBTransaction> = []
        @FocusState private var focusedField: Int?

        @State private var originalAmount = 0.0
        
        
        var body: some View {
            StandardContainer {
                VStack {
                    VStack {
                        HStack {
                            Text("Original Total \(originalAmount.currencyWithDecimals(useWholeNumbers ? 0 : 2))")
                            Spacer()
                        }
                        HStack {
                            Text("Original Transaction")
                            Spacer()
                        }
                        StandardTitleTextField(symbolWidth: 26, focusedField: _focusedField, focusID: 0, showSymbol: true, parentType: XrefEnum.transaction, showTitleSuggestions: .constant(false), obj: trans)
                        
                        StandardAmountTextField(symbolWidth: 26, focusedField: _focusedField, focusID: 1, showSymbol: true, negativeOnFocusIfEmpty: trans.payMethod?.accountType != .credit, obj: trans)
                            .disabled(true)
                        
                        categoryMenu
                        
                        Divider()
                            .padding(.bottom, 12)
                    }
                    
                    
                    ForEach(additionalTrans) { newTrans in
                        TransactionLine(trans: newTrans, additionalTrans: $additionalTrans)
                        Divider()
                            .padding(.bottom, 12)
                    }
                    
                    splitButton
                }
            } header: {
                SheetHeader(title: "Split Transaction") {
                    trans.amountString = String(originalAmount)
                    showSplitSheet = false
                } view1: {
                    addTransButton
                }
            }
            .task {
                originalAmount = trans.amount
                addTrans()
            }
            .onChange(of: additionalTrans.map { $0.amount }) { oldValue, newValue in
                let newAmount = newValue.reduce(0, +)
                trans.amountString = String(originalAmount - newAmount)
            }
        }
        
        func addTrans() {
            let newTrans = CBTransaction(uuid: UUID().uuidString)
            newTrans.title = trans.title
            newTrans.date = trans.date
            newTrans.payMethod = trans.payMethod
            withAnimation {
                additionalTrans.append(newTrans)
            }
        }
        
        var addTransButton: some View {
            Button(action: addTrans) {
                Image(systemName: "plus")
            }
        }
        
        var splitButton: some View {
            Button("Perform Split") {
                showSplitSheet = false
                                
                if let day = calModel.sMonth.days.filter({ $0.dateComponents?.day == trans.dateComponents?.day }).first {
                    for each in additionalTrans {
                        day.upsert(each)
                    }
                }
                
                Task {
                    await calModel.editMultiple(trans: additionalTrans)
                }
            }
            .disabled(additionalTrans.isEmpty || additionalTrans.map { $0.amount }.contains(0))
            .buttonStyle(.borderedProminent)
        }
                
        var categoryMenu: some View {
            HStack {
                Group {
                    if lineItemIndicator == .dot {
                        Image(systemName: "books.vertical.fill")
                            .foregroundStyle((trans.category?.color ?? .gray).gradient)
                        
                    } else if let emoji = trans.category?.emoji {
                        Image(systemName: emoji)
                            .foregroundStyle((trans.category?.color ?? .gray).gradient)
                        //Text(emoji)
                    } else {
                        Image(systemName: "books.vertical.fill")
                            .foregroundStyle(.gray.gradient)
                    }
                }
                .frame(width: 26)
                
                CategorySheetButton(category: $trans.category)
            }
        }
        
        
        private struct TransactionLine: View {
            @Bindable var trans: CBTransaction
            @Binding var additionalTrans: [CBTransaction]
            
            @FocusState private var focusedField: Int?
            
            var body: some View {
                VStack {
                    HStack {
                        Text("New Transaction")
                        Spacer()
                        Button("Remove") {
                            withAnimation {
                                additionalTrans.removeAll(where: {$0.id == trans.id})
                            }
                            
                        }
                        .foregroundStyle(.red)
                    }
                    
                    StandardTitleTextField(symbolWidth: 26, focusedField: _focusedField, focusID: 0, showSymbol: true, parentType: XrefEnum.transaction, showTitleSuggestions: .constant(false), obj: trans)
                    
                    StandardAmountTextField(symbolWidth: 26, focusedField: _focusedField, focusID: 1, showSymbol: true, negativeOnFocusIfEmpty: trans.payMethod?.accountType != .credit, obj: trans)
                    
                    HStack {
                        Image(systemName: "books.vertical.fill")
                            .foregroundStyle((trans.category?.color ?? .gray).gradient)
                            .frame(width: 26)
                        
                        CategorySheetButton(category: $trans.category)
                    }
                }
            }
        }
    }
    
    
    struct SheetHeaderView: View {
        @Environment(\.dismiss) var dismiss
        @Environment(CalendarModel.self) private var calModel
            
        var title: String
        @Bindable var trans: CBTransaction
        @Binding var transEditID: String?
        var focusedField: FocusState<Int?>.Binding
        @Binding var showDeleteAlert: Bool
        var isTemp: Bool
        
        @State private var showSplitSheet = false
        
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
                view1: { theMenu },
                view3: { deleteButton }
            )
            .sheet(isPresented: $showSplitSheet) {
                TransactionSplitSheet(trans: trans, showSplitSheet: $showSplitSheet)
            }
        }
        
        var theMenu: some View {
            Menu {
                Section {
                    factorInCalculationsButton
                    if !isTemp {
                        notificationButton
                    }
                }
                
                if !isTemp {
                    Section {
                        copyButton
                        splitButton
                    }
                }
                
                Section {
                    TitleColorMenu(transactions: [trans], saveOnChange: false) {
                        Label {
                            Text("Title Color")
                        } icon: {
                            Image(systemName: "paintbrush.fill")
                                .tint(trans.color)
                        }
                    }
                }
            } label: {
                Image(systemName: "ellipsis")
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
        
        var copyButton: some View {
            Button {
                calModel.transactionToCopy = trans
                AppState.shared.showToast(title: "Transaction Copied", symbol: "doc.on.doc.fill", symbolColor: .green)
                
            } label: {
                Label {
                    Text("Copy Transaction")
                } icon: {
                    Image(systemName: "doc.on.doc.fill")
                }
            }
        }
        
        var splitButton: some View {
            Button {
                showSplitSheet = true
                
            } label: {
                Label {
                    Text("Split Transaction")
                } icon: {
                    Image(systemName: "plus.square.fill.on.square.fill")
                }
            }
        }
        
        var notificationButton: some View {
            Button {
                withAnimation {
                    if trans.notifyOnDueDate {
                        trans.notifyOnDueDate = false
                        trans.notificationOffset = nil
                    } else {
                        trans.notifyOnDueDate = true
                        trans.notificationOffset = 0
                    }
                }
            } label: {
                Label {
                    Text(trans.notifyOnDueDate ? "Cancel Notification" : "Add Notification")
                } icon: {
                    Image(systemName: trans.notifyOnDueDate ? "bell.slash.fill" : "bell.fill")
                }
            }
        }
        
        var factorInCalculationsButton: some View {
            Button {
                withAnimation {
                    trans.factorInCalculations.toggle()
                }
            } label: {
                Label {
                    Text(trans.factorInCalculations ? "Exclude from Calculations" : "Include in Calculations")
                } icon: {
                    Image(systemName: trans.factorInCalculations ? "eye.slash.fill" : "eye.fill")
                }
            }
        }
        
        func validateBeforeClosing() {
            if !trans.title.isEmpty && !trans.amountString.isEmpty && trans.payMethod == nil {
                
                if trans.payMethod == nil && (trans.isSmartTransaction ?? false) {
                    focusedField.wrappedValue = nil
                    transEditID = nil
                    dismiss()
                } else {
                    let config = AlertConfig(
                        title: "Missing Payment Method",
                        subtitle: "Please add a payment method or delete this transaction.",
                        symbol: .init(name: "creditcard.trianglebadge.exclamationmark.fill", color: .orange)
                    )
                    AppState.shared.showAlert(config: config)
                }
                
                
                
            } else {
                focusedField.wrappedValue = nil
                transEditID = nil
                dismiss()
            }
        }
    }
    
    
    struct DeleteYesButton: View {
        @Environment(CalendarModel.self) private var calModel
    
        @Environment(\.dismiss) var dismiss
        @Bindable var trans: CBTransaction
        @Binding var transEditID: String?
        var isTemp: Bool
        
        var body: some View {
            Button("Yes", role: .destructive) {
                if isTemp {
                    //transEditID = nil
                    dismiss()
                    calModel.tempTransactions.removeAll { $0.id == trans.id }
                    //let _ = DataManager.shared.delete(type: TempTransaction.self, predicate: .byId(.string(trans.id)))
                    
                    Task {
                        guard let entity = try? await DataManager.shared.getOne(type: TempTransaction.self, predicate: .byId(.string(trans.id)), createIfNotFound: true) else { return }
                        entity.action = TransactionAction.delete.rawValue
                        entity.tempAction = TransactionAction.delete.rawValue
                        let _ = await DataManager.shared.save()
                        
                    }
                    
                } else {
                    transEditID = nil
                    trans.action = .delete
                    dismiss()
                    
                    //calModel.saveTransaction(id: trans.id, day: day)
                }
            }
        }
    }
    
    
    
    // MARK: - Photo Views
//    var photoSection: some View {
//        Group {
//            @Bindable var calModel = calModel
//            @Bindable var photoModel = PhotoModel.shared
//            
//            HStack(alignment: .top) {
//                Image(systemName: "photo.fill")
//                    .foregroundColor(.gray)
//                    .frame(width: symbolWidth)
//                                
//                
//                if isTemp {
//                    Text("Photos are unavailable without internet connection.")
//                        .foregroundStyle(.gray)
//                        .italic(true)
//                    Spacer()
//                } else {
//                    
//                    /// Check for active for 1 situation only - if a photo fails to upload, we deactivate it to hide the view.
//                    if let pictures = trans.pictures?.filter({ $0.active }) {
//                        ScrollView(.horizontal, showsIndicators: false) {
//                            HStack(alignment: .top, spacing: 4) {
//                                ForEach(pictures) { pic in
//                                    VStack {
//                                        ZStack {
//                                            if pic.isPlaceholder {
//                                                PicPlaceholder(text: "Uploading…")
//                                            } else {
//                                                PicImage(pic: pic)
//                                            }
//                                            
//                                            #if os(macOS)
//                                            if vm.hoverPic == pic {
//                                                PicButtons(pic: pic, trans: trans)
//                                            }
//                                            #endif
//                                        }
//                                    }
//                                    #if os(macOS)
//                                    /// Open in safari browser
//                                    .onTapGesture {
//                                        openURL(URL(string: "https://\(Keys.baseURL):8676/pictures/budget_app.photo.\(pic.uuid).jpg")!)
//                                    }
//                                    /// Hover to show share button and delete button.
//                                    .onContinuousHover { phase in
//                                        switch phase {
//                                        case .active:
//                                            vm.hoverPic = pic
//                                        case .ended:
//                                            vm.hoverPic = nil
//                                        }
//                                    }
//                                    #else
//                                    
//                                    /// Open inline safari-sheet
//                                    .onTapGesture {
//                                        safariUrl = URL(string: "https://\(Keys.baseURL):8676/pictures/budget_app.photo.\(pic.uuid).jpg")!
//                                    }
//                                    /// Long press to show delete (no share sheet option. Can share directly from safari sheet)
//                                    .onLongPressGesture {
//                                        //buzzPhone(.warning)
//                                        vm.deletePic = pic
//                                        vm.showDeletePicAlert = true
//                                    }
//                                    .sensoryFeedback(.warning, trigger: vm.showDeletePicAlert) { oldValue, newValue in
//                                        !oldValue && newValue
//                                    }
//                                    #endif
//                                }
//                                photoPickerButton
//                            }
//                        }
//                    } else {
//                        photoPickerButton
//                        Spacer()
//                    }
//                }
//            }
//            .photosPicker(isPresented: $showPhotosPicker, selection: $photoModel.imagesFromLibrary, matching: .images, photoLibrary: .shared())
//            .onChange(of: showPhotosPicker) { oldValue, newValue in
//                if !newValue {
//                    if PhotoModel.shared.imagesFromLibrary.isEmpty {
//                        calModel.cleanUpPhotoVariables()
//                    } else {
//                        PhotoModel.shared.uploadPicturesFromLibrary(delegate: calModel, photoType: XrefModel.getItem(from: .photoTypes, byEnumID: .transaction))
//                    }
//                }
//            }
//            #if os(iOS)
//            .fullScreenCover(isPresented: $showCamera) {
//                AccessCameraView(selectedImage: $photoModel.imageFromCamera)
//                    .background(.black)
//            }
//            .onChange(of: showCamera) { oldValue, newValue in
//                if !newValue {
//                    PhotoModel.shared.uploadPictureFromCamera(delegate: calModel, photoType: XrefModel.getItem(from: .photoTypes, byEnumID: .transaction))
//                }
//            }
//            #endif
//        }
//    }
//    
//    
//    var photoPickerButton: some View {
//        Group {
//            @Bindable var calModel = calModel
//            VStack(spacing: 6) {
//                Button(action: {
//                    showPhotosPicker = true
//                }, label: {
//                    RoundedRectangle(cornerRadius: 8)
//                        .fill(addPhotoButtonHoverColor2)
//                        #if os(iOS)
//                        .frame(width: photoWidth, height: (photoHeight / 2) - 3)
//                        #else
//                        .frame(width: photoWidth, height: photoHeight)
//                        #endif
//                    
//                        .overlay {
//                            VStack {
//                                Image(systemName: "photo.badge.plus")
//                                    .font(.title)
//                                Text("Library")
//                            }
//                            .foregroundStyle(.gray)
//                        }
//                })
//                .buttonStyle(.plain)
//                .onHover { isHovered in addPhotoButtonHoverColor2 = isHovered ? Color(.systemFill) : Color(.tertiarySystemFill) }
//                .focusEffectDisabled(true)
//                
//                #if os(iOS)
//                Button {
//                    showCamera = true
//                } label: {
//                    RoundedRectangle(cornerRadius: 8)
//                        .fill(addPhotoButtonHoverColor2)
//                        .frame(width: photoWidth, height: (photoHeight / 2) - 3)
//                        .overlay {
//                            VStack {
//                                Image(systemName: "camera")
//                                    .font(.title)
//                                Text("Camera")
//                            }
//                            .foregroundStyle(.gray)
//                        }
//                }
//                .buttonStyle(.plain)
//                .onHover { isHovered in addPhotoButtonHoverColor2 = isHovered ? Color(.systemFill) : Color(.tertiarySystemFill) }
//                .focusEffectDisabled(true)
//                #endif
//                
//            }
//            
//        }
//    }
//    
//                        
//    struct PicImage: View {
//        @Environment(ViewModel.self) var vw
//        var pic: CBPicture
//        
//        var body: some View {
//            @Bindable var vw = vw
//            AsyncImage(
//                //url: URL(string: "http://www.codyburnett.com:8677/budget_app.photo.\(picture.path).jpg"),
//                url: URL(string: "https://\(Keys.baseURL):8676/pictures/budget_app.photo.\(pic.uuid).jpg"),
//                content: { image in
//                    image
//                        .resizable()
//                        .frame(width: photoWidth, height: photoHeight)
//                        .aspectRatio(contentMode: .fill)
//                        .clipShape(.rect(cornerRadius: 12))
//                        //.frame(maxWidth: 300, maxHeight: 300)
//                },
//                placeholder: {
//                    PicPlaceholder(text: "Downloading…")
//                }
//            )
//            .opacity(((vw.isDeletingPic && pic.id == vw.deletePic?.id) || vw.hoverPic == pic || pic.isPlaceholder) ? 0.2 : 1)
//            .overlay(ProgressView().tint(.none).opacity(vw.isDeletingPic && pic.id == vw.deletePic?.id ? 1 : 0))
//        }
//    }
//    
//    
//    struct PicPlaceholder: View {
//        let text: String
//        var body: some View {
//            RoundedRectangle(cornerRadius: 8)
//                .fill(Color.gray.opacity(0.1))
//                .frame(width: photoWidth, height: photoHeight)
//                .overlay {
//                    VStack {
//                        ProgressView()
//                            .tint(.none)
//                        Text(text)
//                    }
//                }
//        }
//    }
//    
//    #if os(macOS)
//    struct PicButtons: View {
//        @Environment(ViewModel.self) var vm
//        var pic: CBPicture
//        var trans: CBTransaction
//        
//        var body: some View {
//            @Bindable var vm = vm
//            
//            VStack {
//                HStack {
////                    Link(destination: URL(string: "http://\(Keys.baseURL):8677/budget_app.photo.\(pic.uuid).jpg")!) {
////                        Image(systemName: "arrow.down.left.and.arrow.up.right")
////                            .frame(width: 30, height: 30)
////                            .background(RoundedRectangle(cornerRadius: 4).fill(.ultraThickMaterial))
////                    }
//                                        
//                    ShareLink(item: URL(string: "https://\(Keys.baseURL):8676/pictures/budget_app.photo.\(pic.uuid).jpg")! /*, subject: Text(trans.title), message: Text(trans.amountString)*/) {
//                        Image(systemName: "square.and.arrow.up")
//                            .frame(width: 30, height: 30)
//                            .foregroundStyle(Color.accentColor)
//                            .background(RoundedRectangle(cornerRadius: 4).fill(.ultraThickMaterial))
//                    }
//                    .buttonStyle(.plain)
//                    
//                    Button {
//                        vm.deletePic = pic
//                        vm.showDeletePicAlert = true
//                    } label: {
//                        Image(systemName: "trash")
//                            .foregroundStyle(.red)
//                            .frame(width: 30, height: 30)
//                            .background(RoundedRectangle(cornerRadius: 4).fill(.ultraThickMaterial))
//                    }
//                    .buttonStyle(.plain)
//                    
//                    //Spacer()
//                }
//                .padding(.leading, 4)
//                Spacer()
//            }
//            .padding(.top, 4)
//            
//            .opacity(vm.isDeletingPic && pic.id == vm.deletePic?.id ? 0 : 1)
//            .disabled(vm.isDeletingPic && pic.id != vm.deletePic?.id)
//        }
//    }
//    #endif
    
    
    
    
    
    // MARK: - Functions
    func prepareTransactionForEditing(isTemp: Bool) {
        /// `WARNING!` Can't do this logic in `init()` due to redraws.

        /// Clear undo history.
        UndodoManager.shared.clearHistory()
        UndodoManager.shared.commitChange(trans: trans)
        
        calModel.hilightTrans = nil
        
        /// Grab the transaction from the model or create a new one.
        /// 2/12/25 now passed in to the view
        //trans = calModel.getTransaction(by: transEditID!, from: isTemp ? .tempList : transLocation)
            
        /// Determine the title button color.
        titleColorButtonHoverColor = trans.color == .primary ? .gray : trans.color
        /// Set the transaction date to the date of the passed in day.
        
        if trans.date == nil && !(trans.isSmartTransaction ?? false) {
            trans.date = day.date!
        }
        
        /// Just for formatting.
        trans.amountString = trans.amount.currencyWithDecimals(useWholeNumbers ? 0 : 2)
                
        /// Set a reference to the transactions ID so photos know where to go.
        //calModel.pictureTransactionID = trans.id
        PhotoModel.shared.pictureParent = PictureParent(id: trans.id, type: XrefModel.getItem(from: .photoTypes, byEnumID: .transaction))

        /// If the transaction is new.
        if trans.action == .add && !isTemp {
            trans.amountString = ""
            
            trans.category = catModel.categories.filter { $0.isNil }.first!
            
            if calModel.isUnifiedPayMethod {
                /// If the unified editing payment method is set, use it.
                
                if calModel.sPayMethod?.accountType == .unifiedChecking {
                    if payModel.paymentMethods.filter({ $0.isEditingDefault }).first?.accountType == .checking {
                        trans.payMethod = payModel.paymentMethods.filter { $0.isEditingDefault }.first
                    }
                }
                
                if calModel.sPayMethod?.accountType == .unifiedCredit {
                    if payModel.paymentMethods.filter({ $0.isEditingDefault }).first?.accountType == .credit {
                        trans.payMethod = payModel.paymentMethods.filter { $0.isEditingDefault }.first
                    }
                }
                
            } else {
                /// Add the selected viewing payment method to the transaction.
                trans.payMethod = calModel.sPayMethod
            }
            /// Pre-add the transaction to the day so we can add photos to it before saving. Get's removed on cancel if title and payment method are blank.
            day.upsert(trans)
            
        } else if trans.tempAction == .add && isTemp {
            calModel.tempTransactions.append(trans)
            trans.amountString = ""
            trans.payMethod = nil
            trans.action = .add
        }
        
        if !trans.trackingNumber.isEmpty || !trans.orderNumber.isEmpty || !trans.url.isEmpty {
            showTrackingOrderAndUrlFields = true
        }
                        
        /// Copy it so we can compare for smart saving.
        trans.deepCopy(.create)
                
        #if os(macOS)
        /// Focus on the title textfield.
        focusedField = 0
        #else
        if (trans.action == .add && !isTemp) || (trans.tempAction == .add && isTemp) {
            //print("should run")
            //trans.title = "Hey"
            focusedField = 0
        }
        #endif
        
        
        /// Remove the date from the deepCopy if editing from a smart transaction that has a date as a problem.
        /// Today's date gets assigned by default when the trans date is nil, so if the date is the only issue, the save function won't see the trans as being valid to save.
        /// By removing the date from the deepCopy, it causes the trans and it's deep copy to fail the equatble check, which will make the app save the transaction.
//        if (trans.isSmartTransaction ?? false) && (trans.smartTransactionIssue?.enumID == .missingDate || trans.smartTransactionIssue?.enumID == .missingPaymentMethodAndDate)  {
//            trans.deepCopy?.date = nil
//        }
        
        
        calModel.transEditID = transEditID
    }
    
    
//    func deletePicture() {
//        Task {
//            vm.isDeletingPic = true
//            let _ = await calModel.delete(picture: vm.deletePic!)
//            vm.isDeletingPic = false
//            vm.deletePic = nil
//        }
//    }
}
