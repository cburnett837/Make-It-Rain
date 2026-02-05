//
//  DebugView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/15/25.
//

import SwiftUI
import PDFKit

struct DebugView: View {
    @AppStorage("shouldWarmUpTransactionViewDuringSplash") var shouldWarmUpTransactionViewDuringSplash: Bool = false

    @Local(\.debugPrint) var debugPrint

    @Environment(CalendarModel.self) var calModel
    @Environment(FuncModel.self) var funcModel
    
    @State private var plaidCosts: Array<PlaidForceRefreshCost> = []
    @State private var showBasicAlert = false
    @State private var text = ""
    @FocusState private var focusedField: Int?
    
    var body: some View {
        List {
            
            //CustomCalculatorKeyboard(text: $text)
            
//            #if os(iOS)
//            customNumPad
//            #endif
            
            Section {
                printAllBudgetsButton
                //documentTester
                NavigationLink("Cache") { CoreDataList() }
            }
            
            
            alertSection
            
            Section("Transaction View") {
                Toggle(isOn: $shouldWarmUpTransactionViewDuringSplash) {
                    Label {
                        VStack(alignment: .leading) {
                            Text("Warm during splash")
                        }
                    } icon: {
                        Image(systemName: "cup.and.heat.waves.fill")
                    }
                }
            }
            
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
    
    
//    var customNumPad: some View {
//        Section {
//            UITextFieldWrapper(placeholder: "Demo", text: $text, toolbar: {
//                KeyboardToolbarView(
//                    focusedField: $focusedField,
//                    accessoryImage3: "plus.forwardslash.minus",
//                    accessoryFunc3: {
//                        Helpers.plusMinus($text)
//                    })
//            })
//            .uiKeyboardType(.custom(.calculator))
//            .focused($focusedField, equals: 0)
//        }
//    }
    
    
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


fileprivate struct CoreDataList: View {
    @Environment(PayMethodModel.self) var payModel
    @Environment(\.dismiss) var dismiss
    
    @State private var logos: Array<PersistentLogo> = []
    @State private var categoryGroups: Array<PersistentCategoryGroup> = []
    @State private var categories: Array<PersistentCategory> = []
    @State private var accounts: Array<PersistentPaymentMethod> = []
    @State private var keywords: Array<PersistentKeyword> = []
    @State private var transactions: Array<TempTransaction> = []
    
    var body: some View {
        List {
            NavigationLink("Categories") { categoryList }
            NavigationLink("Category Groups") { categoryGroupList }
            NavigationLink("Accounts") { accountList }
            NavigationLink("Logos") { logoList }
            NavigationLink("Rules") { keywordsList }
            NavigationLink("Transactions") { transList }
        }
        .task {
            let context = DataManager.shared.container.viewContext
            if let logos = DataManager.shared.getMany(context: context, type: PersistentLogo.self) { self.logos = logos }
            if let categoryGroups = DataManager.shared.getMany(context: context, type: PersistentCategoryGroup.self) { self.categoryGroups = categoryGroups }
            if let categories = DataManager.shared.getMany(context: context, type: PersistentCategory.self) { self.categories = categories }
            if let accounts = DataManager.shared.getMany(context: context, type: PersistentPaymentMethod.self) { self.accounts = accounts }
            if let keywords = DataManager.shared.getMany(context: context, type: PersistentKeyword.self) { self.keywords = keywords }
            if let trans = DataManager.shared.getMany(context: context, type: TempTransaction.self) { self.transactions = trans }
        }
        .navigationTitle("Local Cache")
        .toolbar {
            #if os(iOS)
            ToolbarItem(placement: .topBarTrailing) {
                dumpCoreDataButton
            }
            #else
            ToolbarItem(placement: .confirmationAction) {
                dumpCoreDataButton
            }
            #endif
        }
    }
    
    @State private var showClearCacheAlert = false
    var dumpCoreDataButton: some View {
        Button("Clear Cache") {
            showClearCacheAlert = true
        }
        .schemeBasedForegroundStyle()
        .confirmationDialog("Clear Cache?", isPresented: $showClearCacheAlert) {
            Button("Yes", role: .destructive) {
                let context = DataManager.shared.createContext()
                context.perform {
                    /// Remove all from cache.
                    let _ = DataManager.shared.deleteAll(context: context, for: PersistentPaymentMethod.self)
                    let _ = DataManager.shared.deleteAll(context: context, for: PersistentCategory.self)
                    let _ = DataManager.shared.deleteAll(context: context, for: PersistentCategoryGroup.self)
                    let _ = DataManager.shared.deleteAll(context: context, for: PersistentKeyword.self)
                    let _ = DataManager.shared.deleteAll(context: context, for: PersistentToast.self)
                    let _ = DataManager.shared.deleteAll(context: context, for: PersistentLogo.self)
                    let _ = DataManager.shared.deleteAll(context: context, for: TempTransaction.self)
                    
                    let _ = DataManager.shared.save(context: context)
                }
                
                dismiss()
            }
            #if os(iOS)
            Button("Cancel", role: .close) {}
            #else
            Button("Cancel") {}
            #endif
        } message: {
            Text("Clear Cache?\nThis will only clear your local storage and not the data on the server. Local storage will be re-populated the next time you refresh.")
        }
    }
    
    
    var logoList: some View {
        List(logos) { logo in
            Label {
                VStack(alignment: .leading) {
                    Text("ID: \(logo.id ?? "N/A")")
                    Text("RelatedID: \(logo.relatedID ?? "N/A")")
                    Text("RelatedTypeID: \(logo.relatedTypeID)")
                    
                    if logo.relatedTypeID == 42 {
                        let methTitle = payModel.paymentMethods.first(where: { $0.id == logo.relatedID })?.title ?? "N/A"
                        Text("Account Title: \(methTitle)")
                    }
                    
                    Text("ServerUpdated: \(logo.serverUpdatedDate?.string(to: .serverDateTime) ?? "N/A")")
                    Text("LocalUpdated: \(logo.localUpdatedDate?.string(to: .serverDateTime) ?? "N/A")")
                }
                .font(.caption2)
            } icon: {
                #if os(iOS)
                if let data = logo.photoData, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .frame(width: 30, height: 30, alignment: .center)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "circle.fill")
                }
                #else
                if let data = logo.photoData, let image = NSImage(data: data) {
                    Image(nsImage: image)
                        .resizable()
                        .frame(width: 30, height: 30, alignment: .center)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "circle.fill")
                }
                #endif
            }
        }
        .navigationTitle("Logos Cache")
    }
    
    
    var categoryList: some View {
        List(categories) { cat in
            VStack(alignment: .leading) {
                Text("ID: \(cat.id ?? "N/A")")
                Text("Title: \(cat.title ?? "N/A")")
                Text("Amount: \(cat.amount)")
                Text("Pending: \(cat.isPending ? "yes" : "no")")
                Text("Listorder: \(Int(cat.listOrder))")
                Text("Symbol: \(cat.emoji ?? "N/A")")
            }
            .font(.caption2)
        }
        .navigationTitle("Categories Cache")
    }
    
    
    var categoryGroupList: some View {
        List(categoryGroups) { group in
            VStack(alignment: .leading) {
                Text("ID: \(group.id ?? "N/A")")
                Text("Title: \(group.title ?? "N/A")")
                Text("Amount: \(group.amount)")
                Text("Pending: \(group.isPending ? "yes" : "no")")
            }
            .font(.caption2)
        }
        .navigationTitle("Category Groups Cache")
    }
    
    
    var accountList: some View {
        List(accounts) { act in
            VStack(alignment: .leading) {
                Text("ID: \(act.id ?? "N/A")")
                Text("Title: \(act.title ?? "N/A")")
                Text("Limit: \(act.limit)")
                Text("Pending: \(act.isPending ? "yes" : "no")")
                Text("Listorder: \(Int(act.listOrder))")
            }
            .font(.caption2)
        }
        .navigationTitle("Accounts Cache")
    }
    
    var keywordsList: some View {
        List(keywords) { key in
            VStack(alignment: .leading) {
                Text("ID: \(key.id ?? "N/A")")
                Text("Title: \(key.keyword ?? "N/A")")
                Text("Pending: \(key.isPending ? "yes" : "no")")
                Text("Rename To: \(key.renameTo ?? "N/A")")
            }
            .font(.caption2)
        }
        .navigationTitle("Rules Cache")
    }
    
    var transList: some View {
        List(transactions) { trans in
            VStack(alignment: .leading) {
                Text("ID: \(trans.id ?? "N/A")")
                Text("Title: \(trans.title ?? "N/A")")
                Text("Amount: \(trans.amount)")
            }
            .font(.caption2)
        }
        .navigationTitle("Transactions Cache")
    }
}
