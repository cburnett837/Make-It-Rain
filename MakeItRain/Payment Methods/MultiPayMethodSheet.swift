//
//  MultiPayMethodSheet.swift
//  MakeItRain
//
//  Created by Cody Burnett on 1/7/25.
//

import SwiftUI

struct MultiPayMethodSheet: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @Environment(CalendarModel.self) private var calModel
    @Environment(PayMethodModel.self) private var payModel
    @Environment(PlaidModel.self) private var plaidModel
    @Local(\.useBusinessLogos) var useBusinessLogos

    @Binding var payMethods: Array<CBPaymentMethod>
    
    var includeHidden: Bool = false
    
    @FocusState private var focusedField: Int?
    @State private var searchText = ""
    let theSections: [PaymentMethodSection] = [.debit, .credit, .other]
    
    
    var body: some View {
        NavigationStack {
            StandardContainerWithToolbar(.list) {
                content
            }
            .navigationTitle("Accounts")
            #if os(iOS)
            .searchable(text: $searchText, prompt: "Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { selectButton }
                
                ToolbarItem(placement: .bottomBar) { PayMethodFilterMenu() }
                ToolbarSpacer(.flexible, placement: AppState.shared.isIpad ? .topBarLeading : .bottomBar)
                DefaultToolbarItem(kind: .search, placement: .bottomBar)
                
                ToolbarSpacer(.flexible, placement: AppState.shared.isIpad ? .topBarLeading : .bottomBar)
                ToolbarItem(placement: AppState.shared.isIpad ? .topBarTrailing : .bottomBar) { PayMethodSortMenu() }
                
                if AppState.shared.isIpad {
                    ToolbarSpacer(.fixed, placement: .topBarTrailing)
                }
                
                ToolbarItem(placement: .topBarTrailing) { closeButton }
            }
            #endif
        }
    }
    
    
    @ViewBuilder
    var content: some View {
        ForEach(payModel.sections) { section in
            Section(section.rawValue) {
                ForEach(payModel.getMethodsFor(
                    section: section,
                    
                    type: .allExceptUnified,
                    sText: searchText
                )) { meth in
                    methLine(meth)
                        .onTapGesture {
                            selectPaymentMethod(meth)
                        }
                }
            }
        }
    }
    
    @ViewBuilder func methLine(_ meth: CBPaymentMethod) -> some View {
        HStack {
            Label {
                VStack(alignment: .leading) {
                    Text(meth.title)
                }
            } icon: {
                //methColorCircle(meth)
                //BusinessLogo(parent: meth, fallBackType: .color)
                BusinessLogo(config: .init(
                    parent: meth,
                    fallBackType: .color
                ))
            }
                                            
            Spacer()
            
                                 
            if payMethods.contains(meth) {
                Image(systemName: "checkmark")
            }
        }
        .contentShape(Rectangle())
    }
    
    
    
    var useBusinessLogosToggle: some View {
        Toggle(isOn: $useBusinessLogos) {
            Text("Use Business Logos")
        }
    }
    
    
    var moreMenu: some View {
        Menu {
            useBusinessLogosToggle
        } label: {
            Image(systemName: "ellipsis")
                .schemeBasedForegroundStyle()
        }
    }
    
    var selectButton: some View {
        Button {
            withAnimation {
                payMethods = payMethods.isEmpty ? payModel.paymentMethods : []
            }
        } label: {
            Text(payMethods.isEmpty ? "Select All" : "Deselect All")
            //Image(systemName: payMethods.isEmpty ? "checklist.checked" : "checklist.unchecked")
                .schemeBasedForegroundStyle()
        }
    }
    
    
    var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .schemeBasedForegroundStyle()
        }
    }
    
    
    func selectPaymentMethod(_ payMethod: CBPaymentMethod) {
        if payMethods.contains(payMethod) {
            payMethods.removeAll(where: { $0.id == payMethod.id })
        } else {
            payMethods.append(payMethod)
        }
    }
}
