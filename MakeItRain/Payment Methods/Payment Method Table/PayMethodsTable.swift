//
//  PaymentMethodsView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/20/24.
//

import SwiftUI
import LocalAuthentication


var CARD_HEIGHT: CGFloat = 250


struct PayMethodsTable: View {
    @Local(\.useBusinessLogos) var useBusinessLogos
    @AppStorage("paymentMethodTableColumnOrder") private var columnCustomization: TableColumnCustomization<CBPaymentMethod>
    @Environment(\.colorScheme) var colorScheme

    //@Environment(\.dismiss) var dismiss
    @Environment(FuncModel.self) var funcModel
    @Environment(CalendarModel.self) private var calModel
    @Environment(PayMethodModel.self) private var payModel
    @Environment(PlaidModel.self) private var plaidModel
    
    @State private var model = ViewModel()
    @State private var sortOrder = [KeyPathComparator(\CBPaymentMethod.title)]
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
//            .navigationDestination(for: CBPaymentMethod.self) { meth in
//                PayMethodOverView(payMethod: meth, navPath: $navPath)
//            }
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
        ToolbarItem(placement: .topBarTrailing) { PayMethodsTableOptionMenu() }
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
