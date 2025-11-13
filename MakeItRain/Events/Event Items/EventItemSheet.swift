//
//  EventCategorySheet 2.swift
//  MakeItRain
//
//  Created by Cody Burnett on 4/2/25.
//


import SwiftUI

struct EventItemSheet: View {
    @Environment(\.dismiss) var dismiss
        
    @State private var labelWidth: CGFloat = 20.0
    
    @Binding var item: CBEventItem?
    @Bindable var trans: CBEventTransaction
    @Bindable var event: CBEvent
            
    @FocusState private var focusedField: Int?
    @State private var searchText = ""
    
    var filteredItems: Array<CBEventItem> {
        if searchText.isEmpty {
            return event.items
                .sorted { $0.listOrder ?? 1000000000 < $1.listOrder ?? 1000000000 }
        } else {
            return event.items.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
                .sorted { $0.listOrder ?? 1000000000 < $1.listOrder ?? 1000000000 }
        }
    }
    
    var body: some View {
        StandardContainer(.list) {
            noneSection
            yourItemsSection
        } header: {
            SheetHeader(title: "Items", close: { dismiss() })
        } subHeader: {
            SearchTextField(title: "Items", searchText: $searchText, focusedField: $focusedField, focusState: _focusedField)
                .padding(.horizontal, -20)
                #if os(macOS)
                .focusable(false) /// prevent mac from auto focusing
                #endif
        }
        .onPreferenceChange(MaxSizePreferenceKey.self) { labelWidth = max(labelWidth, $0) }
    }
    
    var noneSection: some View {
        Section("None") {
            HStack {
                Text("None")
                    .strikethrough(true)
                Spacer()
                if item?.id == nil {
                    Image(systemName: "checkmark")
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { doIt(nil) }
        }
    }
    
    var yourItemsSection: some View {
        Section("Your Items") {
            ForEach(filteredItems) { it in
                HStack {
                    Text(it.title)
                    Spacer()
                    if item?.id == it.id {
                        Image(systemName: "checkmark")
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { doIt(it) }
            }
        }
    }
    
    func doIt(_ item: CBEventItem?) {
        self.item = item
        dismiss()
    }
}
