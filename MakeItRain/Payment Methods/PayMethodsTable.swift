//
//  PaymentMethodsView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/20/24.
//

import SwiftUI

//struct PaymentMethodSectionData: Identifiable {
//    let id = UUID()
//    var title: String
//    var items: [CBPaymentMethod] // Optional: if sections also contain reorderable items
//}

struct PayMethodsTable: View {
    @Local(\.useBusinessLogos) var useBusinessLogos
    @AppStorage("paymentMethodTableColumnOrder") private var columnCustomization: TableColumnCustomization<CBPaymentMethod>
    
    @Environment(\.dismiss) var dismiss
    @Environment(FuncModel.self) var funcModel
    @Environment(CalendarModel.self) private var calModel
    @Environment(PayMethodModel.self) private var payModel
    
    @Environment(PlaidModel.self) private var plaidModel
    
    @State private var searchText = ""
    @State private var selectedPaymentMethod: CBPaymentMethod?
    @State private var editPaymentMethod: CBPaymentMethod?
    @State private var paymentMethodEditID: CBPaymentMethod.ID?
    @State private var sortOrder = [KeyPathComparator(\CBPaymentMethod.title)]
    
    @State private var defaultViewingMethod: CBPaymentMethod?
    @State private var defaultEditingMethod: CBPaymentMethod?
    @State private var showDefaultViewingSheet = false
    @State private var showDefaultEditingSheet = false
    
    @State private var navPath = NavigationPath()
    
    var listOrders: [Int] {
        payModel.paymentMethods.map { $0.listOrder ?? 0 }.sorted { $0 > $1 }
    }
        
//    var filteredPayMethods: [CBPaymentMethod] {
//        payModel.paymentMethods
//            .filter { !$0.isUnified }
//            .filter { $0.isPermitted }
//            .filter { searchText.isEmpty ? !$0.title.isEmpty : $0.title.localizedCaseInsensitiveContains(searchText) }
//            //.sorted { $0.title.lowercased() < $1.title.lowercased() }
//    }
//    
//    var debitMethods: [CBPaymentMethod] {
//        payModel.paymentMethods
//            .filter { $0.isPermitted }
//            .filter { $0.accountType == .checking || $0.accountType == .unifiedChecking }
//            .filter { searchText.isEmpty ? true : $0.title.localizedCaseInsensitiveContains(searchText) }
//    }
//    
//    var creditMethods: [CBPaymentMethod] {
//        payModel.paymentMethods
//            .filter { $0.isPermitted }
//            .filter { $0.accountType == .credit || $0.accountType == .unifiedCredit || $0.accountType == .loan }
//            .filter { searchText.isEmpty ? true : $0.title.localizedCaseInsensitiveContains(searchText) }
//    }
//    
//    var otherMethods: [CBPaymentMethod] {
//        payModel.paymentMethods
//            .filter { $0.isPermitted }
//            .filter { $0.accountType != .checking && $0.accountType != .credit && $0.accountType != .loan && !$0.isUnified }
//            .filter { searchText.isEmpty ? true : $0.title.localizedCaseInsensitiveContains(searchText) }
//    }
//    var sections: Array<SectionData> {
//        return [
//            SectionData(title: "Debit", items: debitMethods),
//            SectionData(title: "Credit", items: creditMethods),
//            SectionData(title: "Other", items: otherMethods)
//        ]
//    }
    
    
    /// Keep the sections in the model so they don't flash every time you go to the account table on the iPad.
    //@State private var sections: Array<PaySection> = []
    
    var somethingChanged: Int {
        var hasher = Hasher()
        /// Update when the user searches.
        hasher.combine(searchText)
        /// Update the sheet if viewing and something changes on another device.
        hasher.combine(payModel.paymentMethods.filter { !$0.isHidden && !$0.isPrivate }.count)
        /// Update when a new payment method gets added or deleted.
        hasher.combine(payModel.paymentMethods.count)
        /// Update when the list order changes via long poll.
        hasher.combine(payModel.paymentMethods.map { $0.listOrder ?? 0 }.sorted { $0 > $1 })
        return hasher.finalize()
    }

    
    var body: some View {
        @Bindable var payModel = payModel
        NavigationStack(path: $navPath) {
            VStack {
                if !payModel.paymentMethods.filter({ !$0.isUnified }).isEmpty {
                    #if os(macOS)
                    macTable
                    #else
                    if AppState.shared.isIphone {
                        phoneList
                    } else {
                        padList
                    }
                    #endif
                } else {
                    ContentUnavailableView("No Accounts", systemImage: "creditcard", description: Text("Click the plus button above to add a new account."))
                }
            }
            #if os(iOS)
            .navigationTitle("Accounts")
            //.navigationBarTitleDisplayMode(.inline)
            #endif
            
            #if os(macOS)
            /// There seems to be a bug in SwiftUI `Table` that prevents the view from refreshing when adding a new payment method, and then trying to edit it.
            /// When I add a new payment method, and then update `model.paymentMethods` with the new ID from the server, the table still contains an ID of 0 on the newly created payment method.
            /// Setting this id forces the view to refresh and update the relevant payment method with the new ID.
            .id(payModel.fuckYouSwiftuiTableRefreshID)
            #endif
            .navigationBarBackButtonHidden(true)
            .task {
                defaultViewingMethod = payModel.paymentMethods.filter { $0.isViewingDefault }.first
                defaultEditingMethod = payModel.paymentMethods.filter { $0.isEditingDefault }.first
                /// NOTE: Sorting must be done here and not in the computed property. If done in the computed property, when reordering, they get all messed up.
                payModel.paymentMethods.sort(by: Helpers.paymentMethodSorter())
                //populateSections()
            }
            .navigationDestination(for: CBPaymentMethod.self) { meth in
                PayMethodOverView(payMethod: meth, navPath: $navPath)
            }
            .toolbar {
                #if os(macOS)
                macToolbar()
                #else
                phoneToolbar()
                #endif
            }
            .searchable(text: $searchText)
            .onAppear {
                print("Clear the breakdowns")
                payModel.paymentMethods.forEach {
                    $0.breakdowns.removeAll()
                    $0.breakdownsRegardlessOfPaymentMethod.removeAll()
                }
            }
            //.onChange(of: AppSettings.shared.paymentMethodFilterMode) { populateSections() }
            //.onChange(of: AppSettings.shared.paymentMethodSortMode) { populateSections() }
            //.onChange(of: somethingChanged) { populateSections() }
            .onChange(of: sortOrder) { payModel.paymentMethods.sort(using: $1) }
//            .sheet(item: $editPaymentMethod, onDismiss: {
//                paymentMethodEditID = nil
//                payModel.determineIfUserIsRequiredToAddPaymentMethod()
//            }) { meth in
//                PayMethodEditView(payMethod: meth, editID: $paymentMethodEditID)
//                    #if os(macOS)
//                    .frame(minWidth: 500, minHeight: 700)
//                    .presentationSizing(.fitted)
//                    #else
//                    .presentationSizing(.page)
//                    #endif
//            }
            .onChange(of: paymentMethodEditID) { oldValue, newValue in
                if let newValue {
                    let payMethod = payModel.getPaymentMethod(by: newValue)
                    selectedPaymentMethod = payMethod
                } else {
                    selectedPaymentMethod = nil
                }
            }
            .sheet(item: $selectedPaymentMethod, onDismiss: {
                paymentMethodEditID = nil
                payModel.determineIfUserIsRequiredToAddPaymentMethod()
            }) { meth in
                PayMethodOverViewWrapperIpad(payMethod: meth)
                    #if os(macOS)
                    .frame(minWidth: 300, minHeight: 500)
                    .presentationSizing(.page)
                    #endif
                    //.presentationSizing(.page)
            }
            .sheet(isPresented: $showDefaultViewingSheet, onDismiss: setDefaultViewingMethod) {
                PayMethodSheet(payMethod: $defaultViewingMethod, whichPaymentMethods: .all, showNoneOption: true)
                    #if os(macOS)
                    .frame(minWidth: 300, minHeight: 500)
                    .presentationSizing(.page)
                    #endif
            }
            .sheet(isPresented: $showDefaultEditingSheet, onDismiss: setDefaultEditingMethod) {
                PayMethodSheet(payMethod: $defaultEditingMethod, whichPaymentMethods: .allExceptUnified, showNoneOption: true)
                    #if os(macOS)
                    .frame(minWidth: 300, minHeight: 500)
                    .presentationSizing(.page)
                    #endif
            }
        }
    }
    
    #if os(macOS)
    @ToolbarContentBuilder
    func macToolbar() -> some ToolbarContent {
        ToolbarItem(placement: .navigation) {
            HStack {
                Button {
                    paymentMethodEditID = UUID().uuidString
                } label: {
                    Image(systemName: "plus")
                }
                .toolbarBorder()
                //.disabled(payModel.isThinking)
                
                ToolbarNowButton()
                    .disabled(!AppState.shared.methsExist)
                ToolbarRefreshButton()
                    .toolbarBorder()
                    .disabled(!AppState.shared.methsExist)
                
                moreMenu
                    .toolbarBorder()
                    .disabled(!AppState.shared.methsExist)
            }
        }
        ToolbarItem(placement: .principal) {
            ToolbarCenterView(enumID: .paymentMethods)
        }
        ToolbarItem {
            Spacer()
        }
    }
      
    
    var macTable: some View {
        Table(of: CBPaymentMethod.self, selection: $paymentMethodEditID, sortOrder: $sortOrder, columnCustomization: $columnCustomization) {
            TableColumn("Title", value: \.title) { meth in
                HStack {
                    if meth.accountType != .unifiedChecking && meth.accountType != .unifiedCredit {
                        Circle()
                            .fill(meth.color)
                            .frame(width: 12, height: 12)
                    } else {
                        Text("-")
                    }
                    Text(meth.title)
                }
            }
            .customizationID("title")
            
            TableColumn("Account Type", value: \.accountType.rawValue) { meth in
                Text(XrefModel.getItem(from: .accountTypes, byID: meth.accountType.rawValue).description)
            }
            .customizationID("accountType")
            
            TableColumn("Last 4", value: \.last4) { meth in
                if meth.accountType == .checking || meth.accountType == .credit {
                    Text(meth.last4 ?? "-")
                } else {
                    Text("-")
                }
            }
            .customizationID("last4")
            
            TableColumn("Limit", value: \.limit.specialDefaultIfNil) { meth in
                if meth.accountType == .credit {
                    Text(meth.limit?.currencyWithDecimals() ?? "-")
                } else {
                    Text("-")
                }
            }
            .customizationID("limit")
            
            TableColumn("Due Date", value : \.dueDate.specialDefaultIfNil) { meth in
                if meth.accountType == .credit || meth.accountType == .loan {
                    Text("The \(meth.dueDate?.withOrdinal() ?? "N/A") of every month")
                    //Text("The \(String(meth.dueDate ?? 0)) of every month")
                } else {
                    Text("-")
                }
            }
            .customizationID("dueDate")
            
//            TableColumn("Reminder", value: \.notificationOffset.specialDefaultIfNil) { meth in
//                if meth.accountType == .credit || meth.accountType == .loan {
//                    if meth.notifyOnDueDate {
//                        Label {
//                            let text = meth.notificationOffset == 0 ? "On day of" : (meth.notificationOffset == 1 ? "The day before" : "2 days before")
//                            Text(text)
//                        } icon: {
//                            Image(systemName: "alarm")
//                        }
//                    }
//                } else {
//                    Text("-")
//                }
//            }
//            .customizationID("reminder")
            
            TableColumn("Viewing (default)") { meth in
                if meth.isViewingDefault {
                    Image(systemName: "checkmark")
                }
            }
            .width(min: 20, ideal: 30, max: 50)
            .customizationID("defaultViewing")
            
            TableColumn("Editing (default)") { meth in
                if meth.isEditingDefault {
                    Image(systemName: "checkmark")
                }
            }
            .width(min: 20, ideal: 30, max: 50)
            .customizationID("defaultEditing")
            
            TableColumn("Private") { meth in
                if meth.isPrivate {
                    Image(systemName: "checkmark")
                }
            }
            .width(min: 20, ideal: 30, max: 50)
            .customizationID("private")
            
            TableColumn("Hidden") { meth in
                if meth.isHidden {
                    Image(systemName: "checkmark")
                }
            }
            .width(min: 20, ideal: 30, max: 50)
            .customizationID("hidden")
        } rows: {
//            Section("Combined Accounts") {
//                ForEach(payModel.paymentMethods.filter { $0.isUnified }) { meth in
//                    TableRow(meth)
//                }
//            }
//            
//            Section("My Accounts") {
//                ForEach(filteredPayMethods) { meth in
//                    TableRow(meth)
//                }
//            }
            
            
            ForEach(payModel.sections) { section in
                Section(section.rawValue) {
                    ForEach(payModel.getMethodsFor(section: section, type: .all, sText: searchText, includeHidden: true)) { meth in
                        TableRow(meth)
                    }
                }
            }
            
//            Section("Debit") {
//                ForEach(debitMethods) { meth in
//                    TableRow(meth)
//                }
//            }
//            
//            Section("Credit") {
//                ForEach(creditMethods) { meth in
//                    TableRow(meth)
//                }
//            }
//            
//            Section("Other") {
//                ForEach(otherMethods) { meth in
//                    TableRow(meth)
//                }
//            }
        }
        .clipped()

    }   
    #endif
    
    
    #if os(iOS)
    @ToolbarContentBuilder
    func phoneToolbar() -> some ToolbarContent {
        @Bindable var payModel = payModel
        ToolbarItem(placement: .topBarLeading) {
            Menu {
                PayMethodFilterMenu()
                PayMethodSortMenu()
                //moreMenu
                
                Section("Default Viewing Account") {
                    showDefaultForViewingSheetButton
                }
                
                Section("Default Editing Account") {
                    showDefaultForEditingSheetButton
                }
                
                Section("Appearance") {
                    useBusinessLogosToggle
                }
                
            } label: {
                Image(systemName: "ellipsis")
                    .schemeBasedForegroundStyle()
            }

            
        }
        //ToolbarItem(placement: .topBarLeading) { PayMethodSortMenu(sections: $payModel.sections) }
        //ToolbarSpacer(.fixed, placement: .topBarLeading)
        //ToolbarItem(placement: .topBarLeading) { moreMenu }
        
        ToolbarItem(placement: .topBarTrailing) { ToolbarLongPollButton() }
        ToolbarItem(placement: .topBarTrailing) { ToolbarRefreshButton().disabled(!AppState.shared.methsExist) }
        //ToolbarSpacer(.fixed, placement: .topBarTrailing)
        ToolbarItem(placement: .topBarTrailing) { newAccountButton }
    }
    
        
    /// On iPhone, use the navigation links directly in the list.
    @ViewBuilder
    var phoneList: some View {
        @Bindable var payModel = payModel
        
        List {
            ForEach(payModel.sections) { section in
                Section(section.rawValue) {
                    ForEach(methodsBinding(for: section)) { meth in
                        NavigationLink(value: meth.wrappedValue) {
                            line(for: meth.wrappedValue)
                        }
                    }
                    .if(AppSettings.shared.paymentMethodSortMode == .listOrder) {
                        $0.onMove { indices, newOffset in
                            methodsBinding(for: section)
                                .wrappedValue
                                .move(fromOffsets: indices, toOffset: newOffset)
                            
                            Task {
                                let updates = await payModel.setListOrders(calModel: calModel)
                                await funcModel.submitListOrders(items: updates, for: .paymentMethods)
                            }
                        }
                    }
                }
            }
            
//            ForEach(payModel.sections) { section in
//                Section(section.rawValue) {
//                    ForEach(payModel.getMethodsFor(section: section, type: .all, sText: searchText, includeHidden: true)) { meth in
//                        NavigationLink(value: meth) {
//                            line(for: meth)
//                        }
//                    }
//                    .if(AppSettings.shared.paymentMethodSortMode == .listOrder) {
//                        $0.onMove { indices, newOffset in
//                            payModel.paymentMethods.move(fromOffsets: indices, toOffset: newOffset)
//                            Task {
//                                let listOrderUpdates = await payModel.setListOrders(calModel: calModel)
//                                let _ = await funcModel.submitListOrders(items: listOrderUpdates, for: .paymentMethods)
//                            }
//                        }
//                    }
//                }
//            }
        }
        .listStyle(.plain)
    }
    
    func methodsBinding(for section: PaymentMethodSection) -> Binding<[CBPaymentMethod]> {
        Binding(
            get: {
                payModel.getMethodsFor(section: section, type: .all, sText: searchText, includeHidden: true)
                //payModel.paymentMethods
//                    .filter { $0.sectionType == section }
//                    .sorted { $0.listOrder ?? 0 < $1.listOrder ?? 0 }
            },
            set: { newValue in
                for (index, method) in newValue.enumerated() {
                    if let globalIndex = payModel.paymentMethods.firstIndex(where: { $0.id == method.id }) {
                        payModel.paymentMethods[globalIndex].listOrder = index
                    }
                }
            }
        )
    }
    
    
    /// On iPad, bind the list to a selection property, which will get caught in an onChange and open the details sheet.
    /// For whatever reason, a button directly in the list was not opening the details sheet directly. I would have to go to another section in the app, and come back in order for it to work. Assume it's a `NavigationStack` issue.
    @ViewBuilder
    var padList: some View {
        @Bindable var payModel = payModel
        
//        List(selection: $paymentMethodEditID) {
//            ForEach($payModel.sections) { $section in
//                Section(section.kind.rawValue) {
//                    ForEach(section.payMethods) { meth in
//                        line(for: meth)
//                    }
//                    .if(AppSettings.shared.paymentMethodSortMode == .listOrder) {
//                        $0.onMove { indices, newOffset in
//                            // Move within this section only
//                            section.payMethods.move(fromOffsets: indices, toOffset: newOffset)
//                            Task {
//                                let listOrderUpdates = await payModel.setListOrders(sections: payModel.sections, calModel: calModel)
//                                let _ = await funcModel.submitListOrders(items: listOrderUpdates, for: .paymentMethods)
//                            }
//                        }
//                    }
//                }
//            }
//        }
//        .listStyle(.plain)
    }
    
    
    @ViewBuilder func line(for meth: CBPaymentMethod) -> some View {
        if meth.isUnified {
            Label {
                VStack(alignment: .leading) {
                    HStack {
                        Text(meth.title)
                        Spacer()
                        
                        if meth.isDebitOrCash {
                            Text("\(funcModel.getPlaidDebitSums().currencyWithDecimals())")
                            
                        } else if meth.isCreditOrLoan {
                            Text("\(funcModel.getPlaidCreditSums().currencyWithDecimals())")
                        }
                    }
                    
                    HStack {
                        Text(XrefModel.getItem(from: .accountTypes, byID: meth.accountType.rawValue).description)
                            .foregroundStyle(.gray)
                            .font(.caption)
                        
                        Spacer()
                    }
                    
                }
            } icon: {
                //BusinessLogo(parent: meth, fallBackType: .gradient)
//                BusinessLogo(config: .init(
//                    parent: meth,
//                    fallBackType: .gradient
//                ))
                BusinessLogo(config: .init(
                    parent: meth,
                    fallBackType: .gradient
                ))
            }
        } else {
            Label {
                VStack(alignment: .leading) {
                    HStack {
                        Text(meth.title)
                        if meth.isPrivate { Image(systemName: "person.slash") }
                        if meth.isHidden { Image(systemName: "eye.slash") }
                        if meth.notifyOnDueDate { Image(systemName: "alarm") }
                                                
                        Spacer()
                        
                        if let balance = plaidModel.balances.filter({ $0.payMethodID == meth.id }).first {
                            Text(balance.amount.currencyWithDecimals())
                        }
                    }
                    
                    HStack {
                        Text(XrefModel.getItem(from: .accountTypes, byID: meth.accountType.rawValue).description)
                            .foregroundStyle(.gray)
                            .font(.caption)
                        Spacer()
                        
                        if let balance = plaidModel.balances.filter({ $0.payMethodID == meth.id }).first {
                            Text(Date().timeSince(balance.enteredDate))
                                .foregroundStyle(.gray)
                                .font(.caption)
                        }
                    }
                }
            } icon: {
                BusinessLogo(config: .init(
                    parent: meth,
                    fallBackType: .color
                ))
                //BusinessLogo(parent: meth, fallBackType: .color)
            }
        }
    }
    
   
    var newAccountButton: some View {
        Button {
            let newId = UUID().uuidString
            
            /// On iPhone, push the details page to the nav, which will auto-open the edit sheet.
            if AppState.shared.isIphone {
                let newMeth = payModel.getPaymentMethod(by: newId)
                navPath.append(newMeth)
            } else {
                /// On iPad, trigger the details sheet to open, which will then open the edit sheet.
                //#error("On Ipad, when closing the edit sheet, the details sheet freaks out.")
                paymentMethodEditID = newId
            }
        } label: {
            Image(systemName: "plus")
        }
        .tint(.none)
        
    }

    #endif
    
    var useBusinessLogosToggle: some View {
        Toggle(isOn: $useBusinessLogos) {
            Text("Use Business Logos")
        }
    }
    
    
    
    var moreMenu: some View {
        Menu {
            Section("Default Viewing Account") {
                showDefaultForViewingSheetButton
            }
            
            Section("Default Editing Account") {
                showDefaultForEditingSheetButton
            }
            
            Section("Appearance") {
                useBusinessLogosToggle
            }
            
//            Section("View") {
//                Button("Card") {
//                    selectedView = "card"
//                }
//                Button("List") {
//                    selectedView = "list"
//                }
//            }
            
        } label: {
            Label("More", systemImage: "ellipsis")            
        }
        .tint(.none)
    }
    
    
    var showDefaultForViewingSheetButton: some View {
        Button {
            showDefaultViewingSheet = true
        } label: {
            let defaultMeth = payModel.paymentMethods.filter { $0.isViewingDefault }.first
            Label {
                Text(defaultMeth?.title ?? "[Select]")
            } icon: {
                Image(systemName: "circle.fill")
                    .tint(defaultMeth?.color ?? .primary)
            }
        }
    }
    
    
    var showDefaultForEditingSheetButton: some View {
        Button {
            showDefaultEditingSheet = true
        } label: {
            let defaultMeth = payModel.paymentMethods.filter { $0.isEditingDefault }.first
            Label {
                Text(defaultMeth?.title ?? "[Select]")
            } icon: {
                Image(systemName: "circle.fill")
                    .tint(defaultMeth?.color ?? .primary)
            }
        }
    }
    
    
    struct SetDefaultButtonPhone: View {
        @Environment(PayMethodModel.self) private var payModel
        var meth: CBPaymentMethod
        
        var body: some View {
            Button {
                meth.isViewingDefault.toggle()
                if meth.isViewingDefault {
                    Task { await payModel.setDefaultViewing(meth) }
                }
            } label: {
                Label {
                    Text("Set Default")
                } icon: {
                    Image(systemName: meth.isViewingDefault ? "checkmark.circle" : "circle")
                }
            }
            .tint(meth.isViewingDefault ? Color.accentColor : .gray)
        }
    }
    
    
//    func populateSections() {
//        let newSections = payModel.getApplicablePayMethods(
//            type: .all,
//            calModel: calModel,
//            plaidModel: plaidModel,
//            searchText: $searchText,
//            includeHidden: true
//        )
//        
//        /// Use this to allow the animations to work when adding or removing a payment method.
//        for newSection in newSections {
//            if let index = payModel.sections.firstIndex(where: { $0.kind == newSection.kind }) {
//                
//                let oldSection = payModel.sections[index]
//                
//                for meth in newSection.payMethods {
//                    if oldSection.doesExist(meth) {
//                        if let index = oldSection.getIndex(for: meth) {
//                            oldSection.payMethods[index].setFromAnotherInstance(payMethod: meth)
//                        }
//                    } else {
//                        withAnimation {
//                            oldSection.upsert(meth)
//                        }
//                    }
//                }
//                                                        
//                for meth in oldSection.payMethods {
//                    if !newSection.doesExist(meth) {
//                        withAnimation {
//                            oldSection.payMethods.removeAll { $0.id == meth.id }
//                        }
//                    }
//                }
//                
//                withAnimation {
//                    oldSection.payMethods.sort(by: Helpers.paymentMethodSorter())
//                }
//            }
//        }
//    
//    }
    
    
    func setDefaultViewingMethod() {
        
        print("-- \(#function)")
        
        Task { await payModel.setDefaultViewing(defaultViewingMethod) }
        
//        if let defaultViewingMethod = defaultViewingMethod {
//            if let currentDefaultID = payModel.paymentMethods.filter({ $0.isViewingDefault }).first?.id {
//                if currentDefaultID != defaultViewingMethod.id {
//                    defaultViewingMethod.isViewingDefault = true
//                    Task { await payModel.setDefaultViewing(defaultViewingMethod) }
//                }
//            }
//        } else {
//            print("not set")
//        }
        
        
    }
    
    
    func setDefaultEditingMethod() {
        print("-- \(#function)")
        Task { await payModel.setDefaultEditing(defaultViewingMethod) }
        
        
//        if let defaultEditingMethod = defaultEditingMethod {
//            if let currentDefaultID = payModel.paymentMethods.filter({ $0.isEditingDefault }).first?.id {
//                if currentDefaultID != defaultEditingMethod.id {
//                    defaultEditingMethod.isEditingDefault = true
//                    Task { await payModel.setDefaultEditing(defaultEditingMethod) }
//                }
//            } else {
//                defaultEditingMethod.isEditingDefault = true
//                Task { await payModel.setDefaultEditing(defaultEditingMethod) }
//            }
//        } else {
//            print("not set")
//        }
    }
    
//    func move(from source: IndexSet, to destination: Int) {
//        payModel.paymentMethods.move(fromOffsets: source, toOffset: destination)
//
//        
////        /// Create an index map of non-nil items.
////        let filteredIndices = payModel.paymentMethods.enumerated()
////            .map { $0.offset }
////
////        /// Convert filtered indices to original indices.
////        guard let sourceInFiltered = source.first, sourceInFiltered < filteredIndices.count, destination <= filteredIndices.count else { return }
////
////        let ogSourceIndex = filteredIndices[sourceInFiltered]
////        let ogDestIndex = destination == filteredIndices.count ? payModel.paymentMethods.count : filteredIndices[destination]
////
////        /// Mutate the original array.
////        payModel.paymentMethods.move(fromOffsets: IndexSet(integer: ogSourceIndex), toOffset: ogDestIndex)
//                
//         Task {
//             let listOrderUpdates = await payModel.setListOrders(calModel: calModel)
//             let _ = await funcModel.submitListOrders(items: listOrderUpdates, for: .paymentMethods)
//         }
//    }
}



//@State private var expandCards = false
//@State private var currentPaymentMethod: CBPaymentMethod?
//@State private var showDetailCard: Bool = false
//@Namespace var animation
//
//@ViewBuilder
//var phoneList2: some View {
//    //List(selection: $paymentMethodEditID) {
//    VStack(spacing: 0) {
//        ScrollView {
//        
////                ForEach(payModel.paymentMethods.filter { $0.isUnified }) { meth in
////                    cardView(for: meth)
////                }
//            
//            ForEach(filteredPayMethods) { meth in
//                
//                Group {
//                    if currentPaymentMethod?.id == meth.id && showDetailCard {
//                        cardViewContainer(for: meth)
//                            .opacity(0)
//                    } else {
//                        cardViewContainer(for: meth)
//                            .matchedGeometryEffect(id: meth.id, in: animation)
//                            
//                    }
//                }
//                .padding(.horizontal, 20)
//                
//                
//            }
//        }
//        .coordinateSpace(name: "PaymentMethodTableList")
//    }
//    //.listStyle(.plain)
//    .frame(maxWidth: .infinity, maxHeight: .infinity)
//    .overlay {
//        if let currentPaymentMethod, showDetailCard {
//            DetailView(currentPaymentMethod: currentPaymentMethod, showDetailCard: $showDetailCard, animation: animation)
//        }
//    }
//}
//
//
//
//@ViewBuilder func cardViewContainer(for meth: CBPaymentMethod) -> some View {
//    GeometryReader { geo in
//        let rect = geo.frame(in: .named("PaymentMethodTableList"))
//        let offset = CGFloat(getIndex(for: meth) * (expandCards ? 10 : 70))
//        
//        
//        CardView(meth: meth)
//        .offset(y: expandCards ? offset : -rect.minY + offset)
//    }
//    .frame(height: 200)
//    .onTapGesture {
//        //withAnimation(.interactiveSpring(response: 0.8, dampingFraction: 0.7, blendDuration: 0.7)) {
//        withAnimation(.easeInOut(duration: 0.35)) {
//            currentPaymentMethod = meth
//            showDetailCard = true
//            
//            
////                if expandCards {
////                    expandCards = false
////                } else {
////                    expandCards = true
////                }
//        }
//    }
//}
//
//struct CardView: View {
//    
//    
//    var meth: CBPaymentMethod
//    var body: some View {
//        ZStack {
//            RoundedRectangle(cornerRadius: 20)
//            //.fill(LinearGradient(gradient: Gradient(colors: [meth.color, .clear]), startPoint: .leading, endPoint: .trailing))
//            
//                .fill(meth.color.gradient)
//                .frame(height: 200)
//            
//            VStack(alignment: .leading) {
//                VStack(alignment: .leading) {
//                    HStack {
//                        Text(meth.title)
//                            .font(.title)
//                        Spacer()
//                        Group {
//                            if meth.accountType == .credit || meth.accountType == .checking {
//                                Image(systemName: "creditcard.fill")
//                            } else if meth.accountType == .cash {
//                                Image(systemName: "banknote.fill")
//                            } else {
//                                Image(systemName: "building.columns.fill")
//                            }
//                        }
//                        .font(.title)
//                    }
//                    
//                    
//                    if meth.accountType == .credit {
//                        Group {
//                            Text("Limit of \(meth.limit?.currencyWithDecimals() ?? "-")")
//                            Text("Due on the \(meth.dueDate?.withOrdinal() ?? "N/A")")
//                            if meth.notifyOnDueDate {
//                                let text = meth.notificationOffset == 0 ? "on day of" : (meth.notificationOffset == 1 ? "the day before" : "2 days before")
//                                Text("Remind me \(text)")
//                            }
//                            
//                        }
//                        .font(.subheadline)
//                        
//                    }
//                }
//                
//                
//                Spacer()
//                
//                HStack {
//                    Text(AppState.shared.user!.name)
//                    Spacer()
//                }
//                
//                
//                HStack {
//                    if meth.accountType == .checking || meth.accountType == .credit {
//                        if meth.last4 == nil {
//                            Text("N/A")
//                        } else {
//                            Text("**** **** **** \(meth.last4 ?? "-")")
//                        }
//                    } else {
//                        Text("N/A")
//                    }
//                    
//                    Spacer()
//                    Text(meth.accountType.rawValue.capitalized)
//                        .bold()
//                }
//            }
//            .padding()
//            
//        }
//    }
//}
//
//
//
//
//func getIndex(for meth: CBPaymentMethod) -> Int {
//    return filteredPayMethods.firstIndex { currentCard in
//        return currentCard.id == meth.id
//    } ?? 0
//}
//
//
//
//struct DetailView: View {
//    var currentPaymentMethod: CBPaymentMethod
//    @Binding var showDetailCard: Bool
//    
//    var animation: Namespace.ID
//        
//    @State private var showExpenses = false
//
//    var body: some View {
//        VStack {
//            CardView(meth: currentPaymentMethod)
//                .matchedGeometryEffect(id: currentPaymentMethod.id, in: animation)
//                .frame(height: 200)
//                .onTapGesture {
//                    //withAnimation(.interactiveSpring(response: 0.8, dampingFraction: 0.7, blendDuration: 0.7)) {
//                    
//                    withAnimation(.easeInOut) {
//                        showExpenses = false
//                    }
//                    
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
//                        withAnimation(.easeInOut(duration: 0.35)) {
//                            showDetailCard = false
//                        }
//                    })
//                    
//                    
//                    
//                }
//                .padding()
//                .zIndex(10)
//            
//            
//            GeometryReader { geo in
//                
//                let height = geo.size.height + 50
//                
//                ScrollView {
//                    VStack(spacing: 20) {
//                        
//                    }
//                    .padding()
//                }
//                .frame(maxWidth: .infinity)
//                .background(
//                    Color(.tertiarySystemBackground)
//                        .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
//                        .ignoresSafeArea()
//                )
//                .offset(y: showExpenses ? 0 : height)
//                                    
//            }
//            .padding([.horizontal, .top])
//            .zIndex(-10)
//            
//            
//            
//        }
//        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
//        .background(Color(.secondarySystemBackground).ignoresSafeArea())
//        .onAppear {
//            withAnimation(.easeInOut.delay(0.1)) {
//                showExpenses = true
//            }
//
//        }
//    }
//}
