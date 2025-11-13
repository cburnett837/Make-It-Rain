//
//  TransactionEditSheetAndLogic.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/4/25.
//


import Foundation
import SwiftUI

extension View {
    func transactionEditSheetAndLogic(
        transEditID: Binding<String?>,
        selectedDay: Binding<CBDay?>,
        overviewDay: Binding<CBDay?> = .constant(nil),
        findTransactionWhere: Binding<WhereToLookForTransaction> = .constant(.normalList),
        presentTip: Bool = false,
        resetSelectedDayOnClose: Bool = false
    ) -> some View {
        modifier(TransactionEditSheetAndLogic(
            transEditID: transEditID,
            selectedDay: selectedDay,
            overviewDay: overviewDay,
            findTransactionWhere: findTransactionWhere,
            presentTip: presentTip,
            resetSelectedDayOnClose: resetSelectedDayOnClose
        ))
    }
}

struct TransactionEditSheetAndLogic: ViewModifier {    
    @Environment(CalendarModel.self) private var calModel
    
    @Binding var transEditID: String?
    @Binding var selectedDay: CBDay?
    @Binding var overviewDay: CBDay?
    @Binding var findTransactionWhere: WhereToLookForTransaction
    var presentTip: Bool
    var resetSelectedDayOnClose: Bool
    
    @State var editTrans: CBTransaction?
        
    func body(content: Content) -> some View {
        return content
            .onChange(of: transEditID) { transEditIdChanged(oldValue: $0, newValue: $1) }
            .sensoryFeedback(.selection, trigger: transEditID) { $1 != nil }
            .sheet(item: $editTrans) { trans in
                TransactionEditView(
                    trans: trans,
                    transEditID: $transEditID,
                    day: selectedDay!,
                    isTemp: false,
                    transLocation: findTransactionWhere
                )
                //#warning("produces a race condition when swiping to close and opening another trans too quickly. Causes transDays to be nil and crashes the app.")
                /// needed to prevent the view from being incorrect.
                .id(trans.id)
                /// This is needed for the drag to dismiss.
                .onDisappear {
                    transEditID = nil
                }
            }
        }
    

    func transEditIdChanged(oldValue: String?, newValue: String?) {
        /// When `newValue` is nil, save to the server via the `oldValue`.
        /// We have to use this technique because on Mac, `.popover(isPresented:)` has no onDismiss option.
        /// In addition, even if I wanted to use a sheets onDismiss, I can't catch the transaction ID there.
        if oldValue != nil && newValue == nil {
            transactionSheetWasClosed(transId: oldValue!)
        } else if newValue != nil {
            transactionSheetWasOpened(transId: newValue!)
        }
    }
    
    func transactionSheetWasOpened(transId: String) {
        if !calModel.editLock {
            /// Prevent a transaction from being opened while another one is trying to save.
            calModel.editLock = true
            editTrans = calModel.getTransaction(by: transId, from: findTransactionWhere)
        }
    }
    
    func transactionSheetWasClosed(transId: String) {
        #if os(iOS)
        if presentTip {
            /// Present tip after trying to add 3 new transactions.
            let trans = calModel.getTransaction(by: transId, from: findTransactionWhere)
            if trans.action == .add {
                TouchAndHoldPlusButtonTip.didTouchPlusButton.sendDonation()
            }
        }
        #endif
                            
        calModel.saveTransaction(
            id: transId,
            //day: selectedDay!,
            location: findTransactionWhere
        )
        /// - When adding a transaction via a day's context menu, `selectedDay` gets changed to the contexts day.
        ///   So when closing the transaction, put `selectedDay`back to today so the normal plus button works and the gray box goes back to today.
        /// - Gotta have a `selectedDay` for the editing of a transaction and transfer sheet.
        ///   Since one is not always used in details view, set to the current day if in the current month, otherwise set to the first of the month.
        /// - If you're viewing the bottom panel, reset `selectedDay` to `overviewDay` so any transactions that are added via the bottom panel have the date of the bottom panel.

        if resetSelectedDayOnClose {
            if overviewDay != nil {
                selectedDay = overviewDay
            } else {
                let targetDay = calModel.sMonth.days.filter { $0.dateComponents?.day == (calModel.sMonth.num == AppState.shared.todayMonth ? AppState.shared.todayDay : 1) }.first
                selectedDay = targetDay
            }
        }

        /// Keep the model clean, and show alert for a photo that may be taking a long time to upload.
        FileModel.shared.fileParent = nil

        /// Force this to `.normalList` since smart transactions will change the variable to look in the temp list.
        findTransactionWhere = .normalList

        /// When true, prevents a transaction from being opened while another one is trying to save.
        /// So unlock and allow further transactions to be edited.
        calModel.editLock = false
    }
}




struct TransactionEditSheetAndLogicTry2: ViewModifier {
    @Bindable var calModel: CalendarModel
    @Binding var transEditID: String?
    @Binding var editTrans: CBTransaction?
    @Binding var selectedDay: CBDay?
    @Binding var overviewDay: CBDay?
    @Binding var findTransactionWhere: WhereToLookForTransaction
    var presentTip: Bool
    var resetSelectedDayOnClose: Bool
    
    //let newTransactionMenuButtonNamespace: Namespace.ID?

    var editTranz: CBTransaction? {
        guard let id = transEditID else { return nil }
        return calModel.getTransaction(by: id)
    }

    func body(content: Content) -> some View {
        return content
            .sensoryFeedback(.selection, trigger: transEditID) { $1 != nil }
            .sheet(item: Binding(
                get: { editTranz },
                set: { _ in transEditID = nil }
            )) { trans in
                let id = trans.id
                TransactionEditView(
                    trans: trans,
                    transEditID: $transEditID,
                    day: selectedDay!,
                    isTemp: false,
                    transLocation: findTransactionWhere
                )
                .id(trans.id)
                .onDisappear {
                    DispatchQueue.main.async {
                        transactionSheetWasClosed(transId: id)
                    }
                }
            }
        }
    

//    func transEditIdChanged(oldValue: String?, newValue: String?) {
//        print(".onChange(of: transEditID) - old: \(String(describing: oldValue)) -- new: \(String(describing: newValue))")
//        /// When `newValue` is false, save to the server. We have to use this because `.popover(isPresented:)` has no onDismiss option, and also because I can;t catch the transaction ID in the on dismiss closure of the sheet..
//        if oldValue != nil && newValue == nil {
//            transactionSheetWasClosed(transId: oldValue!)
//        } else if newValue != nil {
//            transactionSheetWasOpened(transId: newValue!)
//        }
//    }
    
    func transactionSheetWasOpened(transId: String) {
        if !calModel.editLock {
            /// Prevent a transaction from being opened while another one is trying to save.
            calModel.editLock = true
            editTrans = calModel.getTransaction(by: transId, from: findTransactionWhere)
        }
    }
    
    func transactionSheetWasClosed(transId: String) {
        #if os(iOS)
        if presentTip {
            /// Present tip after trying to add 3 new transactions.
            let trans = calModel.getTransaction(by: transId, from: findTransactionWhere)
            if trans.action == .add {
                TouchAndHoldPlusButtonTip.didTouchPlusButton.sendDonation()
            }
        }
        #endif
                            
        calModel.saveTransaction(
            id: transId,
            //day: selectedDay!,
            location: findTransactionWhere
        )
        /// - When adding a transaction via a day's context menu, `selectedDay` gets changed to the contexts day.
        ///   So when closing the transaction, put `selectedDay`back to today so the normal plus button works and the gray box goes back to today.
        /// - Gotta have a `selectedDay` for the editing of a transaction and transfer sheet.
        ///   Since one is not always used in details view, set to the current day if in the current month, otherwise set to the first of the month.
        /// - If you're viewing the bottom panel, reset `selectedDay` to `overviewDay` so any transactions that are added via the bottom panel have the date of the bottom panel.

        if resetSelectedDayOnClose {
            if overviewDay != nil {
                selectedDay = overviewDay
            } else {
                let targetDay = calModel.sMonth.days.filter { $0.dateComponents?.day == (calModel.sMonth.num == AppState.shared.todayMonth ? AppState.shared.todayDay : 1) }.first
                selectedDay = targetDay
            }
        }

        /// Keep the model clean, and show alert for a photo that may be taking a long time to upload.
        //calModel.pictureTransactionID = nil
        FileModel.shared.fileParent = nil

        /// Force this to `.normalList` since smart transactions will change the variable to look in the temp list.
        findTransactionWhere = .normalList

        /// Prevent a transaction from being opened while another one is trying to save.
        calModel.editLock = false
    }
}





//
//
//struct TransactionEditSheetAndLogicForDemo: ViewModifier {
//    @Bindable var calModel: CalendarModel
//    @Binding var transEditID: String?
//    @Binding var editTrans: CBTransaction?
//    
//    func body(content: Content) -> some View {
//        return content
//            .onChange(of: transEditID) { transEditIdChanged(oldValue: $0, newValue: $1) }
//            .sheet(item: $editTrans) { trans in
//                TransactionEditView(
//                    trans: trans,
//                    transEditID: $transEditID
//                )
//                /// needed to prevent the view from being incorrect.
//                .id(trans.id)
//                /// This is needed for the drag to dismiss.
//                .onDisappear {
//                    transEditID = nil
//                }
//            }
//        }
//    
//    func transEditIdChanged(oldValue: String?, newValue: String?) {
//        if oldValue != nil && newValue == nil {
//            transactionSheetWasClosed(transId: oldValue!)
//        } else if newValue != nil {
//            transactionSheetWasOpened(transId: newValue!)
//        }
//    }
//    
//    func transactionSheetWasOpened(transId: String) {
//        editTrans = calModel.getTransaction(by: transId)
//    }
//    
//    func transactionSheetWasClosed(transId: String) {
//        calModel.saveTransaction(id: transId)
//    }
//}
