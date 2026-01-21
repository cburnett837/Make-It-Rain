//
//  TransactionEditViewMoreOptions.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/31/25.
//

import SwiftUI

struct TevMoreOptions: View {
    @AppStorage("transactionTitleSuggestionType") var transactionTitleSuggestionType: TitleSuggestionType = .location
    @Environment(\.colorScheme) var colorScheme
    @Environment(CalendarModel.self) private var calModel
    @Environment(FuncModel.self) private var funcModel
    
    @Bindable var trans: CBTransaction
    @Binding var showSplitSheet: Bool
    var isTemp: Bool
    @Binding var navPath: NavigationPath
    @Binding var showBadgeBell: Bool
    @Binding var showHiddenEye: Bool
    
    @State private var showInvoiceGeneratorSheet = false

    
//    var titleColorDescription: String {
//        trans.color == .primary ? (colorScheme == .dark ? "White" : "Black") : trans.color.description.capitalized
//    }
        
    var body: some View {
        StandardContainerWithToolbar(.list) {
            Section {
                NavigationLink(value: TransNavDestination.titleColorMenu) {
                    HStack {
                        Label {
                            Text("Title Color")
                        } icon: {
                            //Image(systemName: "paintbrush")
                            Image(systemName: "paintpalette")
                                .symbolRenderingMode(.multicolor)
                                //.foregroundStyle(trans.color)
                                .foregroundStyle(.gray)
                        }
                        
                        Spacer()
                        Circle()
                            .fill(trans.color)
                            .frame(width: 25, height: 25)
//                        Text(titleColorDescription)
//                            .foregroundStyle(trans.color)
                    }
                    
                }
            }
            
            Section {
                factorInCalculationsToggleRow
            } footer: {
                Text("Choose if this transaction should be included in calculations and analytics.")
            }
            
            if !isTemp {
                Section {
                    notificationButton
                    if trans.notifyOnDueDate {
                        ReminderPicker(title: "for…", notificationOffset: $trans.notificationOffset)
                    }
                } footer: {
                    if trans.notifyOnDueDate {
                        Text("You will be notified around 9:00 AM.")
                            //.foregroundStyle(.gray)
                            //.font(.caption)
                            //.multilineTextAlignment(.leading)
                    }
                }
            }
            
            
            if !isTemp {
                Section {
                    createInvoiceButton
                } footer: {
                    Text("Create a PDF invoice to either send or save.")
                }
                .disabled(trans.title.isEmpty)
                
                Section {
                    splitButton
                } footer: {
                    Text("Split this transaction into multiple categories & amounts.")
                }
                .disabled(trans.title.isEmpty)
                
                Section {
                    copyButton
                    //splitButton
                } footer: {
                    Text("Touch and hold on a day to paste.")
                }
                .disabled(trans.title.isEmpty)
            }
            
            titleAutoFillSuggestions
        }
        .navigationTitle("Transaction Options")        
    }
    
    var titleAutoFillSuggestions: some View {
        Section {
            Picker("", selection: $transactionTitleSuggestionType) {
                Label {
                    Text("History")
                } icon: {
                    Image(systemName: "clock")
                        .foregroundStyle(.gray)
                }
                .tag(TitleSuggestionType.history)
                
                Label {
                    Text("Locations")
                } icon: {
                    locationSelectionIcon
                }
                .tag(TitleSuggestionType.location)

            }
            .labelsHidden()
            .pickerStyle(.inline)
        } header: {
            Text("Title Autofill Suggestions")
        } footer: {
            let description: LocalizedStringKey = "When entering a title, choose how suggestions are made.\n**History** will search your past transactions.\n**Locations** will search nearby businesses."
            Text(description)
        }
        .onChange(of: transactionTitleSuggestionType) {
            if $1 == .location
            && LocationManager.shared.authIsAllowed == false
            && LocationManager.shared.manager.authorizationStatus == .denied {
                transactionTitleSuggestionType = .history
                alertUserLoctionServicesAreDisabled()
            }
        }
    }
    
    @ViewBuilder
    var locationSelectionIcon: some View {
        if LocationManager.shared.authIsAllowed == false && LocationManager.shared.manager.authorizationStatus == .denied {
            Image(systemName: "exclamationmark.triangle")
                .foregroundStyle(LinearGradient(
                    gradient: Gradient(colors: [.orange, .red]), startPoint: .top, endPoint: .bottom)
                )
        } else {
            Image(systemName: "map")
                .foregroundStyle(.gray)
        }
    }
    
    
    var createInvoiceButton: some View {
        Button {
            showInvoiceGeneratorSheet = true
        } label: {
            Text("Create PDF Invoice / Receipt")
        }
        .sheet(isPresented: $showInvoiceGeneratorSheet) {
            PdfInvoiceCreatorSheet(trans: trans)
        }
    }
    
    var copyButton: some View {
        Button {
            if trans.title.isEmpty {
                navPath.removeLast()
                AppState.shared.showToast(
                    title: "Failed To Copy",
                    body: "Title cannot be blank",
                    symbol: "exclamationmark.triangle",
                    symbolColor: .orange
                )
                return
            } else {
                calModel.transactionToCopy = trans
                navPath.removeLast()
                AppState.shared.showToast(
                    title: "\(trans.title) Copied",
                    symbol: "doc.on.doc.fill",
                    symbolColor: .green
                )
            }
            
            
        } label: {
            Text("Copy Transaction")
//            Label {
//                Text("Copy Transaction")
//            } icon: {
//                Image(systemName: "document.on.document")
//            }
        }
    }
    
    var splitButton: some View {
        Button {
            navPath.removeLast()
            showSplitSheet = true
            
        } label: {
            Text("Split Transaction")
//            Label {
//                Text("Split Transaction")
//            } icon: {
//                Image(systemName: "arrow.trianglehead.branch")
//            }
        }
    }
       
    
    //@State private var bellDisabled = false
    /// Use a dedicated state property instead of `trans.notifyOnDueDate` otherwise the animation will be funky. Not sure why.
    var notificationButton: some View {
        Toggle(isOn: $trans.notifyOnDueDate.animation()) {
            Label {
                Text("Set Reminder")
            } icon: {
                Image(systemName: showBadgeBell ? "bell.badge" : "bell")
                    .foregroundStyle(.gray)
                    .symbolRenderingMode(showBadgeBell ? .multicolor : .monochrome)
                    .contentTransition(.symbolEffect(.replace))
                    .symbolEffect(.wiggle, value: trans.notifyOnDueDate)
                
                    /// Run initially so the symbol gets set properly if we have a notificaiton enabled.
                    .onChange(of: trans.notifyOnDueDate, initial: true) {
                        showBadgeBell = $1
                    }
            }
            
            //Text(trans.notifyOnDueDate ? "Cancel Notification" : "Add Notification")
        }
        .onChange(of: trans.notifyOnDueDate) {
            trans.notificationOffset = 0
//            if !$1 {
//                trans.notificationOffset = nil
//            } else {
//                trans.notificationOffset = 0
//            }
        }
//        Button {
//            withAnimation {
//                if trans.notifyOnDueDate {
//                    trans.notifyOnDueDate = false
//                    trans.notificationOffset = nil
//                } else {
//                    trans.notifyOnDueDate = true
//                    trans.notificationOffset = 0
//                }
//            }
//            //navPath.removeLast()
//        } label: {
//            Text(trans.notifyOnDueDate ? "Cancel Notification" : "Add Notification")
////            Label {
////                Text(trans.notifyOnDueDate ? "Cancel Notification" : "Add Notification")
////            } icon: {
////                Image(systemName: trans.notifyOnDueDate ? "bell.slash.fill" : "bell.fill")
////            }
//        }
    }
    
//    var factorInCalculationsButton: some View {
//        Button {
//            withAnimation {
//                trans.factorInCalculations.toggle()
//            }
//            navPath.removeLast()
//        } label: {
//            Text(trans.factorInCalculations ? "Exclude from Calculations" : "Include in Calculations")
////            Label {
////                Text(trans.factorInCalculations ? "Exclude from Calculations" : "Include in Calculations")
////            } icon: {
////                Image(systemName: trans.factorInCalculations ? "eye.slash.fill" : "eye.fill")
////            }
//        }
//    }
    var factorInCalculationsToggleRow: some View {
        Toggle(isOn: $trans.factorInCalculations.animation()) {
            Label {
                Text("Include In Calculations")
                    .schemeBasedForegroundStyle()
            } icon: {
                Image(systemName: showHiddenEye ? "eye.slash" : "eye")
                    .foregroundStyle(.gray)
                    .contentTransition(.symbolEffect(.replace))
                    .onChange(of: trans.factorInCalculations) { old, new in
                        withAnimation { showHiddenEye = !new }
                    }
            }
        }
        .onAppear {
            if !trans.factorInCalculations {
                showHiddenEye = true
            }
        }
    }
    
    
    func alertUserLoctionServicesAreDisabled() {
        let openSettingsButton = AlertConfig.AlertButton(
            closeOnFunction: true,
            config: .init(text: "Open Settings", function: {
                let settingsAppURL = URL(string: UIApplication.openSettingsURLString)!
                UIApplication.shared.open(settingsAppURL, options: [:], completionHandler: nil)
            })
        )
        
        let alertConfig = AlertConfig(
            title: "Location Serviced Disabled",
            subtitle: "Please enable Location Services by going to Settings -> Privacy & Security",
            symbol: .init(name: "location.slash.fill", color: .orange), primaryButton: openSettingsButton
        )
        AppState.shared.showAlert(config: alertConfig)
    }
    
    
    
    
    
    
    
    
    
    
//    @State private var pdfUrl: URL?
//    @State private var showFileMover = false
//    
//    @ViewBuilder
//    var sendInvoiceButton: some View {
//        if let pdfUrl {
//            SendPdfView(pdfURL: pdfUrl)
//        }
//        
//    }
//    
//    var createInvoiceButton: some View {
//        Button("Create Invoice") {
//            Task {
//                await withTaskGroup(of: Void.self) { group in
//                    if let files = trans.files?.filter({ $0.active }), !files.isEmpty, let firstFile = files.first {
//                        group.addTask { await funcModel.downloadFile(file: firstFile) }
//                    }
//                }
//                
//                let fileUrl: URL? = try? PdfMaker.create(pageCount: 3, pageContent: { pageIndex in
//                    InvoicePdfViewForSingleTransaction(pageIndex: pageIndex, trans: trans)
//                })
//                
//                if let url = fileUrl {
//                    self.pdfUrl = url
//                    //showFileMover = true
//                }
//            }
//        }
//        .fileMover(isPresented: $showFileMover, file: pdfUrl) { result in
//            print(result)
//        }
//        
//    }
    
//    var fileUrl: URL? {
//        
//        //let pageCount = Int((PdfMaker.PageSize.a4().size.height - 120) / 80)
//        //let chunkTransactions = calModel.justTransactions.chunked(into: pageCount)
////        return try? PdfMaker.create(pageCount: chunkTransactions.count, pageContent: { pageIndex in
////            InvoicePdfView(pageIndex: pageIndex, transactions: chunkTransactions[pageIndex])
////        })
//        
//        return try? PdfMaker.create(pageCount: 3, pageContent: { pageIndex in
//            InvoicePdfView(pageIndex: pageIndex, trans: trans)
//        })
//    }
}

//
//struct InvoicePdfOptionsView: View {
//    @Environment(ContactStoreManager.self) private var storeManager
//
//    var body: some View {
//        List {
//            Button("Select Contact") {
//                
//            }
//        }
//    }
//}









