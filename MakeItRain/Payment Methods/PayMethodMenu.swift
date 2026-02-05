//
//  PayMethodMenu.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/18/24.
//

import SwiftUI

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
    let theSections: [PaymentMethodSection] = [.debit, .credit, .other]
    
    
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
        
    
    @ViewBuilder
    var menuItems: some View {
        ForEach(theSections) { section in
            Section(section.rawValue) {
                ForEach(payModel.getMethodsFor(section: section, type: .all)) { meth in
                    Button {
                        payMethod = meth
                        if calcAndSaveOnChange && trans != nil {
                            Task {
                                await calModel.saveTransaction(id: trans!.id)
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: payMethod?.id == meth.id ? "checkmark" : "circle.fill")
                                .tint(meth.isUnified ? (colorScheme == .dark ? .white : .black) : meth.color)
                                //.foregroundStyle(meth.isUnified ? (colorScheme == .dark ? .white : .black) : meth.color, .primary, .secondary)
                            Text(meth.title)
                        }
                    }
                }
            }
        }
    }
}
