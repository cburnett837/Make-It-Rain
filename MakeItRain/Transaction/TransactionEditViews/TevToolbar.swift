//
//  TevToolbar.swift
//  MakeItRain
//
//  Created by Cody Burnett on 12/18/25.
//

import SwiftUI

struct TevToolbar: ToolbarContent {
    @Environment(\.dismiss) var dismiss // <--- NO NICE THAT ONE WITH SHEETS IN A SHEET. BEWARE!.

    var trans: CBTransaction
    //@Binding var transEditID: String?
    var isTemp: Bool
    var showExpensiveViews: Bool
    var focusedField: FocusState<Int?>.Binding
    @Binding var shouldDismissOnMac: Bool
    
    @State private var isValidToSave = false
    @State private var showDeleteAlert = false
    
    
    var transactionValuesChanged: Int {
        var hasher = Hasher()
        hasher.combine(trans.factorInCalculations)
        hasher.combine(trans.notificationOffset)
        hasher.combine(trans.notifyOnDueDate)
        hasher.combine(trans.title)
        hasher.combine(trans.amountString)
        hasher.combine(trans.payMethod)
        hasher.combine(trans.category)
        hasher.combine(trans.date)
        hasher.combine(trans.locations)
        hasher.combine(trans.trackingNumber)
        hasher.combine(trans.orderNumber)
        hasher.combine(trans.url)
        hasher.combine(trans.tags)
        hasher.combine(trans.notes)
        hasher.combine(trans.color.hashValue)
        return hasher.finalize()
    }

    
    var body: some ToolbarContent {
        #if os(iOS)
        ToolbarItem(placement: .topBarLeading) { deleteButton }
        ToolbarSpacer(.fixed, placement: .topBarLeading)
        ToolbarItem(placement: .topBarLeading) {
            moreMenu
                .if(trans.notifyOnDueDate) {
                    $0.badge(Text(""))
                }
        }
        ToolbarItem(placement: .topBarTrailing) {
            AnimatedCloseButton(isValidToSave: isValidToSave, closeButton: closeButton)
                /// Check what color the save button should be.
                .onChange(of: transactionValuesChanged) { checkIfTransactionIsValidToSave() }
        }
        
        
        if showExpensiveViews {
            ToolbarItem(placement: .bottomBar) {
                NavigationLink(value: TransNavDestination.logs) {
                    EnteredByAndUpdatedByView(
                        enteredBy: trans.enteredBy,
                        updatedBy: trans.updatedBy,
                        enteredDate: trans.enteredDate,
                        updatedDate: trans.updatedDate
                    )
                }
            }
            //.sharedBackgroundVisibility(.hidden)
        }
        #else
        ToolbarItemGroup(placement: .destructiveAction) {
            HStack {
                NavigationLink(value: TransNavDestination.logs) {
                    EnteredByAndUpdatedByView(
                        enteredBy: trans.enteredBy,
                        updatedBy: trans.updatedBy,
                        enteredDate: trans.enteredDate,
                        updatedDate: trans.updatedDate
                    )
                }
                .buttonStyle(.roundMacButton(horizontalPadding: 5))
            }
        }
        
        ToolbarItemGroup(placement: .confirmationAction) {
            HStack {
                
                deleteButton
                moreMenu
                
                AnimatedCloseButton(isValidToSave: isValidToSave, closeButton: closeButton)
                    /// Check what color the save button should be.
                    .onChange(of: transactionValuesChanged) { checkIfTransactionIsValidToSave() }
            }
        }
                
        #endif
    }
    
    
    var closeButton: some View {
        Button {
            if !isValidToSave {
                trans.status = nil
            }
            validateBeforeClosing()
        } label: {
            Image(systemName: isValidToSave ? "checkmark" : "xmark")
                .schemeBasedForegroundStyle()
        }
    }
    
        
    var moreMenu: some View {
        NavigationLink(value: TransNavDestination.options) {
            Image(systemName: "ellipsis")
                .schemeBasedForegroundStyle()
        }
        #if os(macOS)
        .buttonStyle(.roundMacButton)
        #endif
    }
        
    
    var deleteButton: some View {
        Button {
            showDeleteAlert = true
        } label: {
            Image(systemName: "trash")
                #if os(macOS)
                    .foregroundStyle(.red)
                #endif
        }
        #if os(macOS)
        .buttonStyle(.roundMacButton)
        #endif
        .sensoryFeedback(.warning, trigger: showDeleteAlert) { !$0 && $1 }
        .tint(.none)
        .confirmationDialog("Delete \"\(trans.title)\"?", isPresented: $showDeleteAlert) {
            /// There's a bug in dismiss() that causes the photo sheet to open, close, and then open again.
            /// By moving the dismiss variable into a seperate view, it doesn't affect the photo sheet anymore.
            DeleteYesButton(
                trans: trans,
                //transEditID: $transEditID,
                shouldDismissOnMac: $shouldDismissOnMac,
                isTemp: isTemp,
                christmasListDeletePeference: .delete
            )
            
            if trans.christmasListGiftID != nil {
                DeleteYesButton(
                    trans: trans,
                    //transEditID: $transEditID,
                    shouldDismissOnMac: $shouldDismissOnMac,
                    isTemp: isTemp,
                    christmasListDeletePeference: .resetStatusToIdea
                )
            }
            
//            #if os(iOS)
//            Button("No", role: .close) {
//                showDeleteAlert = false
//            }
//            #else
//            Button("No") {
//                showDeleteAlert = false
//            }
//            #endif
        } message: {
            #if os(iOS)
            Text("Delete \"\(trans.title)\"?")
            #endif
        }
    }
    
    
    // MARK: - Functions
    func checkIfTransactionIsValidToSave() {
        if trans.title.isEmpty {
            isValidToSave = false; return
        }
        if trans.payMethod == nil {
            isValidToSave = false; return
        }
        if trans.date == nil && (trans.isSmartTransaction ?? false) {
            isValidToSave = false; return
        }
        if !trans.hasChanges(shouldLog: false) {
            //print("Transaction does not have changes")
            isValidToSave = false; return
        } else {
            //print("Transaction does! have changes")
            isValidToSave = true; return
        }
    }
    
    
    func validateBeforeClosing() {
        if !trans.title.isEmpty && !trans.amountString.isEmpty && trans.payMethod == nil {
            
            if trans.payMethod == nil && (trans.isSmartTransaction ?? false) {
                focusedField.wrappedValue = nil
                //transEditID = nil
                dismiss()
            } else {
                let config = AlertConfig(
                    title: "Missing Payment Method",
                    subtitle: "Please assign an account or delete this transaction.",
                    symbol: .init(name: "creditcard.trianglebadge.exclamationmark.fill", color: .orange)
                )
                AppState.shared.showAlert(config: config)
            }
            
        } else {
            focusedField.wrappedValue = nil
            //transEditID = nil
            #if os(iOS)
            dismiss()
            #else
            shouldDismissOnMac = true
            #endif
        }
    }
    
    
    struct DeleteYesButton: View {
        @Environment(CalendarModel.self) private var calModel
    
        @Environment(\.dismiss) var dismiss
        @Bindable var trans: CBTransaction
        @Binding var shouldDismissOnMac: Bool
        //@Binding var transEditID: String?
        var isTemp: Bool
        var christmasListDeletePeference: ChristmasListDeletePreference
        
        
        var deleteLingo: String {
            if trans.christmasListGiftID == nil {
                "Delete"
            } else {
                switch christmasListDeletePeference {
                case .delete:
                    "Delete transaction & gift"
                case .resetStatusToIdea:
                    "Delete & set gift as idea"
                }
            }
        }
        
        var body: some View {
            Button(deleteLingo, role: .destructive, action: delete)
        }
        
        func delete() {
            if isTemp {
                #if os(iOS)
                dismiss()
                #else
                shouldDismissOnMac = true
                #endif
                calModel.tempTransactions.removeAll { $0.id == trans.id }
                //let _ = DataManager.shared.delete(type: TempTransaction.self, predicate: .byId(.string(trans.id)))
                
                Task {
                    let context = DataManager.shared.createContext()
                    context.perform {
                        if let entity = DataManager.shared.getOne(context: context, type: TempTransaction.self, predicate: .byId(.string(trans.id)), createIfNotFound: true) {
                            entity.action = TransactionAction.delete.rawValue
                            entity.tempAction = TransactionAction.delete.rawValue
                            let _ = DataManager.shared.save(context: context)
                        }
                    }
                }
                
            } else {
                //transEditID = nil
                trans.christmasListDeletePreference = christmasListDeletePeference
                trans.action = .delete
                #if os(iOS)
                dismiss()
                #else
                shouldDismissOnMac = true
                #endif
                
                //calModel.saveTransaction(id: trans.id, day: day)
            }
        }
    }
}
