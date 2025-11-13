//
//  EventCategorySheet.swift
//  MakeItRain
//
//  Created by Cody Burnett on 4/2/25.
//


import SwiftUI

struct EventCategorySheet: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("lineItemIndicator") var lineItemIndicator: LineItemIndicator = .emoji
    @AppStorage("categorySortMode") var categorySortMode: SortMode = .title
    
    @Environment(EventModel.self) private var eventModel
        
    @State private var labelWidth: CGFloat = 20.0
    
    @Binding var category: CBEventCategory?
    @Bindable var trans: CBEventTransaction
    @Bindable var event: CBEvent
            
    @FocusState private var focusedField: Int?
    @State private var searchText = ""
    
    var filteredCategories: Array<CBEventCategory> {
        if searchText.isEmpty {
            return event.categories
                .sorted { $0.listOrder ?? 1000000000 < $1.listOrder ?? 1000000000 }
        } else {
            return event.categories.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
                .sorted { $0.listOrder ?? 1000000000 < $1.listOrder ?? 1000000000 }
        }
    }
    
    var body: some View {
        StandardContainer(.list) {
            noneSection
            yourCategoriesSection
        } header: {
            SheetHeader(title: "Categories", close: { dismiss() })
        } subHeader: {
            SearchTextField(title: "Categories", searchText: $searchText, focusedField: $focusedField, focusState: _focusedField)
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
                if category?.id == nil {
                    Image(systemName: "checkmark")
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { doIt(nil) }
        }
    }
    
    var yourCategoriesSection: some View {
        Section("Your Categories") {
            ForEach(filteredCategories) { cat in
                HStack {
                    if lineItemIndicator == .dot {
                        HStack { /// This can be a button or whatever you want
                            Image(systemName: "circle.fill")
                                .foregroundStyle(cat.color.gradient, .primary, .secondary)
                            Text(cat.title)
                            Spacer()
                            if category?.id == cat.id {
                                Image(systemName: "checkmark")
                            }
                        }
                    } else {
                        if let emoji = cat.emoji {
                            HStack {
                                Image(systemName: emoji)
                                    .foregroundStyle(cat.color.gradient)
                                    .frame(minWidth: labelWidth, alignment: .center)
                                    .maxViewWidthObserver()
                                Text(cat.title)
                                //Text("\(emoji) \(cat.title)")
                                Spacer()
                                if category?.id == cat.id {
                                    Image(systemName: "checkmark")
                                }
                            }
                        } else {
                            HStack {
                                Text(cat.title)
                                Spacer()
                                if category?.id == cat.id {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                    Spacer()
                }
                .contentShape(Rectangle())
                .onTapGesture { doIt(cat) }
            }
        }
    }
    
    func doIt(_ cat: CBEventCategory?) {
        category = cat
        dismiss()
    }
}



