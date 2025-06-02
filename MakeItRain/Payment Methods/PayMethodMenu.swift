//
//  PayMethodMenu.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/18/24.
//

import SwiftUI

enum PaymentMethodSection: String {
    case combined = "Combined"
    case debit = "Debit"
    case credit = "Credit"
    case other = "Other"
}

enum ApplicablePaymentMethods {
    case all, allExceptUnified, basedOnSelected, remainingAvailbleForPlaid
}

struct PaySection: Identifiable {
    let id = UUID()
    let kind: PaymentMethodSection
    let payMethods: [CBPaymentMethod]
}


struct PayMethodMenu<Content: View>: View {
    @Environment(\.colorScheme) var colorScheme
    
    @Environment(CalendarModel.self) private var calModel
    
    @Environment(PayMethodModel.self) private var payModel
    #if os(iOS)
    @Environment(PlaidModel.self) private var plaidModel
    #endif
    
    
    @Binding var payMethod: CBPaymentMethod?
    var trans: CBTransaction?
    let calcAndSaveOnChange: Bool
    let whichPaymentMethods: ApplicablePaymentMethods
    let menuItemOnly: Bool
    @ViewBuilder let content: Content
    
    
    init(payMethod: Binding<CBPaymentMethod?>, whichPaymentMethods: ApplicablePaymentMethods, menuItemsOnly: Bool = false, @ViewBuilder content: () -> Content) {
        self._payMethod = payMethod
        self.trans = nil
        self.calcAndSaveOnChange = false
        self.whichPaymentMethods = whichPaymentMethods
        self.content = content()
        self.menuItemOnly = menuItemsOnly
    }
    
    
    init(payMethod: Binding<CBPaymentMethod?>, trans: CBTransaction?, calcAndSaveOnChange: Bool, whichPaymentMethods: ApplicablePaymentMethods, menuItemsOnly: Bool = false, @ViewBuilder content: () -> Content) {
        self._payMethod = payMethod
        self.trans = trans
        self.calcAndSaveOnChange = calcAndSaveOnChange
        self.whichPaymentMethods = whichPaymentMethods
        self.content = content()
        self.menuItemOnly = menuItemsOnly
    }
    
    
    
    
    var body: some View {
        if menuItemOnly {
            menuItems
        } else {
            Menu {
                menuItems
            } label: {
                content
                .foregroundStyle((payMethod?.title ?? "").isEmpty ? .gray : .primary)
            }
        }
        
    }
    
    
    var menuItems: some View {
        ForEach(getApplicablePayMethods(type: whichPaymentMethods)) { section in
            if !section.payMethods.isEmpty {
                Section(section.kind.rawValue) {
                    ForEach(section.payMethods.sorted { $0.title.lowercased() < $1.title.lowercased() }) { meth in
                        Button {
                            payMethod = meth
                            if calcAndSaveOnChange && trans != nil {
                                //trans!.updatedBy = AppState.shared.user!
                                //let _ = calModel.calculateTotal(for: calModel.sMonth)
                                //Task { await calModel.submit(trans!) }
                                calModel.saveTransaction(id: trans!.id)
                            }
                        } label: {
                            HStack {
                                
                                //Image(meth.accountType == .checking ? "boa" : "boa")
                                    //.resizable()
                                    //.frame(maxWidth: 30, maxHeight: 30)
                                
                                Image(systemName: payMethod?.id == meth.id ? "checkmark" : "circle.fill")
                                    .foregroundStyle(meth.isUnified ? (colorScheme == .dark ? .white : .black) : meth.color, .primary, .secondary)
                                Text(meth.title)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func getApplicablePayMethods(type: ApplicablePaymentMethods) -> Array<PaySection> {
        
        switch type {
        case .all:
            return [
                PaySection(kind: .combined, payMethods: payModel.paymentMethods.filter { $0.accountType == .unifiedCredit || $0.accountType == .unifiedChecking }),
                PaySection(kind: .debit, payMethods: payModel.paymentMethods.filter { $0.accountType == .checking }),
                PaySection(kind: .credit, payMethods: payModel.paymentMethods.filter { $0.accountType == .credit }),
                PaySection(kind: .other, payMethods: payModel.paymentMethods.filter { ![.unifiedCredit, .unifiedChecking, .credit, .checking].contains($0.accountType) })
            ]
            
        case .allExceptUnified:
            return [
                PaySection(kind: .debit, payMethods: payModel.paymentMethods.filter { $0.accountType == .checking }),
                PaySection(kind: .credit, payMethods: payModel.paymentMethods.filter { $0.accountType == .credit }),
                PaySection(kind: .other, payMethods: payModel.paymentMethods.filter { ![.unifiedCredit, .unifiedChecking, .credit, .checking].contains($0.accountType) })
            ]
            
        case .basedOnSelected:
            if calModel.sPayMethod?.accountType == .unifiedChecking {
                return [PaySection(kind: .debit, payMethods: payModel.paymentMethods.filter { $0.accountType == .checking })]
    
            } else if calModel.sPayMethod?.accountType == .unifiedCredit {
                return [PaySection(kind: .credit, payMethods: payModel.paymentMethods.filter { $0.accountType == .credit })]
    
            } else {
                return [PaySection(kind: .other, payMethods: payModel.paymentMethods.filter { ![.unifiedCredit, .unifiedChecking, .credit, .checking].contains($0.accountType) })]
            }
            
        case .remainingAvailbleForPlaid:
            #if os(iOS)
            let taken: Array<String> = plaidModel.banks.flatMap ({ $0.accounts.compactMap({ $0.paymentMethodID }) })
            return [
                PaySection(kind: .debit, payMethods: payModel.paymentMethods.filter { $0.accountType == .checking && !taken.contains($0.id) }),
                PaySection(kind: .credit, payMethods: payModel.paymentMethods.filter { $0.accountType == .credit && !taken.contains($0.id) }),
                PaySection(kind: .other, payMethods: payModel.paymentMethods.filter { ![.unifiedCredit, .unifiedChecking, .credit, .checking].contains($0.accountType) && !taken.contains($0.id)  })
            ]
            #else
            return []
            #endif
            
        }
    }
}
