//
//  CategoryEditSheetAndLogic.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/13/26.
//

import Foundation
import SwiftUI

extension View {
    func categoryEditSheetAndLogic(
        editId: Binding<String?>,
        onDismiss: ((_ didSave: Bool) -> ())? = nil
    ) -> some View {
        modifier(CategoryEditSheetAndLogic(editId: editId, onDismiss: onDismiss))
    }
    
    func categoryGroupEditSheetAndLogic(
        editId: Binding<String?>,
        onDismiss: ((_ didSave: Bool) -> ())? = nil
    ) -> some View {
        modifier(CategoryGroupEditSheetAndLogic(editId: editId, onDismiss: onDismiss))
    }
}

fileprivate struct CategoryEditSheetAndLogic: ViewModifier {
    @Environment(CalendarProps.self) private var calProps
    @Environment(CategoryModel.self) private var catModel
    
    @Binding var editId: String?
    var onDismiss: ((_ didSave: Bool) -> ())?
    
    @State private var editCategory: CBCategory?
        
    func body(content: Content) -> some View {
        content
            //.sensoryFeedback(.selection, trigger: editId) { $1 != nil }
            .onChange(of: editId) { editIdChanged(oldId: $0, newId: $1) }
            .sheet(item: $editCategory, onDismiss: {
                editId = nil
            }) { cat in
                CategoryEditView(category: cat, editID: $editId)
                    .id(cat.id)
                    #if os(macOS)
                    .presentationSizing(.page)
                    .frame(minWidth: 320, minHeight: 320)
                    #endif
            }
    }
    

    func editIdChanged(oldId: String?, newId: String?) {
        if let newId {
            sheetWasOpened(id: newId)
        } else {
            Task {
                await sheetWasClosed(id: oldId!)
            }
        }
    }
    
    
    func sheetWasOpened(id: String) {
        if let category = catModel.getCategory(by: id) {
            editCategory = category
        } else {
            editCategory = CBCategory(uuid: id)
        }
    }
    
    func sheetWasClosed(id: String) async {
        let didSave = await catModel.saveCategory(id: id)
        
        if let onDismiss = onDismiss {
            onDismiss(didSave)
        }
    }
}


fileprivate struct CategoryGroupEditSheetAndLogic: ViewModifier {
    @Environment(CalendarProps.self) private var calProps
    @Environment(CategoryModel.self) private var catModel
    
    @Binding var editId: String?
    var onDismiss: ((_ didSave: Bool) -> ())?
    
    @State private var editGroup: CBCategoryGroup?
        
    func body(content: Content) -> some View {
        content
            //.sensoryFeedback(.selection, trigger: editId) { $1 != nil }
            .onChange(of: editId) { editIdChanged(oldId: $0, newId: $1) }
            .sheet(item: $editGroup, onDismiss: {
                editId = nil
            }) { group in
                CategoryGroupEditView(group: group, editID: $editId)
                    .id(group.id)
                    #if os(macOS)
                    .presentationSizing(.page)
                    .frame(minWidth: 320, minHeight: 320)
                    #endif
            }
    }
    

    func editIdChanged(oldId: String?, newId: String?) {
        if let newId {
            sheetWasOpened(id: newId)
        } else {
            Task {
                await sheetWasClosed(id: oldId!)
            }
        }
    }
    
    
    func sheetWasOpened(id: String) {
        if let category = catModel.getCategoryGroup(by: id) {
            editGroup = category
        } else {
            editGroup = CBCategoryGroup(uuid: id)
        }
    }
    
    func sheetWasClosed(id: String) async {
        let didSave = await catModel.saveCategoryGroup(id: id)
        
        if let onDismiss = onDismiss {
            onDismiss(didSave)
        }
    }
}



