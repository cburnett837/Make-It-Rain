//
//  PaymentMethodsView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/20/24.
//

import SwiftUI
import LocalAuthentication


var CARD_HEIGHT: CGFloat = 250

@Observable
class PayMethodTableViewModel {
    var paymentMethodEditID: String?
    var editPaymentMethod: CBPaymentMethod?
    var transEditID: String?
    var transDay: CBDay?
    var selectedPaymentMethod: CBPaymentMethod?

    var hideUnselectedCards: Bool = false
    var walletSearchText = ""
    var transSearchText = ""
    var showOfflineCardDetailsSheet = false
    
    var info: Info = .init()

    var isCardSelected: Bool {
        return selectedPaymentMethod != nil
    }
    
    var navTitle: String {
        "\(isCardSelected ? selectedPaymentMethod!.title : "Wallet")\(AppState.shared.devMode ? " (Dev)" : "")"
    }
    
    var animation: Animation = .interactiveSpring(response: 0.55, dampingFraction: 0.8)

    
    struct Info {
        //var scrollOffset: CGFloat = 0
        var containerSize: CGSize = .zero
        var safeArea: EdgeInsets = .init()
        var minY: CGFloat = 0
        
    }
    
}

struct PayMethodsTable: View {
    @Local(\.useBusinessLogos) var useBusinessLogos
    @AppStorage("paymentMethodTableColumnOrder") private var columnCustomization: TableColumnCustomization<CBPaymentMethod>
    @Environment(\.colorScheme) var colorScheme

    //@Environment(\.dismiss) var dismiss
    @Environment(FuncModel.self) var funcModel
    @Environment(CalendarModel.self) private var calModel
    @Environment(PayMethodModel.self) private var payModel
    @Environment(PlaidModel.self) private var plaidModel
    
    @State private var model = PayMethodTableViewModel()
    @State private var sortOrder = [KeyPathComparator(\CBPaymentMethod.title)]
    
    @State private var defaultViewingMethod: CBPaymentMethod?
    @State private var defaultEditingMethod: CBPaymentMethod?
    @State private var showDefaultViewingSheet = false
    @State private var showDefaultEditingSheet = false
    @State private var showReorderSheet = false
    //@State private var showOfflineCardDetailsSheet = false
    
    @State private var navPath = NavigationPath()
    //@Binding var navPath: NavigationPath /// only if in the more list
        
    var listOrders: [Int] {
        payModel.paymentMethods.map { $0.listOrder ?? 0 }.sorted { $0 > $1 }
    }
    
    var somethingChanged: Int {
        var hasher = Hasher()
        /// Update when the user searches.
        hasher.combine(model.walletSearchText)
        /// Update the sheet if viewing and something changes on another device.
        hasher.combine(payModel.paymentMethods.filter { !$0.isHidden && !$0.isPrivate }.count)
        /// Update when a new payment method gets added or deleted.
        hasher.combine(payModel.paymentMethods.count)
        /// Update when the list order changes via long poll.
        hasher.combine(payModel.paymentMethods.map { $0.listOrder ?? 0 }.sorted { $0 > $1 })
        return hasher.finalize()
    }
    
    struct SortedSection {
        let section: PaymentMethodSection
        var methods: [CBPaymentMethod]
    }
    
    var sortedMethods: [CBPaymentMethod] {
        var sections = [
            SortedSection(section: .debit, methods: []),
            SortedSection(section: .credit, methods: []),
            SortedSection(section: .other, methods: []),
        ]
        
        for each in payModel.paymentMethods
            .filter({
                $0.isPermitted
                && $0.accountHolderFilter()
            })
                
//        .filter ({
//            switch AppSettings.shared.paymentMethodFilterMode {
//            case .all:
//                return true
//                
//            case .justPrimary:
//                return $0.holderOne?.id == AppState.shared.user?.id
//                
//            case .primaryAndSecondary:
//                return $0.holderOne?.id == AppState.shared.user?.id
//                || $0.holderTwo?.id == AppState.shared.user?.id
//                || $0.holderThree?.id == AppState.shared.user?.id
//                || $0.holderFour?.id == AppState.shared.user?.id
//            }
//        })
        .sorted(by: Helpers.paymentMethodSorter()) {
            if let index = sections.firstIndex(where: {$0.section == each.sectionType}) {
                sections[index].methods.append(each)
            }
        }
        
        return sections.flatMap({ $0.methods })
    }

    
    var body: some View {
        //let _ = Self._printChanges()
        NavigationStack {
            VStack {
                ScrollView {
                    ForEach(payModel.sections) { section in
                        let methods = methodsBinding(for: section)
                        if !methods.isEmpty {
                            VStack {
                                Text(model.isCardSelected ? "" : section.rawValue)
                                    .font(.title3)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .scenePadding(.horizontal)
                                    .padding(.leading, 12)
                                    .bold()
                                
                                VStack(spacing: -190) {
                                    ForEach(methods) { meth in
                                        FakeCreditCardView(
                                            meth: meth.wrappedValue,
                                            model: model,
                                            info: model.info,
                                            navPath: $navPath,
                                            sortedMethods: sortedMethods
                                            //isCardSelected: model.isCardSelected
                                        )
                                    }
                                }
                            }
                            
                            /// Put some space between the sections.
                            Spacer()
                                .frame(height: 30)
                        }
                    }
                }
                #if os(iOS)
                .background(Color(.systemGroupedBackground))
                #endif
            }
            .navigationTitle(model.navTitle)
            .searchable(
                text: model.isCardSelected ? $model.transSearchText : $model.walletSearchText,
                placement: .toolbar,
                prompt: model.isCardSelected ? "Search in \(model.selectedPaymentMethod!.title)" : "Search in Wallet"
            )
            #if os(iOS)
            .searchToolbarBehavior(.minimize)
            #endif
            .toolbar {
                #if os(macOS)
                //macToolbar()
                #else
                if let meth = model.selectedPaymentMethod {
                    cardToolbar(for: meth)
                } else {
                    tableToolbar()
                }
                #endif
            }
            .scrollDisabled(model.isCardSelected)
            .navigationDestination(for: CBPaymentMethod.self) { meth in
                PayMethodOverView(payMethod: meth, navPath: $navPath)
            }
            .onGeometryChange(for: CGSize.self) {
                $0.size
            } action: {
                print("(container) info.containerSize is \($0)")
                model.info.containerSize = $0
            }
            .onGeometryChange(for: EdgeInsets.self) {
                $0.safeAreaInsets
            } action: {
                print("(container) info.safeArea is \($0)")
                model.info.safeArea = $0
            }
            .onGeometryChange(for: CGFloat.self) {
                $0.frame(in: .global).minY
            } action: {
                print("(scrollview) info.minY is \($0)")
                model.info.minY = $0
            }
            .sheet(isPresented: $showReorderSheet) {
                PayMethodTableReorderList()
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
            /// Change logic has to be here, as opposed to each individual card, otherwise it will end up running for each card and we will end up with a record for each card, even tho you only edited 1.
            .sheet(item: $model.editPaymentMethod, onDismiss: {
                model.paymentMethodEditID = nil
                payModel.determineIfUserIsRequiredToAddPaymentMethod()
            }) { meth in
                PayMethodEditView(payMethod: meth, editID: $model.paymentMethodEditID)
            }
            .onChange(of: model.paymentMethodEditID) { oldId, newId in
                if let newId {
                    if let payMethod = payModel.getPaymentMethod(by: newId) {
                        model.editPaymentMethod = payMethod
                    } else {
                        model.editPaymentMethod = CBPaymentMethod(uuid: newId)
                    }

                } else if let oldId {
                    if let meth = payModel.getPaymentMethod(by: oldId) {
                        Task {
                            await payModel.savePaymentMethod(id: oldId, calModel: calModel, plaidModel: plaidModel)
                            payModel.determineIfUserIsRequiredToAddPaymentMethod()
                        }
                        
                        /// Close if deleting since it will be gone.
                        /// Also close if adding, since the server will send back the real ID, and cause the list to redraw, which would cause the sheet to dismiss itself and reopen.
                        /// iPhone: pop from nav.
                        /// iPad: dismiss sheet.
                        if meth.action == .delete || meth.action == .add {
                            if AppState.shared.isIphone {
                                withAnimation(model.animation) {
                                    model.selectedPaymentMethod = nil
                                    model.hideUnselectedCards = false
                                }
                                //navPath.removeLast()
                            }
    //                        else {
    //                            dismiss()
    //                        }
                        }
                    }
                } else {
                    fatalError("problem with the payment method edit id")
                }
            }
        }
    }
    
    
    @ToolbarContentBuilder
    func tableToolbar() -> some ToolbarContent {
        #if os(iOS)
        ToolbarItem(placement: .topBarTrailing) { ToolbarRefreshButton() }        
        ToolbarItem(placement: .topBarTrailing) { newAccountButton }
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                PayMethodFilterMenu()
                PayMethodSortMenu()
                
                showReorderSheetButton
                
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
        #else
        ToolbarItem(placement: .principal) { newAccountButton }
        ToolbarItem(placement: .principal) {
            Menu {
                PayMethodFilterMenu()
                PayMethodSortMenu()
                
                showReorderSheetButton
                
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
        #endif
    }
    
    
    @ToolbarContentBuilder
    func cardToolbar(for meth: CBPaymentMethod) -> some ToolbarContent {
        #if os(iOS)
        ToolbarItem(placement: .topBarLeading) {
            closeButton
        }
        
        if !meth.isUnified {
            ToolbarItem(placement: .topBarTrailing) {
                editPaymentMethodButton(meth)
            }
            
            if meth.accountType != .cash {
                ToolbarSpacer(.fixed, placement: .topBarTrailing)
                ToolbarItem(placement: .topBarTrailing) {
                    offlineCardInfoButton
                }
            }
        }
        #else
        ToolbarItem(placement: .principal) {
            closeButton
        }
        
        if !meth.isUnified {
            ToolbarItem(placement: .principal) {
                editPaymentMethodButton(meth)
            }
            
            if meth.accountType != .cash {
                //ToolbarSpacer(.fixed, placement: .principal)
                ToolbarItem(placement: .principal) {
                    offlineCardInfoButton
                }
            }
        }
        #endif
    }
    
    
    @ViewBuilder
    func editPaymentMethodButton(_ meth: CBPaymentMethod) -> some View {
        Button("Edit") {
            model.paymentMethodEditID = meth.id
        }
        .schemeBasedForegroundStyle()
    }
    
    
    var offlineCardInfoButton: some View {
        Button {
            model.showOfflineCardDetailsSheet = true
        } label: {
            Image(systemName: "creditcard.and.numbers")
        }
        .schemeBasedForegroundStyle()
    }
    
    
    var newAccountButton: some View {
        Button {
            let newId = UUID().uuidString
            
            /// On iPhone, push the details page to the nav, which will auto-open the edit sheet.
            if AppState.shared.isIphone {
                //let newMeth = CBPaymentMethod(uuid: newId)
                //let newMeth = payModel.getPaymentMethod(by: newId)
                withAnimation {
                    model.paymentMethodEditID = newId
                }
                //navPath.append(CBPaymentMethod(uuid: newId))
            } else {
                /// On iPad, trigger the details sheet to open, which will then open the edit sheet.
                //#error("On Ipad, when closing the edit sheet, the details sheet freaks out.")
                model.paymentMethodEditID = newId
            }
        } label: {
            Image(systemName: "plus")
        }
        .tint(.none)
        
    }

    
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
    
    
    var showReorderSheetButton: some View {
        Button {
            showReorderSheet = true
        } label: {
            Label {
                Text("Reorder")
            } icon: {
                Image(systemName: "list.number.badge.ellipsis")
                    .tint(.primary)
            }
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
    
    
    var closeButton: some View {
        Button {
            withAnimation(model.animation) {
                model.selectedPaymentMethod = nil
                model.hideUnselectedCards = false
//                model.blur = 0
//                model.scale = 1
//                model.zindex = 1
                //scrollID = transactions.first?.id
            }
        } label: {
            Image(systemName: "xmark")
                .schemeBasedForegroundStyle()
        }
        #if os(macOS)
        .buttonStyle(.roundMacButton)
        #endif
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
        print("-- \(#function)")
        Task { await payModel.setDefaultViewing(defaultViewingMethod) }
    }
    
    
    func setDefaultEditingMethod() {
        print("-- \(#function)")
        Task { await payModel.setDefaultEditing(defaultEditingMethod) }
    }
        
    
    func methodsBinding(for section: PaymentMethodSection) -> Binding<[CBPaymentMethod]> {
        Binding(
            get: {
                payModel.getMethodsFor(section: section, type: .all, sText: model.walletSearchText, includeHidden: true)
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
}

#if os(iOS)
struct OfflineCardDetailsSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var isEditing = false
    @State private var keychainCardNumber: String?
    @State private var keychainExpirationMonth: String?
    @State private var keychainExpirationYear: String?
    @State private var keychainSecurityCode: String?
    
    
    @State private var keychainCardNumberBackup: String?
    @State private var keychainExpirationMonthBackup: String?
    @State private var keychainExpirationYearBackup: String?
    @State private var keychainSecurityCodeBackup: String?
    
    //@State private var keychainCardNumber2: String = ""
    
    @Bindable var payMethod: CBPaymentMethod
    
    let context = LAContext()
    @State private var error: NSError?
    @State private var isUnlocked = false
    @State private var authImage: String = "faceid"
    
    @State private var expDate: Date?
    @State private var showDatePicker = false
    @FocusState private var focusedField: Int?
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    fakeCardCardNumber
                        .blur(radius: isUnlocked ? 0 : 20)
                    fakeCardExpirationDate
                        .blur(radius: isUnlocked ? 0 : 20)
                    fakeCardSecurityCode
                        .blur(radius: isUnlocked ? 0 : 20)
                        
                } footer: {
                    Text("These card details are only for your convenience, are stored securely on-device, and are never transmitted to the server.")
                }
                //.privacySensitive()
                
                if !isUnlocked {
                    Button {
                        authenticate()
                    } label: {
                        Text("Unlock")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                
                if isEditing {
                    clearButton
                }
            }
            .navigationTitle("Physical Card Details")
            .toolbar {
                if isUnlocked {
                    ToolbarItem(placement: .topBarLeading) {
                        editCancelButton
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    if isEditing {
                        saveButton
                    } else {
                        closeButton
                    }
                }
            }
            .sheet(isPresented: $showDatePicker) {
                YearMonthPicker(date: $expDate ?? Date())
                    .presentationDetents([.height(200)])
                    .frame(maxWidth: .infinity)
            }
        }
        .task {
            prepareAuth()
            try? await Task.sleep(for: .seconds(0.5))
            authenticate()
        }
        
        .onChange(of: isUnlocked) {
            if $1 { getCardDetailsFromKeychain() }
        }
        .onChange(of: isEditing) {
            if !$1 { saveCardDetailsToKeychain() }
        }
        .onChange(of: expDate) {
            if let new = $1 {
                keychainExpirationMonth = new.string(to: .mm)
                keychainExpirationYear = new.string(to: .yy)
            }
        }
    }
                 
    
    var fakeCardCardNumber: some View {
        HStack {
            Text("Card Number")
            Spacer()
            UITextFieldWrapper(placeholder: "Card Number", text: $keychainCardNumber ?? "", toolbar: {
                KeyboardToolbarView(
                    focusedField: $focusedField,
                    removeNavButtons: true
                )
            })
            .uiTag(0)
            .uiClearButtonMode(.whileEditing)
            .uiStartCursorAtEnd(true)
            .uiTextAlignment(.right)
            .uiKeyboardType(.system(.numberPad))
            .uiDisabled(!isEditing)
            .uiTextColor(isEditing ? .label : .clear)
            .focused($focusedField, equals: 0)
            .overlay(alignment: .trailing) {
                Text(keychainCardNumber ?? "")
                    .opacity(isEditing ? 0 : 1)
                    .textSelection(.enabled)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    
    var fakeCardExpirationDate: some View {
        HStack {
            Text("Expiration Date")
            Spacer()
            
            if let keychainExpirationMonth, let keychainExpirationYear {
                Text(keychainExpirationMonth.isEmpty || keychainExpirationYear.isEmpty
                     ? "Expiration Date"
                     : "\(keychainExpirationMonth)/\(keychainExpirationYear)"
                )
                .textSelection(.enabled)
                .foregroundStyle(isEditing ? .primary : .secondary)
                .onTapGesture {
                    if isEditing {
                        showDatePicker = true
                        focusedField = nil
                    }
                }
                
            } else {
                Text("Expiration Date")
                    .foregroundStyle(Color(.placeholderText))
                    .onTapGesture {
                        if isEditing {
                            showDatePicker = true
                            focusedField = nil
                        }
                    }
            }
        }
    }
    
    
    var fakeCardSecurityCode: some View {
        HStack {
            Text("Security Code")
            Spacer()
            
            UITextFieldWrapper(placeholder: "Security Code", text: $keychainSecurityCode ?? "", toolbar: {
                KeyboardToolbarView(
                    focusedField: $focusedField,
                    removeNavButtons: true
                )
            })
            .uiTag(1)
            .uiClearButtonMode(.whileEditing)
            .uiStartCursorAtEnd(true)
            .uiTextAlignment(.right)
            .uiKeyboardType(.system(.numberPad))
            .uiDisabled(!isEditing)
            .uiTextColor(isEditing ? .label : .clear)
            .focused($focusedField, equals: 1)
            .overlay(alignment: .trailing) {
                Text(keychainSecurityCode ?? "")
                    .opacity(isEditing ? 0 : 1)
                    .textSelection(.enabled)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    
    var clearButton: some View {
        Button {
            keychainCardNumber = nil
            keychainExpirationMonth = nil
            keychainExpirationYear = nil
            keychainSecurityCode = nil
            expDate = nil
            isEditing = false
        } label: {
            Text("Clear")
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .foregroundStyle(.red)
    }
    
    
    var editCancelButton: some View {
        Button {
            if isEditing {
                keychainCardNumber = keychainCardNumberBackup
                keychainExpirationMonth = keychainExpirationMonthBackup
                keychainExpirationYear = keychainExpirationYearBackup
                keychainSecurityCode = keychainSecurityCodeBackup
                isEditing = false
            } else {
                isEditing = true
                keychainCardNumberBackup = keychainCardNumber
                keychainExpirationMonthBackup = keychainExpirationMonth
                keychainExpirationYearBackup = keychainExpirationYear
                keychainSecurityCodeBackup = keychainSecurityCode
            }
        } label: {
            Text(isEditing ? "Cancel" : "Edit")
                .schemeBasedForegroundStyle()
        }
    }
    
    
    var saveButton: some View {
        Button {
            isEditing = false
            //focusedField = nil
        } label: {
            Text("Save")
                .schemeBasedForegroundStyle()
        }
        .buttonStyle(.glassProminent)
    }
    
    
    var closeButton: some View {
        Button {
            saveCardDetailsToKeychain()
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .schemeBasedForegroundStyle()
        }
        #if os(macOS)
        .buttonStyle(.roundMacButton)
        #endif
    }
    
    
    func close() {
        saveCardDetailsToKeychain()
        dismiss()
    }
    
    
    func prepareAuth() {
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
            } else {
                try keychainManager.removeFromKeychain(key: "payment_method_card_number_\(payMethod.id)")
            }
            
            if let keychainExpirationMonth = keychainExpirationMonth {
                try keychainManager.addToKeychain(key: "payment_method_expiration_month_\(payMethod.id)", value: keychainExpirationMonth)
            } else {
                try keychainManager.removeFromKeychain(key: "payment_method_expiration_month_\(payMethod.id)")
            }
            
            if let keychainExpirationYear = keychainExpirationYear {
                try keychainManager.addToKeychain(key: "payment_method_expiration_year_\(payMethod.id)", value: keychainExpirationYear)
            } else {
                try keychainManager.removeFromKeychain(key: "payment_method_expiration_year_\(payMethod.id)")
            }
            
            if let keychainSecurityCode = keychainSecurityCode {
                try keychainManager.addToKeychain(key: "payment_method_security_code_\(payMethod.id)", value: keychainSecurityCode)
            } else {
                try keychainManager.removeFromKeychain(key: "payment_method_security_code_\(payMethod.id)")
            }

        } catch {
            print(error.localizedDescription)
        }
    }
    
    
    
    struct YearMonthPicker: UIViewRepresentable {
        @Binding var date: Date

        func makeUIView(context: Context) -> UIDatePicker {
            let picker = UIDatePicker()
            picker.datePickerMode = .yearAndMonth
            picker.preferredDatePickerStyle = .wheels
            picker.addTarget(
                context.coordinator,
                action: #selector(Coordinator.dateChanged(_:)),
                for: .valueChanged
            )
            return picker
        }

        func updateUIView(_ picker: UIDatePicker, context: Context) {
            picker.date = date
        }

        func makeCoordinator() -> Coordinator {
            Coordinator(date: $date)
        }

        final class Coordinator: NSObject {
            @Binding var date: Date

            init(date: Binding<Date>) {
                self._date = date
            }

            @objc func dateChanged(_ sender: UIDatePicker) {
                date = sender.date
            }
        }
    }
}
#endif


struct FakeCreditCardView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(FuncModel.self) var funcModel
    @Environment(CalendarModel.self) private var calModel
    @Environment(PayMethodModel.self) private var payModel
    @Environment(PlaidModel.self) private var plaidModel
    

    var meth: CBPaymentMethod
    @Bindable var model: PayMethodTableViewModel
    var info: PayMethodTableViewModel.Info
    @Binding var navPath: NavigationPath
    //var isCardSelected: Bool
    var sortedMethods: [CBPaymentMethod]
    
    @State private var blur: CGFloat = 0
    @State private var scale: CGFloat = 1
    //@State private var showOfflineCardDetailsSheet = false

    
    var month: CBMonth? {
        calModel.months.filter({ $0.actualNum == AppState.shared.todayMonth && $0.year == AppState.shared.todayYear }).first
    }
    
    /// Even though this is a property in the model, we need it to be local so we can use it in the visual effects capture list.
    var isCardSelected: Bool {
        return model.isCardSelected
    }
        
    var isCurrent: Bool {
        meth.id == model.selectedPaymentMethod?.id
    }
    
    var currentIndex: Int {
        sortedMethods.firstIndex(where: { $0.id == meth.id }) ?? 0
    }
    
    var selectedIndex: Int {
        sortedMethods.firstIndex(where: { $0.id == model.selectedPaymentMethod?.id }) ?? 0
    }
    
    var plaidBalance: CBPlaidBalance? {
        plaidModel.balances.filter({ $0.payMethodID == meth.id }).first
    }
    
    var plaidBalanceIsStale: Bool {
        if let balance = plaidBalance, let entered = balance.enteredDate {
            return Calendar.current.dateComponents([.day], from: entered, to: Date()).day! > 2
        } else {
            return false
        }
        
    }

    var body: some View {
        //let _ = Self._printChanges()
        card
            //.zIndex(Double(currentIndex))
            .padding(14)
            .frame(maxWidth: .infinity)
            .frame(height: CARD_HEIGHT)
            .background(fakeCardBackground)
            //.shadow(radius: 10)
            .scenePadding(.horizontal) /// Pad the card instead of the list since the transaction list is naturally padded.
            .blur(radius: blur)
            .scaleEffect(scale)
            .onTapGesture(perform: touchCard)
            .onChange(of: model.hideUnselectedCards) { old, new in
                guard meth.id != model.selectedPaymentMethod?.id else { return }
                if new {
                    blur = 0
                    scale = 0
                } else {
                    blur = 0
                    scale = 1
                }
            }
            .overlay(alignment: .top) {
                if isCardSelected && isCurrent {
                    CardAccessoryView(
                        meth: meth,
                        model: model,
                        blur: $blur,
                        scale: $scale,
                        navPath: $navPath
                    )
                }
            }
            .visualEffect { [info, isCardSelected, selectedIndex, currentIndex, isCurrent] content, proxy in
                let rect = proxy.frame(in: .scrollView)

                let pushOffset = selectedIndex < currentIndex
                ? info.containerSize.height + info.safeArea.bottom - rect.minY
                : -rect.minY

                let stackedScale = selectedIndex < currentIndex ? 1.0 : 0.95

                return content
                    /// use a tiny scale effect so we don't see the other cards bounce behind the selected card when animating.
                    .scaleEffect(isCardSelected ? (isCurrent ? 1 : stackedScale) : 1, anchor: .top)
                    .offset(y: isCardSelected ? pushOffset : 0)
            }
        #if os(iOS)
            .sheet(isPresented: $model.showOfflineCardDetailsSheet) {
                if let meth = model.selectedPaymentMethod {
                    OfflineCardDetailsSheet(payMethod: meth)
                }
            }
        #endif
//            .sheet(item: $model.editPaymentMethod, onDismiss: {
//                model.paymentMethodEditID = nil
//                payModel.determineIfUserIsRequiredToAddPaymentMethod()
//            }) { meth in
//                PayMethodEditView(payMethod: meth, editID: $model.paymentMethodEditID)
//            }
//            .onChange(of: model.paymentMethodEditID) { oldId, newId in
//                print("running attached to \(model.editPaymentMethod?.title)")
//                if let newId {
//                    if let payMethod = payModel.getPaymentMethod(by: newId) {
//                        model.editPaymentMethod = payMethod
//                    } else {
//                        model.editPaymentMethod = CBPaymentMethod(uuid: newId)
//                    }
//
//                } else {
//                    if let meth = payModel.getPaymentMethod(by: oldId!) {
//                        let _ = payModel.savePaymentMethod(id: oldId!, calModel: calModel, plaidModel: plaidModel)
//                        payModel.determineIfUserIsRequiredToAddPaymentMethod()
//                        /// Close if deleting since it will be gone.
//                        /// Also close if adding, since the server will send back the real ID, and cause the list to redraw, which would cause the sheet to dismiss itself and reopen.
//                        /// iPhone: pop from nav.
//                        /// iPad: dismiss sheet.
//                        if meth.action == .delete || meth.action == .add {
//                            if AppState.shared.isIphone {
//                                withAnimation(model.animation) {
//                                    model.selectedPaymentMethod = nil
//                                    model.hideUnselectedCards = false
//                                }
//                                //navPath.removeLast()
//                            }
//    //                        else {
//    //                            dismiss()
//    //                        }
//                        }
//                    }
//                }
//            }
    }
    
    @ViewBuilder
    var card: some View {
        VStack {
            HStack {
                HStack(spacing: 12) {
                    PayMethodLogoMashup(meth: meth, size: 40)
//                    BusinessLogo(config: .init(
//                        parent: meth,
//                        fallBackType: meth.isUnified ? .gradient : .color,
//                        size: 40
//                    ))
                    .blur(radius: blur)
                    
                    Text(meth.title)
                        .font(.title3)
                        .bold()
                }
                
                Spacer()
                
                if meth.isUnified {
                    let ids = payModel.paymentMethods
                        .filter({ filterMeth in
                            if meth.isUnifiedDebit {
                                return filterMeth.isDebitOrCash && filterMeth.isPermittedAndNotHidden
                            } else if meth.isUnifiedCredit {
                                return filterMeth.isCreditOrLoan && filterMeth.isPermittedAndNotHidden
                            } else {
                                return false
                            }
                        })
                        .filter { $0.accountHolderFilter() }
//                        .filter {
//                            switch AppSettings.shared.paymentMethodFilterMode {
//                            case .all:
//                                return true
//                                
//                            case .justPrimary:
//                                return $0.holderOne?.id == AppState.shared.user?.id
//                                
//                            case .primaryAndSecondary:
//                                return $0.holderOne?.id == AppState.shared.user?.id
//                                || $0.holderTwo?.id == AppState.shared.user?.id
//                                || $0.holderThree?.id == AppState.shared.user?.id
//                                || $0.holderFour?.id == AppState.shared.user?.id
//                            }
//                        }
                        .map({ $0.id })
                    
                    let balance = plaidModel.balances
                        .filter({ ids.contains($0.payMethodID) })
                        .map({ $0.amount })
                        .reduce(0, +)
                    
                    Text(balance.currencyWithDecimals())
                        .bold()
                
                    
                } else if let balance = plaidBalance {
                    HStack {
                        Text(balance.amount.currencyWithDecimals())
                            .bold()
                        
                        if plaidBalanceIsStale {
                            Image(systemName: "exclamationmark.triangle")
                        }
                    }
                }
            }
            
            HStack(alignment: .top) {
                Spacer()
                if let balance = plaidBalance {
                    Text("\(Date().timeSince(balance.enteredDate))")
                        .foregroundStyle(.gray)
                        .font(.subheadline)
                        .opacity(isCardSelected && meth.id == model.selectedPaymentMethod?.id ? 1 : 0)
                        .offset(y: -14)
                }
            }
            
            
            
//            HStack {
//                Text("**** **** **** \(meth.last4 ?? "****")")
//                    .font(.title)
//                Spacer()
//            }
                                            
            Spacer()
            
            HStack {
                VStack(alignment: .leading) {
                    HStack {
                        Text(meth.accountType.prettyValue)
                        if meth.isPrivate { Image(systemName: "person.slash") }
                        if meth.isHidden { Image(systemName: "eye.slash") }
                        if meth.notifyOnDueDate { Image(systemName: "alarm") }
                    }
                                        
                    Text(meth.holderDisplay)
                        .lineLimit(1)
                    
                    Text("**** \(meth.last4 ?? "****")")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                //Spacer()
                VStack(alignment: .trailing, spacing: 0) {
                    if let ccBrand = meth.ccBrand {
                        Image(ccBrand.rawValue)
                            .renderingMode(.original)
                            .interpolation(.high)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 40, alignment: .bottomTrailing)
                            .offset(x:
                                ccBrand.rawValue.contains("visa")
                                ? 18
                                : ccBrand.rawValue.contains("mastercard")
                                ? 14
                                : 0
                            )
                    }
                    
                    if let cunt = meth.country {
                        HStack {
                            FlagCircle(code: cunt.code)
                            Text("\(cunt.currencyCode)")
                        }
                    }
                }
                
            }
        }
    }
    
    
    
    @ViewBuilder
    var fakeCardBackground: some View {
        let colors: Array<Color> = meth.isUnified ? [
            .purple, .red, .orange,
            .blue, .red, .orange,
            .blue, .orange, .orange
        ] : [
            meth.color, meth.color, meth.color,
            meth.color.lighter(by: 30), meth.color, meth.color.lighter(by: 30),
            meth.color, meth.color.lighter(by: 30), meth.color
        ]
        
        RoundedRectangle(cornerRadius: 26)
            //.fill(AngularGradient(gradient: rainbowGradient, center: .center))
            .fill(
                MeshGradient(
                    width: 3,
                    height: 3,
                    points: [
                        .init(0, 0), .init(0.5, 0), .init(1, 0),
                        .init(0, 0.5), .init(0.9, 0.6), .init(1, 0.5),
                        .init(0, 1), .init(0.5, 1), .init(1, 1),
                    ],
                    colors: colors
                )
            )
    }
    
    
    func touchCard() {
        withAnimation(model.animation) {
            if isCardSelected {
                model.selectedPaymentMethod = nil
                model.hideUnselectedCards = false
            } else {
                model.selectedPaymentMethod = meth
            }
        } completion: {
            if isCardSelected {
                model.hideUnselectedCards = true
            }
        }
    }
}






struct CardAccessoryView: View {
    @Environment(CalendarModel.self) private var calModel
    @Environment(PayMethodModel.self) private var payModel
    @Bindable var meth: CBPaymentMethod
    @Bindable var model: PayMethodTableViewModel
    @Binding var blur: CGFloat
    @Binding var scale: CGFloat
    @Binding var navPath: NavigationPath
    
    @State private var transactions: [CBTransaction] = []
    
    var filteredTransactions: [CBTransaction] {
        transactions.filter {
            model.transSearchText.isEmpty ? true : String($0.title).localizedCaseInsensitiveContains(model.transSearchText)
        }
        .sorted(by: { $0.date ?? Date() > $1.date ?? Date() })
    }
    
    var month: CBMonth? {
        calModel.months.filter({ $0.actualNum == AppState.shared.todayMonth && $0.year == AppState.shared.todayYear }).first
    }
        
    var noTransReasonText: String {
        calModel.sYear == AppState.shared.todayYear ? "No Transactions" : "Transactions will only show here for \(AppState.shared.todayYear)"
    }

    var body: some View {
        VStack {
            List {
                NavigationLink(value: "chart-page") {
                    Label("Insights", systemImage: "chart.xyaxis.line")
                        .schemeBasedForegroundStyle()
                }
                
                if let month = month, !transactions.isEmpty {
                    Section("Recent Transactions") {
                        ForEach(filteredTransactions) { trans in
                            TransactionListLine(trans: trans, withDate: true, withTags: true, withPhotos: true) {
                                let day = month.days.filter { $0.id == trans.dateComponents?.day }.first
                                model.transDay = day
                                model.transEditID = trans.id
                            }
                            .id(trans.id)
                        }
                    }
                } else {
                    Section {
                        ContentUnavailableView(noTransReasonText, systemImage: "square.slash.fill")
                    }
                }
            }
        }
        .onScrollGeometryChange(for: CGFloat.self) {
            $0.contentOffset.y + $0.contentInsets.top
        } action: { _, newOffset in
            guard model.isCardSelected else { return }

            let collapseDistance: CGFloat = 200
            let raw = 1 - (newOffset / collapseDistance)

            blur = min(newOffset / 16, 8)
            scale = max(min(raw, 1), 0)
        }
        
        .navigationDestination(for: String.self) { _ in chartPage }
        //.scrollPosition(id: $scrollID)
        .scrollContentBackground(.hidden)
        .frame(height: model.info.containerSize.height + model.info.safeArea.bottom)
        .contentMargins(.top, CARD_HEIGHT + 10, for: .scrollContent)
        .contentMargins(.bottom, model.info.safeArea.bottom, for: .scrollContent)
        .task {
            //await prepareView()
            
            guard let month = month, let meth = model.selectedPaymentMethod else { return }
            self.transactions = calModel
                .getTransactions(months: [month], meth: meth)
                .filter { $0.dateComponents?.day ?? 0 <= AppState.shared.todayDay }
                .filter { model.transSearchText.isEmpty ? true : String($0.title).localizedCaseInsensitiveContains(model.transSearchText) }
        }
        /// Make sure this stays under the other modifiers otherwise the frame will get appplied and cause weird scroll offset.
        .transactionEditSheetAndLogic(transEditID: $model.transEditID, selectedDay: $model.transDay, extraDismissLogic: { didSave in
//            if didSave {
//                Task { await prepareView() }
//            }
        })
    }
    
    @ViewBuilder
    var chartPage: some View {
        if meth.action == .add {
            ContentUnavailableView("Insights are not available when adding a new account", systemImage: "square.stack.3d.up.slash.fill")
        } else {
            PayMethodDashboard(payMethod: meth, navPath: $navPath)
        }
    }
    
    
//    func prepareView() async {
//        if meth.action == .add {
//            //payModel.upsert(payMethod)
//            model.paymentMethodEditID = meth.id
//            viewModel.isLoadingHistory = false
//        } else {
//            
//            viewModel.fetchHistory(for: meth, payModel: payModel, setChartAsNew: true)
//            
////            /// iPhone: only fetch the new historical if it has been wiped out (by returning to the account list), or if a transaction has been updated since the history was fetched from the server.
////            /// Due to the navigation stack, we can leave the chart open and go elsewhere in the app. Thus, no need to refresh the data unless a transaction changed in the meantime.
////            /// Likewise, when returning to the account list, the viewmodel would be destroyed, and the history would need to be refetched.
////            ///
////            /// iPad: Always fetch the data since everything is inside a sheet, which must be closed before returning to the rest of the app. Thus the viewmodel would be destroyed, and the history would need to be refetched.
////            let needsUpdates = calModel.transactionsUpdatesExistAfter(fetchHistoryTime)
////            if meth.breakdownsRegardlessOfPaymentMethod.isEmpty || needsUpdates || AppState.shared.isIpad {
////                fetchHistoryTime = Date()
////                viewModel.fetchHistory(for: meth, payModel: payModel, setChartAsNew: true)
////            }
//        }
//    }
}

//
//struct CardAccessorySheet: View {
//    @Environment(CalendarModel.self) private var calModel
//    @Environment(PayMethodModel.self) private var payModel
//    @Environment(PlaidModel.self) private var plaidModel
//
//    var payMethod: CBPaymentMethod
//    let info: PayMethodsTable.Info
//    @Binding var paymentMethodEditID: CBPaymentMethod.ID?
//
//    @Binding var navPath: NavigationPath
//    var searchText: String
//
//    @State private var editPaymentMethod: CBPaymentMethod?
//    @State private var transEditID: String?
//    @State private var transDay: CBDay?
//
//    var maxSheetHeight: CGFloat {
//        info.containerSize.height + info.safeArea.bottom - 10 /// Add the 10 because of some natural padding iOS does on sheets. (i think)
//    }
//    var minSheetHeight: CGFloat {
//        maxSheetHeight - 10 - CARD_HEIGHT - 10 /// add another 10 for the sheet issue above, + the height of the card, + a little extra to give it. some space.
//    }
//
//    var body: some View {
//        PaymentMethodTransactionList(payMethod: payMethod, transEditID: $transEditID, transDay: $transDay, searchText: searchText)
//            .transactionEditSheetAndLogic(transEditID: $transEditID, selectedDay: $transDay, extraDismissLogic: { didSave in
//    //            if didSave {
//    //                Task { await prepareView() }
//    //            }
//            })
//            .presentationDragIndicator(.hidden)
//            .presentationDetents([.height(minSheetHeight), .height(maxSheetHeight), .large])
//            .presentationBackgroundInteraction(.enabled(upThrough: .height(minSheetHeight)))
//            .interactiveDismissDisabled()
//            .sheet(item: $editPaymentMethod, onDismiss: {
//                paymentMethodEditID = nil
//                payModel.determineIfUserIsRequiredToAddPaymentMethod()
//            }) { meth in
//                PayMethodEditView(payMethod: meth, editID: $paymentMethodEditID)
//            }
//            .onChange(of: paymentMethodEditID) { oldId, newId in
//                if let newId {
//                    if let payMethod = payModel.getPaymentMethod(by: newId) {
//                        editPaymentMethod = payMethod
//                    } else {
//                        editPaymentMethod = CBPaymentMethod(uuid: newId)
//                    }
//
//                } else {
//                    let _ = payModel.savePaymentMethod(id: oldId!, calModel: calModel, plaidModel: plaidModel)
//                    payModel.determineIfUserIsRequiredToAddPaymentMethod()
//                    /// Close if deleting since it will be gone.
//                    /// Also close if adding, since the server will send back the real ID, and cause the list to redraw, which would cause the sheet to dismiss itself and reopen.
//                    /// iPhone: pop from nav.
//                    /// iPad: dismiss sheet.
//                    if payMethod.action == .delete || payMethod.action == .add {
//                        if AppState.shared.isIphone {
//                            navPath.removeLast()
//                        }
////                        else {
////                            dismiss()
////                        }
//                    }
//                }
//            }
//    }
//}
//


















//
//
//struct PayMethodsTableNORMAL: View {
//    @Local(\.useBusinessLogos) var useBusinessLogos
//    @AppStorage("paymentMethodTableColumnOrder") private var columnCustomization: TableColumnCustomization<CBPaymentMethod>
//    
//    @Environment(\.dismiss) var dismiss
//    @Environment(FuncModel.self) var funcModel
//    @Environment(CalendarModel.self) private var calModel
//    @Environment(PayMethodModel.self) private var payModel
//    
//    @Environment(PlaidModel.self) private var plaidModel
//    
//    @State private var searchText = ""
//    @State private var selectedPaymentMethod: CBPaymentMethod?
//    @State private var editPaymentMethod: CBPaymentMethod?
//    @State private var paymentMethodEditID: CBPaymentMethod.ID?
//    @State private var sortOrder = [KeyPathComparator(\CBPaymentMethod.title)]
//    
//    @State private var defaultViewingMethod: CBPaymentMethod?
//    @State private var defaultEditingMethod: CBPaymentMethod?
//    @State private var showDefaultViewingSheet = false
//    @State private var showDefaultEditingSheet = false
//    
//    @Binding var navPath: NavigationPath
//    //@State private var navPath = NavigationPath()
//    
//    var listOrders: [Int] {
//        payModel.paymentMethods.map { $0.listOrder ?? 0 }.sorted { $0 > $1 }
//    }
//        
////    var filteredPayMethods: [CBPaymentMethod] {
////        payModel.paymentMethods
////            .filter { !$0.isUnified }
////            .filter { $0.isPermitted }
////            .filter { searchText.isEmpty ? !$0.title.isEmpty : $0.title.localizedCaseInsensitiveContains(searchText) }
////            //.sorted { $0.title.lowercased() < $1.title.lowercased() }
////    }
////    
////    var debitMethods: [CBPaymentMethod] {
////        payModel.paymentMethods
////            .filter { $0.isPermitted }
////            .filter { $0.accountType == .checking || $0.accountType == .unifiedChecking }
////            .filter { searchText.isEmpty ? true : $0.title.localizedCaseInsensitiveContains(searchText) }
////    }
////    
////    var creditMethods: [CBPaymentMethod] {
////        payModel.paymentMethods
////            .filter { $0.isPermitted }
////            .filter { $0.accountType == .credit || $0.accountType == .unifiedCredit || $0.accountType == .loan }
////            .filter { searchText.isEmpty ? true : $0.title.localizedCaseInsensitiveContains(searchText) }
////    }
////    
////    var otherMethods: [CBPaymentMethod] {
////        payModel.paymentMethods
////            .filter { $0.isPermitted }
////            .filter { $0.accountType != .checking && $0.accountType != .credit && $0.accountType != .loan && !$0.isUnified }
////            .filter { searchText.isEmpty ? true : $0.title.localizedCaseInsensitiveContains(searchText) }
////    }
////    var sections: Array<SectionData> {
////        return [
////            SectionData(title: "Debit", items: debitMethods),
////            SectionData(title: "Credit", items: creditMethods),
////            SectionData(title: "Other", items: otherMethods)
////        ]
////    }
//    
//    
//    /// Keep the sections in the model so they don't flash every time you go to the account table on the iPad.
//    //@State private var sections: Array<PaySection> = []
//    
//    var somethingChanged: Int {
//        var hasher = Hasher()
//        /// Update when the user searches.
//        hasher.combine(searchText)
//        /// Update the sheet if viewing and something changes on another device.
//        hasher.combine(payModel.paymentMethods.filter { !$0.isHidden && !$0.isPrivate }.count)
//        /// Update when a new payment method gets added or deleted.
//        hasher.combine(payModel.paymentMethods.count)
//        /// Update when the list order changes via long poll.
//        hasher.combine(payModel.paymentMethods.map { $0.listOrder ?? 0 }.sorted { $0 > $1 })
//        return hasher.finalize()
//    }
//
//    
//    var body: some View {
//        @Bindable var payModel = payModel
//        //NavigationStack(path: $navPath) {
//            VStack {
//                if !payModel.paymentMethods.filter({ !$0.isUnified }).isEmpty {
//                    #if os(macOS)
//                    macTable
//                    #else
//                    if AppState.shared.isIphone {
//                        phoneList
//                    } else {
//                        padList
//                    }
//                    #endif
//                } else {
//                    ContentUnavailableView("No Accounts", systemImage: "creditcard", description: Text("Click the plus button above to add a new account."))
//                }
//            }
//            #if os(iOS)
//            .navigationTitle("Accounts\(AppState.shared.devMode ? " (Dev)" : "")")
//            //.navigationBarTitleDisplayMode(.inline)
//            #endif
//            
//            #if os(macOS)
//            /// There seems to be a bug in SwiftUI `Table` that prevents the view from refreshing when adding a new payment method, and then trying to edit it.
//            /// When I add a new payment method, and then update `model.paymentMethods` with the new ID from the server, the table still contains an ID of 0 on the newly created payment method.
//            /// Setting this id forces the view to refresh and update the relevant payment method with the new ID.
//            .id(payModel.fuckYouSwiftuiTableRefreshID)
//            #endif
//            //.navigationBarBackButtonHidden(true)
//            .task {
//                defaultViewingMethod = payModel.paymentMethods.filter { $0.isViewingDefault }.first
//                defaultEditingMethod = payModel.paymentMethods.filter { $0.isEditingDefault }.first
//                /// NOTE: Sorting must be done here and not in the computed property. If done in the computed property, when reordering, they get all messed up.
//                payModel.paymentMethods.sort(by: Helpers.paymentMethodSorter())
//                //populateSections()
//            }
//            .navigationDestination(for: CBPaymentMethod.self) { meth in
//                PayMethodOverView(payMethod: meth, navPath: $navPath)
//            }
//            .toolbar {
//                #if os(macOS)
//                macToolbar()
//                #else
//                phoneToolbar()
//                #endif
//            }
//            .searchable(text: $searchText)
//            .onAppear {
//                print("Clear the breakdowns")
//                payModel.paymentMethods.forEach {
//                    $0.breakdowns.removeAll()
//                    $0.breakdownsRegardlessOfPaymentMethod.removeAll()
//                }
//            }
//            //.onChange(of: AppSettings.shared.paymentMethodFilterMode) { populateSections() }
//            //.onChange(of: AppSettings.shared.paymentMethodSortMode) { populateSections() }
//            //.onChange(of: somethingChanged) { populateSections() }
//            .onChange(of: sortOrder) { payModel.paymentMethods.sort(using: $1) }
////            .sheet(item: $editPaymentMethod, onDismiss: {
////                paymentMethodEditID = nil
////                payModel.determineIfUserIsRequiredToAddPaymentMethod()
////            }) { meth in
////                PayMethodEditView(payMethod: meth, editID: $paymentMethodEditID)
////                    #if os(macOS)
////                    .frame(minWidth: 500, minHeight: 700)
////                    .presentationSizing(.fitted)
////                    #else
////                    .presentationSizing(.page)
////                    #endif
////            }
//            .onChange(of: paymentMethodEditID) { oldValue, newValue in
//                if let newValue {
//                    let payMethod = payModel.getPaymentMethod(by: newValue)
//                    selectedPaymentMethod = payMethod
//                } else {
//                    selectedPaymentMethod = nil
//                }
//            }
//            .sheet(item: $selectedPaymentMethod, onDismiss: {
//                paymentMethodEditID = nil
//                payModel.determineIfUserIsRequiredToAddPaymentMethod()
//            }) { meth in
//                PayMethodOverViewWrapperIpad(payMethod: meth)
//                    #if os(macOS)
//                    .frame(minWidth: 300, minHeight: 500)
//                    .presentationSizing(.page)
//                    #endif
//                    //.presentationSizing(.page)
//            }
//            .sheet(isPresented: $showDefaultViewingSheet, onDismiss: setDefaultViewingMethod) {
//                PayMethodSheet(payMethod: $defaultViewingMethod, whichPaymentMethods: .all, showNoneOption: true)
//                    #if os(macOS)
//                    .frame(minWidth: 300, minHeight: 500)
//                    .presentationSizing(.page)
//                    #endif
//            }
//            .sheet(isPresented: $showDefaultEditingSheet, onDismiss: setDefaultEditingMethod) {
//                PayMethodSheet(payMethod: $defaultEditingMethod, whichPaymentMethods: .allExceptUnified, showNoneOption: true)
//                    #if os(macOS)
//                    .frame(minWidth: 300, minHeight: 500)
//                    .presentationSizing(.page)
//                    #endif
//            }
//        //}
//    }
//    
//    #if os(macOS)
//    @ToolbarContentBuilder
//    func macToolbar() -> some ToolbarContent {
//        ToolbarItem(placement: .navigation) {
//            HStack {
//                Button {
//                    paymentMethodEditID = UUID().uuidString
//                } label: {
//                    Image(systemName: "plus")
//                }
//                .toolbarBorder()
//                //.disabled(payModel.isThinking)
//                
//                ToolbarNowButton()
//                    .disabled(!AppState.shared.methsExist)
//                ToolbarRefreshButton()
//                    .toolbarBorder()
//                    .disabled(!AppState.shared.methsExist)
//                
//                moreMenu
//                    .toolbarBorder()
//                    .disabled(!AppState.shared.methsExist)
//            }
//        }
//        ToolbarItem(placement: .principal) {
//            ToolbarCenterView(enumID: .paymentMethods)
//        }
//        ToolbarItem {
//            Spacer()
//        }
//    }
//      
//    
//    var macTable: some View {
//        Table(of: CBPaymentMethod.self, selection: $paymentMethodEditID, sortOrder: $sortOrder, columnCustomization: $columnCustomization) {
//            TableColumn("Title", value: \.title) { meth in
//                HStack {
//                    if meth.accountType != .unifiedChecking && meth.accountType != .unifiedCredit {
//                        Circle()
//                            .fill(meth.color)
//                            .frame(width: 12, height: 12)
//                    } else {
//                        Text("-")
//                    }
//                    Text(meth.title)
//                }
//            }
//            .customizationID("title")
//            
//            TableColumn("Account Type", value: \.accountType.rawValue) { meth in
//                Text(XrefModel.getItem(from: .accountTypes, byID: meth.accountType.rawValue).description)
//            }
//            .customizationID("accountType")
//            
//            TableColumn("Last 4", value: \.last4) { meth in
//                if meth.accountType == .checking || meth.accountType == .credit {
//                    Text(meth.last4 ?? "-")
//                } else {
//                    Text("-")
//                }
//            }
//            .customizationID("last4")
//            
//            TableColumn("Limit", value: \.limit.specialDefaultIfNil) { meth in
//                if meth.accountType == .credit {
//                    Text(meth.limit?.currencyWithDecimals() ?? "-")
//                } else {
//                    Text("-")
//                }
//            }
//            .customizationID("limit")
//            
//            TableColumn("Due Date", value : \.dueDate.specialDefaultIfNil) { meth in
//                if meth.accountType == .credit || meth.accountType == .loan {
//                    Text("The \(meth.dueDate?.withOrdinal() ?? "N/A") of every month")
//                    //Text("The \(String(meth.dueDate ?? 0)) of every month")
//                } else {
//                    Text("-")
//                }
//            }
//            .customizationID("dueDate")
//            
////            TableColumn("Reminder", value: \.notificationOffset.specialDefaultIfNil) { meth in
////                if meth.accountType == .credit || meth.accountType == .loan {
////                    if meth.notifyOnDueDate {
////                        Label {
////                            let text = meth.notificationOffset == 0 ? "On day of" : (meth.notificationOffset == 1 ? "The day before" : "2 days before")
////                            Text(text)
////                        } icon: {
////                            Image(systemName: "alarm")
////                        }
////                    }
////                } else {
////                    Text("-")
////                }
////            }
////            .customizationID("reminder")
//            
//            TableColumn("Viewing (default)") { meth in
//                if meth.isViewingDefault {
//                    Image(systemName: "checkmark")
//                }
//            }
//            .width(min: 20, ideal: 30, max: 50)
//            .customizationID("defaultViewing")
//            
//            TableColumn("Editing (default)") { meth in
//                if meth.isEditingDefault {
//                    Image(systemName: "checkmark")
//                }
//            }
//            .width(min: 20, ideal: 30, max: 50)
//            .customizationID("defaultEditing")
//            
//            TableColumn("Private") { meth in
//                if meth.isPrivate {
//                    Image(systemName: "checkmark")
//                }
//            }
//            .width(min: 20, ideal: 30, max: 50)
//            .customizationID("private")
//            
//            TableColumn("Hidden") { meth in
//                if meth.isHidden {
//                    Image(systemName: "checkmark")
//                }
//            }
//            .width(min: 20, ideal: 30, max: 50)
//            .customizationID("hidden")
//        } rows: {
////            Section("Combined Accounts") {
////                ForEach(payModel.paymentMethods.filter { $0.isUnified }) { meth in
////                    TableRow(meth)
////                }
////            }
////            
////            Section("My Accounts") {
////                ForEach(filteredPayMethods) { meth in
////                    TableRow(meth)
////                }
////            }
//            
//            
//            ForEach(payModel.sections) { section in
//                Section(section.rawValue) {
//                    ForEach(payModel.getMethodsFor(section: section, type: .all, sText: searchText, includeHidden: true)) { meth in
//                        TableRow(meth)
//                    }
//                }
//            }
//            
////            Section("Debit") {
////                ForEach(debitMethods) { meth in
////                    TableRow(meth)
////                }
////            }
////            
////            Section("Credit") {
////                ForEach(creditMethods) { meth in
////                    TableRow(meth)
////                }
////            }
////            
////            Section("Other") {
////                ForEach(otherMethods) { meth in
////                    TableRow(meth)
////                }
////            }
//        }
//        .clipped()
//
//    }   
//    #endif
//    
//    
//    #if os(iOS)
//    @ToolbarContentBuilder
//    func phoneToolbar() -> some ToolbarContent {
//        @Bindable var payModel = payModel
//        ToolbarItem(placement: .topBarLeading) {
//            Menu {
//                PayMethodFilterMenu()
//                PayMethodSortMenu()
//                //moreMenu
//                
//                Section("Default Viewing Account") {
//                    showDefaultForViewingSheetButton
//                }
//                
//                Section("Default Editing Account") {
//                    showDefaultForEditingSheetButton
//                }
//                
//                Section("Appearance") {
//                    useBusinessLogosToggle
//                }
//                
//            } label: {
//                Image(systemName: "ellipsis")
//                    .schemeBasedForegroundStyle()
//            }
//
//            
//        }
//        //ToolbarItem(placement: .topBarLeading) { PayMethodSortMenu(sections: $payModel.sections) }
//        //ToolbarSpacer(.fixed, placement: .topBarLeading)
//        //ToolbarItem(placement: .topBarLeading) { moreMenu }
//        
//        ToolbarItem(placement: .topBarTrailing) { ToolbarLongPollButton() }
//        ToolbarItem(placement: .topBarTrailing) { ToolbarRefreshButton().disabled(!AppState.shared.methsExist) }
//        //ToolbarSpacer(.fixed, placement: .topBarTrailing)
//        ToolbarItem(placement: .topBarTrailing) { newAccountButton }
//    }
//    
//        
//    /// On iPhone, use the navigation links directly in the list.
//    @ViewBuilder
//    var phoneList: some View {
//        @Bindable var payModel = payModel
//        
//        List {
//            ForEach(payModel.sections) { section in
//                Section(section.rawValue) {
//                    ForEach(methodsBinding(for: section)) { meth in
//                        NavigationLink(value: meth.wrappedValue) {
//                            line(for: meth.wrappedValue)
//                        }
//                    }
//                    .if(AppSettings.shared.paymentMethodSortMode == .listOrder) {
//                        $0.onMove { indices, newOffset in
//                            methodsBinding(for: section)
//                                .wrappedValue
//                                .move(fromOffsets: indices, toOffset: newOffset)
//                            
//                            Task {
//                                let updates = await payModel.setListOrders(calModel: calModel)
//                                await funcModel.submitListOrders(items: updates, for: .paymentMethods)
//                            }
//                        }
//                    }
//                }
//            }
//            
////            ForEach(payModel.sections) { section in
////                Section(section.rawValue) {
////                    ForEach(payModel.getMethodsFor(section: section, type: .all, sText: searchText, includeHidden: true)) { meth in
////                        NavigationLink(value: meth) {
////                            line(for: meth)
////                        }
////                    }
////                    .if(AppSettings.shared.paymentMethodSortMode == .listOrder) {
////                        $0.onMove { indices, newOffset in
////                            payModel.paymentMethods.move(fromOffsets: indices, toOffset: newOffset)
////                            Task {
////                                let listOrderUpdates = await payModel.setListOrders(calModel: calModel)
////                                let _ = await funcModel.submitListOrders(items: listOrderUpdates, for: .paymentMethods)
////                            }
////                        }
////                    }
////                }
////            }
//        }
//        .listStyle(.plain)
//    }
//    
//    func methodsBinding(for section: PaymentMethodSection) -> Binding<[CBPaymentMethod]> {
//        Binding(
//            get: {
//                payModel.getMethodsFor(section: section, type: .all, sText: searchText, includeHidden: true)
//                //payModel.paymentMethods
////                    .filter { $0.sectionType == section }
////                    .sorted { $0.listOrder ?? 0 < $1.listOrder ?? 0 }
//            },
//            set: { newValue in
//                for (index, method) in newValue.enumerated() {
//                    if let globalIndex = payModel.paymentMethods.firstIndex(where: { $0.id == method.id }) {
//                        payModel.paymentMethods[globalIndex].listOrder = index
//                    }
//                }
//            }
//        )
//    }
//    
//    
//    /// On iPad, bind the list to a selection property, which will get caught in an onChange and open the details sheet.
//    /// For whatever reason, a button directly in the list was not opening the details sheet directly. I would have to go to another section in the app, and come back in order for it to work. Assume it's a `NavigationStack` issue.
//    @ViewBuilder
//    var padList: some View {
//        @Bindable var payModel = payModel
//        
////        List(selection: $paymentMethodEditID) {
////            ForEach($payModel.sections) { $section in
////                Section(section.kind.rawValue) {
////                    ForEach(section.payMethods) { meth in
////                        line(for: meth)
////                    }
////                    .if(AppSettings.shared.paymentMethodSortMode == .listOrder) {
////                        $0.onMove { indices, newOffset in
////                            // Move within this section only
////                            section.payMethods.move(fromOffsets: indices, toOffset: newOffset)
////                            Task {
////                                let listOrderUpdates = await payModel.setListOrders(sections: payModel.sections, calModel: calModel)
////                                let _ = await funcModel.submitListOrders(items: listOrderUpdates, for: .paymentMethods)
////                            }
////                        }
////                    }
////                }
////            }
////        }
////        .listStyle(.plain)
//    }
//    
//    
//    @ViewBuilder func line(for meth: CBPaymentMethod) -> some View {
//        if meth.isUnified {
//            Label {
//                VStack(alignment: .leading) {
//                    HStack {
//                        Text(meth.title)
//                        Spacer()
//                        
//                        if meth.isDebitOrCash {
//                            Text("\(funcModel.getPlaidDebitSums().currencyWithDecimals())")
//                            
//                        } else if meth.isCreditOrLoan {
//                            Text("\(funcModel.getPlaidCreditSums().currencyWithDecimals())")
//                        }
//                    }
//                    
//                    HStack {
//                        Text(meth.accountType.prettyValue)
//                            .foregroundStyle(.gray)
//                            .font(.caption)
//                        
//                        Spacer()
//                    }
//                    
//                }
//            } icon: {
//                //BusinessLogo(parent: meth, fallBackType: .gradient)
////                BusinessLogo(config: .init(
////                    parent: meth,
////                    fallBackType: .gradient
////                ))
//                BusinessLogo(config: .init(
//                    parent: meth,
//                    fallBackType: .gradient
//                ))
//            }
//        } else {
//            Label {
//                VStack(alignment: .leading) {
//                    HStack {
//                        Text(meth.title)
//                        if meth.isPrivate { Image(systemName: "person.slash") }
//                        if meth.isHidden { Image(systemName: "eye.slash") }
//                        if meth.notifyOnDueDate { Image(systemName: "alarm") }
//                                                
//                        Spacer()
//                        
//                        if let balance = plaidModel.balances.filter({ $0.payMethodID == meth.id }).first {
//                            Text(balance.amount.currencyWithDecimals())
//                        }
//                    }
//                    
//                    HStack {
//                        Text(meth.accountType.prettyValue)
//                            .foregroundStyle(.gray)
//                            .font(.caption)
//                        Spacer()
//                        
//                        if let balance = plaidModel.balances.filter({ $0.payMethodID == meth.id }).first {
//                            Text(Date().timeSince(balance.enteredDate))
//                                .foregroundStyle(.gray)
//                                .font(.caption)
//                        }
//                    }
//                }
//            } icon: {
//                BusinessLogo(config: .init(
//                    parent: meth,
//                    fallBackType: .color
//                ))
//                //BusinessLogo(parent: meth, fallBackType: .color)
//            }
//        }
//    }
//    
//   
//    var newAccountButton: some View {
//        Button {
//            let newId = UUID().uuidString
//            
//            /// On iPhone, push the details page to the nav, which will auto-open the edit sheet.
//            if AppState.shared.isIphone {
//                //let newMeth = CBPaymentMethod(uuid: newId)
//                //let newMeth = payModel.getPaymentMethod(by: newId)
//                navPath.append(CBPaymentMethod(uuid: newId))
//            } else {
//                /// On iPad, trigger the details sheet to open, which will then open the edit sheet.
//                //#error("On Ipad, when closing the edit sheet, the details sheet freaks out.")
//                paymentMethodEditID = newId
//            }
//        } label: {
//            Image(systemName: "plus")
//        }
//        .tint(.none)
//        
//    }
//
//    #endif
//    
//    var useBusinessLogosToggle: some View {
//        Toggle(isOn: $useBusinessLogos) {
//            Text("Use Business Logos")
//        }
//    }
//    
//    
//    
//    var moreMenu: some View {
//        Menu {
//            Section("Default Viewing Account") {
//                showDefaultForViewingSheetButton
//            }
//            
//            Section("Default Editing Account") {
//                showDefaultForEditingSheetButton
//            }
//            
//            Section("Appearance") {
//                useBusinessLogosToggle
//            }
//            
////            Section("View") {
////                Button("Card") {
////                    selectedView = "card"
////                }
////                Button("List") {
////                    selectedView = "list"
////                }
////            }
//            
//        } label: {
//            Label("More", systemImage: "ellipsis")            
//        }
//        .tint(.none)
//    }
//    
//    
//    var showDefaultForViewingSheetButton: some View {
//        Button {
//            showDefaultViewingSheet = true
//        } label: {
//            let defaultMeth = payModel.paymentMethods.filter { $0.isViewingDefault }.first
//            Label {
//                Text(defaultMeth?.title ?? "[Select]")
//            } icon: {
//                Image(systemName: "circle.fill")
//                    .tint(defaultMeth?.color ?? .primary)
//            }
//        }
//    }
//    
//    
//    var showDefaultForEditingSheetButton: some View {
//        Button {
//            showDefaultEditingSheet = true
//        } label: {
//            let defaultMeth = payModel.paymentMethods.filter { $0.isEditingDefault }.first
//            Label {
//                Text(defaultMeth?.title ?? "[Select]")
//            } icon: {
//                Image(systemName: "circle.fill")
//                    .tint(defaultMeth?.color ?? .primary)
//            }
//        }
//    }
//    
//    
//    struct SetDefaultButtonPhone: View {
//        @Environment(PayMethodModel.self) private var payModel
//        var meth: CBPaymentMethod
//        
//        var body: some View {
//            Button {
//                meth.isViewingDefault.toggle()
//                if meth.isViewingDefault {
//                    Task { await payModel.setDefaultViewing(meth) }
//                }
//            } label: {
//                Label {
//                    Text("Set Default")
//                } icon: {
//                    Image(systemName: meth.isViewingDefault ? "checkmark.circle" : "circle")
//                }
//            }
//            .tint(meth.isViewingDefault ? Color.accentColor : .gray)
//        }
//    }
//    
//    
//    func setDefaultViewingMethod() {
//        print("-- \(#function)")
//        Task { await payModel.setDefaultViewing(defaultViewingMethod) }
//    }
//    
//    
//    func setDefaultEditingMethod() {
//        print("-- \(#function)")
//        Task { await payModel.setDefaultEditing(defaultEditingMethod) }
//    }
//}
//
//
