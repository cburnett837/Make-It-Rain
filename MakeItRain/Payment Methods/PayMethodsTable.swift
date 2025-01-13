//
//  PaymentMethodsView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/20/24.
//

import SwiftUI

struct PayMethodsTable: View {
    @AppStorage("useWholeNumbers") var useWholeNumbers = false
    #if os(macOS)
    @AppStorage("paymentMethodTableColumnOrder") private var columnCustomization: TableColumnCustomization<CBPaymentMethod>
    #endif
    
    @Environment(FuncModel.self) var funcModel
    @Environment(CalendarModel.self) private var calModel
    @Environment(PayMethodModel.self) private var payModel
    
    @State private var searchText = ""
    
    @State private var deleteMethod: CBPaymentMethod?
    @State private var editPaymentMethod: CBPaymentMethod?
    @State private var paymentMethodEditID: CBPaymentMethod.ID?
    
    @State private var sortOrder = [KeyPathComparator(\CBPaymentMethod.title)]
    //    @State private var sortOrder: [KeyPathComparator<CBPaymentMethod>] = [
    //            .init(\.title, order: .forward),
    //        ]
    
    @State private var showDeleteAlert = false
    
    
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
                Group {
                    #if os(macOS)
                    macTable
                    #else
                    phoneList
                    #endif
                }
            } else {
                ContentUnavailableView("No Payment Methods", systemImage: "creditcard", description: Text("Click the plus button above to add a new payment method."))
                    #if os(iOS)
                    .standardBackground()
                    #endif
            }
        }
        #if os(iOS)
        .navigationTitle("Payment Methods")
        .navigationBarTitleDisplayMode(.inline)
        #endif
        
        /// There seems to be a bug in SwiftUI `Table` that prevents the view from refreshing when adding a new payment method, and then trying to edit it.
        /// When I add a new payment method, and then update `model.paymentMethods` with the new ID from the server, the table still contains an ID of 0 on the newly created payment method.
        /// Setting this id forces the view to refresh and update the relevant payment method with the new ID.
        .id(payModel.fuckYouSwiftuiTableRefreshID)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            #if os(macOS)
            macToolbar()
            #else
            phoneToolbar()
            #endif
        }
        .searchable(text: $searchText) {
            #if os(macOS)
            let relevantTitles: Array<String> = payModel.paymentMethods
                .compactMap { $0.title }
                .uniqued()
                .filter { $0.localizedStandardContains(searchText) }
            
            ForEach(relevantTitles, id: \.self) { title in
                Text(title)
                    .searchCompletion(title)
            }
            #endif
        }
        
        .sheet(item: $editPaymentMethod, onDismiss: {
            paymentMethodEditID = nil
        }, content: { meth in
            PayMethodView(payMethod: meth, payModel: payModel, editID: $paymentMethodEditID)
            #if os(iOS)
            //.presentationDetents([.medium, .large])
            #endif
        })
        .onChange(of: sortOrder) { _, sortOrder in
            payModel.paymentMethods.sort(using: sortOrder)
        }
        .onChange(of: paymentMethodEditID) { oldValue, newValue in
            if let newValue {
                let payMethod = payModel.getPaymentMethod(by: newValue)
                
                if payMethod.accountType == .unifiedChecking || payMethod.accountType == .unifiedCredit {
                    paymentMethodEditID = nil
                    AppState.shared.showAlert("Combined payment methods cannot be edited.")
                } else {
                    editPaymentMethod = payMethod
                }
            } else {
                payModel.savePaymentMethod(id: oldValue!, calModel: calModel)
                payModel.determineIfUserIsRequiredToAddPaymentMethod()
            }
        }
        .confirmationDialog("Delete \"\(deleteMethod == nil ? "N/A" : deleteMethod!.title)\"?", isPresented: $showDeleteAlert, actions: {
            Button("Yes", role: .destructive) {
                if let deleteMethod = deleteMethod {
                    Task {
                        await payModel.delete(deleteMethod, andSubmit: true, calModel: calModel)
                    }
                }
            }
            
            Button("No", role: .cancel) {
                deleteMethod = nil
                showDeleteAlert = false
            }
        }, message: {
            #if os(iOS)
            Text("Delete \"\(deleteMethod == nil ? "N/A" : deleteMethod!.title)\"?\nThis will also delete all associated transactions.")
            #else
            Text("This will also delete all associated transactions.")
            #endif
        })
        
        .sensoryFeedback(.warning, trigger: showDeleteAlert) { oldValue, newValue in
            !oldValue && newValue
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
            }
        }
        ToolbarItem(placement: .principal) {
            ToolbarCenterView()
        }
        ToolbarItem {
            Spacer()
        }
    }
        
    var macTable: some View {
        Table(of: CBPaymentMethod.self, selection: $paymentMethodEditID, sortOrder: $sortOrder, columnCustomization: $columnCustomization) {
            TableColumn("Title", value: \.title) { meth in
                Text(meth.title)
            }
            .customizationID("title")
            
            TableColumn("Account Type", value: \.accountType.rawValue) { meth in
                Text(meth.accountType.rawValue)
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
            
            TableColumn("Color") { meth in
                if meth.accountType != .unifiedChecking && meth.accountType != .unifiedCredit {
                    Circle()
                        .fill(meth.color)
                        .frame(width: 12, height: 12)
                } else {
                    Text("-")
                }
            }
            .customizationID("color")
            
            TableColumn("Default") { meth in
                Toggle(isOn: Binding<Bool>(get: { return meth.isDefault }, set: { meth.isDefault = $0 })) {
                    EmptyView()
                }
                .onChange(of: meth.isDefault) { oldValue, newValue in
                    if meth.isDefault {
                        Task { await payModel.setDefault(meth) }
                    }
                }
            }
            .width(min: 20, ideal: 30, max: 50)
            .customizationID("default")
            
            TableColumn("Delete") { meth in
                if !meth.isUnified {
                    Button {
                        deleteMethod = meth
                        showDeleteAlert = true
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
            }
            .width(min: 20, ideal: 30, max: 50)
            
        } rows: {
            Section("Combined Payment Methods") {
                ForEach(payModel.paymentMethods.filter { $0.isUnified }) { meth in
                    TableRow(meth)
                }
            }
            
            Section("My Payment Methods") {
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
            Button {
                NavigationManager.shared.navPath.removeLast()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
            }
        }
        
        ToolbarItem(placement: .topBarTrailing) {
            HStack {
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
    
    
    var phoneList: some View {
        List(selection: $paymentMethodEditID) {
            Section("Combined Payment Methods") {
                ForEach(payModel.paymentMethods.filter { $0.isUnified }) { meth in
                    HStack {
                        VStack(alignment: .leading) {
                            HStack {
                                if meth.isDefault {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                }
                                
                                Text(meth.title)
                            }
                                                        
                            Text(meth.accountType.rawValue.capitalized)
                                .foregroundStyle(.gray)
                                .font(.caption)
                        }
                        Spacer()
                    }
                    .rowBackground()
                    .swipeActions(allowsFullSwipe: false) {
                        SetDefaultButtonPhone(meth: meth)
                    }
                }
            }
            .rowBackground()
            
            Section("My Payment Methods") {
                ForEach(filteredPayMethods) { meth in
                    HStack(alignment: .circleAndTitle, spacing: 4) {
                        Circle()
                            .fill(meth.color)
                            .frame(width: 12, height: 12)
                            .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
                        
                        if meth.isDefault {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
                        }
                        
                        VStack(alignment: .leading) {
                            HStack {
                                Text(meth.title)
                                Spacer()
                                Text(meth.accountType.rawValue.capitalized)
                                    .foregroundStyle(.gray)
                                    .font(.caption)
                            }
                            .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
                            
                            
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
                    .rowBackgroundWithSelection(id: meth.id, selectedID: paymentMethodEditID)
                    .swipeActions(allowsFullSwipe: false) {
                        SetDefaultButtonPhone(meth: meth)
                        
                        Button {
                            deleteMethod = meth
                            showDeleteAlert = true
                        } label: {
                            Label {
                                Text("Delete")
                            } icon: {
                                Image(systemName: "trash")
                            }
                            
                        }
                        .tint(.red)
                    }
                }
            }
            .rowBackground()
        }
        .listStyle(.plain)
        .standardBackground()
    }
    #endif
    
    
    struct SetDefaultButtonPhone: View {
        @Environment(PayMethodModel.self) private var payModel
        var meth: CBPaymentMethod
        
        var body: some View {
            Button {
                meth.isDefault.toggle()
                if meth.isDefault {
                    Task { await payModel.setDefault(meth) }
                }
            } label: {
                Label {
                    Text("Set Default")
                } icon: {
                    Image(systemName: meth.isDefault ? "checkmark.circle" : "circle")
                }
            }
            .tint(meth.isDefault ? Color.accentColor : .gray)
        }
    }
}
