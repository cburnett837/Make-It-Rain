//
//  PaymentMethodsView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/20/24.
//

import SwiftUI

struct RepeatingTransactionsTable: View {
    @Environment(\.dismiss) var dismiss
    
    @Local(\.useWholeNumbers) var useWholeNumbers
    #if os(macOS)
    @AppStorage("repeatingTransactionsTableColumnOrder") private var columnCustomization: TableColumnCustomization<CBRepeatingTransaction>
    #endif

    @Environment(FuncModel.self) var funcModel
    @Environment(PayMethodModel.self) private var payModel
    @Environment(CategoryModel.self) private var catModel
    @Environment(RepeatingTransactionModel.self) private var repModel
    
    @State private var searchText = ""
    
    @State private var editRepeatingTransaction: CBRepeatingTransaction?
    @State private var repTransactionEditID: CBRepeatingTransaction.ID?
    
    @State private var sortOrder = [KeyPathComparator(\CBRepeatingTransaction.title)]
    @State private var labelWidth: CGFloat = 20.0
    
    var filteredTransactions: [CBRepeatingTransaction] {
        repModel.repTransactions
            .filter { searchText.isEmpty ? !$0.title.isEmpty : $0.title.localizedStandardContains(searchText) }
    }
        
    var body: some View {
        @Bindable var repModel = repModel
        
        Group {
            if !repModel.repTransactions.isEmpty {
                #if os(macOS)
                macTable
                #else
                phoneList
                #endif
            } else {
                ContentUnavailableView("No Reoccuring Transactions", systemImage: "repeat", description: Text("Click the plus button above to add a new repeating transaction."))
            }
        }
        //.loadingSpinner(id: .repeatingTransactions, text: "Loading Reoccuring Transactions…")
        #if os(iOS)
        .navigationTitle("Reoccuring Transactions")
        //.navigationBarTitleDisplayMode(.inline)
        #endif        
        /// There seems to be a bug in SwiftUI `Table` that prevents the view from refreshing when adding a new repTransaction, and then trying to edit it.
        /// When I add a new repTransaction, and then update `model.repTransactions` with the new ID from the server, the table still contains an ID of 0 on the newly created repTransaction.
        /// Setting this id forces the view to refresh and update the relevant repTransaction with the new ID.
        .id(repModel.fuckYouSwiftuiTableRefreshID)
        //.navigationBarBackButtonHidden(true)
        .toolbar {
            #if os(macOS)
            macToolbar()
            #else
            phoneToolbar()
            #endif
        }
        .searchable(text: $searchText)
        .onChange(of: sortOrder) { _, sortOrder in
            repModel.repTransactions.sort(using: sortOrder)
        }
        .sheet(item: $editRepeatingTransaction, onDismiss: { repTransactionEditID = nil }) { rep in
            RepeatingTransactionView(repTransaction: rep, repModel: repModel, catModel: catModel, payModel: payModel, editID: $repTransactionEditID)                
                #if os(macOS)
                .frame(minWidth: 500, minHeight: 700)
                .presentationSizing(.fitted)
                #endif
        }
        .onChange(of: repTransactionEditID) { oldValue, newValue in
            if let newValue {
                editRepeatingTransaction = repModel.getRepeatingTransaction(by: newValue)
            } else {
                repModel.saveTransaction(id: oldValue!)
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
            ToolbarCenterView(enumID: .repeatingTransactions)
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
            
            TableColumn("Account", value: \.payMethod?.title) { repTrans in
                HStack {
                    Circle()
                        .fill(repTrans.payMethod?.color ?? .primary)
                        .frame(width: 12, height: 12)
                    Text(repTrans.payMethod?.title ?? "")
                }
            }
            .customizationID("paymentMethod")
        }
        .clipped()
        .onPreferenceChange(MaxSizePreferenceKey.self) { labelWidth = max(labelWidth, $0) }
    }    
    #endif
    
     
    #if os(iOS)
    @ToolbarContentBuilder
    func phoneToolbar() -> some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) { ToolbarLongPollButton() }
        ToolbarItem(placement: .topBarTrailing) { ToolbarRefreshButton() }
        ToolbarSpacer(.fixed, placement: .topBarTrailing)
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                repTransactionEditID = UUID().uuidString
            } label: {
                Image(systemName: "plus")
            }
            .tint(.none)
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
                        Text("Account")
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
            }            
        }
        .listStyle(.plain)
    }
    #endif
}
