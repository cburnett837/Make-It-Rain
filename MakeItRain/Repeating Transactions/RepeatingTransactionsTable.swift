//
//  PaymentMethodsView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/20/24.
//

import SwiftUI

struct RepeatingTransactionsTable: View {
    @Environment(\.dismiss) var dismiss
    
    @AppStorage("useWholeNumbers") var useWholeNumbers = false
    @AppStorage("preferDarkMode") var preferDarkMode: Bool = true
    #if os(macOS)
    @AppStorage("repeatingTransactionsTableColumnOrder") private var columnCustomization: TableColumnCustomization<CBRepeatingTransaction>
    #endif

    @Environment(FuncModel.self) var funcModel
    @Environment(PayMethodModel.self) private var payModel
    @Environment(CategoryModel.self) private var catModel
    @Environment(RepeatingTransactionModel.self) private var repModel
    
    @State private var searchText = ""
    
    @State private var deleteRepeatingTransaction: CBRepeatingTransaction?
    @State private var editRepeatingTransaction: CBRepeatingTransaction?
    @State private var repTransactionEditID: CBRepeatingTransaction.ID?
    
    @State private var sortOrder = [KeyPathComparator(\CBRepeatingTransaction.title)]
    
    @State private var showDeleteAlert = false
    @State private var labelWidth: CGFloat = 20.0
    
    var filteredTransactions: [CBRepeatingTransaction] {
        repModel.repTransactions
            .filter { searchText.isEmpty ? !$0.title.isEmpty : $0.title.localizedStandardContains(searchText) }
    }
        
    var body: some View {
        @Bindable var repModel = repModel
        
        Group {
            if !repModel.repTransactions.isEmpty {
                Group {
                    #if os(macOS)
                    macTable
                    #else
                    phoneList
                    #endif
                }
            } else {
                ContentUnavailableView("No Reoccuring Transactions", systemImage: "repeat", description: Text("Click the plus button above to add a new repeating transaction."))
                    #if os(iOS)
                    .standardBackground()
                    #endif
            }
        }
        //.loadingSpinner(id: .repeatingTransactions, text: "Loading Reoccuring Transactions…")
        #if os(iOS)
        .navigationTitle("Reoccuring Transactions")
        .navigationBarTitleDisplayMode(.inline)
        #endif        
        /// There seems to be a bug in SwiftUI `Table` that prevents the view from refreshing when adding a new repTransaction, and then trying to edit it.
        /// When I add a new repTransaction, and then update `model.repTransactions` with the new ID from the server, the table still contains an ID of 0 on the newly created repTransaction.
        /// Setting this id forces the view to refresh and update the relevant repTransaction with the new ID.
        .id(repModel.fuckYouSwiftuiTableRefreshID)
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
            let relevantTitles: Array<String> = repModel.repTransactions
                .compactMap { $0.title }
                .uniqued()
                .filter { $0.localizedStandardContains(searchText) }
                    
            ForEach(relevantTitles, id: \.self) { title in
                Text(title)
                    .searchCompletion(title)
            }
            #endif
        }
        
        .onChange(of: sortOrder) { _, sortOrder in
            repModel.repTransactions.sort(using: sortOrder)
        }
        
        .sheet(item: $editRepeatingTransaction, onDismiss: {
            repTransactionEditID = nil
        }, content: { rep in
            RepeatingTransactionView(repTransaction: rep, repModel: repModel, catModel: catModel, payModel: payModel, editID: $repTransactionEditID)
        })
        .onChange(of: repTransactionEditID) { oldValue, newValue in
            if let newValue {
                editRepeatingTransaction = repModel.getRepeatingTransaction(by: newValue)
            } else {
                repModel.saveTransaction(id: oldValue!)
            }
        }

        .confirmationDialog("Delete \"\(deleteRepeatingTransaction == nil ? "N/A" : deleteRepeatingTransaction!.title)\"?", isPresented: $showDeleteAlert, actions: {
            Button("Yes", role: .destructive) {
                if let deleteRepeatingTransaction = deleteRepeatingTransaction {
                    Task {
                        await repModel.delete(deleteRepeatingTransaction, andSubmit: true)
                    }
                }
            }
            
            Button("No", role: .cancel) {
                deleteRepeatingTransaction = nil
                showDeleteAlert = false
            }
        }, message: {
            #if os(iOS)
            Text("Delete \"\(deleteRepeatingTransaction == nil ? "N/A" : deleteRepeatingTransaction!.title)\"?")
            #endif
        })        
        .sensoryFeedback(.warning, trigger: showDeleteAlert) { oldValue, newValue in
            !oldValue && newValue
        }
        .task {
            repModel.repTransactions.forEach {
                $0.flipColor(preferDarkMode: preferDarkMode)
            }
        }
    }
    
    #if os(macOS)
    @ToolbarContentBuilder
    func macToolbar() -> some ToolbarContent {
        ToolbarItem(placement: .navigation) {
            HStack {
                Button {
                    repTransactionEditID = UUID().uuidString
                } label: {
                    Image(systemName: "plus")
                }
                .toolbarBorder()
                //.disabled(repModel.isThinking)
                
                ToolbarNowButton()
                
                ToolbarRefreshButton()
                    .toolbarBorder()
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
        Table(filteredTransactions, selection: $repTransactionEditID, sortOrder: $sortOrder, columnCustomization: $columnCustomization) {
            TableColumn("Title", value: \.title) { repTrans in
                Text(repTrans.title)
            }
            .customizationID("title")
            
            TableColumn("Amount", value: \.amount) { repTrans in
                Text(repTrans.amount.currencyWithDecimals(useWholeNumbers ? 0 : 2))
            }
            .customizationID("amount")
            
            TableColumn("Category", value: \.category?.title) { repTrans in
                HStack {
                    if let cat = repTrans.category {
                        Image(systemName: cat.emoji ?? "")
                            .foregroundStyle(cat.color)
                            .frame(minWidth: labelWidth, alignment: .center)
                        Text(cat.title)
                    } else {
                        Circle()
                            .fill(repTrans.category?.color ?? .primary)
                            .frame(width: labelWidth, height: labelWidth)
                        Text(repTrans.category?.title ?? "N/A")
                    }
                }
            }
            .customizationID("category")
            
            TableColumn("Payment Method", value: \.payMethod?.title) { repTrans in
                HStack {
                    Circle()
                        .fill(repTrans.payMethod?.color ?? .primary)
                        .frame(width: 12, height: 12)
                    Text(repTrans.payMethod?.title ?? "")
                }
            }
            .customizationID("paymentMethod")
            
            TableColumn("Delete") { repTrans in
                Button {
                    deleteRepeatingTransaction = repTrans
                    showDeleteAlert = true
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
            .width(min: 20, ideal: 30, max: 50)
        }
        .clipped()
        .onPreferenceChange(MaxSizePreferenceKey.self) { labelWidth = max(labelWidth, $0) }
    }
    #endif
    
     
    #if os(iOS)
    @ToolbarContentBuilder
    func phoneToolbar() -> some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            if !AppState.shared.isIpad {
                Button {
                    dismiss() //NavigationManager.shared.selection = nil // NavigationManager.shared.navPath.removeLast()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
            } else {
                HStack {
                    ToolbarRefreshButton()
                    Button {
                        repTransactionEditID = UUID().uuidString
                    } label: {
                        Image(systemName: "plus")
                    }
                    //.disabled(repModel.isThinking)
                }
            }
        }
        
        if !AppState.shared.isIpad {
            ToolbarItem(placement: .topBarTrailing) {
                HStack {
                    ToolbarRefreshButton()
                    Button {
                        repTransactionEditID = UUID().uuidString
                    } label: {
                        Image(systemName: "plus")
                    }
                    //.disabled(repModel.isThinking)
                }
            }
        }
    }
    
    var phoneList: some View {
        List(filteredTransactions, selection: $repTransactionEditID) { repTrans in
            HStack(alignment: .circleAndTitle, spacing: 4) {
                
                Circle()
                    .fill(repTrans.category?.color ?? .clear)
                    .frame(width: 12, height: 12)
                    .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
                
                VStack(alignment: .leading) {
                    
                    
                    HStack {
                        Text(repTrans.title)
                        Spacer()
                        Text(repTrans.amount.currencyWithDecimals(useWholeNumbers ? 0 : 2))
                            .foregroundStyle(.gray)
                            .font(.caption)
                    }
                    .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
                                       
                    
                    
                    HStack {
                        Text("Payment Method:")
                        Spacer()
                        Text(repTrans.payMethod?.title ?? "N/A")
                    }
                    .foregroundStyle(.gray)
                    .font(.caption)
                    
                    HStack {
                        Text("Category:")
                        Spacer()
                        Text(repTrans.category?.title ?? "N/A")
                    }
                    .foregroundStyle(.gray)
                    .font(.caption)
                }
                Spacer()
                
            }
            .rowBackgroundWithSelection(id: repTrans.id, selectedID: repTransactionEditID)
            .swipeActions(allowsFullSwipe: false) {
                Button {
                    deleteRepeatingTransaction = repTrans
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
        .listStyle(.plain)
        .standardBackground()
    }
    #endif
}
