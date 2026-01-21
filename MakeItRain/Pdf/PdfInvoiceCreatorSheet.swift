//
//  CreatePdfInvoiceButton.swift
//  MakeItRain
//
//  Created by Cody Burnett on 1/19/26.
//

import SwiftUI
import MessageUI
import Contacts
//
//struct CreatePdfInvoiceButton: View {
//    @Environment(CalendarModel.self) private var calModel
//    @Environment(FuncModel.self) private var funcModel
//
//    var trans: CBTransaction
////    
////    @State private var contactManager = ContactStoreManager()
////    @State private var showContactPicker = false
////    @State private var selectedPhone: String?
////    @State private var selectedContact: CNContact?
////    @State private var selectedReceipt: CBFile?
////    
////    @State private var showMessageComposer = false
////    @State private var pdfUrl: URL?
////    @State private var showFileMover = false
////    @State private var showReceiptPicker = false
////    
////    @State private var isGeneratingInvoiceToSend = false
////    @State private var isGeneratingInvoiceToSave = false
//    
//    @State private var showInvoiceGeneratorSheet = false
//    
////    var fileName: String {
////        "Invoice-\(trans.title)-\(trans.date?.string(to: .invoiceDate) ?? "N/A")"
////    }
////    
////    var contactName: String {
////        if let name = selectedContact?.givenName { return " \(name)" }
////        return ""
////    }
////    
////    var messagePlaceholder: String {
////        "Hey\(contactName), here is an invoice for \(trans.title) from \(trans.date?.string(to: .monthDayShortYear) ?? "N/A")"
////    }
//    
//    
//    var body: some View {
//        generateInvoiceButton
////        sendInvoiceButton
////        createInvoiceButton
////            .sheet(isPresented: $showReceiptPicker, onDismiss: {
////                Task {
////                    await createInvoice()
////                    
////                    if isGeneratingInvoiceToSend == true {
////                        showMessageComposer = true
////                    } else {
////                        showFileMover = true
////                    }
////                }
////            }) {
////                if let files = trans.files {
////                    ReceiptPicker(selectedReceipt: $selectedReceipt, files: files)
////                    //Text("hey")
////                }
////            }
//    }
//    
//    
//    var generateInvoiceButton: some View {
//        Button {
//            showInvoiceGeneratorSheet = true
//        } label: {
//            Text("Generate Invoice")
//        }
//        .sheet(isPresented: $showInvoiceGeneratorSheet) {
//            InvoiceCreatorSheet(trans: trans)
//        }
//    }
//    
////    var sendInvoiceButton: some View {
////        Button {
////            Task {
////                isGeneratingInvoiceToSend = true
////                await contactManager.fetchContacts()
////                showContactPicker = true
////            }
////        } label: {
////            HStack {
////                Label("Send Invoice", systemImage: "arrow.up.message")
////                //Text("Send Invoice To Contact")
////                Spacer()
////                if isGeneratingInvoiceToSend {
////                    ProgressView()
////                        .tint(.none)
////                }
////            }
////        }
////        .sheet(isPresented: $showContactPicker) {
////            ContactPickerView { contact in
////                selectedPhone = contact.phoneNumbers.first?.value.stringValue
////                selectedContact = contact
////                showContactPicker = false
////                showReceiptPicker = true
////                
//////                Task {
//////                    await createInvoice()
//////                    showMessageComposer = true
//////                }
////            }
////        }
////        .sheet(isPresented: $showMessageComposer, onDismiss: {
////            isGeneratingInvoiceToSend = false
////            selectedReceipt = nil
////        }) {
////            if let phone = selectedPhone,
////            let pdfUrl = pdfUrl,
////            MFMessageComposeViewController.canSendText(),
////            MFMessageComposeViewController.canSendAttachments() {
////                MessageComposerView(
////                    phoneNumber: phone,
////                    messageBody: messagePlaceholder,
////                    pdfURL: pdfUrl
////                )
////            } else {
////                Text("Messaging is not available.")
////            }
////        }
////    }
////            
////    
////    var createInvoiceButton: some View {
////        Button {
////            Task {
////                isGeneratingInvoiceToSave = true
////                showReceiptPicker = true
////            }
////        } label: {
////            HStack {
////                Label("Save Invoice", systemImage: "arrow.down.document")
//////                Text("Save Invoice To Files")
////                Spacer()
////                if isGeneratingInvoiceToSave {
////                    ProgressView()
////                        .tint(.none)
////                }
////            }
////        }
////        .fileMover(isPresented: $showFileMover, file: pdfUrl, onCompletion: { _ in
////            isGeneratingInvoiceToSave = false
////            selectedReceipt = nil
////        }, onCancellation: {
////            isGeneratingInvoiceToSave = false
////            selectedReceipt = nil
////        })
////    }
////    
////    
////    func createInvoice() async {
////        await withTaskGroup(of: Void.self) { group in
////            if let files = trans.files?.filter({ $0.active }), !files.isEmpty, let firstFile = files.first {
////                group.addTask { await funcModel.downloadFile(file: firstFile) }
////            }
////        }
////        
////        let fileUrl: URL? = try? PdfMaker.create(pageCount: 1, fileName: fileName) { pageIndex in
////            InvoicePdfViewForSingleTransaction(
////                pageIndex: pageIndex,
////                trans: trans,
////                contact: selectedContact,
////                receipt: selectedReceipt
////            )
////        }
////        
////        if let url = fileUrl { self.pdfUrl = url }
////    }
//}


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
    
    @FocusState private var focusedField: Int?
    
    @State private var isGeneratingToSend = false
    @State private var isGeneratingToSave = false
    
    let threeColumnGrid = Array(repeating: GridItem(.flexible(), spacing: 5, alignment: .top), count: 3)
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    amountRowPhone
                    dateRow
                } header: {
                    Text("Amount & Date")
                }
                
                Section("PDF Type") {
                    invoiceTypePicker
                }
                
                if let files = trans.files?.filter({ $0.fileType == .photo }) {
                    Section {
                        fileScroller(for: files)
                    } header: {
                        Text("Optional Images")
                    } footer: {
                        Text("Select an image to include on the \(model.invoiceTypeLingo.lowercased()). You can only select one.")
                    }
                }
                
                Section {
                    sendInvoiceButton
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
            }
        }
    }
    
    
    var invoiceTypePicker: some View {
        Picker("", selection: $model.invoiceType) {
            ForEach(PdfInvoiceCreatorModel.InvoiceType.allCases, id: \.self) {
                Text($0.rawValue.capitalized)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
    }
    
    var amountRowPhone: some View {
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
                .uiTag(1)
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
            .focused($focusedField, equals: 1)
            .formatCurrencyLiveAndOnUnFocus(
                focusValue: 1,
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
                Text("Date")
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
            Task {
                /// Check to make sure we have contact access. If not, it will take us through the access flow.
                await contactManager.fetchContacts()
                showContactPicker = true
            }
        } label: {
            HStack {
                Text("Send")
                Spacer()
                if isGeneratingToSend {
                    ProgressView()
                        .tint(.none)
                }
            }
        }
        .sheet(isPresented: $showContactPicker, onDismiss: {
            /// When the contact picker is dismissed, create the invoice and show the messaging view.
            /// If a contact was selected, it will populate the messaging to-field. If not, the to field will be focused so the user can enter a phone number.
            Task {
                await model.createInvoice()
                showMessageComposer = true
                isGeneratingToSend = false
            }
        }) {
            /// When you touch a contact, it will be passed into this closure and will be set in the model.
            ContactPickerView { contact in
                model.selectedPhone = contact.phoneNumbers.first?.value.stringValue
                model.selectedContact = contact
            }
        }
        .sheet(isPresented: $showMessageComposer, onDismiss: {
            /// When done sending the text, dismiss the invoice creator sheet.
            isGeneratingToSend = false
            dismiss()
        }) {
            if let pdfUrl = model.pdfUrl, model.canSendTextAndAttachments {
                MessageComposerView(phoneNumber: model.selectedPhone, messageBody: model.messagePlaceholder, pdfURL: pdfUrl)
            } else {
                PdfInvoiceCreatorMessagingUnavailableView(model: model)
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
                Text("Save")
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
            dismiss()
        })
    }
}








//
//struct ReceiptPicker: View {
//    @Environment(\.dismiss) var dismiss
//    @Environment(CalendarModel.self) private var calModel
//    @Binding var selectedReceipt: CBFile?
//    var files: [CBFile]
//    
//    @State private var props = FileViewProps()
//    
//    let threeColumnGrid = Array(repeating: GridItem(.flexible(), spacing: 5, alignment: .top), count: 3)
//    
//    var body: some View {
//        NavigationStack {
//            ScrollView {
//                LazyVGrid(columns: threeColumnGrid, spacing: 5) {
//                    ForEach(files) { file in
//                        
//                        ZStack {
//                            if file.isPlaceholder {
//                                LoadingPlaceholder(text: "Uploading…", displayStyle: .grid)
//                            } else {
//                                fileView(file: file)
//                            }
//                        }
//                        .overlay {
//                            checkmarkView(file: file)
//                        }
//                        .contentShape(.rect)
//                        .onTapGesture {
//                            print("tapped")
//                            selectedReceipt = file
//                            dismiss()
//                        }
//                    }
//                }
//                //.contentMargins(20, for: .scrollContent)
//                //.padding()
//            }
//            .scenePadding()
//            .environment(props)
//            .navigationTitle("Select Receipt")
//            .navigationSubtitle("Select the receipt you'd like to add to the invoice.")
//            .toolbar {
//                ToolbarItem(placement: .topBarTrailing) {
//                    Button {
//                        dismiss()
//                    } label: {
//                        Image(systemName: "xmark")
//                            .schemeBasedForegroundStyle()
//                    }
//                }
//            }
//        }
//    }
//    
//    @ViewBuilder
//    func checkmarkView(file: CBFile) -> some View {
//        HStack {
//            Spacer()
//            VStack {
//                Spacer()
//                if selectedReceipt?.id == file.id {
//                    Image(systemName: "checkmark.circle")
//                }
//            }
//        }
//        .padding(5)
//    }
//    
//    
//    @ViewBuilder
//    func fileView(file: CBFile) -> some View {
//        switch file.fileType {
//        case .photo:
//            CustomAsyncImage(file: file) { image in
//                image
//                    .resizable()
//                    .frame(width: 125, height: 250)
//                    .aspectRatio(contentMode: .fit)
//                    .clipShape(.rect(cornerRadius: 6))
//            } placeholder: {
//                RoundedRectangle(cornerRadius: 6)
//                    .fill(.ultraThickMaterial)
//                    .frame(width: 125, height: 250)
//                    .overlay(ProgressView().tint(.none))
//            }
//        case .pdf:
//            CustomAsyncPdf(file: file, displayStyle: .grid)
//        case .csv, .spreadsheet:
//            CustomAsyncCsv(file: file, displayStyle: .grid)
//        }
//    }
//}
