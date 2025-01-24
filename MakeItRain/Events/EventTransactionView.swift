//
//  TransactionEditViewBackuo.swift
//  MakeItRain
//
//  Created by Cody Burnett on 1/21/25.
//

import Foundation
import SwiftUI
import PhotosUI
import SafariServices
import TipKit


struct FakeTransEditView: View {
    @AppStorage("useWholeNumbers") var useWholeNumbers = false
    
    @Environment(\.dismiss) var dismiss
    
    @Bindable var trans: CBEventTransaction
    @Bindable var item: CBEventItem
    @Bindable var event: CBEvent
    
    @State private var showDeleteAlert = false
    @State private var showUserSheet = false
    @State private var showPaymentMethodSheet = false
    @State private var showCategorySheet = false
    
    @FocusState private var focusedField: Int?
    
    var title: String { trans.action == .add ? "New Transaction" : "Edit Transaction" }
        
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
                close: { dismiss() },
                view3: { deleteButton }
            )
            .padding()
            
            Divider()
                .padding(.horizontal)
        }
    }
    
    
    var body: some View {
        VStack(spacing: 0) {
            header
            List {
                HStack {
                    Text("Title")
                    Spacer()
                    #if os(iOS)
                    UITextFieldWrapperFancy(placeholder: "Transaction Title", text: $trans.title, toolbar: {
                        KeyboardToolbarView(focusedField: $focusedField)
                    })
                    .uiTag(0)
                    .uiTextAlignment(.right)
                    .uiClearButtonMode(.whileEditing)
                    .uiStartCursorAtEnd(true)
                    #else
                    TextField("Transaction Title", text: $trans.title)
                        .multilineTextAlignment(.trailing)
                    #endif
                }
                .focused($focusedField, equals: 0)
                
                HStack {
                    Text("Amount")
                    Spacer()
                    
                    #if os(iOS)
                    UITextFieldWrapperFancy(placeholder: "Total", text: $trans.amountString, toolbar: {
                        KeyboardToolbarView(
                            focusedField: $focusedField,
                            accessoryImage3: "plus.forwardslash.minus",
                            accessoryFunc3: {
                                Helpers.plusMinus($trans.amountString)
                            })
                    })
                    .uiKeyboardType(useWholeNumbers ? .numberPad : .decimalPad)
                    .uiTag(1)
                    .uiTextAlignment(.right)
                    .uiClearButtonMode(.whileEditing)
                    .uiStartCursorAtEnd(true)
                    #else
                    TextField("Budget", text: $trans.amountString ?? "")
                        .multilineTextAlignment(.trailing)
                    #endif
                }
                .focused($focusedField, equals: 1)
                
                HStack {
                    Text("Date")
                    Spacer()
                    DatePicker("", selection: $trans.date ?? Date(), displayedComponents: [.date])
                        .labelsHidden()
                    
                }
                
                HStack {
                    Text("Who Paid")
                    Spacer()
                    
                    Button(trans.paidBy?.name ?? "Select Payee") {
                        showUserSheet = true
                    }
                    
                }
                
                HStack {
                    Text("Status")
                    Spacer()
                    Menu("\(trans.status.description)") {
                        ForEach(XrefModel.eventTransactionStatuses) { status in
                            Button(status.description) {
                                trans.status = status
                                trans.paidBy = AppState.shared.user!
                            }
                        }
                    }
                }
                
                if trans.status.enumID == .claimed {
                    HStack {
                        Text("Payment Method")
                        Spacer()
                        Button((trans.realTransaction.payMethod == nil ? "Select" : trans.realTransaction.payMethod?.title) ?? "Select") {
                            showPaymentMethodSheet = true
                        }
                    }
                    .sheet(isPresented: $showPaymentMethodSheet) {
                        PaymentMethodSheet(payMethod: $trans.realTransaction.payMethod, whichPaymentMethods: .allExceptUnified)
                        #if os(macOS)
                            .frame(minWidth: 300, minHeight: 500)
                            .presentationSizing(.fitted)
                        #endif
                    }
                    
                    HStack {
                        Text("Category")
                        Spacer()
                    }
                }
                
            }
        }
        .task {
            if trans.date == nil {
                trans.date = Date()
            }
            
            item.upsert(trans)
        }
        .confirmationDialog("Delete \"\(trans.title)\"?", isPresented: $showDeleteAlert, actions: {
            Button("Yes", role: .destructive) {
                dismiss()
                item.deleteTransaction(id: trans.id)
            }
            
            Button("No", role: .cancel) {
                showDeleteAlert = false
            }
        }, message: {
            #if os(iOS)
            Text("Delete \"\(trans.title)\"?\nThis will not delete any associated transactions.")
            #else
            Text("This will not delete any associated transactions.")
            #endif
        })
        .sheet(isPresented: $showUserSheet) {
            UserSheet(selectedUser: $trans.paidBy, availableUsers: event.participants.map { $0.user })
            #if os(macOS)
                .frame(minWidth: 300, minHeight: 500)
                .presentationSizing(.fitted)
            #endif
        }

    }
}




fileprivate let photoWidth: CGFloat = 125
fileprivate let photoHeight: CGFloat = 200

struct EventTransactionEditViewACTUAL: View {
    @Observable
    class ViewModel {
        var hoverPic: CBPicture?
        var deletePic: CBPicture?
        var isDeletingPic = false
        var showDeletePicAlert = false
    }
    
    //@Environment(\.dismiss) var dismiss <--- NO NICE THAT ONE WITH SHEETS IN A SHEET.
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("appColorTheme") var appColorTheme: String = Color.green.description
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
    @State private var trans = CBTransaction()
    
    @State private var titleColorButtonHoverColor: Color = .gray
    @State private var payMethodMenuColor: Color = Color(.tertiarySystemFill)
    @State private var categoryMenuColor: Color = Color(.tertiarySystemFill)
    @State private var addPhotoButtonHoverColor: Color = .gray
    @State private var addPhotoButtonHoverColor2: Color = Color(.tertiarySystemFill)
        
    @FocusState private var focusedField: Int?
    
    var transEditID: String?
    @Bindable var day: CBDay
    var isTemp: Bool
    var transLocation: WhereToLookForTransaction = .normalList
    
    var title: String { return trans.action == .add ? "New Transaction" : "Edit Transaction" }
    let symbolWidth: CGFloat = 26
        
    @State private var safariUrl: URL?
    
    //@State private var totalHeight = CGFloat.zero
    @State private var showLogSheet = false
    @State private var showTagSheet = false
    @State private var showPaymentMethodSheet = false
    @State private var showCategorySheet = false
    @State private var showPaymentMethodChangeAlert = false
    @State private var showDeleteAlert = false
    //@State private var showErrorAlert = false
    
    @State private var blockKeywordChangeWhenViewLoads = true
    @State private var showCamera = false
    @State private var showTrackingOrderAndUrlFields = false
    
    //@State private var keyboardHeight: CGFloat = 0
    //@State private var offset: CGFloat = 100
    
    
    let changeTransactionTitleColorTip = ChangeTransactionTitleColorTip()
    
    var transTypeLingo: String {
        if trans.payMethod?.accountType == .credit {
            trans.amountString.contains("-") ? "Payment" : "Expense"
        } else {
            trans.amountString.contains("-") ? "Expense" : "Income"
        }
    }
    
    var header: some View {
        Group {
            SheetHeaderView(title: title, trans: trans, focusedField: $focusedField, showDeleteAlert: $showDeleteAlert)
                .padding()
            
            Divider()
                .padding(.horizontal)
        }
    }
    
    var body: some View {
        //let _ = Self._printChanges()
        @Bindable var calModel = calModel
        @Bindable var payModel = payModel
        @Bindable var catModel = catModel
        @Bindable var keyModel = keyModel
        
        //NavigationStack {
            VStack(spacing: 0) {
                /// There's a bug in dismiss() that causes the photo sheet to open, close, and then open again. By moving the dismiss variable into a seperate view, it doesn't affect the photo sheet anymore.
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
                            reminderSection
                                .disabled(isTemp)
                            StandardDivider()
                        }
                        
                        trackingAndOrderSection
                        StandardDivider()
                        
                        hashtags
                            .disabled(isTemp)
                                                
                        StandardDivider()
                        
                        photoSection
                            .disabled(isTemp)
                        
                        StandardDivider()
                        
                        notes
                        
                        StandardDivider()
                                                
                        logs
                            .disabled(isTemp)
                        
                        StandardDivider()
                        
                        alteredBy
                            #if os(macOS)
                            .padding(.bottom, 12)
                            #endif
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            #if os(iOS)
            .toolbar(.hidden) /// To hide the nav bar
            #endif
        //}
        
//        #if os(iOS)
//        .keyboardToolbar(
//            text:
//                focusedField == 0 ? $trans.title :
//                focusedField == 1 ? $trans.amountString :
//                focusedField == 2 ? $trans.trackingNumber :
//                focusedField == 3 ? $trans.orderNumber :
//                focusedField == 4 ? $trans.url :
//                focusedField == 5 ? $trans.notes :
//                .constant(""),
//            focusedField: $focusedField,
//            focusViews: [
//                FocusView(
//                    focusID: 1,
//                    view: AnyView(
//                        Button {
//                            trans.amountString = Helpers.plusMinus(amountString: trans.amountString)
//                        } label: {
//                            Image(systemName: "plus.forwardslash.minus")
//                                .foregroundStyle(.gray)
//                        }
//                    )
//                )
//            ]
//        )
//        #endif
        
        .environment(vm)
        .task {
            prepareTransactionForEditing(isTemp: isTemp)
            ChangeTransactionTitleColorTip.didOpenTransaction.sendDonation()
        }
        .alert("Please change the payment method by right-clicking on the line item from the main view.", isPresented: $showPaymentMethodChangeAlert) {
            Button("OK"){}
        }
        
        .confirmationDialog("Delete \"\(trans.title)\"?", isPresented: $showDeleteAlert) {
            /// There's a bug in dismiss() that causes the photo sheet to open, close, and then open again. By moving the dismiss variable into a seperate view, it doesn't affect the photo sheet anymore.
            DeleteYesButton(trans: trans, isTemp: isTemp)
                        
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
                StandardUITextFieldFancy("Title", text: $trans.title, onSubmit: {
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
                    StandardUITextFieldFancy("Amount", text: $trans.amountString, toolbar: {
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
                    .cbTextfieldInputType(.currency)
                    /// Format the amount field
                    .onChange(of: focusedField) { oldValue, newValue in
                        if newValue == 1 {
                            if trans.amount == 0.0 {
                                trans.amountString = ""
                            }
                        } else {
                            if oldValue == 1 && !trans.amountString.isEmpty {
                                if trans.amountString == "$" || trans.amountString == "-$" {
                                    trans.amountString = ""
                                } else {
                                    trans.amountString = trans.amount.currencyWithDecimals(useWholeNumbers ? 0 : 2)
                                }
                            }
                        }
                    }
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
                StandardUITextFieldFancy("Tracking Number", text: $trans.trackingNumber, onSubmit: {
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
                StandardUITextFieldFancy("Order Number", text: $trans.orderNumber, onSubmit: {
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
                    StandardUITextFieldFancy("URL", text: $trans.url, onSubmit: {
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
            
            DatePicker(selection: $trans.date ?? Date(), displayedComponents: [.date]) {
                EmptyView()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .labelsHidden()
                                                                
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
                .foregroundColor(trans.payMethod == nil ? .gray : trans.payMethod!.color)
                .frame(width: symbolWidth)
                        
            RoundedRectangle(cornerRadius: 8)
                //.stroke(.gray, lineWidth: 1)
                .fill(payMethodMenuColor)
                #if os(macOS)
                .frame(height: 27)
                #else
                .frame(height: 34)
                #endif
                .overlay {
                    MenuOrListButton(title: trans.payMethod?.title, alternateTitle: "Select Payment Method") {
                        #if os(macOS)
                        if trans.payMethod == nil || calModel.isUnifiedPayMethod {
                            showPaymentMethodSheet = true
                        } else {
                            showPaymentMethodChangeAlert = true
                        }
                        #else
                        showPaymentMethodSheet = true
                        #endif
                    }
                }
                .onHover { payMethodMenuColor = $0 ? Color(.systemFill) : Color(.tertiarySystemFill) }
        }
        .sheet(isPresented: $showPaymentMethodSheet) {
            #if os(macOS)
            PaymentMethodSheet(payMethod: $trans.payMethod, trans: trans, calcAndSaveOnChange: false, whichPaymentMethods: .basedOnSelected)
                .frame(minWidth: 300, minHeight: 500)
                .presentationSizing(.fitted)
            #else
            PaymentMethodSheet(payMethod: $trans.payMethod, trans: trans, calcAndSaveOnChange: false, whichPaymentMethods: .allExceptUnified)
            #endif
        }
    }
    
    
    var categoryMenu: some View {
        HStack(alignment: .circleAndTitle) {
            Group {
                if lineItemIndicator == .dot {
                    Image(systemName: "books.vertical.fill")
                        .foregroundStyle(trans.category?.color ?? .gray)
                } else {
                    if let emoji = trans.category?.emoji {
                        Image(systemName: emoji)
                            .foregroundStyle(trans.category?.color ?? .gray)
                        //Text(emoji)
                    } else {
                        Image(systemName: "books.vertical.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .frame(width: symbolWidth)
            .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
            
            VStack(alignment: .leading, spacing: 0) {
                CategorySheetButton(category: $trans.category)
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
            
            
            TextEditor(text: $trans.notes)
                .foregroundStyle(trans.notes.isEmpty ? .gray : .primary)
                .scrollContentBackground(.hidden)
                .background(.clear)
                .frame(minHeight: 100)
                .focused($focusedField, equals: showTrackingOrderAndUrlFields ? 5 : 2)
//                .keyboardType(.asciiCapable)
//                .autocorrectionDisabled()
                .overlay {
                    VStack {}
                    Text("Notes…")
                        .foregroundStyle(.gray)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .opacity(!trans.notes.isEmpty || focusedField == (showTrackingOrderAndUrlFields ? 5 : 2) ? 0 : 1)
                        .allowsHitTesting(false)
                        .padding(.top, -2)
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
        
        var title: String
        @Bindable var trans: CBTransaction
        var focusedField: FocusState<Int?>.Binding
        @Binding var showDeleteAlert: Bool
        
        var body: some View {
            SheetHeader(
                title: title,
                subtitle: trans.relatedTransactionID == nil ? nil : "(Linked)",
                close: { focusedField.wrappedValue = nil; dismiss() },
                view1: { notificationButton },
                view2: { factorInCalculationsButton },
                view3: { deleteButton }
            )
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
                withAnimation { trans.notifyOnDueDate.toggle() }
            } label: {
                Image(systemName: trans.notifyOnDueDate ? "bell.slash.fill" : "bell.fill")
            }
        }
        
        var factorInCalculationsButton: some View {
            Button {
                withAnimation { trans.factorInCalculations.toggle() }
            } label: {
                Image(systemName: trans.factorInCalculations ? "eye.slash.fill" : "eye.fill")
            }
        }
    }
    
    
    struct DeleteYesButton: View {
        @Environment(CalendarModel.self) private var calModel
        @Environment(\.dismiss) var dismiss
        @Bindable var trans: CBTransaction
        var isTemp: Bool
        
        var body: some View {
            Button("Yes", role: .destructive) {
                if isTemp {
                    //transEditID = nil
                    dismiss()
                    calModel.tempTransactions.removeAll { $0.id == trans.id }
                    let _ = DataManager.shared.delete(type: TempTransaction.self, predicate: .byId(.string(trans.id)))
                } else {
                    //transEditID = nil
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
                    
                    if let pictures = trans.pictures {
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
                                        openURL(URL(string: "https://\(Keys.baseURL):8676/budget_app.photo.\(pic.uuid).jpg")!)
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
                                        safariUrl = URL(string: "https://\(Keys.baseURL):8676/budget_app.photo.\(pic.uuid).jpg")!
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
            #if os(iOS)
            .fullScreenCover(isPresented: $showCamera) {
                AccessCameraView(selectedImage: $calModel.selectedImage)
                    .background(.black)
            }
            #endif
        }
        
    }
    
    
    var photoPickerButton: some View {
        Group {
            @Bindable var calModel = calModel
            VStack(spacing: 6) {
                PhotosPicker(selection: $calModel.imageSelection, matching: .images, photoLibrary: .shared()) {
                    RoundedRectangle(cornerRadius: 12)
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
                }
                .buttonStyle(.plain)
                .onHover { isHovered in addPhotoButtonHoverColor2 = isHovered ? Color(.systemFill) : Color(.tertiarySystemFill) }
                .focusEffectDisabled(true)
                
                #if os(iOS)
                Button {
                    showCamera = true
                } label: {
                    RoundedRectangle(cornerRadius: 12)
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
                url: URL(string: "https://\(Keys.baseURL):8676/budget_app.photo.\(pic.uuid).jpg"),
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
            RoundedRectangle(cornerRadius: 12)
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
                                        
                    ShareLink(item: URL(string: "https://\(Keys.baseURL):8676/budget_app.photo.\(pic.uuid).jpg")! /*, subject: Text(trans.title), message: Text(trans.amountString)*/) {
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

        /// Get the transaction from the model.
        //var trans: CBTransaction?
                
        calModel.hilightTrans = nil
        
        trans = calModel.getTransaction(by: transEditID!, from: isTemp ? .tempList : transLocation)
        
            
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
                trans.payMethod = nil
            } else {
                /// Add the selected viewing payment method to the transaction.
                trans.payMethod = calModel.sPayMethod ?? CBPaymentMethod()
            }
            /// Pre-add the transaction to the day so we can add photos to it before saving. Get's removed on cancel if title and payment method are blank.
            day.upsert(trans)
            
        } else if isTemp {
            if trans.tempAction == .add {
                calModel.tempTransactions.append(trans)
                trans.amountString = ""
                trans.payMethod = nil
            } else {
                
            }
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
        if trans.action == .add {
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
