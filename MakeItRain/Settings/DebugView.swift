//
//  DebugView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/15/25.
//

import SwiftUI
import PDFKit

struct DebugView: View {
    @Local(\.debugPrint) var debugPrint

    @Environment(CalendarModel.self) var calModel
    @Environment(FuncModel.self) var funcModel
    
    @State private var plaidCosts: Array<PlaidForceRefreshCost> = []
    @State private var showBasicAlert = false
    @State private var text = ""
    @FocusState private var focusedField: Int?
    
    var body: some View {
        List {
            #if os(iOS)
            customNumPad
            #endif
            
            Section {
                dumpCoreDataButton
                printAllBudgetsButton
                documentTester
                logoNavLink
            }
            
            
            alertSection
            
            Section("Xcode") {
                consolePrintToggle
            }
            
            loadTimeSection
            
            plaidForceRefreshSection
        }
        .navigationTitle("Debug")
        .toolbar {
            #if os(macOS)
            macToolbar()
            #else
            phoneToolbar()
            #endif
        }
        .task {
            await fetchPlaidCosts()
        }
    }
    
    @State private var showFileImporter = false
    @State private var selectedFileURL: URL?

    @ViewBuilder
    var documentTester: some View {
        @Bindable var photoModel = FileModel.shared
        Button("Select Document") {
                showFileImporter = true
            }
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [.pdf, .plainText, .commaSeparatedText], // Specify the allowed document types
                allowsMultipleSelection: false // Set to true for multiple selection
            ) { result in
                switch result {
                case .success(let urls):
                    // Handle the selected URL(s)
                    if let url = urls.first {
                        selectedFileURL = url
                        
                        //PDFKitView(url: pdfURL)
                        
                        Task {
                            if let safeUrl = selectedFileURL, let fileData = try? Data(contentsOf: safeUrl) {
                                typealias ResultResponse = Result<ResultCompleteModel?, AppError>
                                
                                
                                let result: ResultResponse = await NetworkManager().uploadFile(
                                    application: "budget_app",
                                    fileParent: .init(id: "13372", type: XrefModel.getItem(from: .fileTypes, byEnumID: .transaction)),
                                    uuid: UUID().uuidString,
                                    fileData: fileData,
                                    fileName: "file",
                                    fileType: .pdf
                                )
                                
                                print(result)
                                
                                
//                                if let _ = await photoModel.uploadPicture(
//                                    imageData: fileData,
//                                    fileParent: .init(id: "13372", type: XrefModel.getItem(from: .fileTypes, byEnumID: .transaction)), //--> will be nil when uploading a smart receipt.
//                                    uuid: UUID().uuidString,
//                                    isSmartTransaction: false,
//                                    smartTransactionDate: nil,
//                                    responseType: ResultResponse.self
//                                ) {
//                                    print("wooo")
//                                }
                            }
                        }
                        
                        
                        // Process the document, e.g., read its content
                        // Remember to handle security-scoped resources if needed
                        // url.startAccessingSecurityScopedResource()
                        // defer { url.stopAccessingSecurityScopedResource() }
                    }
                case .failure(let error):
                    // Handle any errors during file selection
                    print("Error selecting file: \(error.localizedDescription)")
                }
            }
    }
    
    
    var logoNavLink: some View {
        NavigationLink("Logos") {
            LogoList()
        }
    }
    
    
    
    
    
    
    var dumpCoreDataButton: some View {
        Button("Clear Core Data") {
            let context = DataManager.shared.createContext()
            context.perform {
                /// Remove all from cache.
                let _ = DataManager.shared.deleteAll(context: context, for: PersistentPaymentMethod.self)
                let _ = DataManager.shared.deleteAll(context: context, for: PersistentCategory.self)
                let _ = DataManager.shared.deleteAll(context: context, for: PersistentKeyword.self)
                let _ = DataManager.shared.deleteAll(context: context, for: PersistentToast.self)
                let _ = DataManager.shared.deleteAll(context: context, for: PersistentLogo.self)
                
                let _ = DataManager.shared.save(context: context)
            }
        }
    }
    
    
    var customNumPad: some View {
        Section {
            UITextFieldWrapper(placeholder: "Demo", text: $text, toolbar: {
                KeyboardToolbarView(
                    focusedField: $focusedField,
                    accessoryImage3: "plus.forwardslash.minus",
                    accessoryFunc3: {
                        Helpers.plusMinus($text)
                    })
            })
            .uiKeyboardType(.custom(.numpad))
            .focused($focusedField, equals: 0)
        }
    }
    
    
    var alertSection: some View {
        Section("Alert & Toast") {
            Button("Show basic alert") {
                showBasicAlert = true
            }
            .alert("Basic Alert", isPresented: $showBasicAlert) {
                Button("Action1") {}
                Button("Action2") {}
                Button("Action3") {}
                Button("cancel", role: .cancel) {}
                Button("destructive", role: .destructive) {}
                #if os(iOS)
                Button("close", role: .close) {}
                Button("confirm", role: .confirm) {}
                #endif
            }
            
            Button("Show basic custom alert") {
                AppState.shared.showAlert("This is a basic demo alert")
            }
            
            Button("Show advanced custom alert 1") {
                let alertConfig = AlertConfig(
                    title: "Alert Title",
                    symbol: .init(name: "ipad.and.iphone.slash", color: .red),
                    primaryButton:
                        AlertConfig.AlertButton(config: .init(text: "Primary", role: .primary, function: {
                            print("Advanced demo alert presented")
                        }))
                )
                AppState.shared.showAlert(config: alertConfig)
                
            }
            
            
            Button("Show advanced custom alert 2") {
                let alertConfig = AlertConfig(
                    title: "Alert Title",
                    subtitle: "Alert subtitle",
                    symbol: .init(name: "ipad.and.iphone.slash", color: .red),
                    primaryButton:
                        AlertConfig.AlertButton(config: .init(text: "Primary", role: .primary, function: {
                            print("Advanced demo alert presented")
                        }))
                )
                AppState.shared.showAlert(config: alertConfig)
                
            }
            
            Button("Show toast") {
                AppState.shared.showToast(title: "Toast title", subtitle: "Toast subtitle", body: "Toast body", symbol: "exclamationmark.triangle", symbolColor: .orange)
            }
        }
    }
    
    
    var printAllBudgetsButton: some View {
        Button("Print Budgets") {
            for month in calModel.months {
                let budgets = month.budgets
                for budget in budgets {
                    print("budget for \(month.actualNum)-\(month.year) --- \(String(describing: budget.category?.title))-\(budget.month)-\(budget.year)")
                }
                
            }
        }
    }
    
    
    var consolePrintToggle: some View {
        Toggle(isOn: $debugPrint) {
            Label {
                VStack(alignment: .leading) {
                    Text("Console print")
                }
            } icon: {
                Image(systemName: "apple.terminal")
            }
        }
        .onChange(of: debugPrint) { oldValue, newValue in
            if newValue {
                UserDefaults.standard.set("YES", forKey: "debugPrint")
                AppState.shared.debugPrintString = "YES"
            } else {
                UserDefaults.standard.set("NO", forKey: "debugPrint")
                AppState.shared.debugPrintString = "NO"
            }
        }
    }
    
    
    var loadTimeSection: some View {
        Section {
            if funcModel.loadTimes.isEmpty {
                Text("App Initial Load Times")
            } else {
                ForEach(funcModel.loadTimes, id: \.id) { metric in
                    HStack {
                        Text("\(metric.date.string(to: .dateTime))")
                        Spacer()
                        Text("\(metric.load)")
                    }
                }
            }
        } header: {
            HStack {
                Text("Load Times")
                Spacer()
                Button("Clear") {
                    funcModel.loadTimes.removeAll()
                }
                .font(.caption)
            }
            
        } footer: {
            Text("Note: These times are not retained between app launches")
        }
    }
    
    
    var plaidForceRefreshSection: some View {
        Section("Plaid Force Refresh Costs") {
            Button("Refresh") {
                Task { await fetchPlaidCosts() }
            }
            ForEach(plaidCosts) { cost in
                HStack {
                    Text("\(cost.month)-\(String(cost.year))")
                    Spacer()
                    Text(cost.totalCost.currencyWithDecimals(2))
                }
            }
        }
    }
    
    
    
    #if os(macOS)
    @ToolbarContentBuilder
    func macToolbar() -> some ToolbarContent {
        ToolbarItem(placement: .navigation) {
            HStack {
                ToolbarNowButton()
                    .disabled(!AppState.shared.methsExist)
                ToolbarRefreshButton()
                    .toolbarBorder()
                    .disabled(!AppState.shared.methsExist)
            }
        }
        ToolbarItem(placement: .principal) {
            ToolbarCenterView(enumID: .debug)
        }
        ToolbarItem {
            Spacer()
        }
    }
    
    #else
    
    @ToolbarContentBuilder
    func phoneToolbar() -> some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) { ToolbarLongPollButton() }
        ToolbarItem(placement: .topBarTrailing) { ToolbarRefreshButton() }                        
    }
    
    #endif
    
    
    @MainActor
    func fetchPlaidCosts() async {
        let model = RequestModel(requestType: "plaid_get_force_refresh_cost", model: AppState.shared.user!)
        typealias ResultResponse = Result<Array<PlaidForceRefreshCost>?, AppError>
        async let result: ResultResponse = await NetworkManager().arrayRequest(requestModel: model)
        
        switch await result {
        case .success(let model):
            if let model {
                self.plaidCosts = model
            }
        case .failure (let error):
            switch error {
            case .taskCancelled:
                /// Task get cancelled when switching years. So only show the alert if the error is not related to the task being cancelled.
                print("calModel fetchPlaidTransactionsFromServer Server Task Cancelled")
            default:
                AppState.shared.showAlert("There was a problem trying to fetch costs.")
            }
        }
    }
    
}


fileprivate struct LogoList: View {
    @State private var logos: Array<PersistentLogo> = []
    
    var body: some View {
        List(logos) { logo in
            HStack {
                Label {
                    VStack(alignment: .leading) {
                        Text("LogoID: \(logo.id ?? "N/A")")
                        Text("RelatedID: \(String(describing: logo.relatedID))")
                        Text("RelatedTypeID: \(String(describing: logo.relatedTypeID))")
                        Text("ServerUpdated: \(String(describing: logo.serverUpdatedDate?.string(to: .serverDateTime)))")
                        Text("LocalUpdated: \(String(describing: logo.localUpdatedDate?.string(to: .serverDateTime)))")
                    }
                    .font(.caption2)
                } icon: {
                    if let data = logo.photoData, let image = UIImage(data: data) {
                        Image(uiImage: image)
                            .resizable()
                            .frame(width: 30, height: 30, alignment: .center)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "circle.fill")
                    }
                }
            }
        }
        .task {
            print("fetching logos")
            let context = DataManager.shared.container.viewContext
            //let context = DataManager.shared.sharedContext
            if let logos = DataManager.shared.getMany(context: context, type: PersistentLogo.self) {
                self.logos = logos
            }
        }
        .navigationTitle("Stored Logos")
    }
    
}


