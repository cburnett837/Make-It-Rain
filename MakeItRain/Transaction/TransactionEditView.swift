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


fileprivate let photoWidth: CGFloat = 125
fileprivate let photoHeight: CGFloat = 200


struct TransactionEditView: View {
    @Observable
    class ViewModel {
        var hoverPic: CBPicture?
        var deletePic: CBPicture?
        var isDeletingPic = false
        var showDeletePicAlert = false
    }
    
    //@Environment(\.dismiss) var dismiss <--- NO NICE THAT ONE WITH SHEETS IN A SHEET.
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("appColorTheme") var appColorTheme: String = Color.blue.description
    @AppStorage("lineItemIndicator") var lineItemIndicator: LineItemIndicator = .emoji
    @AppStorage("useWholeNumbers") var useWholeNumbers = false

    #if os(macOS)
    @Environment(\.openURL) var openURL
    #endif
    @Environment(CalendarModel.self) private var calModel
    @Environment(PayMethodModel.self) private var payModel
    @Environment(CategoryModel.self) private var catModel
    @Environment(KeywordModel.self) private var keyModel
    //@Environment(TagModel.self) private var tagModel
    
    @State private var vm = ViewModel()
    
    @State private var titleColorButtonHoverColor: Color = .gray
    @State private var payMethodMenuColor: Color = Color(.tertiarySystemFill)
    @State private var categoryMenuColor: Color = Color(.tertiarySystemFill)
    @State private var addPhotoButtonHoverColor: Color = .gray
    @State private var addPhotoButtonHoverColor2: Color = Color(.tertiarySystemFill)
        
    @FocusState private var focusedField: Int?
    
    @Bindable var trans: CBTransaction
    @Binding var transEditID: String?
    @Bindable var day: CBDay
    var isTemp: Bool
    var transLocation: WhereToLookForTransaction = .normalList
    
    var title: String { trans.action == .add ? "New Transaction" : "Edit Transaction" }
    let symbolWidth: CGFloat = 26
        
    @State private var safariUrl: URL?
    
    //@State private var totalHeight = CGFloat.zero
    @State private var showLogSheet = false
    @State private var showTagSheet = false
    @State private var showPaymentMethodSheet = false
    @State private var showCategorySheet = false
    @State private var showPaymentMethodChangeAlert = false
    @State private var showDeleteAlert = false
    
    @State private var blockUndoCommitOnLoad = true
    @State private var blockKeywordChangeWhenViewLoads = true
    @State private var showTrackingOrderAndUrlFields = false
    @State private var showPhotosPicker = false
    @State private var showCamera = false
    
    @State private var titleChangedTask: Task<Void, Error>?
    @State private var amountChangedTask: Task<Void, Error>?
    
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
        
        SheetContainerView {
            titleTextField
            amountTextField
            
            StandardDivider()
            
            paymentMethodMenu
            categoryMenu
            
            StandardDivider()
            
            #if os(iOS)
            datePickerSection
            
            StandardDivider()
            #endif
            
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
                photoSection
                StandardDivider()
            }
                                    
            notes
            
            StandardDivider()
            
            if !isTemp {
                logs
                StandardDivider()
            }
                                    
            alteredBy
                #if os(macOS)
                .padding(.bottom, 12)
                #else
                .if(AppState.shared.isIpad) {
                    $0.padding(.bottom, 12)
                }
                #endif
        } header: {
            SheetHeaderView(title: title, trans: trans, transEditID: $transEditID, focusedField: $focusedField, showDeleteAlert: $showDeleteAlert)
        } footer: {
            if let linkedLingo {
                Text(linkedLingo)
                   .font(.caption2)
                   .foregroundStyle(.gray)
            }
        }
        .interactiveDismissDisabled(paymentMethodMissing)
        .environment(vm)
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
        
        .confirmationDialog("Delete this picture?", isPresented: $vm.showDeletePicAlert) {
            Button("Yes", role: .destructive) {
                deletePicture()
            }
            Button("No", role: .cancel) {
                vm.hoverPic = nil
                vm.deletePic = nil
            }
        } message: {
            Text("Delete this picture?")
        }
                                
        #if os(iOS)
        .sheet(item: $safariUrl) { SFSafariView(url: $0) }
        #endif
//        .alert(AppState.shared.alertText, isPresented: $appState.showAlert) {
//            if let function = AppState.shared.alertFunction {
//                Button(AppState.shared.alertButtonText, action: function)
//            }
//            if let function = AppState.shared.alertFunction2 {
//                Button(AppState.shared.alertButtonText2, action: function)
//            } else {
//                Button("Close", action: {})
//            }
//        }
        // MARK: - Undo Stuff
        #if os(iOS)
        .onShake {
            UndodoManager.shared.getChangeFields(trans: trans)            
            UndodoManager.shared.showAlert = true
        }
//        .alert("Undo / Redo", isPresented: $showUndoRedoAlert) {
//            VStack {
//                if UndodoManager.shared.canUndo {
//                    Button {
//                        if let old = UndodoManager.shared.undo(trans: trans) {
//                            UndodoManager.shared.returnMe = old
//                        }
//                    } label: {
//                        Text("Undo \(UndodoManager.shared.undoField)")
//                    }
//                }
//                
//                if UndodoManager.shared.canRedo {
//                    Button {
//                        if let new = UndodoManager.shared.redo(trans: trans) {
//                            UndodoManager.shared.returnMe = new
//                        }
//                    } label: {
//                        Text("Redo \(UndodoManager.shared.redoField)")
//                    }
//                }
//                
//                Button(role: .cancel) {
//                    print(UndodoManager.shared.history)
//                } label: {
//                    Text("Cancel")
//                }
//            }
//        }
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
        .onChange(of: trans.title) { UndodoManager.shared.processChange(trans: trans) }
        .onChange(of: trans.amountString) { UndodoManager.shared.processChange(trans: trans) }
        .onChange(of: trans.payMethod) { UndodoManager.shared.processChange(trans: trans) }
        .onChange(of: trans.category) { UndodoManager.shared.processChange(trans: trans) }
        //.onChange(of: trans.date) { UndodoManager.shared.commitChange(trans: trans) }
        .onChange(of: trans.trackingNumber) { UndodoManager.shared.processChange(trans: trans) }
        .onChange(of: trans.orderNumber) { UndodoManager.shared.processChange(trans: trans) }
        .onChange(of: trans.url) { UndodoManager.shared.processChange(trans: trans) }
        .onChange(of: trans.notes) { UndodoManager.shared.processChange(trans: trans) }
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
        #endif
    }
               
    
    
    
    // MARK: - SubViews
    var titleTextField: some View {
        HStack {
            #if os(macOS)
            Image(systemName: "bag.fill")
            //Image(systemName: trans.color == .primary ? "lightspectrum.horizontal" : "bag.fill")
                .foregroundColor(titleColorButtonHoverColor)
                .frame(width: symbolWidth)
                //.symbolRenderingMode(.multicolor)
                .contentShape(Rectangle())
                .overlay {
                    TitleColorMenu(trans: trans, saveOnChange: false) {
                        EmptyView()
                    }
                    .menuStyle(.borderlessButton)
                    .menuIndicator(.hidden)
                    .onTapGesture {
                        ChangeTransactionTitleColorTip.didTouchColorChangeButton = true
                    }
                    //.padding(.leading, 4)
                }
                .onHover { isHovering in titleColorButtonHoverColor = isHovering ? (trans.color == Color.accentColor ? .white : Color.accentColor) : ((trans.color == .white || trans.color == .primary) ? .gray : trans.color) }
                .padding(.leading, 1)
                .popoverTip(changeTransactionTitleColorTip)
                //.focusEffectDisabled(true)
            
            #else
            TitleColorMenu(trans: trans, saveOnChange: false) {
                Image(systemName: "bag.fill")
                //Image(systemName: trans.color == .primary ? "lightspectrum.horizontal" :"bag.fill")
                    .foregroundColor(trans.color == .primary ? .gray : trans.color)
                    .frame(width: symbolWidth)
                    .onTapGesture {
                        ChangeTransactionTitleColorTip.didTouchColorChangeButton = true
                    }
                    //.symbolRenderingMode(.multicolor)
            }
            .popoverTip(changeTransactionTitleColorTip)
            #endif
            
            Group {
                #if os(iOS)
                
                StandardUITextField("Title", text: $trans.title, onSubmit: {
                    focusedField = 1
                }, toolbar: {
                    KeyboardToolbarView(focusedField: $focusedField)
                })
                .cbClearButtonMode(.whileEditing)
                .cbFocused(_focusedField, equals: 0)
                .cbSubmitLabel(.next)
                .overlay {
                    if !trans.factorInCalculations {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(.red, lineWidth: 4)
                    }
                }
                
                #else
                StandardTextField("Title", text: $trans.title, focusedField: $focusedField, focusValue: 0)
                    .onSubmit { focusedField = 1 }
                    .overlay {
                        if !trans.factorInCalculations {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(.red, lineWidth: 4)
                        }
                    }
                #endif
            }
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
    }
    
    
    var amountTextField: some View {
        HStack(alignment: .circleAndTitle) {
            Image(systemName: "dollarsign.circle.fill")
                .foregroundColor(.gray)
                .frame(width: symbolWidth)
                .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
            
            VStack(alignment: .leading, spacing: 0) {
                Group {
                    #if os(iOS)
                    StandardUITextField("Amount", text: $trans.amountString, toolbar: {
                        KeyboardToolbarView(
                            focusedField: $focusedField,
                            accessoryImage3: "plus.forwardslash.minus",
                            accessoryFunc3: {
                                Helpers.plusMinus($trans.amountString)
                            })
                    })
                    .cbClearButtonMode(.whileEditing)
                    .cbFocused(_focusedField, equals: 1)
                    .cbKeyboardType(useWholeNumbers ? .numberPad : .decimalPad)
                    //.cbTextfieldInputType(.currency)                    
//                    .onChange(of: trans.amountString) {
//                        Helpers.liveFormatCurrency(oldValue: $0, newValue: $1, text: $trans.amountString)
//                    }
//                    .onChange(of: focusedField) {
//                        if let string = Helpers.formatCurrency(focusValue: 1, oldFocus: $0, newFocus: $1, amountString: trans.amountString, amount: trans.amount) {
//                            trans.amountString = string
//                        }
//                    }
//
//
//                    .onChange(of: focusedField) { oldValue, newValue in
//                        if newValue == 1 {
//                            if trans.amount == 0.0 {
//                                trans.amountString = ""
//                            }
//                        } else {
//                            if oldValue == 1 && !trans.amountString.isEmpty {
//                                if trans.amountString == "$" || trans.amountString == "-$" {
//                                    trans.amountString = ""
//                                } else {
//                                    trans.amountString = trans.amount.currencyWithDecimals(useWholeNumbers ? 0 : 2)
//                                }
//                            }
//                        }
//                    }
//                    .onChange(of: trans.amountString) { oldValue, newValue in
//                        if trans.amountString != "-" {
//                            if trans.amount == 0.0 {
//                                trans.amountString = ""
//                            } else {
//                                trans.amountString = trans.amount.currencyWithDecimals(useWholeNumbers ? 0 : 2)
//                            }
//                        }
//                    }
                    #else
                    StandardTextField("Amount", text: $trans.amountString, focusedField: $focusedField, focusValue: 1)
                    #endif
                }
                .formatCurrencyLiveAndOnUnFocus(
                    focusValue: 1,
                    focusedField: focusedField,
                    amountString: trans.amountString,
                    amountStringBinding: $trans.amountString,
                    amount: trans.amount
                )
                .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
                
                (Text("Transaction Type: ") + Text(transTypeLingo).bold(true).foregroundStyle(Color.fromName(appColorTheme)))
                    .foregroundStyle(.gray)
                    .font(.caption)
                    .multilineTextAlignment(.leading)
                    .padding(.leading, 6)
                    .disabled(trans.amountString.isEmpty)
                    .onTapGesture {
                        Helpers.plusMinus($trans.amountString)
                        
                        /// Just do on Mac because the calendar view is still visable.
                        #if os(macOS)
                        calModel.calculateTotalForMonth(month: calModel.sMonth)
                        #endif
                    }
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
                            Text("Add Tracking/Order Numbers")
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
        HStack(alignment: .circleAndTitle) {
            Image(systemName: "network")
                .foregroundColor(.gray)
                .frame(width: symbolWidth)
                .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
                     
            VStack(alignment: .leading) {
                HStack {
                    #if os(iOS)
                    StandardUITextField("URL", text: $trans.url, onSubmit: {
                        focusedField = nil
                    }, toolbar: {
                        KeyboardToolbarView(focusedField: $focusedField)
                    })
                    .cbClearButtonMode(.whileEditing)
                    .cbFocused(_focusedField, equals: 4)
                    .cbAutoCorrectionDisabled(true)
                    .cbKeyboardType(.URL)
                    #else
                    StandardTextField("URL", text: $trans.url, focusedField: $focusedField, focusValue: 4)
                        .autocorrectionDisabled(true)
                        .onSubmit { focusedField = nil }
                    #endif
                    
                    if let url = URL(string: trans.url) {
                        Link(destination: url) {
                            Image(systemName: "safari")
                        }
                    }
                }
                .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
                                
                if trans.trackingNumber.isEmpty && trans.orderNumber.isEmpty && trans.url.isEmpty {
                    Button {
                        withAnimation {
                            showTrackingOrderAndUrlFields = false
                        }
                    } label: {
                        Text("Hide")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding(.bottom, 6)
    }
    
    
    var datePickerSection: some View {
        HStack {
            Image(systemName: "calendar")
                .foregroundColor(.gray)
                .frame(width: symbolWidth)
            
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
            
            PaymentMethodSheetButton(payMethod: $trans.payMethod, trans: trans, saveOnChange: false, whichPaymentMethods: .allExceptUnified)
        }        
    }
    
    
    var categoryMenu: some View {
        HStack(alignment: .circleAndTitle) {
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
            .frame(width: symbolWidth)
            .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
            
            VStack(alignment: .leading, spacing: 0) {
                CategorySheetButton(category: $trans.category)
                    /// Initial undo handled inside the button.
                    .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
                
                if trans.category != nil {
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
                                        .foregroundStyle(Color.fromName(appColorTheme))
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
    
    
    var notes: some View {
        HStack(alignment: .top) {
            Image(systemName: "note.text")
                .foregroundColor(.gray)
                .frame(width: symbolWidth)
            
            
//            UITextEditorWrapper(placeholder: "Notes…", text: $trans.notes, toolbar: {
//                KeyboardToolbarView(focusedField: $focusedField)
//            })
            
            TextEditor(text: $trans.notes)
                .foregroundStyle(trans.notes.isEmpty ? .gray : .primary)
                .scrollContentBackground(.hidden)
                .background(.clear)
                .frame(minHeight: 100)
                .focused($focusedField, equals: showTrackingOrderAndUrlFields ? 5 : 2)
                #if os(iOS)
                .offset(y: -10)
                #else
                .offset(y: 1)
                #endif
                .overlay {
                    Text("Notes…")
                        .foregroundStyle(.gray)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .opacity(!trans.notes.isEmpty || focusedField == (showTrackingOrderAndUrlFields ? 5 : 2) ? 0 : 1)
                        .allowsHitTesting(false)
                        #if os(iOS)
                        .padding(.top, -2)
                        #else
                        .offset(y: -1)
                        #endif
                        .padding(.leading, 0)
                }
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
    }
    
    
    
    
    struct SheetHeaderView: View {
        @Environment(\.dismiss) var dismiss
        @Environment(CalendarModel.self) private var calModel
        
        var title: String
        @Bindable var trans: CBTransaction
        @Binding var transEditID: String?
        var focusedField: FocusState<Int?>.Binding
        @Binding var showDeleteAlert: Bool
        
        
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
        }
        
        var theMenu: some View {
            Menu {
                Section {
                    factorInCalculationsButton
                    notificationButton
                }
                
                Section {
                    copyButton
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
        
        var notificationButton: some View {
            Button {
                withAnimation { trans.notifyOnDueDate.toggle() }
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
                withAnimation { trans.factorInCalculations.toggle() }
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
                let config = AlertConfig(
                    title: "Missing Payment Method",
                    subtitle: "Please add a payment method or delete this transaction.",
                    symbol: .init(name: "creditcard.trianglebadge.exclamationmark.fill", color: .orange)
                )
                AppState.shared.showAlert(config: config)
                
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
                    
                    guard let entity = DataManager.shared.getOne(type: TempTransaction.self, predicate: .byId(.string(trans.id)), createIfNotFound: true) else { return }
                    entity.action = TransactionAction.delete.rawValue
                    entity.tempAction = TransactionAction.delete.rawValue
                    let _ = DataManager.shared.save()
                    
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
    var photoSection: some View {
        Group {
            @Bindable var calModel = calModel
            
            HStack(alignment: .top) {
                Button {
                    showCamera = true
                } label: {
                    Image(systemName: "photo.fill")
                        .foregroundColor(addPhotoButtonHoverColor)
                        .frame(width: symbolWidth)
                }

//                PhotosPicker(selection: $calModel.imageSelection, matching: .images, photoLibrary: .shared()) {
//                    Image(systemName: "photo.fill")
//                        .foregroundColor(addPhotoButtonHoverColor)
//                        .frame(width: symbolWidth)
//
//                }
                .buttonStyle(.plain)
                .onHover { isHovered in addPhotoButtonHoverColor = isHovered ? Color.accentColor : .gray }
                .focusEffectDisabled(true)
                    
                
                if isTemp {
                    Text("Photos are unavailable without internet connection.")
                        .foregroundStyle(.gray)
                        .italic(true)
                    Spacer()
                } else {
                    
                    /// Check for active for 1 situation only - if a photo fails to upload, we deactivate it to hide the view.
                    if let pictures = trans.pictures?.filter({ $0.active }) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(alignment: .top, spacing: 4) {
                                ForEach(pictures) { pic in
                                    VStack {
                                        ZStack {
                                            if pic.isPlaceholder {
                                                PicPlaceholder(text: "Uploading…")
                                            } else {
                                                PicImage(pic: pic)
                                            }
                                            
                                            #if os(macOS)
                                            if vm.hoverPic == pic {
                                                PicButtons(pic: pic, trans: trans)
                                            }
                                            #endif
                                        }
                                    }
                                    #if os(macOS)
                                    /// Open in safari browser
                                    .onTapGesture {
                                        openURL(URL(string: "https://\(Keys.baseURL):8676/pictures/budget_app.photo.\(pic.uuid).jpg")!)
                                    }
                                    /// Hover to show share button and delete button.
                                    .onContinuousHover { phase in
                                        switch phase {
                                        case .active:
                                            vm.hoverPic = pic
                                        case .ended:
                                            vm.hoverPic = nil
                                        }
                                    }
                                    #else
                                    
                                    /// Open inline safari-sheet
                                    .onTapGesture {
                                        safariUrl = URL(string: "https://\(Keys.baseURL):8676/pictures/budget_app.photo.\(pic.uuid).jpg")!
                                    }
                                    /// Long press to show delete (no share sheet option. Can share directly from safari sheet)
                                    .onLongPressGesture {
                                        //buzzPhone(.warning)
                                        vm.deletePic = pic
                                        vm.showDeletePicAlert = true
                                    }
                                    .sensoryFeedback(.warning, trigger: vm.showDeletePicAlert) { oldValue, newValue in
                                        !oldValue && newValue
                                    }
                                    #endif
                                }
                                photoPickerButton
                            }
                        }
                    } else {
                        photoPickerButton
                        Spacer()
                    }
                }
            }
            .photosPicker(isPresented: $showPhotosPicker, selection: $calModel.imagesFromLibrary, matching: .images, photoLibrary: .shared())
            .onChange(of: showPhotosPicker) { oldValue, newValue in
                if !newValue { calModel.uploadPictures() }
            }
            #if os(iOS)
            .fullScreenCover(isPresented: $showCamera) {
                AccessCameraView(selectedImage: $calModel.imageFromCamera)
                    .background(.black)
            }
            #endif
        }
    }
    
    
    var photoPickerButton: some View {
        Group {
            @Bindable var calModel = calModel
            VStack(spacing: 6) {
//                PhotosPicker(selection: $calModel.imageFromLibrary, matching: .images, photoLibrary: .shared()) {
//                    RoundedRectangle(cornerRadius: 12)
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
//                }
                Button(action: {
                    showPhotosPicker = true
                }, label: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(addPhotoButtonHoverColor2)
                        #if os(iOS)
                        .frame(width: photoWidth, height: (photoHeight / 2) - 3)
                        #else
                        .frame(width: photoWidth, height: photoHeight)
                        #endif
                    
                        .overlay {
                            VStack {
                                Image(systemName: "photo.badge.plus")
                                    .font(.title)
                                Text("Library")
                            }
                            .foregroundStyle(.gray)
                        }
                })
                .buttonStyle(.plain)
                .onHover { isHovered in addPhotoButtonHoverColor2 = isHovered ? Color(.systemFill) : Color(.tertiarySystemFill) }
                .focusEffectDisabled(true)
                
                #if os(iOS)
                Button {
                    showCamera = true
                } label: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(addPhotoButtonHoverColor2)
                        .frame(width: photoWidth, height: (photoHeight / 2) - 3)
                        .overlay {
                            VStack {
                                Image(systemName: "camera")
                                    .font(.title)
                                Text("Camera")
                            }
                            .foregroundStyle(.gray)
                        }
                }
                .buttonStyle(.plain)
                .onHover { isHovered in addPhotoButtonHoverColor2 = isHovered ? Color(.systemFill) : Color(.tertiarySystemFill) }
                .focusEffectDisabled(true)
                #endif
                
            }
            
        }
    }
    
                        
    struct PicImage: View {
        @Environment(ViewModel.self) var vw
        var pic: CBPicture
        
        var body: some View {
            @Bindable var vw = vw
            AsyncImage(
                //url: URL(string: "http://www.codyburnett.com:8677/budget_app.photo.\(picture.path).jpg"),
                url: URL(string: "https://\(Keys.baseURL):8676/pictures/budget_app.photo.\(pic.uuid).jpg"),
                content: { image in
                    image
                        .resizable()
                        .frame(width: photoWidth, height: photoHeight)
                        .aspectRatio(contentMode: .fill)
                        .clipShape(.rect(cornerRadius: 12))
                        //.frame(maxWidth: 300, maxHeight: 300)
                },
                placeholder: {
                    PicPlaceholder(text: "Downloading…")
                }
            )
            .opacity(((vw.isDeletingPic && pic.id == vw.deletePic?.id) || vw.hoverPic == pic || pic.isPlaceholder) ? 0.2 : 1)
            .overlay(ProgressView().tint(.none).opacity(vw.isDeletingPic && pic.id == vw.deletePic?.id ? 1 : 0))
        }
    }
    
    
    struct PicPlaceholder: View {
        let text: String
        var body: some View {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.1))
                .frame(width: photoWidth, height: photoHeight)
                .overlay {
                    VStack {
                        ProgressView()
                            .tint(.none)
                        Text(text)
                    }
                }
        }
    }
    
    #if os(macOS)
    struct PicButtons: View {
        @Environment(ViewModel.self) var vm
        var pic: CBPicture
        var trans: CBTransaction
        
        var body: some View {
            @Bindable var vm = vm
            
            VStack {
                HStack {
//                    Link(destination: URL(string: "http://\(Keys.baseURL):8677/budget_app.photo.\(pic.uuid).jpg")!) {
//                        Image(systemName: "arrow.down.left.and.arrow.up.right")
//                            .frame(width: 30, height: 30)
//                            .background(RoundedRectangle(cornerRadius: 4).fill(.ultraThickMaterial))
//                    }
                                        
                    ShareLink(item: URL(string: "https://\(Keys.baseURL):8676/pictures/budget_app.photo.\(pic.uuid).jpg")! /*, subject: Text(trans.title), message: Text(trans.amountString)*/) {
                        Image(systemName: "square.and.arrow.up")
                            .frame(width: 30, height: 30)
                            .foregroundStyle(Color.accentColor)
                            .background(RoundedRectangle(cornerRadius: 4).fill(.ultraThickMaterial))
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        vm.deletePic = pic
                        vm.showDeletePicAlert = true
                    } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(.red)
                            .frame(width: 30, height: 30)
                            .background(RoundedRectangle(cornerRadius: 4).fill(.ultraThickMaterial))
                    }
                    .buttonStyle(.plain)
                    
                    //Spacer()
                }
                .padding(.leading, 4)
                Spacer()
            }
            .padding(.top, 4)
            
            .opacity(vm.isDeletingPic && pic.id == vm.deletePic?.id ? 0 : 1)
            .disabled(vm.isDeletingPic && pic.id != vm.deletePic?.id)
        }
    }
    #endif
    
    
    
    
    
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
        
        if trans.date == nil {
            trans.date = day.date!
        }
        
        /// Just for formatting.
        trans.amountString = trans.amount.currencyWithDecimals(useWholeNumbers ? 0 : 2)
                
        /// Set a reference to the transactions ID so photos know where to go.
        calModel.pictureTransactionID = trans.id

        /// If the transaction is new.
        if trans.action == .add && !isTemp {
            trans.amountString = ""
            if calModel.isUnifiedPayMethod {
                /// Require the user to pick a payment method if in a unified view.
                /// trans.payMethod = nil
            } else {
                /// Add the selected viewing payment method to the transaction.
                trans.payMethod = calModel.sPayMethod// ?? CBPaymentMethod()
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
        
        calModel.transEditID = transEditID
    }
    
    
    func deletePicture() {
        Task {
            vm.isDeletingPic = true
            let _ = await calModel.delete(picture: vm.deletePic!)
            vm.isDeletingPic = false
            vm.deletePic = nil
        }
    }
}



















