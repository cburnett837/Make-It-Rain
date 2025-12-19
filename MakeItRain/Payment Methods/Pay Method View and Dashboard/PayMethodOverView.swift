//
//  PayMethodOverView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/17/25.
//


import SwiftUI
import Charts
import LocalAuthentication


/// On iPad, we need a special view with its own navPath since this view will be presented in a sheet.
/// The reason being is without it, when you navigate to the charts, the account list will also navigate to nothing since we could be bound back to its navPath.
struct PayMethodOverViewWrapperIpad: View {
    @State private var navPath = NavigationPath()
    @Bindable var payMethod: CBPaymentMethod
    
    var body: some View {
        NavigationStack(path: $navPath) {
            PayMethodOverView(payMethod: payMethod, navPath: $navPath)
        }
    }
}

struct PayMethodOverView: View {
    enum TransactionsOrInsights: String {
        case transactions = "transactions"
        case insights = "insights"
    }
    
    @Local(\.incomeColor) var incomeColor
    @Local(\.useWholeNumbers) var useWholeNumbers
    @AppStorage("selectedPaymentMethodTab") var selectedTab: TransactionsOrInsights = .transactions
    @AppStorage(LocalKeys.Charts.Options.showOverviewDataPerMethodOnUnified) var showOverviewDataPerMethodOnUnifiedChart = false
    @Environment(\.dismiss) var dismiss
    //@Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Environment(CalendarModel.self) private var calModel
    
    @Environment(PayMethodModel.self) private var payModel
    @Environment(PlaidModel.self) private var plaidModel
    
    @Bindable var payMethod: CBPaymentMethod
    @Binding var navPath: NavigationPath
        
    @State private var viewModel = PayMethodViewModel()
    @State private var editPaymentMethod: CBPaymentMethod?
    @State private var paymentMethodEditID: CBPaymentMethod.ID?
    @State private var transEditID: String?
    @State private var transDay: CBDay?
    @State private var fetchHistoryTime = Date()
    
    @State private var flipped = false
    @State private var zindex: Double = 1
    @State private var scrollOffset: CGFloat = 0
    @State private var blur: CGFloat = 0
    @State private var scale: CGFloat = 1
    @State private var accountTypeMenuColor: Color = Color(.tertiarySystemFill)
    
    @State private var editKeychainDetails = false
    @State private var keychainCardNumber: String?
    @State private var keychainExpirationMonth: String?
    @State private var keychainExpirationYear: String?
    @State private var keychainSecurityCode: String?
    
    @FocusState private var focusedField: Int?
    
    @Namespace private var namespace
    
    let context = LAContext()
    @State private var error: NSError?
    @State private var isUnlocked = false
    @State private var authImage: String = "faceid"
    
    var pickerAnimation: Animation? {
        payMethod.accountType == .credit || payMethod.accountType == .loan ? nil : .default
    }
    
    var title: String {
        payMethod.action == .add ? "New Account" : payMethod.title
    }
    
    var cardColor: Color {
        if payMethod.isUnified {
            colorScheme == .dark ? Color(.systemGray2) : Color(.white)
        } else {
            payMethod.color
        }
    }
    
    
    var body: some View {
        /// This page just handles whether we should go directly to the charts (For a unified account), or display the details page.
        coordinatorPage
            .background(Color(.systemBackground)) // force matching
            .task { await prepareView() }
            .sheet(item: $editPaymentMethod, onDismiss: {
                paymentMethodEditID = nil
                payModel.determineIfUserIsRequiredToAddPaymentMethod()
            }) { meth in
                PayMethodEditView(payMethod: meth, editID: $paymentMethodEditID)
            }
            .onChange(of: paymentMethodEditID) { oldId, newId in
                if let newId {
                    let payMethod = payModel.getPaymentMethod(by: newId)
                    editPaymentMethod = payMethod
                } else {
                    let _ = payModel.savePaymentMethod(id: oldId!, calModel: calModel, plaidModel: plaidModel)
                    payModel.determineIfUserIsRequiredToAddPaymentMethod()
                    /// Close if deleting since it will be gone.
                    /// Also close if adding, since the server will send back the real ID, and cause the list to redraw, which would cause the sheet to dismiss itself and reopen.
                    /// iPhone: pop from nav.
                    /// iPad: dismiss sheet.
                    if payMethod.action == .delete || payMethod.action == .add {
                        if AppState.shared.isIphone {
                            navPath.removeLast()
                        } else {
                            dismiss()
                        }
                    }
                }
            }
    }
    
    
    @ViewBuilder
    var coordinatorPage: some View {
        if payMethod.isUnified {
            chartPage
        } else {
            detailPage
                .background(Color(uiColor: .systemGroupedBackground))
                .navigationTitle("Account Details")
                .navigationBarTitleDisplayMode(.inline)
                .navigationDestination(for: String.self) { _ in chartPage }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Edit") {
                            paymentMethodEditID = payMethod.id
                        }
                        .schemeBasedForegroundStyle()
                    }
                    
                    if AppState.shared.isIpad {
                        ToolbarSpacer(.fixed, placement: .topBarTrailing)
                        ToolbarItem(placement: .topBarTrailing) { closeButton }
                    }
                }
        }
    }
    
    
    var detailPage: some View {
        ZStack(alignment: .top) {
            fakeCard

            List {
                NavigationLink(value: "chart-page") {
                    Label("Insights", systemImage: "chart.xyaxis.line")
                        .schemeBasedForegroundStyle()
                }

                TransactionList(payMethod: payMethod, transEditID: $transEditID, transDay: $transDay)
            }
            .scrollContentBackground(.hidden)
            .contentMargins(.top, 300, for: .scrollContent)
            .onScrollGeometryChange(for: CGFloat.self) {
                $0.contentOffset.y + $0.contentInsets.top
            } action: { _, newOffset in
                let collapseDistance: CGFloat = 200
                let raw = 1 - (newOffset / collapseDistance)
                
                withAnimation(.bouncy(duration: 0.5, extraBounce: 0)) {
                    blur = min(newOffset / 16, 8)
                    scale = max(min(raw, 1), 0)
                    
                    if blur <= 0 {
                        zindex = 1
                    } else {
                        zindex = -1
                    }
                }
            }
            .transactionEditSheetAndLogic(transEditID: $transEditID, selectedDay: $transDay, extraDismissLogic: { didSave in
                if didSave {
                    Task { await prepareView() }
                }
            })
        }
    }
    
    
    var fakeCard: some View {
        VStack {
            ZStack {
                fakeCardFront
                    .opacity(flipped ? 0 : 1)
                
                ZStack {
                    fakeCardBack
                        .blur(radius: isUnlocked ? 0 : 8)
                    
                    if !isUnlocked {
                        Image(systemName: authImage)
                            .font(.system(size: 60))
                            .onTapGesture {
                                authenticate()
                            }
                    }
                }
                .rotation3DEffect(.degrees(180), axis: (0,1,0))
                .opacity(flipped ? 1 : 0)
            }
            .rotation3DEffect(.degrees(flipped ? -180 : 0), axis: (0,1,0))
            .animation(.easeInOut(duration: 0.6), value: flipped)
            .onTapGesture {
                if payMethod.accountType != .cash {
                    flipped.toggle()
                    if flipped && !isUnlocked {
                        authenticate()
                    }
                }
            }
            .blur(radius: blur)
            .scaleEffect(scale)
        }
        .frame(height: 300)
        .zIndex(zindex)
    }
    
  
    var fakeCardFront: some View {
        VStack {
            VStack {
                HStack {
                    Text(payMethod.title)
                        .font(.largeTitle)
                    Spacer()
                    BusinessLogo(config: .init(
                        parent: payMethod,
                        fallBackType: payMethod.isUnified ? .gradient : .color,
                        size: 60
                    ))
                    .blur(radius: blur)
                }
                
                HStack {
                    Text("**** **** **** \(payMethod.last4 ?? "****")")
                        .font(.title)
                    Spacer()
                }
                                                
                Spacer()
                
                VStack(alignment: .leading) {
                    HStack {
                        VStack(alignment: .leading) {
                            if let balance = plaidModel.balances.filter({ $0.payMethodID == payMethod.id }).first {
                                Text(balance.amount.currencyWithDecimals(useWholeNumbers ? 0 : 2))
                                    .bold()
                            }
                        }
                                                                                    
                        if payMethod.isPrivate { Image(systemName: "person.slash") }
                        if payMethod.isHidden { Image(systemName: "eye.slash") }
                        if payMethod.notifyOnDueDate { Image(systemName: "alarm") }
                    }
                    
                    HStack {
                        Text(payMethod.holderOne?.name ?? "")
                        Spacer()
                        Text(payMethod.accountType.prettyValue)
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .frame(height: 250)
            .background(fakeCardBackground)
            .shadow(radius: 10)
            .scenePadding(.horizontal)
                                    
            HStack {
                if let balance = plaidModel.balances.filter({ $0.payMethodID == payMethod.id }).first {
                    Text("Updated \(Date().timeSince(balance.enteredDate))")
                        .foregroundStyle(.gray)
                        .font(.subheadline)
                }
                
                Spacer()
            }
            .scenePadding(.horizontal)
            .padding(.leading, 14)
        }
    }
         
    
    var fakeCardBack: some View {
        VStack {
            VStack {
//                HStack {
//                    Rectangle()
//                        .fill(.black)
//                        .frame(height: 20)
//                }
                
                fakeCardCardNumber
                fakeCardExpirationDate
                fakeCardSecurityCode
                
                Spacer()
                
                Text("These card details are only for your convenience, are stored securely on-device, and are never transmitted to the server.")
                    .schemeBasedForegroundStyle()
                    .font(.caption)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                Button(editKeychainDetails ? "Done" : "Edit") {
                    withAnimation {
                        editKeychainDetails.toggle()
                    }
                }
                .schemeBasedForegroundStyle()
                .buttonStyle(.glass)
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .frame(height: 250)
            .background(fakeCardBackground)
            .shadow(radius: 10)
            .scenePadding(.horizontal)
                                    
            HStack {
                if let balance = plaidModel.balances.filter({ $0.payMethodID == payMethod.id }).first {
                    Text("Updated \(Date().timeSince(balance.enteredDate))")
                        .foregroundStyle(.gray)
                        .font(.subheadline)
                }
                
                Spacer()
            }
            .scenePadding(.horizontal)
            .padding(.leading, 14)
        }
        .onChange(of: isUnlocked) {
            if $1 { getCardDetailsFromKeychain() }
        }
        .onChange(of: editKeychainDetails) {
            if !$1 { saveCardDetailsToKeychain() }
        }
    }
    
    
    var fakeCardBackground: some View {
        RoundedRectangle(cornerRadius: 26)
            .fill(
                MeshGradient(width: 3, height: 3, points: [
                    .init(0, 0), .init(0.5, 0), .init(1, 0),
                    .init(0, 0.5), .init(0.9, 0.6), .init(1, 0.5),
                    .init(0, 1), .init(0.5, 1), .init(1, 1),
                ], colors: [
//                    cardColor, cardColor, .pink,
//                    .pink, .orange, cardColor,
//                    cardColor, .orange, cardColor,
//                    
//                    cardColor, cardColor, .white,
//                    cardColor, cardColor, cardColor,
//                    cardColor, .white, cardColor,
                    
                    cardColor, cardColor, cardColor.lighter(by: 30),
                    cardColor, cardColor, cardColor,
                    cardColor, cardColor.lighter(by: 30), cardColor,
                ])
            )
            //.fill(cardColor.gradient)
    }
    
    
    var fakeCardCardNumber: some View {
        HStack {
            if editKeychainDetails {
                TextField("Card Number", text: $keychainCardNumber ?? "")
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
            } else {
                HStack {
                    Text("NUM:")
                        .frame(width: 50, alignment: .leading)
                    
                    if let keychainCardNumber {
                        Text(keychainCardNumber.isEmpty ? "N/A" : keychainCardNumber)
                            .font(.title)
                    } else {
                        Text("N/A")
                            .font(.title)
                    }
                }
                
                Spacer()
            }
        }
    }
    
    
    var fakeCardExpirationDate: some View {
        HStack {
            if editKeychainDetails {
                TextField("Expiration Month", text: $keychainExpirationMonth ?? "")
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                TextField("Expiration Year", text: $keychainExpirationYear ?? "")
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
            } else {
                HStack {
                    Text("EXP:")
                        .frame(width: 50, alignment: .leading)
                    
                    if let keychainExpirationMonth, let keychainExpirationYear {
                        Text(keychainExpirationMonth.isEmpty || keychainExpirationYear.isEmpty
                             ? "N/A"
                             : "\(keychainExpirationMonth)/\(keychainExpirationYear)"
                        )
                        .font(.title)
                    } else {
                        Text("N/A")
                            .font(.title)
                    }
                }
                
                Spacer()
            }
        }
    }
    
    
    var fakeCardSecurityCode: some View {
        HStack {
            if editKeychainDetails {
                TextField("Security Code", text: $keychainSecurityCode ?? "")
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
            } else {
                HStack {
                    Text("CVV:")
                        .frame(width: 50, alignment: .leading)
                    
                    if let keychainSecurityCode {
                        Text(keychainSecurityCode.isEmpty ? "N/A" : keychainSecurityCode)
                            .font(.title)
                    } else {
                        Text("N/A")
                            .font(.title)
                    }
                }
                Spacer()
            }
        }
    }
    
    
    /// Only for iPad.
    var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .schemeBasedForegroundStyle()
        }
    }
    
    
    @ViewBuilder
    var chartPage: some View {
        if payMethod.action == .add {
            ContentUnavailableView("Insights are not available when adding a new account", systemImage: "square.stack.3d.up.slash.fill")
        } else {
            PayMethodDashboard(vm: viewModel, payMethod: payMethod, navPath: $navPath)
                .opacity(viewModel.isLoadingHistory ? 0 : 1)
                .overlay {
                    ProgressView("Loading Insights…")
                        .tint(.none)
                        .opacity(viewModel.isLoadingHistory ? 1 : 0)
                }
                .focusable(false)
        }
    }
    
    
    func prepareView() async {
        if payMethod.action == .add {
            //payModel.upsert(payMethod)
            paymentMethodEditID = payMethod.id
            viewModel.isLoadingHistory = false
        } else {
            /// iPhone: only fetch the new historical if it has been wiped out (by returning to the account list), or if a transaction has been updated since the history was fetched from the server.
            /// Due to the navigation stack, we can leave the chart open and go elsewhere in the app. Thus, no need to refresh the data unless a transaction changed in the meantime.
            /// Likewise, when returning to the account list, the viewmodel would be destroyed, and the history would need to be refetched.
            ///
            /// iPad: Always fetch the data since everything is inside a sheet, which must be closed before returning to the rest of the app. Thus the viewmodel would be destroyed, and the history would need to be refetched.
            let needsUpdates = calModel.transactionsUpdatesExistAfter(fetchHistoryTime)
            if payMethod.breakdownsRegardlessOfPaymentMethod.isEmpty || needsUpdates || AppState.shared.isIpad {
                fetchHistoryTime = Date()
                await viewModel.fetchHistory(for: payMethod, payModel: payModel, setChartAsNew: true)
            }
        }
        
        
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            authImage = switch context.biometryType {
            case .faceID: "faceid"
            case .touchID: "touchid"
            case .none: "lock.trianglebadge.exclamationmark"
            case .opticID: "opticid"
            @unknown default: "lock.trianglebadge.exclamationmark"
            }
        } else {
            authImage = "lock.trianglebadge.exclamationmark"
        }
    }
    
    
    func authenticate() {
        context.localizedCancelTitle = "Enter Password"
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            let reason = "Unlock to view your card information."
            
            //.deviceOwnerAuthenticationWithBiometrics
            //.deviceOwnerAuthentication to fallback to passcode if bio fails
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, authenticationError in
                withAnimation {
                    isUnlocked = success
                }
            }
        } else {
            // no biometrics
        }
    }
    
    
    func getCardDetailsFromKeychain() {
        print("-- \(#function)")
        let keychainManager = KeychainManager()
        do {
            if let cardNumber = try keychainManager.getFromKeychain(key: "payment_method_card_number_\(payMethod.id)") {
                self.keychainCardNumber = cardNumber
            }
            if let expirationMonth = try keychainManager.getFromKeychain(key: "payment_method_expiration_month_\(payMethod.id)") {
                self.keychainExpirationMonth = expirationMonth
            }
            if let expirationYear = try keychainManager.getFromKeychain(key: "payment_method_expiration_year_\(payMethod.id)") {
                self.keychainExpirationYear = expirationYear
            }
            if let securityCode = try keychainManager.getFromKeychain(key: "payment_method_security_code_\(payMethod.id)") {
                self.keychainSecurityCode = securityCode
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    
    func saveCardDetailsToKeychain() {
        print("-- \(#function)")
        let keychainManager = KeychainManager()
                        
        do {
            if let keychainCardNumber = keychainCardNumber {
                try keychainManager.addToKeychain(key: "payment_method_card_number_\(payMethod.id)", value: keychainCardNumber)
            }
            if let keychainExpirationMonth = keychainExpirationMonth {
                try keychainManager.addToKeychain(key: "payment_method_expiration_month_\(payMethod.id)", value: keychainExpirationMonth)
            }
            if let keychainExpirationYear = keychainExpirationYear {
                try keychainManager.addToKeychain(key: "payment_method_expiration_year_\(payMethod.id)", value: keychainExpirationYear)
            }
            if let keychainSecurityCode = keychainSecurityCode {
                try keychainManager.addToKeychain(key: "payment_method_security_code_\(payMethod.id)", value: keychainSecurityCode)
            }

        } catch {
            print(error.localizedDescription)
        }
    }
}


fileprivate struct TransactionList: View {
    @Local(\.transactionSortMode) var transactionSortMode
    @Local(\.categorySortMode) var categorySortMode
    @Local(\.useWholeNumbers) var useWholeNumbers
    @Environment(CalendarModel.self) private var calModel
    
    @Bindable var payMethod: CBPaymentMethod
    @Binding var transEditID: String?
    @Binding var transDay: CBDay?
    
    var month: CBMonth? {
        calModel.months.filter({ $0.actualNum == AppState.shared.todayMonth && $0.year == AppState.shared.todayYear }).first
    }
    
    var transactions: [CBTransaction] {
        guard let month = month else { return [] }
        let trans = calModel
            .getTransactions(months: [month], meth: payMethod)
            .filter { $0.dateComponents?.day ?? 0 <= AppState.shared.todayDay }
        return trans
    }
    
    var noTransReasonText: String {
        calModel.sYear == AppState.shared.todayYear ? "No Transactions" : "Transactions will only show here for \(AppState.shared.todayYear)"
    }

    var body: some View {
        Group {
            if let month = month, !transactions.isEmpty {
                let days = month.legitDays.filter { $0.id <= AppState.shared.todayDay }.reversed()
                ForEach(days) { day in
                    let trans = getTransactions(day: day)
                    if !trans.isEmpty {
                        Section {
                            transLoop(with: trans)
                        } header: {
                            sectionHeader(for: day)
                        }
                    }
                }
            } else {
                Section {
                    ContentUnavailableView(noTransReasonText, systemImage: "square.slash.fill")
                }
            }
        }
    }
    
    
    @ViewBuilder
    func transLoop(with transactions: Array<CBTransaction>) -> some View {
        ForEach(transactions) { trans in
            TransactionListLine(trans: trans, withDate: false)
                .onTapGesture {
                    let day = month?.days.filter { $0.id == trans.dateComponents?.day }.first
                    self.transDay = day
                    self.transEditID = trans.id
                }
        }
    }
    
    
    @ViewBuilder
    func sectionHeader(for day: CBDay) -> some View {
        if let date = day.date, date.isToday {
            todayIndicatorLine
        } else {
            Text(day.date?.string(to: .monthDayShortYear) ?? "")
        }
    }
    
    
    var todayIndicatorLine: some View {
        HStack {
            Text("TODAY")
                .foregroundStyle(Color.theme)
            VStack {
                Divider()
                    .overlay(Color.theme)
            }
        }
    }
    
    
    func getTransactions(day: CBDay) -> Array<CBTransaction> {
        transactions
            .filter { $0.dateComponents?.day == day.id }
            .sorted { $0.date ?? Date() < $1.date ?? Date() }
    }
}
