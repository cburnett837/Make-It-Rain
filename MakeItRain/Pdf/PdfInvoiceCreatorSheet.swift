//
//  CreatePdfInvoiceButton.swift
//  MakeItRain
//
//  Created by Cody Burnett on 1/19/26.
//

import SwiftUI
import MessageUI
import Contacts

struct PdfInvoiceCreatorSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(CalendarModel.self) private var calModel
    @Environment(FuncModel.self) private var funcModel
    var trans: CBTransaction
    
    @State private var contactManager = ContactStoreManager()
    @State private var model = PdfInvoiceCreatorModel()
    @State private var props = FileViewProps()
    
    @State private var showContactPicker = false
    @State private var showMessageComposer = false
    @State private var showFileMover = false
    @State private var showPdfPreview = false
    
    @FocusState private var focusedField: Int?
    
    @State private var isGeneratingToSend = false
    @State private var isGeneratingToSave = false
    @State private var isGeneratingToPreview = false
    
    let threeColumnGrid = Array(repeating: GridItem(.flexible(), spacing: 5, alignment: .top), count: 3)
    
    var body: some View {
        NavigationStack {
            List {
                Section("Recipient") {
                    recipRow
                }
                
//                Section("PDF Type") {
//                    invoiceTypePicker
//                }
                
                Section("Details") {
                    titleRow
                    amountRow
                    dateRow
                    invoiceTypePicker
                }
                
                if let files = trans.files?.filter({ $0.fileType == .photo }) {
                    Section {
                        fileScroller(for: files)
                    } header: {
                        Text("Optional Images")
                    } footer: {
                        Text("Select an image to include on the \(model.invoiceTypeLingo.lowercased()).")
                    }
                }
                
                Section {
                    sendInvoiceButton
                    previewInvoiceButton
                    saveInvoiceButton
                }
            }
            .environment(props)
            .navigationTitle("Create PDF \(model.invoiceTypeLingo)")
            //.navigationSubtitle("Create a PDF invoice to either send or save.")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .schemeBasedForegroundStyle()
                    }
                }
            }
            .task {
                model.prepareSelf(trans: trans)
                /// Check to make sure we have contact access. If not, it will take us through the access flow.
                await contactManager.fetchContacts()
                focusedField = 0
            }
        }
    }
    
    
    var invoiceTypePicker: some View {
        Picker(selection: $model.invoiceType) {
            ForEach(PdfInvoiceCreatorModel.InvoiceType.allCases, id: \.self) {
                Text($0.rawValue.capitalized)
            }
        } label: {
            Label {
                Text("PDF Type")
            } icon: {
                Image(systemName: "document")
                    .foregroundStyle(.gray)
            }

            //Label("PDF Type", systemImage: "document")
        }

        
//        Picker("", selection: $model.invoiceType) {
//            ForEach(PdfInvoiceCreatorModel.InvoiceType.allCases, id: \.self) {
//                Text($0.rawValue.capitalized)
//            }
//        }
//        .pickerStyle(.segmented)
//        .labelsHidden()
    }
    
    
    @State private var blockContactSuggestions = false
    @ViewBuilder
    var recipRow: some View {
        VStack {
            HStack(spacing: 10) {
                ContactAvatar(contact: model.selectedContact)
                
//                Label {
//                    Text("")
//                } icon: {
//                    Image(systemName: "person.circle")
//                        .foregroundStyle(.gray)
//                }
                
                recipTextField
                    .onChange(of: model.recipient) { old, new in
                        //print("Changed \(new)")
                        if blockContactSuggestions {
                            blockContactSuggestions = false
                            model.contactSearchResults.removeAll()
                            
                        } else if new.isEmpty {
                            model.selectedContact = nil
                            model.contactSearchResults.removeAll()
                            //model.selectedPhone = nil
                            
                        } else {
                            model.liveSearchContacts()
                        }
                    }
                    .onChange(of: focusedField) {
                        if $1 != 0 {
                            model.contactSearchResults.removeAll()
                        }
                    }
            }
        }
        
        ForEach(model.contactSearchResults) { contact in
            Button {
                blockContactSuggestions = true
                model.recipient = contact.formattedName
                //model.selectedPhone = contact.phoneNumbers.first?.value.stringValue
                model.selectedContact = contact
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    focusedField = nil
                }
                
            } label: {
                HStack(spacing: 10) {
                    ContactAvatar(contact: contact)
                    Text(contact.formattedName)
                }
            }
        }
    }
    
    
    @ViewBuilder
    var recipTextField: some View {
        Group {
            #if os(iOS)
            UITextFieldWrapper(placeholder: "Who is the \(model.invoiceTypeLingo.lowercased()) for?", text: $model.recipient, onSubmit: {
                focusedField = 1
            }, toolbar: {
                KeyboardToolbarView(focusedField: $focusedField, disableUp: true)
            })
            .uiTag(0)
            .uiClearButtonMode(.whileEditing)
            .uiStartCursorAtEnd(true)
            .uiTextAlignment(.left)
            .uiReturnKeyType(.next)
            .uiAutoCorrectionDisabled(true)
            //.uiTextColor(UIColor(trans.color))
            #else
            StandardTextField("Title", text: $trans.recipient, focusedField: $focusedField, focusValue: 0)
                .onSubmit { focusedField = 1 }
            #endif
        }
        .focused($focusedField, equals: 0)
    }
    
    
    
    @ViewBuilder
    var titleRow: some View {
        VStack {
            HStack(spacing: 0) {
                Label {
                    Text("")
                } icon: {
                    Image(systemName: "t.circle")
                        .foregroundStyle(.gray)
                }
                
                titleTextField
            }
        }
    }
    
    
    @ViewBuilder
    var titleTextField: some View {
        Group {
            #if os(iOS)
            UITextFieldWrapper(placeholder: "What is the \(model.invoiceTypeLingo.lowercased()) for?", text: $model.title, onSubmit: {
                focusedField = 2
            }, toolbar: {
                KeyboardToolbarView(focusedField: $focusedField, disableUp: true)
            })
            .uiTag(1)
            .uiClearButtonMode(.whileEditing)
            .uiStartCursorAtEnd(true)
            .uiTextAlignment(.left)
            .uiReturnKeyType(.next)
            //.uiTextColor(UIColor(trans.color))
            #else
            StandardTextField("Title", text: $trans.title, focusedField: $focusedField, focusValue: 0)
                .onSubmit { focusedField = 2 }
            #endif
        }
        .focused($focusedField, equals: 1)
    }
    
    
    var amountRow: some View {
        HStack(spacing: 0) {
            Label {
                Text("")
            } icon: {
                Image(systemName: "dollarsign.circle")
                    .foregroundStyle(.gray)
            }
            
            Group {
                #if os(iOS)
                UITextFieldWrapper(placeholder: "\(model.invoiceTypeLingo) Amount", text: $model.amountString, toolbar: {
                    KeyboardToolbarView(focusedField: $focusedField, removeNavButtons: true)
                })
                .uiTag(2)
                .uiClearButtonMode(.whileEditing)
                .uiStartCursorAtEnd(true)
                .uiTextAlignment(.left)
                .uiKeyboardType(.custom(.numpad))
                //.uiKeyboardType(useWholeNumbers ? .numberPad : .decimalPad)
                //.uiTextColor(.secondaryLabel)
                //.uiTextAlignment(.right)
                #else
                StandardTextField("Amount", text: $transfer.amountString, focusedField: $focusedField, focusValue: 1)
                #endif
            }
            .focused($focusedField, equals: 2)
            .formatCurrencyLiveAndOnUnFocus(
                focusValue: 2,
                focusedField: focusedField,
                amountString: model.amountString,
                amountStringBinding: $model.amountString,
                amount: model.amount
            )
        }
        //.validate(model.amountString, rules: .regex(.positiveCurrency, "The entered amount must be positive currency"))
        
    }
    
    
    var dateRow: some View {
        HStack(spacing: 0) {
            Label {
                Text("\(model.invoiceTypeLingo) Date")
            } icon: {
                Image(systemName: "calendar")
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            DatePicker("", selection: $model.date, displayedComponents: [.date])
                .frame(maxWidth: .infinity, alignment: .trailing)
                .labelsHidden()
        }
        .listRowInsets(EdgeInsets())
        .padding(.horizontal, 16)
    }
    
    
    @ViewBuilder
    func fileScroller(for files: [CBFile]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 4) {
                ForEach(files) { file in
                    fileView(file: file)
                        .overlay {
                            if model.selectedReceipt?.id == file.id {
                                RoundedRectangle(cornerRadius: 14)
                                   .fill(Color.clear)
                                   .stroke(Color.green, lineWidth: 2)
                            }
                            //checkmarkView(file: file)
                        }
                        .overlay {
                            if model.selectedReceipt != nil && model.selectedReceipt?.id != file.id {
                                RoundedRectangle(cornerRadius: 14)
                                   .fill(Color.gray.opacity(0.8))
                           }
                        }
                        .contentShape(.rect)
                        .onTapGesture {
                            if model.selectedReceipt?.id == file.id {
                                model.selectedReceipt = nil
                            } else {
                                model.selectedReceipt = file
                            }
                        }
                }
            }
        }
    }
    
    
    @ViewBuilder
    func checkmarkView(file: CBFile) -> some View {
        HStack {
            Spacer()
            VStack {
                Spacer()
                if model.selectedReceipt?.id == file.id {
                    Image(systemName: "checkmark.circle")
                        .foregroundStyle(Color.theme)
                        .font(.largeTitle)
                }
            }
        }
        .padding(5)
    }
    
                
    @ViewBuilder
    func fileView(file: CBFile) -> some View {
        switch file.fileType {
        case .photo:
            CustomAsyncImage(file: file) { image in
                image
                    .resizable()
                    .frame(width: 125, height: 250)
                    .aspectRatio(contentMode: .fill)
                    .clipShape(.rect(cornerRadius: 14))
            } placeholder: {
                RoundedRectangle(cornerRadius: 14)
                    .fill(.ultraThickMaterial)
                    .frame(width: 125, height: 250)
                    .overlay(ProgressView().tint(.none))
            }
        case .pdf:
            CustomAsyncPdf(file: file, displayStyle: .grid)
        case .csv, .spreadsheet:
            CustomAsyncCsv(file: file, displayStyle: .grid)
        }
    }
            
    
    var sendInvoiceButton: some View {
        Button {
            /// Flow:
            /// - Open contact picker
            /// - Selected contact will come back in the onSelect closure in the ``ContactPickerView``
            /// - The contact picker sheet's onDismiss will create the invoice and open the messaging view.
            /// - When the messaging view closes, it will close the invoice creation sheet.
            isGeneratingToSend = true
            
//            if model.selectedContact == nil {
//                showContactPicker = true
//            } else {
//                Task {
//                    await model.createInvoice()
//                    showMessageComposer = true
//                }
//            }
            
            Task {
                await model.createInvoice()
                showMessageComposer = true
            }
            
        } label: {
            HStack {
                Text("Send via Messages")
                Spacer()
                if isGeneratingToSend {
                    ProgressView()
                        .tint(.none)
                }
            }
        }
//        .sheet(isPresented: $showContactPicker, onDismiss: {
//            /// When the contact picker is dismissed, create the invoice and show the messaging view.
//            /// If a contact was selected, it will populate the messaging to-field. If not, the to field will be focused so the user can enter a phone number.
//            Task {
//                await model.createInvoice()
//                showMessageComposer = true
//            }
//        }) {
//            /// When you touch a contact, it will be passed into this closure and will be set in the model.
//            ContactPickerView { contact in
//                model.selectedPhone = contact.phoneNumbers.first?.value.stringValue
//                model.selectedContact = contact
//            }
//        }
        .sheet(isPresented: $showMessageComposer, onDismiss: {
            /// When done sending the text, dismiss the invoice creator sheet.
            isGeneratingToSend = false
            //dismiss()
        }) {
            if let pdfUrl = model.pdfUrl, model.canSendTextAndAttachments {
                let phoneNumber = model.selectedContact?.phoneNumbers.first?.value.stringValue
                MessageComposerView(phoneNumber: phoneNumber, messageBody: model.messagePlaceholder, pdfURL: pdfUrl)
            } else {
                ThereWasAProblemFullScreenView(title: "Messaging Error", text: model.cantSendMessageReason)
            }
        }
    }
    
    
    var saveInvoiceButton: some View {
        Button {
            Task {
                isGeneratingToSave = true
                await model.createInvoice()
                showFileMover = true
            }
        } label: {
            HStack {
                Text("Save to Files")
                Spacer()
                if isGeneratingToSave {
                    ProgressView()
                        .tint(.none)
                }
            }
        }
        .fileMover(isPresented: $showFileMover, file: model.pdfUrl, onCompletion: { _ in
            isGeneratingToSave = false
            dismiss()
        }, onCancellation: {
            isGeneratingToSave = false
            //dismiss()
        })
    }
    
    
    var previewInvoiceButton: some View {
        Button {
            Task {
                isGeneratingToPreview = true
                await model.createInvoice()
                showPdfPreview = true
            }
        } label: {
            HStack {
                Text("Preview & Share")
                Spacer()
                if isGeneratingToPreview {
                    ProgressView()
                        .tint(.none)
                }
            }
        }
        .sheet(isPresented: $showPdfPreview, onDismiss: {
            isGeneratingToPreview = false
        }, content: {
            PdfInvoicePreview(model: model)
        })
    }
}




struct PdfInvoicePreview: View {
    @Environment(\.dismiss) var dismiss
    
    var model: PdfInvoiceCreatorModel
    
    var body: some View {
        NavigationStack {
            if let url = model.pdfUrl {
                PDFKitRepresentedView(url: url)
                    .navigationTitle("\(model.invoiceTypeLingo) Preview")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) { shareLink }
                        ToolbarItem(placement: .topBarTrailing) { closeButton }
                    }
            } else {
                ThereWasAProblemFullScreenView(
                    title: "\(model.invoiceTypeLingo) Problem",
                    text: "There was a problem trying to generate the \(model.invoiceTypeLingo.lowercased())"
                )
            }
        }
    }

    @ViewBuilder
    var shareLink: some View {
        if let url = model.pdfUrl {
            ShareLink(
                item: url,
                subject: Text("\(model.invoiceTypeLingo) from \(AppState.shared.user?.name ?? "N/A")"),
                message: Text(model.messagePlaceholder)
            ) {
                Image(systemName: "square.and.arrow.up")
            }
//            ShareLink(item: url) {
//                Image(systemName: "square.and.arrow.up")
//            }
            .schemeBasedForegroundStyle()
        }
    }

    var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .schemeBasedForegroundStyle()
        }
    }
}
