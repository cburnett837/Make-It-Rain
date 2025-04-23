//
//  EventItemView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 1/21/25.
//

import SwiftUI



struct EventItemView: View {
    @AppStorage("useWholeNumbers") var useWholeNumbers = false
    @AppStorage("appColorTheme") var appColorTheme: String = Color.blue.description
   
    #if os(macOS)
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    #endif
    @Environment(\.dismiss) var dismiss
    @Environment(EventModel.self) private var eventModel
    
    @Bindable var item: CBEventItem
    @Bindable var event: CBEvent
    
    /// This is only here to blank out the selection hilight on the iPhone list
    @Binding var editID: String?
    
    @State private var showDeleteAlert = false
    @State private var labelWidth: CGFloat = 20.0
    
    var title: String { item.action == .add ? "New Item" : "Edit Item" }
    
    @FocusState private var focusedField: Int?
    @State private var showSymbolPicker = false
                
    
    var deleteButton: some View {
        Button {
            showDeleteAlert = true
        } label: {
            Image(systemName: "trash")
        }
        .sensoryFeedback(.warning, trigger: showDeleteAlert) { !$0 && $1 }
    }
    
    var body: some View {
        StandardContainer {
            LabeledRow("Name", labelWidth) {
                #if os(iOS)
                StandardUITextField("Title", text: $item.title, toolbar: {
                    KeyboardToolbarView(focusedField: $focusedField)
                })
                .cbFocused(_focusedField, equals: 0)
                .cbClearButtonMode(.whileEditing)
                #else
                StandardTextField("Title", text: $item.title, focusedField: $focusedField, focusValue: 0)
                #endif
            }

        } header: {
            SheetHeader(title: title, close: { closeSheet() }, view3: { deleteButton })
        }
        .onPreferenceChange(MaxSizePreferenceKey.self) { labelWidth = max(labelWidth, $0) }
        .task {
            await prepareItemView()
        }
        .confirmationDialog("Delete \"\(item.title)\"?", isPresented: $showDeleteAlert, actions: {
            Button("Yes", role: .destructive) {
                dismiss()
                event.deleteItem(id: item.id)
            }
            
            Button("No", role: .cancel) {
                showDeleteAlert = false
            }
        }, message: {
            #if os(iOS)
            Text("Delete \"\(item.title)\"?\nThis will not delete any associated transactions.")
            #else
            Text("This will not delete any associated transactions.")
            #endif
        })
        
    }
    
    func closeSheet() {
        editID = nil
        dismiss()
    }
    
    
    func prepareItemView() async {
        item.deepCopy(.create)
        event.upsert(item)
        
        #if os(macOS)
        /// Focus on the title textfield.
        focusedField = 0
        #else
        if item.action == .add {
            focusedField = 0
        }
        #endif
    }
    
}



//
//
//
//struct EventItemViewOG: View {
//    @Environment(\.dismiss) var dismiss
//    @Environment(CalendarModel.self) private var calModel
//    
//    @Environment(EventModel.self) private var eventModel
//    
//    @Bindable var event: CBEvent
//    @State private var showDeleteAlert = false
//    @FocusState private var focusedField: Int?
//    
//    @State private var deleteItem: CBEventItem?
//    
//    var header: some View {
//        Group {
//            SheetHeader(
//                title: "Sections",
//                close: { dismiss() }
//            )
//            .padding()
//            
//            Divider()
//                .padding(.horizontal)
//        }
//    }
//    
//    var body: some View {
//        VStack(spacing: 0) {
//            header
//            List {
//                ForEach($event.items.filter {$0.wrappedValue.active}) { $item in
//                    Group {
//                        #if os(iOS)
//                        UITextFieldWrapper(placeholder: "Item Title", text: $item.title, toolbar: {
//                            KeyboardToolbarView(focusedField: $focusedField)
//                        })
//                        .uiTag(0)
//                        .uiTextAlignment(.left)
//                        .uiClearButtonMode(.whileEditing)
//                        .uiStartCursorAtEnd(true)
//                        #else
//                        TextField("Item Title", text: $item.title)
//                            .multilineTextAlignment(.leading)
//                        #endif
//                    }
//                    .swipeActions(allowsFullSwipe: false) {
//                        Button {
//                            deleteItem = item
//                            showDeleteAlert = true
//                        } label: {
//                            Image(systemName: "trash")
//                                .tint(.red)
//                        }
//                    }
//                    .focused($focusedField, equals: getFocusIndex(for: item))
//                    
//                }
//                
//                Button("Add Item") {
//                    let item = CBEventItem()
//                    event.upsert(item)
//                }
//            }
//        }
//        .confirmationDialog("Delete \"\(deleteItem?.title ?? "N.A")\"?", isPresented: $showDeleteAlert, actions: {
//            if let deleteItem {
//                Button("Yes", role: .destructive) {
//                    event.deleteItem(id: deleteItem.id)
//                }
//            }
//            Button("No", role: .cancel) {
//                showDeleteAlert = false
//            }
//        }, message: {
//            #if os(iOS)
//            Text("Delete \"\(deleteItem?.title ?? "N.A")\"?\nThis will not delete any associated transactions.")
//            #else
//            Text("This will not delete any associated transactions.")
//            #endif
//        })
//    }
//    
//    func getFocusIndex(for item: CBEventItem) -> Int {
//        return (event.items.firstIndex(of: item) ?? 0) + 2
//    }
//    
//}
