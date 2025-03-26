//
//  EventCategoryView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 3/26/25.
//

import SwiftUI


struct EventCategoriesTable: View {
    @Environment(\.dismiss) var dismiss
    @Environment(CalendarModel.self) private var calModel
    @Environment(EventModel.self) private var eventModel
    
    @Bindable var event: CBEvent
    @State private var showDeleteAlert = false
    @FocusState private var focusedField: Int?
    
    @State private var deleteCategory: CBEventCategory?
    @State private var editCategory: CBEventCategory?
    @State private var categoryEditID: CBEventCategory.ID?
    
    @State private var labelWidth: CGFloat = 20.0
    
    
    var header: some View {
        Group {
            SheetHeader(
                title: "Categories",
                close: { dismiss() },
                view1: {
                    Button {
                        categoryEditID = UUID().uuidString
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            )
            .padding()
            
            Divider()
                .padding(.horizontal)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            header
            listForPhone
//            List {
//                ForEach($event.categories.filter {$0.wrappedValue.active}) { $category in
//                    Group {
//                        #if os(iOS)
//                        UITextFieldWrapper(placeholder: "Category Title", text: $category.title, toolbar: {
//                            KeyboardToolbarView(focusedField: $focusedField)
//                        })
//                        .uiTag(0)
//                        .uiTextAlignment(.left)
//                        .uiClearButtonMode(.whileEditing)
//                        .uiStartCursorAtEnd(true)
//                        #else
//                        TextField("Category Title", text: $category.title)
//                            .multilineTextAlignment(.leading)
//                        #endif
//                    }
//                    .swipeActions(allowsFullSwipe: false) {
//                        Button {
//                            deleteCategory = category
//                            showDeleteAlert = true
//                        } label: {
//                            Image(systemName: "trash")
//                                .tint(.red)
//                        }
//                    }
//                    .focused($focusedField, equals: getFocusIndex(for: category))
//                    
//                }
//                
//                Button("Add Category") {
//                    let category = CBEventCategory()
//                    event.upsert(category)
//                }
//            }
        }
        .confirmationDialog("Delete \"\(deleteCategory?.title ?? "N.A")\"?", isPresented: $showDeleteAlert, actions: {
            if let deleteCategory {
                Button("Yes", role: .destructive) {
                    event.deleteCategory(id: deleteCategory.id)
                }
            }
            Button("No", role: .cancel) {
                showDeleteAlert = false
            }
        }, message: {
            #if os(iOS)
            Text("Delete \"\(deleteCategory?.title ?? "N.A")\"?\nThis will not delete any associated transactions.")
            #else
            Text("This will not delete any associated transactions.")
            #endif
        })
        .onChange(of: categoryEditID) { oldValue, newValue in
            if let newValue {
                editCategory = event.getCategory(by: newValue)
            } else {
                event.saveCategory(id: oldValue!)
            }
        }
        .sheet(item: $editCategory, onDismiss: {
            categoryEditID = nil
        }, content: { cat in
            EventCategoryView(category: cat, event: event, editID: $categoryEditID)
                #if os(macOS)
                .frame(minWidth: 500, minHeight: 700)
                .presentationSizing(.fitted)
                #endif
        })
    }
    
    
    
    
    var listForPhone: some View {
        List(selection: $categoryEditID) {
            ForEach(event.categories.filter {$0.active}) { cat in
                HStack(alignment: .center) {
                    Text(cat.title)
                    Spacer()
                    
                    if let emoji = cat.emoji {
                        Image(systemName: emoji)
                            .foregroundStyle(cat.color.gradient)
                            .frame(minWidth: labelWidth, alignment: .center)
                            .maxViewWidthObserver()
                    } else {
                        Circle()
                            .fill(cat.color.gradient)
                            .frame(width: 12, height: 12)
                    }
                }
                #if os(iOS)
                .standardRowBackgroundWithSelection(id: cat.id, selectedID: categoryEditID)
                .swipeActions(allowsFullSwipe: false) {
                    Button {
                        deleteCategory = cat
                        showDeleteAlert = true
                    } label: {
                        Label {
                            Text("Delete")
                        } icon: {
                            Image(systemName: "trash")
                        }
                    }
                    .tint(.red)
                }
                #else
                .selectionDisabled()
                #endif
            }
        }
        .listStyle(.plain)
        #if os(iOS)
        .standardBackground()
        #endif
    }
    
    
    
    
    
    
    
    
    
    func getFocusIndex(for category: CBEventCategory) -> Int {
        return (event.categories.firstIndex(of: category) ?? 0) + 2
    }
    
}
