//
//  PayMethodOptionMenu.swift
//  MakeItRain
//
//  Created by Cody Burnett on 8/31/26.
//

import SwiftUI

enum HidablePayMethodOptionMenuOptions {
    case reorder, defaultViewing, defaultEditing
}

struct PayMethodsTableOptionMenu: View {
    @Local(\.useBusinessLogos) var useBusinessLogos
    @Environment(PayMethodModel.self) private var payModel
    
    let actions: [HidablePayMethodOptionMenuOptions]
    init(hide actions: HidablePayMethodOptionMenuOptions...) {
        self.actions = actions
    }
    
    @State private var defaultViewingMethod: CBPaymentMethod?
    @State private var defaultEditingMethod: CBPaymentMethod?
    @State private var showDefaultViewingSheet = false
    @State private var showDefaultEditingSheet = false
    @State private var showReorderSheet = false
    
    var body: some View {
        Menu {
            PayMethodFilterMenu()
            PayMethodSortMenu()
            
            if !actions.contains(.reorder) {
                showReorderSheetButton
            }
            
            
            if !actions.contains(.defaultViewing) {
                Section("Default Viewing Account") {
                    showDefaultForViewingSheetButton
                }
            }
            
            if !actions.contains(.defaultEditing) {
                Section("Default Editing Account") {
                    showDefaultForEditingSheetButton
                }
            }
            
            Section("Appearance") {
                useBusinessLogosToggle
            }
            
        } label: {
            Image(systemName: "ellipsis")
                .schemeBasedForegroundStyle()
        }
        .sheet(isPresented: $showReorderSheet) {
            PayMethodsTableReorderList()
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
    }
    
    var useBusinessLogosToggle: some View {
        Toggle(isOn: $useBusinessLogos) {
            Text("Use Business Logos")
        }
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
    
    func setDefaultViewingMethod() {
        print("-- \(#function)")
        Task { await payModel.setDefaultViewing(defaultViewingMethod) }
    }
    
    
    func setDefaultEditingMethod() {
        print("-- \(#function)")
        Task { await payModel.setDefaultEditing(defaultEditingMethod) }
    }
}
