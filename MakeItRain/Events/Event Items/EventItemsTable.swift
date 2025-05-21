//
//  EventItemsTable.swift
//  MakeItRain
//
//  Created by Cody Burnett on 3/27/25.
//

import Foundation
import SwiftUI

struct EventItemsTable: View {
    @Environment(\.dismiss) var dismiss
    @Environment(FuncModel.self) var funcModel
    @Environment(CalendarModel.self) private var calModel
    @Environment(EventModel.self) private var eventModel
    
    @Bindable var event: CBEvent
    @State private var showDeleteAlert = false
    @FocusState private var focusedField: Int?
    
    @State private var deleteItem: CBEventItem?
    @State private var editItem: CBEventItem?
    @State private var itemEditID: CBEventItem.ID?
    
    @State private var labelWidth: CGFloat = 20.0
    
    
    var header: some View {
        Group {
            SheetHeader(
                title: "Items",
                close: { dismiss() },
                view1: {
                    Button {
                        itemEditID = UUID().uuidString
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            )
        }
    }
    
    var body: some View {
        StandardContainer(.plainWithSelection, selectionID: $itemEditID) {
            if event.items.isEmpty {
                ContentUnavailableView("No Sections", systemImage: "bag.fill.badge.questionmark")
                Button("Add") {
                    itemEditID = UUID().uuidString
                }
                .frame(maxWidth: .infinity)
                
            } else {
                listForPhone
            }
        } header: {
            header
        }
        .confirmationDialog("Delete \"\(deleteItem?.title ?? "N.A")\"?", isPresented: $showDeleteAlert, actions: {
            if let deleteItem {
                Button("Yes", role: .destructive) {
                    event.deleteItem(id: deleteItem.id)
                    Task {
                        await eventModel.submit(deleteItem)
                    }
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
        .onChange(of: itemEditID) { oldValue, newValue in
            if let newValue {
                editItem = event.getItem(by: newValue)
            } else {
                if event.saveItem(id: oldValue!) {
                    let item = event.getItem(by: oldValue!)
                    Task {
                        await eventModel.submit(item)
                    }
                }
                
            }
        }
        .sheet(item: $editItem, onDismiss: {
            itemEditID = nil
        }, content: { item in
            EventItemView(item: item, event: event, editID: $itemEditID)
                #if os(macOS)
                .frame(minWidth: 500, minHeight: 700)
                .presentationSizing(.fitted)
                #endif
        })
    }
    
    
    
    
    var listForPhone: some View {
        //List(selection: $itemEditID) {
            ForEach(event.items.filter {$0.active}) { item in
                HStack(alignment: .center) {
                    Text(item.title)
                    Spacer()
                }
                #if os(iOS)
                .swipeActions(allowsFullSwipe: false) {
                    Button {
                        deleteItem = item
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
            .onMove(perform: move)
        //}
        .listStyle(.plain)
    }
    
    func getFocusIndex(for item: CBEventItem) -> Int {
        return (event.items.firstIndex(of: item) ?? 0) + 2
    }
    
    
    func move(from source: IndexSet, to destination: Int) {
        event.items.move(fromOffsets: source, toOffset: destination)
        let listOrderUpdates = event.setListOrdersForItems()
        
        Task {
            await funcModel.submitListOrders(items: listOrderUpdates, for: .eventItems)
        }
    }
    
}
