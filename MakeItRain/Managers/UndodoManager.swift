//
//  UndoooManager.swift
//  MakeItRain
//
//  Created by Cody Burnett on 2/11/25.
//

import Foundation
import SwiftUI

struct UndoableText: Equatable {
    let text: String
    let focusedField: Int
}

@Observable
class UndodoManager {
    static let shared = UndodoManager()
    var showAlert = false
    var returnMe: UndoableText?
    
    var undoPosition: Int = 0
    private var history: [UndoableText] = []
    var maxIndex: Int { history.count - 1 }

    func commitTextChange(text: String, focusedField: Int) {
        /// Make sure you don't duplicate changes.
        guard text != history.last?.text else { return }

        
        let undoText = UndoableText(text: text, focusedField: focusedField)
        history.append(undoText)
        undoPosition += 1
        
        if maxIndex == -1 {
            undoPosition = 0
        } else if undoPosition < maxIndex  {
            let range = undoPosition..<maxIndex
            history.removeSubrange(range)
        } else {
            undoPosition = maxIndex
        }
        
        print(undoPosition)
        print(history.map {$0.text})
        
    }

    func undo() -> UndoableText? {
        print("old position \(undoPosition)")
        //print(history)
        
        if undoPosition > 0 {
            undoPosition -= 1
        } else {
            undoPosition = 0
        }
        print("New position \(undoPosition)")
        return history[undoPosition]
    }

    func redo() -> UndoableText?  {
        print("old position \(undoPosition)")
        //print(history)
        
        if undoPosition < maxIndex {
            undoPosition += 1
        } else {
            undoPosition = maxIndex
        }
        print("New position \(undoPosition)")
        return history[undoPosition]
    }
    
    func clearHistory() {
        history.removeAll()
    }
}




@Observable
class UndodoManagerOG {
    static let shared = UndodoManager()
    var showAlert = false
    
    var returnMe: UndoableText?

    var canUndo: Bool = false
    var canRedo: Bool = false
    
    private var undoStack: [UndoableText] = []
    private var redoStack: [UndoableText] = []
        
    private var lastCommittedText: String = ""

    init() { }

    func commitTextChange(text: String, focusedField: Int) {
        
        guard text != undoStack.last?.text else { return }

        print("Adding for undo -- \(text)")
        let undoText = UndoableText(text: text, focusedField: focusedField)
        undoStack.append(undoText)
        //redoStack.removeAll()
        updateButtonStates()
        
        print(undoStack.map {"\($0.text) - \($0.focusedField)"})
        print(redoStack.map {"\($0.text) - \($0.focusedField)"})
    }

    func undo() -> UndoableText? {
        guard let lastAction = undoStack.popLast() else { return nil }
        
        if lastAction.text != redoStack.last?.text {
            print("Appending for redo \(lastAction.text)")
            redoStack.append(lastAction)
        }
        
        updateButtonStates()
        
        print(undoStack.map {"\($0.text) - \($0.focusedField)"})
        print(redoStack.map {"\($0.text) - \($0.focusedField)"})
        
        return undoStack.last
    }

    func redo() -> UndoableText?  {
        guard let lastAction = redoStack.popLast() else { return nil }
        
        //print(redoStack.map {$0.text})
        
        if lastAction.text != undoStack.last?.text {
            print("Appending for undo \(lastAction.text)")
            undoStack.append(lastAction)
        }
        
        print(undoStack.map {"\($0.text) - \($0.focusedField)"})
        print(redoStack.map {"\($0.text) - \($0.focusedField)"})
        
        updateButtonStates()
        return lastAction
    }
    
    private func updateButtonStates() {
        canUndo = !undoStack.isEmpty
        canRedo = !redoStack.isEmpty
    }
}
