//
//  PaymentMethodsView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/20/24.
//

import SwiftUI

struct PayMethodsTable: View {
    @Environment(\.dismiss) var dismiss
    
    @Local(\.useWholeNumbers) var useWholeNumbers
    #if os(macOS)
    @AppStorage("paymentMethodTableColumnOrder") private var columnCustomization: TableColumnCustomization<CBPaymentMethod>
    #endif
    
    @Environment(FuncModel.self) var funcModel
    @Environment(CalendarModel.self) private var calModel
    @Environment(PayMethodModel.self) private var payModel
    @Environment(EventModel.self) private var eventModel
    @Environment(PlaidModel.self) private var plaidModel
    
    @State private var searchText = ""
    @State private var editPaymentMethod: CBPaymentMethod?
    @State private var paymentMethodEditID: CBPaymentMethod.ID?
    @State private var sortOrder = [KeyPathComparator(\CBPaymentMethod.title)]
    
    @State private var defaultViewingMethod: CBPaymentMethod?
    @State private var defaultEditingMethod: CBPaymentMethod?
    @State private var showDefaultViewingSheet = false
    @State private var showDefaultEditingSheet = false
        
    var filteredPayMethods: [CBPaymentMethod] {
        payModel.paymentMethods
            .filter { !$0.isUnified }
            .filter { searchText.isEmpty ? !$0.title.isEmpty : $0.title.localizedStandardContains(searchText) }
            //.sorted { $0.title.lowercased() < $1.title.lowercased() }
    }
    
    var body: some View {
        @Bindable var payModel = payModel
        
        Group {
            if !payModel.paymentMethods.filter({ !$0.isUnified }).isEmpty {
                #if os(macOS)
                macTable
                #else
                phoneList
                #endif
            } else {
                ContentUnavailableView("No Accounts", systemImage: "creditcard", description: Text("Click the plus button above to add a new account."))
            }
        }
        #if os(iOS)
        .navigationTitle("Accounts")
        //.navigationBarTitleDisplayMode(.inline)
        #endif
        
        /// There seems to be a bug in SwiftUI `Table` that prevents the view from refreshing when adding a new payment method, and then trying to edit it.
        /// When I add a new payment method, and then update `model.paymentMethods` with the new ID from the server, the table still contains an ID of 0 on the newly created payment method.
        /// Setting this id forces the view to refresh and update the relevant payment method with the new ID.
        .id(payModel.fuckYouSwiftuiTableRefreshID)
        .navigationBarBackButtonHidden(true)
        .task {
            defaultViewingMethod = payModel.paymentMethods.filter { $0.isViewingDefault }.first
            defaultEditingMethod = payModel.paymentMethods.filter { $0.isEditingDefault }.first
        }
        .toolbar {
            #if os(macOS)
            macToolbar()
            #else
            phoneToolbar()
            #endif
        }
        .searchable(text: $searchText)
        .onChange(of: sortOrder) { _, sortOrder in
            payModel.paymentMethods.sort(using: sortOrder)
        }
        .sheet(item: $editPaymentMethod, onDismiss: {
            paymentMethodEditID = nil
            payModel.determineIfUserIsRequiredToAddPaymentMethod()
        }) { meth in
            PayMethodView(payMethod: meth, editID: $paymentMethodEditID)
                #if os(iOS)
                .presentationSizing(.page)
                #else
                .frame(minWidth: 500, minHeight: 700)
                .presentationSizing(.fitted)
                #endif
        }
        .onChange(of: paymentMethodEditID) { oldValue, newValue in
            if let newValue {
                let payMethod = payModel.getPaymentMethod(by: newValue)
                editPaymentMethod = payMethod
            } else {
                payModel.savePaymentMethod(id: oldValue!, calModel: calModel)
                payModel.determineIfUserIsRequiredToAddPaymentMethod()
            }
        }
        .sheet(isPresented: $showDefaultViewingSheet, onDismiss: setDefaultViewingMethod) {
            PayMethodSheet(payMethod: $defaultViewingMethod, whichPaymentMethods: .all, showStartingAmountOption: false)
                #if os(macOS)
                .frame(minWidth: 300, minHeight: 500)
                .presentationSizing(.fitted)
                #endif
        }
        .sheet(isPresented: $showDefaultEditingSheet, onDismiss: setDefaultEditingMethod) {
            PayMethodSheet(payMethod: $defaultEditingMethod, whichPaymentMethods: .allExceptUnified, showStartingAmountOption: false)
                #if os(macOS)
                .frame(minWidth: 300, minHeight: 500)
                .presentationSizing(.fitted)
                #endif
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
                
                defaultPayMethodMenu
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
            TableColumn("Color") { meth in
                if meth.accountType != .unifiedChecking && meth.accountType != .unifiedCredit {
                    Circle()
                        .fill(meth.color)
                        .frame(width: 12, height: 12)
                } else {
                    Text("-")
                }
            }
            .width(min: 20, ideal: 30, max: 50)
            .customizationID("color")
            
            TableColumn("Title", value: \.title) { meth in
                Text(meth.title)
            }
            .customizationID("title")
            
            TableColumn("Account Type", value: \.accountType.rawValue) { meth in
                Text(XrefModel.getItem(from: .accountTypes, byID: meth.accountType.rawValue).description)
            }
            .customizationID("accountType")
            
            TableColumn("Limit", value: \.limit.specialDefaultIfNil) { meth in
                if meth.accountType == .credit {
                    Text(meth.limit?.currencyWithDecimals(useWholeNumbers ? 0 : 2) ?? "-")
                } else {
                    Text("-")
                }
            }
            .customizationID("limit")
            
            TableColumn("Last 4", value: \.last4) { meth in
                if meth.accountType == .checking || meth.accountType == .credit {
                    Text(meth.last4 ?? "-")
                } else {
                    Text("-")
                }
            }
            .customizationID("last4")
            
            TableColumn("Due Date", value : \.dueDate.specialDefaultIfNil) { meth in
                if meth.accountType == .credit {
                    Text("The \(meth.dueDate?.withOrdinal() ?? "N/A") of every month")
                    //Text("The \(String(meth.dueDate ?? 0)) of every month")
                } else {
                    Text("-")
                }
            }
            .customizationID("dueDate")
            
            TableColumn("Reminder", value: \.notificationOffset.specialDefaultIfNil) { meth in
                if meth.accountType == .credit {
                    if meth.notifyOnDueDate {
                        Label {
                            let text = meth.notificationOffset == 0 ? "On day of" : (meth.notificationOffset == 1 ? "The day before" : "2 days before")
                            Text(text)
                        } icon: {
                            Image(systemName: "bell")
                        }
                    }
                } else {
                    Text("-")
                }
            }
            .customizationID("reminder")
            
            TableColumn("Default Viewing") { meth in
                Toggle(isOn: Binding<Bool>(get: { return meth.isViewingDefault }, set: { meth.isViewingDefault = $0 })) {
                    EmptyView()
                }
                .onChange(of: meth.isViewingDefault) { oldValue, newValue in
                    if meth.isViewingDefault {
                        Task { await payModel.setDefaultViewing(meth) }
                    }
                }
            }
            .width(min: 20, ideal: 30, max: 50)
            .customizationID("defaultViewing")
            
            TableColumn("Default Editing") { meth in
                Toggle(isOn: Binding<Bool>(get: { return meth.isEditingDefault }, set: { meth.isEditingDefault = $0 })) {
                    EmptyView()
                }
                .onChange(of: meth.isEditingDefault) { oldValue, newValue in
                    if meth.isEditingDefault {
                        Task { await payModel.setDefaultEditing(meth) }
                    }
                }
            }
            .width(min: 20, ideal: 30, max: 50)
            .customizationID("defaultEditing")            
        } rows: {
            Section("Combined Accounts") {
                ForEach(payModel.paymentMethods.filter { $0.isUnified }) { meth in
                    TableRow(meth)
                }
            }
            
            Section("My Accounts") {
                ForEach(filteredPayMethods) { meth in
                    TableRow(meth)
                }
            }
        }
        .clipped()

    }   
    #endif
    
    #if os(iOS)
    @ToolbarContentBuilder
    func phoneToolbar() -> some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            if AppState.shared.isIphone {
                HStack {
                    defaultPayMethodMenu
//                    Button {
//                        dismiss() //NavigationManager.shared.selection = nil // NavigationManager.shared.navPath.removeLast()
//                    } label: {
//                        HStack(spacing: 4) {
//                            Image(systemName: "chevron.left")
//                            Text("Back")
//                        }
//                    }
                    //ToolbarLongPollButton()
                }
                
            } else {
                HStack(spacing: 20) {
                    Button {
                        paymentMethodEditID = UUID().uuidString
                    } label: {
                        Image(systemName: "plus")
                    }
                    //.disabled(payModel.isThinking)
                    
                    ToolbarRefreshButton()
                        .disabled(!AppState.shared.methsExist)
                                        
                    defaultPayMethodMenu
                        .disabled(!AppState.shared.methsExist)
                    
                    ToolbarLongPollButton()
                }
            }
        }
        
        if AppState.shared.isIphone {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 20) {
                    
                    ToolbarLongPollButton()
                    
                    ToolbarRefreshButton()
                        .disabled(!AppState.shared.methsExist)
                    
                    Button {
                        paymentMethodEditID = UUID().uuidString
                    } label: {
                        Image(systemName: "plus")
                    }
                    //.disabled(payModel.isThinking)
                }
            }
        }
    }
    
    
    var debitMethods: [CBPaymentMethod] {
        payModel.paymentMethods
            .filter { $0.accountType == .checking || $0.accountType == .unifiedChecking }
            .filter { searchText.isEmpty ? true : $0.title.localizedStandardContains(searchText) }
    }
    
    var creditMethods: [CBPaymentMethod] {
        payModel.paymentMethods
            .filter { $0.accountType == .credit || $0.accountType == .unifiedCredit }
            .filter { searchText.isEmpty ? true : $0.title.localizedStandardContains(searchText) }
    }
    
    var otherMethods: [CBPaymentMethod] {
        payModel.paymentMethods
            .filter { $0.accountType != .checking && $0.accountType != .credit && !$0.isUnified }
            .filter { searchText.isEmpty ? true : $0.title.localizedStandardContains(searchText) }
    }
    
    var phoneList: some View {
        List(selection: $paymentMethodEditID) {
            
            Section("Debit") {
                ForEach(debitMethods) { meth in
                    line(for: meth)
                }
            }
            
            Section("Credit") {
                ForEach(creditMethods) { meth in
                    line(for: meth)
                }
            }
            
            Section("Other") {
                ForEach(otherMethods) { meth in
                    line(for: meth)
                }
            }
            
            
//            Section("Combined Payment Methods") {
//                ForEach(payModel.paymentMethods.filter { $0.isUnified }) { meth in
//                    HStack {
//                        VStack(alignment: .leading) {
//                            HStack {
//                                if meth.isViewingDefault {
//                                    Image(systemName: "checkmark.circle.fill")
//                                        .foregroundStyle(.green)
//                                }
//                                
//                                Text(meth.title)
//                            }
//                                                        
//                            Text(meth.accountType.rawValue.capitalized)
//                                .foregroundStyle(.gray)
//                                .font(.caption)
//                        }
//                        Spacer()
//                    }
//                    .swipeActions(allowsFullSwipe: false) {
//                        if !meth.isViewingDefault {
//                            SetDefaultButtonPhone(meth: meth)
//                        }
//                    }
//                }
//            }
//            
//            Section("My Payment Methods") {
//                ForEach(filteredPayMethods) { meth in
//                    line(for: meth)
//                    .swipeActions(allowsFullSwipe: false) {
//                        if !meth.isViewingDefault {
//                            SetDefaultButtonPhone(meth: meth)
//                        }
//                        
//                        Button {
//                            deleteMethod = meth
//                            showDeleteAlert = true
//                        } label: {
//                            Label {
//                                Text("Delete")
//                            } icon: {
//                                Image(systemName: "trash")
//                            }
//                            
//                        }
//                        .tint(.red)
//                    }
//                }
//            }
        }
        .listStyle(.plain)
    }
    
    
    @ViewBuilder func line(for meth: CBPaymentMethod) -> some View {
        if meth.isUnified {
            HStack {
                Circle()
                    .fill(AngularGradient(gradient: Gradient(colors: [.red, .yellow, .green, .blue, .purple, .red]), center: .center))
                    .frame(width: 12, height: 12)
                                                
                    Text(meth.title)
                    Spacer()
                    Text(XrefModel.getItem(from: .accountTypes, byID: meth.accountType.rawValue).description)
                        .foregroundStyle(.gray)
                        .font(.caption)
            }
        } else {
            HStack(alignment: .circleAndTitle, spacing: 4) {
                Circle()
                    .fill(meth.color)
                    .frame(width: 12, height: 12)
                    .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
                
                if meth.isViewingDefault {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
                }
                
                VStack(alignment: .leading) {
                    HStack {
                        Text(meth.title)
                        Spacer()
                        Text(XrefModel.getItem(from: .accountTypes, byID: meth.accountType.rawValue).description)
                            .foregroundStyle(.gray)
                            .font(.caption)
                    }
                    .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
                    
                    if let balance = plaidModel.balances.filter({ $0.payMethodID == meth.id }).first {
                        HStack {
                            //Text("Balance as of \(balance.lastTimeICheckedPlaidSyncedDate?.string(to: .monthDayYearHrMinAmPm) ?? "N/A"):")
                            Text("Balance as of \(balance.lastTimePlaidSyncedWithInstitutionDate?.string(to: .monthDayYearHrMinAmPm) ?? "N/A"):")
                            
                            Spacer()
                            
                            Text(balance.amountString)
                        }
                        .foregroundStyle(.gray)
                        .font(.caption)
                    }
                    
                    
                    if meth.accountType == .checking || meth.accountType == .credit {
                        HStack {
                            Text("Last 4:")
                            Spacer()
                            if meth.last4 == nil {
                                Text("N/A")
                            } else {
                                Text("xxxxx\(meth.last4 ?? "-")")
                            }
                        }
                        .foregroundStyle(.gray)
                        .font(.caption)
                    }
                    
                    if meth.accountType == .credit {
                        HStack {
                            Text("Limit:")
                            Spacer()
                            if meth.accountType == .credit {
                                Text(meth.limit?.currencyWithDecimals(useWholeNumbers ? 0 : 2) ?? "-")
                            }
                        }
                        .foregroundStyle(.gray)
                        .font(.caption)
                    
                    
                        HStack {
                            Text("Due Date:")
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("The \(meth.dueDate?.withOrdinal() ?? "N/A")")
                            }
                        }
                        .foregroundStyle(.gray)
                        .font(.caption)
                    }
                    
                    
                    if meth.notifyOnDueDate {
                        HStack {
                            Text("Reminder:")
                            Spacer()
                            let text = meth.notificationOffset == 0 ? "On day of" : (meth.notificationOffset == 1 ? "The day before" : "2 days before")
                            Text(text)
                        }
                        .foregroundStyle(.gray)
                        .font(.caption)
                    }
                }
            }
        }
    }
    
    
    
    
    
    
    
    #endif
    
    
    var defaultPayMethodMenu: some View {
        Menu {
            Section("Default for viewing") {
                showDefaultForViewingSheetButton
            }
            
            Section("Default for editing") {
                showDefaultForEditingSheetButton
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
            Image(systemName: "ellipsis.circle")
        }
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
    
    
    func setDefaultViewingMethod() {
        //print("-- \(#function)")
        if let defaultViewingMethod = defaultViewingMethod {
            if let currentDefaultID = payModel.paymentMethods.filter({ $0.isViewingDefault }).first?.id {
                if currentDefaultID != defaultViewingMethod.id {
                    defaultViewingMethod.isViewingDefault = true
                    Task { await payModel.setDefaultViewing(defaultViewingMethod) }
                }
            }
        } else {
            print("not set")
        }
    }
    
    
    func setDefaultEditingMethod() {
        //print("-- \(#function)")
        if let defaultEditingMethod = defaultEditingMethod {
            if let currentDefaultID = payModel.paymentMethods.filter({ $0.isEditingDefault }).first?.id {
                if currentDefaultID != defaultEditingMethod.id {
                    defaultEditingMethod.isEditingDefault = true
                    Task { await payModel.setDefaultEditing(defaultEditingMethod) }
                }
            }
        } else {
            print("not set")
        }
    }
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
//    @Local(\.useWholeNumbers) var useWholeNumbers
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
//                            Text("Limit of \(meth.limit?.currencyWithDecimals(useWholeNumbers ? 0 : 2) ?? "-")")
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
