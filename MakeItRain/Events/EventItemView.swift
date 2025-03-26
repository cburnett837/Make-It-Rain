//
//  EventItemView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 1/21/25.
//

import SwiftUI

struct EventItemView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(CalendarModel.self) private var calModel
    
    @Environment(EventModel.self) private var eventModel
    
    @Bindable var event: CBEvent
    @State private var showDeleteAlert = false
    @FocusState private var focusedField: Int?
    
    @State private var deleteItem: CBEventItem?
    
    var header: some View {
        Group {
            SheetHeader(
                title: "Sections",
                close: { dismiss() }
            )
            .padding()
            
            Divider()
                .padding(.horizontal)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            header
            List {
                ForEach($event.items.filter {$0.wrappedValue.active}) { $item in
                    Group {
                        #if os(iOS)
                        UITextFieldWrapper(placeholder: "Item Title", text: $item.title, toolbar: {
                            KeyboardToolbarView(focusedField: $focusedField)
                        })
                        .uiTag(0)
                        .uiTextAlignment(.left)
                        .uiClearButtonMode(.whileEditing)
                        .uiStartCursorAtEnd(true)
                        #else
                        TextField("Item Title", text: $item.title)
                            .multilineTextAlignment(.leading)
                        #endif
                    }
                    .swipeActions(allowsFullSwipe: false) {
                        Button {
                            deleteItem = item
                            showDeleteAlert = true
                        } label: {
                            Image(systemName: "trash")
                                .tint(.red)
                        }
                    }
                    .focused($focusedField, equals: getFocusIndex(for: item))
                    
                }
                
                Button("Add Item") {
                    let item = CBEventItem()
                    event.upsert(item)
                }
            }
        }
        .confirmationDialog("Delete \"\(deleteItem?.title ?? "N.A")\"?", isPresented: $showDeleteAlert, actions: {
            if let deleteItem {
                Button("Yes", role: .destructive) {
                    event.deleteItem(id: deleteItem.id)
                }
            }
            Button("No", role: .cancel) {
                showDeleteAlert = false
            }
        }, message: {
            #if os(iOS)
            Text("Delete \"\(deleteItem?.title ?? "N.A")\"?\nThis will not delete any associated transactions.")
            #else
            Text("This will not delete any associated transactions.")
            #endif
        })
    }
    
    func getFocusIndex(for item: CBEventItem) -> Int {
        return (event.items.firstIndex(of: item) ?? 0) + 2
    }
    
}
