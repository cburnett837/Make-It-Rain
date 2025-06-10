//
//  PlaidTransactionOverlay.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/28/25.
//

import SwiftUI

struct PlaidTransactionOverlay: View {
    @Local(\.colorTheme) var colorTheme
    
    #if os(macOS)
    @Environment(\.dismiss) private var dismiss
    #endif
    @Environment(CalendarModel.self) private var calModel
    @Environment(CategoryModel.self) private var catModel
    @Environment(PayMethodModel.self) private var payModel
    @Environment(PlaidModel.self) private var plaidModel
    
    @Binding var bottomPanelContent: BottomPanelContent?
    @Binding var bottomPanelHeight: CGFloat
    @Binding var scrollContentMargins: CGFloat
    
    @State private var showClearBeforeDatePicker = false
    @State private var clearDate: Date = Date()
    
    @State private var rowNumber = 1
    
    var plaidTransactions: [CBPlaidTransaction] {
        plaidModel.trans.filter({ !$0.isAcknowledged })
    }
    
    var body: some View {
        StandardContainer(AppState.shared.isIpad ? .sidebarScrolling : .bottomPanel) {
            content
        } header: {
            if AppState.shared.isIpad {
                sidebarHeader
            } else {
                sheetHeader
            }
        }
    }
    
    
    var content: some View {
        Group {
            if plaidTransactions.isEmpty {
                if plaidModel.isFetchingMoreTransactions {
                     ProgressView()
                        .tint(.none)
                } else {
                    ContentUnavailableView("No Plaid Transactions", systemImage: "bag.fill.badge.questionmark")
                }
                
            } else {
                
                if showClearBeforeDatePicker {
                    VStack {
                        Text("Choose a date to reject transactions")
                        Text("All transactions before this date will be rejected.")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                        
                        DatePicker("", selection: $clearDate, displayedComponents: .date)
                            .labelsHidden()
                        
                        HStack {
                            Button("Cancel") {
                                showClearBeforeDatePicker = false
                            }
                            .buttonStyle(.borderedProminent)
                            
                            Button("Clear") {
                                Task {
                                    let dummyTrans = CBTransaction()
                                    dummyTrans.date = clearDate
                                    await plaidModel.clearPlaidTransactionBeforeDate(dummyTrans)
                                    
                                    for each in plaidModel.trans {
                                        if let date = each.date {
                                            if date < clearDate {
                                                each.isAcknowledged = true
                                                plaidModel.delete(each)
                                            }
                                        }
                                    }
                                    showClearBeforeDatePicker = false
                                }
                            }
                            .tint(.red)
                            .buttonStyle(.borderedProminent)
                        }
                    }
                } else {
                    VStack(spacing: 0) {
                        ForEach(plaidTransactions) { trans in
                            LineItem(trans: trans)
                                .padding(.horizontal, 8)
                        }
                        
                        if plaidTransactions.count >= 50 {
                            loadMoreButton
                                .padding(.top, 20)
                        }
                    }
                }
            }
        }
    }
    
    
    var sheetHeader: some View {
        SheetHeader(
            title: "Plaid Transactions",
            close: {
                #if os(iOS)
                withAnimation {
                    bottomPanelContent = nil
                }
                #else
                dismiss()
                #endif
            },
            view1: {
                Button {
                    rowNumber = 1
                    loadFromServer(removeAllBefore: true)
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .contentShape(Rectangle())
                }
            },
            view2: { moreMenu }
        )
        //.background(Color.red)
        #if os(iOS)
        .bottomPanelAndScrollViewHeightAdjuster(bottomPanelHeight: $bottomPanelHeight, scrollContentMargins: $scrollContentMargins)
        #endif
    }
    
    @ViewBuilder
    var moreMenu: some View {
        Menu {
            Button("Reject everything before date…") {
                showClearBeforeDatePicker = true
            }
        } label: {
            Image(systemName: "ellipsis")
                .contentShape(Rectangle())
        }
    }
    
    
    var sidebarHeader: some View {
        SidebarHeader(
            title: "Plaid Transactions",
            close: {
                rowNumber = 1
                #if os(iOS)
                withAnimation {
                    bottomPanelContent = nil
                }
                #else
                dismiss()
                #endif
            },
            view1: {
                Button {
                    rowNumber = 1
                    loadFromServer(removeAllBefore: true)
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .contentShape(Rectangle())
                }
            }
        )
    }
        
    
    var loadMoreButton: some View {
        Button {
            rowNumber += 50
            loadFromServer(removeAllBefore: false)
        } label: {
            Text("Fetch 50 more")
                .opacity(plaidModel.isFetchingMoreTransactions ? 0 : 1)
        }
        .disabled(plaidModel.isFetchingMoreTransactions)
        .buttonStyle(.borderedProminent)
        .overlay {
            ProgressView()
                .tint(.none)
                .opacity(plaidModel.isFetchingMoreTransactions ? 1 : 0)
        }
    }
    
    
    func loadFromServer(removeAllBefore: Bool) {
        
        if removeAllBefore {
            plaidModel.trans.removeAll()
        }
        
        plaidModel.isFetchingMoreTransactions = true
        let fetchModel = PlaidServerModel(rowNumber: rowNumber)
        Task {
            await plaidModel.fetchPlaidTransactionsFromServer(fetchModel)
            plaidModel.isFetchingMoreTransactions = false
        }
    }
    
    
    struct LineItem: View {
        @Local(\.colorTheme) var colorTheme
        @Local(\.useWholeNumbers) var useWholeNumbers

        @Environment(CalendarModel.self) private var calModel
        @Environment(CategoryModel.self) private var catModel
        @Environment(PlaidModel.self) private var plaidModel
        
        var trans: CBPlaidTransaction
        
        var body: some View {
            VStack(spacing: 0) {
                HStack {
                    ScrollView(.horizontal, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 0) {
                            
                            HStack(spacing: 0) {
                                CircleDot(color: trans.category?.color, width: 10)
                                Text(trans.title.capitalized)
                            }
                            
                            HStack(spacing: 0) {
                                CircleDot(color: trans.payMethod?.color, width: 10)
                                Text(trans.amount.currencyWithDecimals(useWholeNumbers ? 0 : 2))
                                    .foregroundStyle(.gray)
                                    .font(.footnote)
                            }
                            
                            Text(trans.prettyDate ?? "N/A")
                                .foregroundStyle(.gray)
                                .font(.caption2)
                        }
                    }
                    
                    Spacer()
                    Button("Accept") {
                        let buttonConfig = AlertConfig.ButtonConfig(text: "Yes", role: .primary) { accept() }
                        let config = AlertConfig(
                            title: "Accept \(trans.title)?",
                            subtitle: trans.prettyDate ?? "N/A",
                            symbol: .init(name: "checkmark.circle.badge.questionmark", color: .green),
                            primaryButton: AlertConfig.AlertButton(config: buttonConfig)
                        )
                        
                        AppState.shared.showAlert(config: config)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.fromName(colorTheme))
                    
                    Button("Reject") {
                        let buttonConfig = AlertConfig.ButtonConfig(text: "Yes", role: .destructive) { reject() }
                        let config = AlertConfig(
                            title: "Reject \(trans.title)?",
                            subtitle: trans.prettyDate ?? "N/A",
                            symbol: .init(name: "checkmark.circle.badge.questionmark", color: .orange),
                            primaryButton: AlertConfig.AlertButton(config: buttonConfig)
                        )
                        
                        AppState.shared.showAlert(config: config)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.gray)
                }
                
                Divider()
                    .padding(.vertical, 2)
            }
            .listRowInsets(EdgeInsets())
        }
        
        
        func accept() {
            trans.isAcknowledged = true
            
            if trans.payMethod?.isCredit ?? false {
                if trans.amountString.contains("-") {
                    trans.amountString = trans.amountString.replacingOccurrences(of: "-", with: "")
                } else {
                    trans.amountString = "-\(trans.amountString)"
                }
            }
            
            if trans.category == nil {
                trans.category = catModel.categories.filter { $0.isNil }.first
            }
            
            let realTrans = CBTransaction(plaidTrans: trans)
            
            if let targetMonth = calModel.months.filter({ $0.actualNum == realTrans.date?.month && $0.year == realTrans.date?.year }).first {
                if let targetDay = targetMonth.days.filter({ $0.dateComponents?.day == realTrans.date?.day }).first {
                    targetDay.upsert(realTrans)
                }
            }
            
            calModel.tempTransactions.append(realTrans)
            calModel.saveTransaction(id: realTrans.id, location: .tempList)
        }
        
        
        func reject() {
            trans.isAcknowledged = true
            Task {
                await plaidModel.denyPlaidTransaction(trans)
                plaidModel.trans.removeAll(where: {$0.id == trans.id})
            }
        }
    }
}
