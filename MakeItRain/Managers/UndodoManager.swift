//
//  UndoooManager.swift
//  MakeItRain
//
//  Created by Cody Burnett on 2/11/25.
//

import Foundation
import SwiftUI

enum TransactionUndoField: String {
    case title = "Title",
         amount = "Amount",
         payMethod = "Account",
         category = "Category",
         date = "Date",
         trackingNumber = "Tracking Number",
         orderNumber = "Order Number",
         url = "URL",
         notes = "Notes"
}

enum UndoRedo {
    case undo, redo
}
//
//struct UndoTask {
//    var field: TransactionUndoField
//    var task: Task<Void, Error>?
//}

struct UndoTransactionSnapshot: Equatable {
    var title: String?
    var amount: String?
    var payMethodID: String?
    var categoryID: String?
    var date: String?
    var trackingNumber: String?
    var orderNumber: String?
    var url: String?
    var notes: AttributedString?
    
    init(title: String?, amount: String?, payMethodID: String?, categoryID: String?, date: String?, trackingNumber: String?, orderNumber: String?, url: String?, notes: AttributedString?) {
        self.title = title
        self.amount = amount
        self.payMethodID = payMethodID
        self.categoryID = categoryID
        self.date = date
        self.trackingNumber = trackingNumber
        self.orderNumber = orderNumber
        self.url = url
        self.notes = notes
    }
}

@Observable
class UndodoManager {
    static let shared = UndodoManager()
        
    var showAlert = false
    var returnMe: UndoTransactionSnapshot?
    
    var undoPosition: Int = 0
    var history: [UndoTransactionSnapshot] = []
    var maxIndex: Int { history.count - 1 }

    var changeTask: Task<Void, Error>?
    
    var canUndo: Bool = false
    var canRedo: Bool = false
    
    func getChangeFields(trans: CBTransaction) {
        let simUndoPosition = undoPosition - 1
        if simUndoPosition == -1 {
            canUndo = false
            
        } else if simUndoPosition == 0 {
            canUndo = true
            
            /// Block the first focus on a textfield from being able to undo.
            if let firstHist = history.first {
                if trans.title == firstHist.title
                && trans.amountString == firstHist.amount
                && trans.payMethod?.id == firstHist.payMethodID
                && trans.category?.id == firstHist.categoryID
                && trans.date?.string(to: .serverDate) == firstHist.date
                && trans.trackingNumber == firstHist.trackingNumber
                && trans.orderNumber == firstHist.orderNumber
                && trans.url == firstHist.url
                && trans.notes == firstHist.notes {
                    canUndo = false
                }
            }
        } else if simUndoPosition > 0 {
            canUndo = true
        }
                
        /// Simulate redo to get field that will be redone if the user takes action.
        let simRedoPosition = undoPosition + 1
        if simRedoPosition > maxIndex {
            canRedo = false
            
        } else if simRedoPosition == maxIndex {
            canRedo = true
            
        } else if simRedoPosition < maxIndex {
            canRedo = true
        }
        
        //print("undoPotentialNext \(simUndoPosition) - \(canUndo) --- redoPotentialNext \(simRedoPosition) - \(canRedo)")
    }
    
    func processChange(trans: CBTransaction) {
        //print("-- \(#function)")
        /// Block the onChanges from running when undo or redo is invoked.
        if returnMe == nil {
            let task = Task {
                do {
                    try await Task.sleep(for: .seconds(1))
                    await MainActor.run {
                        self.commitChange(trans: trans)
                    }
                }
            }
            
            changeTask?.cancel()
            changeTask = task
        }
    }
    
    
    func commitChangeInTask(trans: CBTransaction) {
        Task {
            do {
                try await Task.sleep(for: .seconds(1))
                await MainActor.run {
                    self.commitChange(trans: trans)
                }
            }
        }
    }
    
    
    func commitChange(trans: CBTransaction) {
        let change = UndoTransactionSnapshot(
            title: trans.title,
            amount: trans.amountString,
            payMethodID: trans.payMethod?.id,
            categoryID: trans.category?.id,
            date: trans.date?.string(to: .serverDate),
            trackingNumber: trans.trackingNumber,
            orderNumber: trans.orderNumber,
            url: trans.url,
            notes: trans.notes
        )
        history.append(change)
        undoPosition += 1
        
        if maxIndex == -1 {
            undoPosition = 0
            
        } else if undoPosition < maxIndex  {
            let range = undoPosition..<maxIndex
            history.removeSubrange(range)
            
        } else {
            undoPosition = maxIndex
        }
        //print("-- \(#function) -- newUndoPositon: \(undoPosition)")
    }

    
    func undo() -> UndoTransactionSnapshot? {
        //print("-- \(#function) ❌old position \(undoPosition)")
        undoPosition -= 1
        
        if undoPosition == -1 {
            undoPosition = 0
            
        } else if undoPosition >= 0 {
            // do the check from getPosition(), but only check for matching, don't get new index
            
        } else if undoPosition > 0 {
            //let usedPosition = getPosition(for: .undo, index: undoPosition)
            //undoPosition = usedPosition
        }
        //print("-- \(#function) ✅usedPosition \(undoPosition)")
//        for each in history {
//            print(each)
//            //print("\n")
//        }
        return history[undoPosition]
        
    }

    
    func redo() -> UndoTransactionSnapshot?  {
        //print("-- \(#function) ❌old position \(undoPosition)")
        undoPosition += 1
        
        if undoPosition > maxIndex {
            undoPosition = maxIndex
            
        } else if undoPosition == maxIndex {
            // do the check from getPosition(), but only check for matching, don't get new index
            
        } else if undoPosition < maxIndex {
            //let usedPosition = getPosition(for: .redo, index: undoPosition)
            //undoPosition = usedPosition
        }
        
        //print("-- \(#function) ✅usedPosition \(undoPosition)")
//        for each in history {
//            print(each)
//            //print("\n")
//        }
        return history[undoPosition]
    }
    
    
    func clearHistory() {
        history.removeAll()
    }
    
    
}



//
//class UndoableText: Equatable {
//    let oldValue: String?
//    let value: String?
//    let field: TransactionUndoField
//    var action: UndoRedo = .undo
//    
//    init(oldValue: String?, value: String?, field: TransactionUndoField) {
//        self.oldValue = oldValue
//        self.value = value
//        self.field = field
//    }
//    
//    static func == (lhs: UndoableText, rhs: UndoableText) -> Bool {
//        if lhs.value == rhs.value && lhs.oldValue == rhs.oldValue && lhs.field == rhs.field {
//            return true
//        }
//        return false
//    }
//}
//
//
//
//@Observable
//class UndodoManagerV2 {
//    static let shared = UndodoManager()
//    
//    var undoField: String = ""
//    var redoField: String = ""
//    var showAlert = false
//    var returnMe: UndoableText?
//    var trans: CBTransaction = CBTransaction()
//    
//    var undoPosition: Int = 0
//    var history: [UndoableText] = []
//    var maxIndex: Int { history.count - 1 }
//
//    private var changeTasks: Array<UndoTask> = []
//    
//    var canUndo: Bool = false
//    var canRedo: Bool = false
//    
//    func getChangeFields() {
//        
//        /// Simulate undo to get field that will be undone if the user takes action.
//        var simUndoPosition = undoPosition - 1
//        print("undo simPos \(simUndoPosition)")
//        
//        if simUndoPosition == -1 {
//            canUndo = false
//            
//        } else if simUndoPosition == 0 {
//            canUndo = true
////            if !shouldIgnore(for: .undo, index: simUndoPosition) {
////                canUndo = true
////                undoField = history[simUndoPosition].field.rawValue
////            } else {
////                canUndo = false
////            }
//            
//        } else if simUndoPosition > 0 {
//            canUndo = true
////            let usedPosition = getPosition(for: .undo, index: simUndoPosition)
////            simUndoPosition = usedPosition
////            print("undo simPos \(simUndoPosition)")
////
////            if simUndoPosition == -1 {
////                canUndo = false
////            } else {
////                canUndo = true
////                undoField = history[simUndoPosition].field.rawValue
////            }
//        }
//        
//        
//        /// Simulate redo to get field that will be redone if the user takes action.
//        var simRedoPosition = undoPosition + 1
//        print("redo simPos \(simRedoPosition)")
//        
//        if simRedoPosition > maxIndex {
//            canRedo = false
//            
//        } else if simRedoPosition == maxIndex {
//            canRedo = false
////            if !shouldIgnore(for: .redo, index: simRedoPosition) {
////                canRedo = true
////                redoField = history[simRedoPosition].field.rawValue
////            } else {
////                canRedo = false
////            }
//            
//        } else if simRedoPosition < maxIndex {
//            canRedo = true
////            let usedPosition = getPosition(for: .redo, index: simRedoPosition)
////            simRedoPosition = usedPosition
////            print("redo simPos \(simRedoPosition)")
////
////            if simRedoPosition > maxIndex {
////                canRedo = false
////            } else {
////                canRedo = true
////                redoField = history[simRedoPosition].field.rawValue
////            }
//        }
//        
//        
//    }
//    
//    func processChange(oldValue: String?, value: String?, field: TransactionUndoField) {
//        if returnMe != nil {
//            returnMe = nil
//        } else {
//            let task = Task {
//                do {
//                    try await Task.sleep(for: .seconds(1))
//                    await MainActor.run {
//                        self.commitChange(oldValue: oldValue, value: value, field: field)
//                    }
//                }
//            }
//                        
//            if let index = changeTasks.firstIndex(where: { $0.field == field }) {
//                changeTasks[index].task?.cancel()
//                changeTasks[index].task = task
//            } else {
//                changeTasks.append(UndoTask(field: field, task: task))
//            }
//        }
//    }
//    
//    
//    func commitChangeInTask(oldValue: String?, value: String?, field: TransactionUndoField) {
//        Task {
//            do {
//                try await Task.sleep(for: .seconds(1))
//                await MainActor.run {
//                    self.commitChange(oldValue: oldValue, value: value, field: field)
//                }
//            }
//        }
//    }
//    
//    
//    func commitChange(oldValue: String?, value: String?, field: TransactionUndoField) {
//        print("-- \(#function) - \(value ?? "") - \(field.rawValue)")
//        /// Make sure you don't duplicate changes.
//        guard (value, field) != (history.last?.value, history.last?.field) else { return }
//
//        
//        let undoText = UndoableText(oldValue: oldValue, value: value, field: field)
//        history.append(undoText)
//        undoPosition += 1
//        
//        if maxIndex == -1 {
//            undoPosition = 0
//        } else if undoPosition < maxIndex  {
//            let range = undoPosition..<maxIndex
//            history.removeSubrange(range)
//        } else {
//            undoPosition = maxIndex
//        }
//        
//        print(undoPosition)
//        print(history.map { "Field: \($0.field.rawValue) - Old: \($0.oldValue ?? "") - New: \($0.value ?? "")" })
//    }
//
//    
//    func undo(trans: CBTransaction) -> UndoableText? {
//        print("-- \(#function) ❌old position \(undoPosition)")
//        undoPosition -= 1
//        
//        if undoPosition == -1 {
//            undoPosition = 0
//            
//        } else if undoPosition == 0 {
//            // do the check from getPosition(), but only check for matching, don't get new index
//            
//        } else if undoPosition > 0 {
//            //let usedPosition = getPosition(for: .undo, index: undoPosition)
//            //undoPosition = usedPosition
//        }
//        print("-- \(#function) ✅usedPosition \(undoPosition)")
//        return history[undoPosition]
//        
//    }
//
//    
//    func redo(trans: CBTransaction) -> UndoableText?  {
//        print("-- \(#function) ❌old position \(undoPosition)")
//        undoPosition += 1
//        
//        if undoPosition > maxIndex {
//            undoPosition = maxIndex
//            
//        } else if undoPosition == maxIndex {
//            // do the check from getPosition(), but only check for matching, don't get new index
//            
//        } else if undoPosition < maxIndex {
//            //let usedPosition = getPosition(for: .redo, index: undoPosition)
//            //undoPosition = usedPosition
//        }
//        
//        print("-- \(#function) ✅usedPosition \(undoPosition)")
//        return history[undoPosition]
//    }
//    
//    
//    func clearHistory() {
//        history.removeAll()
//    }
//    
//    
////    func getPosition(for undoredo: UndoRedo, index: Int) -> Int {
////        let target = history[index]
////
////        let next = undoredo == .undo ? index - 1 : index + 1
////
////        switch target.field {
////        case .title:
////            if trans.title == target.value { return getPosition(for: undoredo, index: next) }
////        case .amount:
////            if trans.amountString == target.value { return getPosition(for: undoredo, index: next) }
////        case .payMethod:
////            if trans.payMethod?.id == target.value { return getPosition(for: undoredo, index: next) }
////        case .category:
////            if trans.category?.id == target.value { return getPosition(for: undoredo, index: next) }
////        case .date:
////            if trans.date?.string(to: .serverDate) == target.value { return getPosition(for: undoredo, index: next) }
////        case .trackingNumber:
////            if trans.trackingNumber == target.value { return getPosition(for: undoredo, index: next) }
////        case .orderNumber:
////            if trans.orderNumber == target.value { return getPosition(for: undoredo, index: next) }
////        case .url:
////            if trans.url == target.value { return getPosition(for: undoredo, index: next) }
////        case .notes:
////            if trans.notes == target.value { return getPosition(for: undoredo, index: next) }
////        }
////        return index
////    }
//    
//    
////    func shouldIgnore(for undoredo: UndoRedo, index: Int) -> Bool {
////        let target = history[index]
////
////        switch target.field {
////        case .title:
////            if trans.title == target.value { return true }
////        case .amount:
////            if trans.amountString == target.value { return true }
////        case .payMethod:
////            if trans.payMethod?.id == target.value { return true }
////        case .category:
////            if trans.category?.id == target.value { return true }
////        case .date:
////            if trans.date?.string(to: .serverDate) == target.value { return true }
////        case .trackingNumber:
////            if trans.trackingNumber == target.value { return true }
////        case .orderNumber:
////            if trans.orderNumber == target.value { return true }
////        case .url:
////            if trans.url == target.value { return true }
////        case .notes:
////            if trans.notes == target.value { return true }
////        }
////        return false
////    }
//}



//
//@Observable
//class UndodoManagerV1 {
//    static let shared = UndodoManager()
//    var showAlert = false
//    
//    var returnMe: UndoableText?
//
//    var canUndo: Bool = false
//    var canRedo: Bool = false
//    
//    private var undoStack: [UndoableText] = []
//    private var redoStack: [UndoableText] = []
//        
//    private var lastCommittedText: String = ""
//
//    init() { }
//
//    func commitTextChange(text: String, focusedField: Int) {
//        
//        guard text != undoStack.last?.text else { return }
//
//        print("Adding for undo -- \(text)")
//        let undoText = UndoableText(text: text, focusedField: focusedField)
//        undoStack.append(undoText)
//        //redoStack.removeAll()
//        updateButtonStates()
//        
//        print(undoStack.map {"\($0.text) - \($0.focusedField)"})
//        print(redoStack.map {"\($0.text) - \($0.focusedField)"})
//    }
//
//    func undo() -> UndoableText? {
//        guard let lastAction = undoStack.popLast() else { return nil }
//        
//        if lastAction.text != redoStack.last?.text {
//            print("Appending for redo \(lastAction.text)")
//            redoStack.append(lastAction)
//        }
//        
//        updateButtonStates()
//        
//        print(undoStack.map {"\($0.text) - \($0.focusedField)"})
//        print(redoStack.map {"\($0.text) - \($0.focusedField)"})
//        
//        return undoStack.last
//    }
//
//    func redo() -> UndoableText?  {
//        guard let lastAction = redoStack.popLast() else { return nil }
//        
//        //print(redoStack.map {$0.text})
//        
//        if lastAction.text != undoStack.last?.text {
//            print("Appending for undo \(lastAction.text)")
//            undoStack.append(lastAction)
//        }
//        
//        print(undoStack.map {"\($0.text) - \($0.focusedField)"})
//        print(redoStack.map {"\($0.text) - \($0.focusedField)"})
//        
//        updateButtonStates()
//        return lastAction
//    }
//    
//    private func updateButtonStates() {
//        canUndo = !undoStack.isEmpty
//        canRedo = !redoStack.isEmpty
//    }
//}
