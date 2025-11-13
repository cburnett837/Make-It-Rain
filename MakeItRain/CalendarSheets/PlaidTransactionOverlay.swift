//
//  PlaidTransactionOverlay.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/28/25.
//

import SwiftUI

struct PlaidTransactionOverlay: View {
    //@Local(\.colorTheme) var colorTheme
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
    
    @State private var clearDate: Date = Date()
    
    @State private var rowNumber = 1
    @State private var selectedMeth: CBPaymentMethod?
    
    @Binding var showInspector: Bool
    @Binding var navPath: NavigationPath
    
    var plaidTransactions: [CBPlaidTransaction] {
        plaidModel.trans
            .filter({ !$0.isAcknowledged })
            .filter({ selectedMeth == nil ? true : $0.payMethod == selectedMeth })
    }
    
    var body: some View {
        #if os(iOS)
        if AppState.shared.isIphone {
            StandardContainer(AppState.shared.isIpad ? .sidebarScrolling : .bottomPanel) {
                content
            } header: {
                sheetHeader
            }
            .navigationDestination(for: String.self) { string in
                clearBeforeDateView
            }
        } else {
            NavigationStack(path: $navPath) {
                StandardContainerWithToolbar(.list) {
                    content
                }
                .navigationTitle("Pending Transactions")
                .if(selectedMeth != nil) {
                    $0.navigationSubtitle("(Only \(selectedMeth!.title))")
                }
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) { refreshButton }
                    ToolbarSpacer(.fixed, placement: .topBarLeading)
                    ToolbarItem(placement: .topBarLeading) { moreMenu }
                    ToolbarItem(placement: .topBarTrailing) { closeButton }
                }
                .navigationDestination(for: String.self) { string in
                    clearBeforeDateView
                }
                #endif
            }
        }
        #else
        sheetHeader
        #endif
    }
    
    
    var content: some View {
        Group {
            if plaidTransactions.isEmpty {
                if plaidModel.isFetchingMoreTransactions {
                     ProgressView()
                        .tint(.none)
                } else {
                    ContentUnavailableView("No Pending Transactions", systemImage: "bag.fill.badge.questionmark")
                }
                
            } else {
                #if os(iOS)
                if AppState.shared.isIphone {
                    VStack(spacing: 0) {
                        transactions
                    }
                } else {
                    transactions
                }
                #else
                transactions
                #endif
            }
        }
    }
    
    
    @ViewBuilder var transactions: some View {
        ForEach(plaidTransactions) { trans in
            LineItem(trans: trans)
                #if os(iOS)
                .padding(.horizontal, AppState.shared.isIphone ? 8 : 0)
                #endif
        }
        
        //let accountSpecificCount = plaidModel.trans.filter({ !$0.isAcknowledged }).filter({ $0.payMethod?.id == meth.id }).count
        
        if /*plaidTransactions.count >= 50 && */(plaidTransactions.count < plaidModel.totalTransCount) && selectedMeth == nil {
            loadMoreButton
                #if os(iOS)
                .padding(.vertical, AppState.shared.isIphone ? 10 : 0)
                #endif
        }
    }
    
    
    var clearBeforeDateView: some View {
        List {
            Section {
                DatePicker("", selection: $clearDate, displayedComponents: .date)
                    .labelsHidden()
            } header: {
                Text("Choose a date to reject transactions")
            } footer: {
                Text(selectedMeth != nil ? "Only \(selectedMeth!.title)" : "(No Account Specified)")
            }

            Section {
                Button("Reject") {
                    Task {
                        let theTrans = plaidModel.trans.filter({ selectedMeth == nil ? true : $0.payMethod == selectedMeth })
                        let dummyTrans = CBTransaction()
                        dummyTrans.date = clearDate
                        dummyTrans.payMethod = selectedMeth
                        
                        for each in theTrans {
                            if let date = each.date {
                                if date < clearDate {
                                    each.isAcknowledged = true
                                    plaidModel.delete(each)
                                    plaidModel.totalTransCount -= 1
                                }
                            }
                        }
                        /// Don't await
                        Task {
                            await plaidModel.clearPlaidTransactionBeforeDate(dummyTrans)
                        }
                        let theTransAgain = plaidModel.trans.filter({ selectedMeth == nil ? true : $0.payMethod == selectedMeth })
                        if theTransAgain.isEmpty {
                            selectedMeth = nil
                        }
                        
                        navPath.removeLast()
                    }
                }
                .tint(.red)
                
                Button("Cancel") {
                    navPath.removeLast()
                }
            }
        }
        
//        VStack {
//            Text("Choose a date to reject transactions")
//            Text("All transactions before this date will be rejected.")
//                .foregroundStyle(.secondary)
//                .font(.caption)
//            
//            DatePicker("", selection: $clearDate, displayedComponents: .date)
//                .labelsHidden()
//            
//            HStack {
//                Button("Cancel") {
//                    navPath.removeLast()
//                }
//                .buttonStyle(.borderedProminent)
//                
//                Button("Reject") {
//                    Task {
//                        let dummyTrans = CBTransaction()
//                        dummyTrans.date = clearDate
//                        await plaidModel.clearPlaidTransactionBeforeDate(dummyTrans)
//                        
//                        for each in plaidModel.trans {
//                            if let date = each.date {
//                                if date < clearDate {
//                                    each.isAcknowledged = true
//                                    plaidModel.delete(each)
//                                }
//                            }
//                        }
//                        showClearBeforeDatePicker = false
//                    }
//                }
//                .tint(.red)
//                .buttonStyle(.borderedProminent)
//            }
//        }
        .navigationTitle("Reject Pending Transactions")
        .navigationSubtitle(selectedMeth != nil ? "Only \(selectedMeth!.title)" : "(No Account Specified)")
    }
    
    
    @ViewBuilder var sheetHeader: some View {
        @Bindable var calProps = calProps
        SheetHeader(
            title: "Pending Transactions",
            subtitle: selectedMeth == nil ? nil : "(\(selectedMeth!.title))",
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
            NavigationLink(value: "reject-view") {
                Text("Reject everything before date…")
            }
            
//            NavigationLink("Reject everything before date…") {
//                clearBeforeDateView
//            }
            
//            Button("Reject everything before date…") {
//                showClearBeforeDatePicker = true
//            }
            
            Menu("Filter By Account") {
                Picker("", selection: $selectedMeth) {
                    let meths = plaidModel.trans
                        .compactMap { $0.payMethod }
                        .uniqued(on: \.id)
                    
                    Text("None")
                        //.strikethrough()
                        .tag(nil as CBPaymentMethod?)
                    
                    ForEach(meths) { meth in
                        let plaidTransCount = plaidModel.trans.filter({ !$0.isAcknowledged }).filter({ $0.payMethod?.id == meth.id }).count
                        Text("\(meth.title) (\(plaidTransCount))")
                            .tag(meth)
                    }
                }
                .labelsHidden()
            }
            
            
        } label: {
            Image(systemName: "ellipsis")
                .contentShape(Rectangle())
                .schemeBasedForegroundStyle()
        }
    }
    
    
    var refreshButton: some View {
        Button {
            rowNumber = 1
            loadFromServer(removeAllBefore: true)
        } label: {
            Image(systemName: "arrow.triangle.2.circlepath")
                .contentShape(Rectangle())
                .schemeBasedForegroundStyle()
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
                .schemeBasedForegroundStyle()
        }
    }
    
    
    var loadMoreButton: some View {
        Button {
            rowNumber += 50
            loadFromServer(removeAllBefore: false)
        } label: {
            Text("Fetch next 50 of \(plaidModel.totalTransCount)")
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
            await plaidModel.fetchPlaidTransactionsFromServer(fetchModel, accumulate: true)
            plaidModel.isFetchingMoreTransactions = false
        }
    }
    
    
    struct LineItem: View {
        //@Local(\.colorTheme) var colorTheme
        @Local(\.useWholeNumbers) var useWholeNumbers

        @Environment(CalendarModel.self) private var calModel
        @Environment(CategoryModel.self) private var catModel
        @Environment(PlaidModel.self) private var plaidModel
        
        @State private var showExpandedTitle = false
        
        var trans: CBPlaidTransaction
        
        var body: some View {
            VStack(spacing: 0) {
                HStack {
                    VStack(spacing: 0) {
                        HStack {
                            BusinessLogo(parent: trans.payMethod, fallBackType: .color)
                            
                            VStack(alignment: .leading, spacing: 0) {
                                Text(trans.title.capitalized)
                                    .lineLimit(showExpandedTitle ? nil : 1)
                                
                                Text(trans.amount.currencyWithDecimals(useWholeNumbers ? 0 : 2))
                                    .foregroundStyle(.gray)
                                    .font(.footnote)
                                                                            
                                Text(trans.prettyDate ?? "N/A")
                                    .foregroundStyle(.gray)
                                    .font(.footnote)
                            }
                        }
                    }
                    .listRowInsets(EdgeInsets())
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showExpandedTitle.toggle()
                    }
                    
                    Spacer()
                    acceptButton
                    rejectButton
                }
                #if os(iOS)
                if AppState.shared.isIphone {
                    Divider()
                        .padding(.vertical, 2)
                }
                #endif
            }
            #if os(iOS)
            .if(AppState.shared.isIphone) {
                $0.listRowInsets(EdgeInsets())
            }
            #endif
            
        }
        
//        var transInfo: some View {
////            VStack(alignment: .leading, spacing: 0) {
////                HStack(spacing: 0) {
////                    CircleDot(color: trans.category?.color, width: 10)
////                    Text(trans.title.capitalized)
////                        .lineLimit(showExpandedTitle ? nil : 1)
////                }
////                
////                HStack(spacing: 0) {
////                    CircleDot(color: trans.payMethod?.color, width: 10)
////                    Text(trans.amount.currencyWithDecimals(useWholeNumbers ? 0 : 2))
////                        .foregroundStyle(.gray)
////                        .font(.footnote)
////                }
////                
////                Text(trans.prettyDate ?? "N/A")
////                    .foregroundStyle(.gray)
////                    .font(.caption2)
////            }
////            .contentShape(Rectangle())
////            .onTapGesture {
////                showExpandedTitle.toggle()
////            }
//            
//            
//            
//            
//            VStack(spacing: 0) {
//                HStack {
//                    BusinessLogo(parent: trans.payMethod, fallBackType: .color)
//                    
//                    VStack(alignment: .leading, spacing: 0) {
//                        Text(trans.title.capitalized)
//                            .lineLimit(showExpandedTitle ? nil : 1)
//                        
//                        Text(trans.amount.currencyWithDecimals(useWholeNumbers ? 0 : 2))
//                            .foregroundStyle(.gray)
//                            .font(.footnote)
//                                                                    
//                        Text(trans.prettyDate ?? "N/A")
//                            .foregroundStyle(.gray)
//                            .font(.footnote)
//                    }
//                }
//            }
//            .listRowInsets(EdgeInsets())
//            .contentShape(Rectangle())
//            .onTapGesture {
//                showExpandedTitle.toggle()
//            }
//            
//            
//            
//            
//        }
        
        
        var acceptButton: some View {
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
            .tint(Color.theme)
        }
        
        var rejectButton: some View {
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
        
        
        func accept() {
            /// Animate for the toolbar button
            withAnimation {
                trans.isAcknowledged = true
            }
            
            plaidModel.totalTransCount -= 1
            
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
            /// Animate for the toolbar button
            withAnimation {
                trans.isAcknowledged = true
            }
            plaidModel.totalTransCount -= 1
            Task {
                await plaidModel.denyPlaidTransaction(trans)
                plaidModel.trans.removeAll(where: {$0.id == trans.id})
            }
        }
    }
}
