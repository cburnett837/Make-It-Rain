//
//  PlaidTransactionOverlay.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/28/25.
//

import SwiftUI

struct PlaidTransactionOverlay: View {
    @Local(\.colorTheme) var colorTheme
    @Environment(\.colorScheme) private var colorScheme
    #if os(macOS)
    @Environment(\.dismiss) private var dismiss
    #endif
    @Environment(CalendarProps.self) private var calProps    
    @Environment(CalendarModel.self) private var calModel
    @Environment(CategoryModel.self) private var catModel
    @Environment(PayMethodModel.self) private var payModel
    @Environment(PlaidModel.self) private var plaidModel
    
    //@Binding var bottomPanelContent: BottomPanelContent?
    //@Binding var bottomPanelHeight: CGFloat
    //@Binding var scrollContentMargins: CGFloat
    
    @State private var showClearBeforeDatePicker = false
    @State private var clearDate: Date = Date()
    
    @State private var rowNumber = 1
    @State private var selectedMeth: CBPaymentMethod?
    
    @Binding var showInspector: Bool
    
    var plaidTransactions: [CBPlaidTransaction] {
        plaidModel.trans
            .filter({ !$0.isAcknowledged })
            .filter({ selectedMeth == nil ? true : $0.payMethod == selectedMeth })
    }
    
    var body: some View {
        if AppState.shared.isIphone {
            StandardContainer(AppState.shared.isIpad ? .sidebarScrolling : .bottomPanel) {
                content
            } header: {
                sheetHeader
            }
        } else {
            NavigationStack {
                StandardContainerWithToolbar(.list) {
                    content
                }
                .navigationTitle("Plaid Transactions")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) { refreshButton }
                    ToolbarSpacer(.fixed, placement: .topBarLeading)
                    ToolbarItem(placement: .topBarLeading) { moreMenu }
                    ToolbarItem(placement: .topBarTrailing) { closeButton }
                }
                #endif
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
    
    
    @ViewBuilder var sheetHeader: some View {
        @Bindable var calProps = calProps
        SheetHeader(
            title: "Plaid Transactions",
            close: {
                #if os(iOS)
                withAnimation {
                    calProps.bottomPanelContent = nil
                }
                #else
                dismiss()
                #endif
            },
            view1: {
                refreshButton
            },
            view2: { moreMenu }
        )
        //.background(Color.red)
//        #if os(iOS)
//        .bottomPanelAndScrollViewHeightAdjuster(bottomPanelHeight: $calProps.bottomPanelHeight, scrollContentMargins: $calProps.scrollContentMargins)
//        #endif
    }
    
    @ViewBuilder
    var moreMenu: some View {
        Menu {
            Button("Reject everything before date…") {
                showClearBeforeDatePicker = true
            }
            
            Menu("Filter By Account") {
                Picker("", selection: $selectedMeth) {
                    let meths = plaidModel.trans
                        .compactMap { $0.payMethod }
                        .uniqued(on: \.id)
                    
                    Text("None")
                        .strikethrough()
                        .tag(nil as CBPaymentMethod?)
                    
                    ForEach(meths) { meth in
                        Text(meth.title)
                            .tag(meth)
                    }
                }
                .labelsHidden()
            }
            
            
        } label: {
            Image(systemName: "ellipsis")
                .contentShape(Rectangle())
                .foregroundStyle(colorScheme == .dark ? .white : .black)
        }
    }
    
    
    var refreshButton: some View {
        Button {
            rowNumber = 1
            loadFromServer(removeAllBefore: true)
        } label: {
            Image(systemName: "arrow.triangle.2.circlepath")
                .contentShape(Rectangle())
                .foregroundStyle(colorScheme == .dark ? .white : .black)
        }
    }
    
    
    var closeButton: some View {
        Button {
            rowNumber = 1
            #if os(iOS)
                if AppState.shared.isIphone {
                    withAnimation { calProps.bottomPanelContent = nil }
                } else {
                    showInspector = false
                }
            #else
                dismiss()
            #endif
        } label: {
            Image(systemName: "xmark")
                .foregroundStyle(colorScheme == .dark ? .white : .black)
        }
    }
    
    
    var loadMoreButton: some View {
        Button {
            rowNumber += 50
            loadFromServer(removeAllBefore: false)
        } label: {
            Text("Fetch next 50")
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
                            
                            //Text(trans.title.capitalized)
                            
                            HStack(spacing: 0) {
//                                if let emoji = trans.category?.emoji {
//                                    Image(systemName: emoji)
//                                        .foregroundStyle(trans.category?.color ?? .primary)
//                                        .font(.footnote)
//                                } else {
//                                    CircleDot(color: trans.category?.color, width: 10)
//                                }
                                CircleDot(color: trans.category?.color, width: 10)
                                Text(trans.title.capitalized)
                            }
                            
                            HStack(spacing: 0) {
                                
                                
//                                let theText = "\(trans.amount.currencyWithDecimals(useWholeNumbers ? 0 : 2)) / \(trans.payMethod?.title ?? "N/A") / \(trans.category?.title ?? "N/A") / \(trans.prettyDate ?? "N/A")"
//                                
//                                Text(theText)
//                                    .foregroundStyle(.gray)
//                                    .font(.footnote)
                                
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
                
                if AppState.shared.isIphone {
                    Divider()
                        .padding(.vertical, 2)
                }
                
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
