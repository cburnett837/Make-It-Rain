//
//  PlaidTransactionOverlay.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/28/25.
//

import SwiftUI
import WidgetKit
#if os(iOS)
import WatchConnectivity
#endif

enum AcceptPlaidTransactionAction {
    case accept, acceptOnlyDate, acceptOnlyAmount, acceptDateAndAmount
}

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
    @Environment(KeywordModel.self) private var keyModel
    @Environment(PlaidModel.self) private var plaidModel
    
    //@Binding var bottomPanelContent: BottomPanelContent?
    //@Binding var bottomPanelHeight: CGFloat
    //@Binding var scrollContentMargins: CGFloat
    
    @State private var clearDate: Date = Date()
    
    @State private var rowNumber = 1
    @Binding var selectedMeth: CBPaymentMethod?
    
    @Binding var showInspector: Bool
    @Binding var navPath: [NavDest]
    
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
                    .drawingGroup()
                    .compositingGroup()
            } header: {
                sheetHeader
            }
//            .navigationDestination(for: CalendarNavDestPlaid.self) { dest in
//                switch dest {
//                case .rejectPage:
//                    clearBeforeDateView
//                }
//            }
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
//                .navigationDestination(for: String.self) { string in
//                    clearBeforeDateView
//                }
                #endif
            }
        }
        #else
        NavigationStack(path: $navPath) {
            StandardContainerWithToolbar(.list) {
                content
            }
            .navigationTitle("Pending Transactions")
            .if(selectedMeth != nil) {
                $0.navigationSubtitle("(Only \(selectedMeth!.title))")
            }
            .toolbar {
                ToolbarItemGroup(placement: .destructiveAction) {
                    HStack {
                        moreMenu
                    }
                }
                ToolbarItemGroup(placement: .confirmationAction) {
                    HStack {
                        refreshButton
                        closeButton
                    }
                }
            }
        }
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
            LineItem(trans: trans, selectedMeth: $selectedMeth)
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
    
    
//    var clearBeforeDateView: some View {
//        List {
//            Section {
//                DatePicker("", selection: $clearDate, displayedComponents: .date)
//                    .labelsHidden()
//            } header: {
//                Text("Choose a date to reject transactions")
//            } footer: {
//                Text(selectedMeth != nil ? "Only \(selectedMeth!.title)" : "(No Account Specified)")
//            }
//
//            Section {
//                Button("Reject") {
//                    Task {
//                        let theTrans = plaidModel.trans.filter({ selectedMeth == nil ? true : $0.payMethod == selectedMeth })
//                        let dummyTrans = CBTransaction()
//                        dummyTrans.date = clearDate
//                        dummyTrans.payMethod = selectedMeth
//                        
//                        for each in theTrans {
//                            if let date = each.date {
//                                if date < clearDate {
//                                    each.isAcknowledged = true
//                                    plaidModel.delete(each)
//                                    plaidModel.totalTransCount -= 1
//                                }
//                            }
//                        }
//                        /// Don't await
//                        Task {
//                            await plaidModel.clearPlaidTransactionBeforeDate(dummyTrans)
//                        }
//                        let theTransAgain = plaidModel.trans.filter({ selectedMeth == nil ? true : $0.payMethod == selectedMeth })
//                        if theTransAgain.isEmpty {
//                            selectedMeth = nil
//                        }
//                        
//                        navPath.removeLast()
//                    }
//                }
//                .tint(.red)
//                
//                Button("Cancel") {
//                    navPath.removeLast()
//                }
//            }
//        }
//        .navigationTitle("Reject Pending Transactions")
//        .navigationSubtitle(selectedMeth != nil ? "Only \(selectedMeth!.title)" : "(No Account Specified)")
//    }
    
    
    @ViewBuilder
    var sheetHeader: some View {
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
            NavigationLink(value: NavDest.plaidRejectPage) {
            //NavigationLink(value: "reject-view") {
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
        #if os(macOS)
        .toolbarBorder()
        //.buttonStyle(.roundMacButton)
        #endif
        .onChange(of: selectedMeth) {
            calModel.sPayMethod = selectedMeth
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
        #if os(macOS)
        .toolbarBorder()
        #endif
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
        #if os(macOS)
        .toolbarBorder()
        #endif
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
        AppState.shared.showAlert("This feature is not yet implemented")
//        if removeAllBefore {
//            plaidModel.trans.removeAll()
//        }
//        
//        plaidModel.isFetchingMoreTransactions = true
//        let fetchModel = PlaidServerModel(rowNumber: rowNumber)
//        Task {
//            await plaidModel.fetchPlaidTransactionsFromServer(fetchModel, accumulate: true)
//            plaidModel.isFetchingMoreTransactions = false
//        }
    }
    
    
    struct LineItem: View {
        //@Local(\.colorTheme) var colorTheme
        
        @Environment(CalendarProps.self) private var calProps
        @Environment(CalendarModel.self) private var calModel
        @Environment(CategoryModel.self) private var catModel
        @Environment(KeywordModel.self) private var keyModel
        @Environment(PlaidModel.self) private var plaidModel
        
        @State private var showExpandedTitle = false
        
        var trans: CBPlaidTransaction
        @Binding var selectedMeth: CBPaymentMethod?
        
        var body: some View {
            VStack(spacing: 0) {
                HStack {
                    VStack(spacing: 0) {
                        HStack {
//                            if trans.potentiallyExistingTransactionID != nil {
//                                AiAnimatedAliveSymbol(symbol: "brain", fontSize: .title3)
//                            } else {
//                                BusinessLogo(config: .init(parent: trans.payMethod, fallBackType: .color))
//                            }
                            
                            BusinessLogo(config: .init(parent: trans.payMethod, fallBackType: .color))
                            
                            //BusinessLogo(parent: trans.payMethod, fallBackType: .color)
                            
                            VStack(alignment: .leading, spacing: 0) {
                                Text(trans.title.capitalized)
                                    .lineLimit(showExpandedTitle ? nil : 1)
                                
                                if let id = trans.potentiallyExistingTransactionID, calModel.getTransaction(by: id) != nil {
                                    Text("This might be a duplicate…")
                                        .foregroundStyle(.orange)
                                        .font(.footnote)
                                }
                                                                            
                                Text(trans.prettyDate ?? "N/A")
                                    .foregroundStyle(.gray)
                                    .font(.footnote)
                                
                                Text(trans.amount.currencyWithDecimals())
                                    .foregroundStyle(.gray)
                                    .font(.footnote)
                                
                                
                            }
                        }
                    }
                    .listRowInsets(EdgeInsets())
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if let id = trans.potentiallyExistingTransactionID {
                            withAnimation {
                                calModel.sPayMethod = trans.payMethod
                            } completion: {
                                calProps.showPotentiallyExistingTransFromPlaidID = id
                                /// Give a little buffer for the calendar to change.
//                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                                    calProps.showPotentiallyExistingTransFromPlaidID = id
//                                }
                            }
                            
                        } else {
                            showExpandedTitle.toggle()
                        }
                    }
                    
                    Spacer()
                    
                    HStack {
//                        if let id = trans.potentiallyExistingTransactionID, let trans = calModel.getTransaction(by: id) {
//                            Button {
//                                calModel.sPayMethod = trans.payMethod
//                                calProps.showPotentiallyExistingTransFromPlaidID = id
//                            } label: {
//                                AiAnimatedAliveSymbol(symbol: "brain")
//                            }
//                        }
                        acceptButton
                        rejectButton
                    }
                    
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
       
        
        
        var acceptButton: some View {
            Button {
                acceptButtonFunc()
            } label: {
//                Text("Accept")
                ZStack {
                    Image(systemName: "checkmark")
                    Image(systemName: "xmark").hidden()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.theme)
        }
        
        var rejectButton: some View {
            Button {
                rejectButtonFunc()
            } label: {
//                Text("Reject")
                ZStack {
                    Image(systemName: "checkmark").hidden()
                    Image(systemName: "xmark")
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.gray)
        }
        
        
//        func acceptButtonFunc() {
//            /// See if there is a rename rule and let the user know it will be renamed.
//            var willRenameTo: String? = nil
//            
//            for key in keyModel.keywords {
//                let upKey = key.keyword.uppercased()
//                let upTitle = trans.title.uppercased()
//                
//                if let renameTo = key.renameTo {
//                    switch key.triggerType {
//                    case .equals:
//                        if upTitle == upKey { willRenameTo = renameTo }
//                    case .contains:
//                        if upTitle.contains(upKey) { willRenameTo = renameTo }
//                    }
//                }
//                
//                if willRenameTo != nil { break }
//            }
//            
//            
//            let logo = LogoConfig(
//                parent: trans.payMethod,
//                fallBackType: .customImage(.init(name: "checkmark.circle.badge.questionmark", color: .green)),
//                size: 65
//            )
//                                    
//            let yesButtonConfig = AlertConfig.ButtonConfig(text: "Yes", role: .primary) {
//                if let newName = willRenameTo { trans.title = newName }
//                Task { await accept(action: .accept) }
//            }
//            
//            var config = AlertConfig(
//                title: "Accept \(trans.title)?",
//                subtitle: (trans.prettyDate ?? "N/A"),
//                logo: logo,
//                logoStrokeColor: .green,
//                primaryButton: AlertConfig.AlertButton(config: yesButtonConfig)
//            )
//            
//            @ViewBuilder
//            var acceptButtonView: some View {
//                let buttonConfig = AlertConfig.ButtonConfig(text: "Create Transaction", role: .primary) {
//                    if let newName = willRenameTo { trans.title = newName }
//                    Task { await accept(action: .accept) }
//                }
//                AlertConfig.AlertButton(config: buttonConfig)
//            }
//            
//            @ViewBuilder
//            var onlyDateButtonview: some View {
//                let buttonConfig = AlertConfig.ButtonConfig(text: "Update Date", role: .primary) {
//                    if let newName = willRenameTo { trans.title = newName }
//                    Task { await accept(action: .acceptOnlyDate) }
//                }
//                AlertConfig.AlertButton(config: buttonConfig)
//            }
//            
//            @ViewBuilder
//            var onlyAmountButtonview: some View {
//                let buttonConfig = AlertConfig.ButtonConfig(text: "Update Amount", role: .primary) {
//                    if let newName = willRenameTo { trans.title = newName }
//                    Task { await accept(action: .acceptOnlyAmount) }
//                }
//                AlertConfig.AlertButton(config: buttonConfig)
//            }
//            
//            @ViewBuilder
//            var dateAndAmountButtonview: some View {
//                let buttonConfig = AlertConfig.ButtonConfig(text: "Update Date & Amount", role: .primary) {
//                    if let newName = willRenameTo { trans.title = newName }
//                    Task { await accept(action: .acceptDateAndAmount) }
//                }
//                AlertConfig.AlertButton(config: buttonConfig)
//            }
//            
//            
//            if let willRenameTo {
//                let subtitleView = VStack {
//                    HStack(spacing: 0) {
//                        Text("(Will be renamed to ")
//                            .foregroundStyle(.gray)
//                        
//                        AiAnimatedAliveLabel(willRenameTo, withGlow: true)
//                        
//                        Text(")")
//                            .foregroundStyle(.gray)
//                    }
//                    
//                    Text("\(trans.prettyDate ?? "N/A")")
//                        /// Standard alert subtitle modifiers
//                        .font(.callout)
//                        .multilineTextAlignment(.center)
//                        .lineLimit(5)
//                        .foregroundStyle(.gray)
//                }
//                
//                config.subtitle = nil
//                config.subtitleView = AnyView(subtitleView)
//            }
//            
//            
//            if trans.potentiallyExistingTransactionID != nil {
//                config.primaryButton = nil
//                config.views = [
//                    .init(content: AnyView(acceptButtonView)),
//                    .init(content: AnyView(onlyDateButtonview)),
//                    .init(content: AnyView(onlyAmountButtonview)),
//                    .init(content: AnyView(dateAndAmountButtonview))
//                ]
//            }
//                        
//            
//            Helpers.buzzPhone(.warning)
//            AppState.shared.showAlert(config: config)
//        }
        
        @discardableResult
        func renameTarget(for title: String) -> String? {
            keyModel.keywords.first { key in
                guard key.renameTo != nil else { return false }

                switch key.triggerType {
                case .equals:
                    return title.caseInsensitiveCompare(key.keyword) == .orderedSame

                case .contains:
                    return title.range(of: key.keyword, options: .caseInsensitive) != nil
                }
            }?.renameTo
        }
        
        
        func acceptButtonFunc() {
            let willRenameTo = renameTarget(for: trans.title)

            let logo = LogoConfig(
                parent: trans.payMethod,
                fallBackType: .customImage(.init(name: "checkmark.circle.badge.questionmark", color: .green)),
                size: 65
            )

            func performAccept(_ action: AcceptPlaidTransactionAction) {
                if let willRenameTo { trans.title = willRenameTo }
                Task { await accept(action: action) }
            }

            func makeButton(_ title: String, action: AcceptPlaidTransactionAction) -> AlertConfig.AlertButton {
                let config = AlertConfig.ButtonConfig(text: title, role: .primary) {
                    performAccept(action)
                }

                return AlertConfig.AlertButton(config: config)
            }

            var config = AlertConfig(
                title: "Accept \(trans.title)?",
                subtitle: trans.prettyDate ?? "N/A",
                logo: logo,
                logoStrokeColor: .green,
                primaryButton: makeButton("Yes", action: .accept)
            )

            if let willRenameTo {
                config.subtitle = nil
                config.subtitleView = AnyView(
                    VStack {
                        HStack(spacing: 0) {
                            Text("(Will be renamed to ")
                                .foregroundStyle(.gray)

                            AiAnimatedAliveLabel(
                                willRenameTo,
                                withGlow: true
                            )

                            Text(")")
                                .foregroundStyle(.gray)
                        }

                        Text(trans.prettyDate ?? "N/A")
                            .font(.callout)
                            .multilineTextAlignment(.center)
                            .lineLimit(5)
                            .foregroundStyle(.gray)
                    }
                )
            }

            if trans.potentiallyExistingTransactionID != nil {
                config.primaryButton = nil
                config.views = [
                    .init(content: AnyView(makeButton("Create Transaction", action: .accept))),
                    .init(content: AnyView(makeButton("Update Date", action: .acceptOnlyDate))),
                    .init(content: AnyView(makeButton("Update Amount", action: .acceptOnlyAmount))),
                    .init(content: AnyView(makeButton("Update Date & Amount", action: .acceptDateAndAmount)))
                ]
            }

            Helpers.buzzPhone(.warning)
            AppState.shared.showAlert(config: config)
        }
        
        
        
//        func accept(action: AcceptPlaidTransactionAction) async {
//            /// Animate for the toolbar button
//            withAnimation {
//                trans.isAcknowledged = true
//            }
//            
//            //plaidModel.totalTransCount -= 1
//            
//            if trans.payMethod?.isCreditOrUnified ?? false {
//                if trans.amountString.contains("-") {
//                    trans.amountString = trans.amountString.replacing("-", with: "")
//                } else {
//                    trans.amountString = "-\(trans.amountString)"
//                }
//            }
//            
//            if trans.category == nil {
//                trans.category = catModel.categories.filter { $0.isNil }.first
//            }
//            
//            var realTrans: CBTransaction? = nil
//            
//            switch action {
//            case .accept:
//                realTrans = CBTransaction(plaidTrans: trans)
//                
//            case .acceptOnlyDate:
//                if let id = trans.potentiallyExistingTransactionID, let foundTrans = calModel.getTransaction(by: id) {
//                    foundTrans.deepCopy(.create)
//                    foundTrans.date = trans.date
//                    realTrans = foundTrans
//                }
//                
//            case .acceptOnlyAmount:
//                if let id = trans.potentiallyExistingTransactionID, let foundTrans = calModel.getTransaction(by: id) {
//                    foundTrans.deepCopy(.create)
//                    foundTrans.amountString = trans.amountString
//                    realTrans = foundTrans
//                }
//                
//            case .acceptDateAndAmount:
//                if let id = trans.potentiallyExistingTransactionID, let foundTrans = calModel.getTransaction(by: id) {
//                    foundTrans.deepCopy(.create)
//                    foundTrans.date = trans.date
//                    foundTrans.amountString = trans.amountString
//                    realTrans = foundTrans
//                }
//            }
//            
//            guard let realTrans else { return }
//            
//            realTrans.plaidID = String(trans.plaidID)
//            
//            /// Switch the calendar to the payment method of the transaction (if it's not already)
//            if calModel.sPayMethod != realTrans.payMethod {
//                withAnimation { calModel.sPayMethod = realTrans.payMethod }
//                
//                try? await Task.sleep(for: .seconds(1))
//            }
//            
//            /// See if there is a rename rule and rename the transaction.
//            renameTarget(for: trans.title)
//            
//            
//            if action == .accept {
//                if
//                    let date = realTrans.date,
//                    let targetMonth = calModel.months.get(by: (date.month, date.year)),
//                    let targetDay = targetMonth.getDay(by: date.day) {
//                    withAnimation {
//                        targetDay.upsert(realTrans)
//                    }
//                }
//            } else {
//                
//            }
//            
//            
//            calModel.tempTransactions.append(realTrans)
//                                    
//            
//            await calModel.saveTransaction(id: realTrans.id, location: .tempList)
//            WidgetCenter.shared.reloadTimelines(ofKind: "PlaidWidget")
//            
////            guard WCSession.default.isReachable else {
////                print("Not reachable")
////                return
////            }
////            WCSession.default.sendMessage(["action": "reloadWidget"], replyHandler: nil) { error in
////                print("Error sending message to watch: \(error.localizedDescription)")
////            }
//            
//            #if os(iOS)
//            let payload: [String: Any] = ["action": "reloadWidget"]
//            WCSession.default.transferUserInfo(payload)
//            #endif
//            
//            let plaidTrans = plaidModel.trans.filter({ !$0.isAcknowledged })
//            try? await UNUserNotificationCenter.current().setBadgeCount(plaidTrans.count)
//        }
        
        
        func accept(action: AcceptPlaidTransactionAction) async {
            /// Animate the Plaid transaction being acknowledged.
            withAnimation {
                trans.isAcknowledged = true
            }

            /// Credit/unified payment methods use the opposite sign convention.
            if trans.payMethod?.isCreditOrUnified == true {
                if trans.amountString.hasPrefix("-") {
                    trans.amountString.removeFirst()
                } else {
                    trans.amountString = "-\(trans.amountString)"
                }
            }

            /// Assign the fallback category if the transaction does not have one.
            if trans.category == nil {
                trans.category = catModel.categories.first(where: \.isNil)
            }

            /// Create the transaction that will actually be saved.
            ///
            /// A full accept creates a new transaction.
            /// Partial accepts update the potentially matching existing transaction.
            let realTrans: CBTransaction

            switch action {
            case .accept:
                realTrans = CBTransaction(plaidTrans: trans)

            case .acceptOnlyDate, .acceptOnlyAmount, .acceptDateAndAmount:
                guard
                    let id = trans.potentiallyExistingTransactionID,
                    let foundTrans = calModel.getTransaction(by: id)
                else {
                    return
                }

                /// Save the current state before modifying the existing transaction.
                foundTrans.deepCopy(.create)

                if action == .acceptOnlyDate || action == .acceptDateAndAmount {
                    foundTrans.date = trans.date
                }

                if action == .acceptOnlyAmount || action == .acceptDateAndAmount {
                    foundTrans.amountString = trans.amountString
                }

                realTrans = foundTrans
            }

            /// Link the calendar transaction back to its Plaid transaction.
            realTrans.plaidID = String(trans.plaidID)

            /// Apply the same rename rule that was shown in the confirmation alert.
            if let renameTo = renameTarget(for: trans.title) {
                realTrans.title = renameTo
            }

            /// Switch the calendar to the transaction's payment method if needed.
            if calModel.sPayMethod != realTrans.payMethod {
                withAnimation {
                    calModel.sPayMethod = realTrans.payMethod
                }

                try? await Task.sleep(for: .seconds(1))
            }

            /// A full accept creates a new calendar transaction, so add it to its day.
            ///
            /// Partial accepts modify an existing transaction that is already in the calendar.
            if action == .accept,
               let date = realTrans.date,
               let targetMonth = calModel.months.get(by: (date.month, date.year)),
               let targetDay = targetMonth.getDay(by: date.day) {

                withAnimation {
                    targetDay.upsert(realTrans)
                }
            }

            /// Add the transaction to the temporary save list and persist it.
            calModel.tempTransactions.append(realTrans)

            await calModel.saveTransaction(id: realTrans.id, location: .tempList)

            /// Refresh the Plaid widget.
            WidgetCenter.shared.reloadTimelines(ofKind: "PlaidWidget")

            /// Tell the Apple Watch to refresh.
            #if os(iOS)
            WCSession.default.transferUserInfo(["action": "reloadWidget"])
            #endif

            /// Update the app badge with the remaining unacknowledged transactions.
            let remainingCount = plaidModel.trans.lazy.filter { !$0.isAcknowledged }.count
            try? await UNUserNotificationCenter.current().setBadgeCount(remainingCount)
        }
        
        
        func rejectButtonFunc() {
            let buttonConfig = AlertConfig.ButtonConfig(text: "Yes", role: .destructive) { reject() }
            let config = AlertConfig(
                title: "Reject \(trans.title)?",
                subtitle: trans.prettyDate ?? "N/A",
                logo: .init(
                    parent: trans.payMethod,
                    fallBackType: .customImage(.init(name: "questionmark.circle", color: .orange)),
                    size: 65
                ),
                logoStrokeColor: .orange,
                primaryButton: AlertConfig.AlertButton(config: buttonConfig)
            )
            
            Helpers.buzzPhone(.warning)
            AppState.shared.showAlert(config: config)
        }
        
        
        func reject() {
            /// Animate for the toolbar button
            withAnimation {
                trans.isAcknowledged = true
            }
            //plaidModel.totalTransCount -= 1
            Task {
                let plaidTrans = plaidModel.trans.filter({ !$0.isAcknowledged })
                try? await UNUserNotificationCenter.current().setBadgeCount(plaidTrans.count)
                
                await plaidModel.denyPlaidTransaction(trans)
                plaidModel.trans.removeAll(where: { $0.id == trans.id })
                WidgetCenter.shared.reloadTimelines(ofKind: "PlaidWidget")
                
//                guard WCSession.default.isReachable else {
//                    print("Not reachable")
//                    return
//                }
//                WCSession.default.sendMessage(["action": "reloadWidget"], replyHandler: nil) { error in
//                    print("Error sending message to watch: \(error.localizedDescription)")
//                }
                
                #if os(iOS)
                let payload: [String: Any] = ["action": "reloadWidget"]
                WCSession.default.transferUserInfo(payload)
                #endif
            }
        }
    }
}


struct ClearPlaidBeforeDateView: View {
    @Environment(PlaidModel.self) private var plaidModel
    @State private var clearDate: Date = Date()
    
    @Binding var selectedMeth: CBPaymentMethod?
    @Binding var navPath: [NavDest]
    
    var body: some View {
        clearBeforeDateView
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
                                    //plaidModel.totalTransCount -= 1
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
        .navigationTitle("Reject Pending Transactions")
        .navigationSubtitle(selectedMeth != nil ? "Only \(selectedMeth!.title)" : "(No Account Specified)")
    }
}
