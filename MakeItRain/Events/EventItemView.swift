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
    @Bindable var item: CBEventItem
    
    @State private var showDeleteAlert = false
    @State private var deleteTrans: CBEventTransaction?
    @State private var editTrans: CBEventTransaction?
    @State private var transEditID: CBEventTransaction.ID?
    
    @FocusState private var focusedField: Int?
    
    var title: String { item.action == .add ? "New Item" : "Edit Item" }
    
    var addItemButton: some View {
        Button {
            transEditID = UUID().uuidString
        } label: {
            Image(systemName: "plus")
        }
    }
        
    var deleteButton: some View {
        Button {
            showDeleteAlert = true
        } label: {
            Image(systemName: "trash")
        }
        .sensoryFeedback(.warning, trigger: showDeleteAlert) { !$0 && $1 }
    }
    
    var header: some View {
        Group {
            SheetHeader(
                title: title,
                close: { dismiss() },
                view1: { addItemButton },
                view3: { deleteButton }
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
                
                HStack {
                    Text("Title")
                    Spacer()
                    #if os(iOS)
                    UITextFieldWrapperFancy(placeholder: "Item Title", text: $item.title, toolbar: {
                        KeyboardToolbarView(focusedField: $focusedField)
                    })
                    .uiTag(0)
                    .uiTextAlignment(.right)
                    .uiClearButtonMode(.whileEditing)
                    .uiStartCursorAtEnd(true)
                    #else
                    TextField("Item Title", text: $event.title)
                        .multilineTextAlignment(.trailing)
                    #endif
                }
                .focused($focusedField, equals: 0)
                
                
                Section("Transactions") {
                    ForEach(item.transactions.filter { $0.active }) { trans in
                        Text(trans.title)
                            .onTapGesture {
                                transEditID = trans.id
                            }
                        
                    }
                    Button("Add Transaction") {
                        transEditID = UUID().uuidString
                    }
                }
                
                
                
            }
        }
        .task {
            event.upsert(item)
        }
        .sheet(item: $editTrans, onDismiss: {
            transEditID = nil
        }, content: { trans in
            FakeTransEditView(trans: trans, item: item, event: event)
            #if os(macOS)
                .frame(minWidth: 300, minHeight: 500)
                .presentationSizing(.fitted)
            #endif
        })
        
        .onChange(of: transEditID) { oldValue, newValue in
            if let newValue {
                editTrans = item.getTransaction(by: newValue)
            } else {
                item.saveTransaction(id: oldValue!)
                
                
                let trans = item.getTransaction(by: oldValue!)
                if trans.status.enumID == .claimed {
                    print("Creating real transaction in itemview")
                    let realTrans = trans.realTransaction
                    realTrans.title = trans.title
                    realTrans.amountString = trans.amountString
                    realTrans.date = trans.date
                    realTrans.enteredBy = trans.paidBy!
                    realTrans.updatedBy = trans.paidBy!
                    realTrans.relatedTransactionID = trans.id
                    realTrans.relatedTransactionType = XrefModel.getItem(from: .relatedTransactionType, byEnumID: .eventTransaction)
                    
                    eventModel.pendingTransactionToSave.append(realTrans)
                }
            }
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
}
