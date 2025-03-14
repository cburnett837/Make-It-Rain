//
//  MultiCategorySheet.swift
//  MakeItRain
//
//  Created by Cody Burnett on 1/3/25.
//

import SwiftUI

struct MultiCategorySheet: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("lineItemIndicator") var lineItemIndicator: LineItemIndicator = .emoji
    @AppStorage("categorySortMode") var categorySortMode: CategorySortMode = .title
    
    @Environment(CalendarModel.self) private var calModel
    @Environment(CalendarViewModel.self) private var calViewModel
    @Environment(CategoryModel.self) private var catModel
    @Environment(KeywordModel.self) private var keyModel
    
    @Binding var categories: Array<CBCategory>
                
    @FocusState private var focusedField: Int?
    @State private var searchText = ""
    @State private var labelWidth: CGFloat = 20.0
    
    var filteredCategories: Array<CBCategory> {
        if searchText.isEmpty {
            return catModel.categories
                .sorted {
                    categorySortMode == .title
                    ? $0.title.lowercased() < $1.title.lowercased()
                    : $0.listOrder ?? 1000000000 < $1.listOrder ?? 1000000000
                }
        } else {
            return catModel.categories
                .filter { $0.title.localizedStandardContains(searchText) }
                .sorted {
                    categorySortMode == .title
                    ? $0.title.lowercased() < $1.title.lowercased()
                    : $0.listOrder ?? 1000000000 < $1.listOrder ?? 1000000000
                }
        }
    }

    
    var body: some View {
        SheetContainerView(.list) {
            Section("Your Categories") {
                ForEach(filteredCategories) { cat in
                    LineItem(cat: cat, categories: $categories, labelWidth: labelWidth)
                }
            }
        } header: {
            SheetHeader(
                title: "Categories",
                close: { dismiss() },
                view1: { selectButton },
                view2: { sortMenu }
            )
        } subHeader: {
            SearchTextField(title: "Categories", searchText: $searchText, focusedField: $focusedField, focusState: _focusedField)
                .padding(.horizontal, -20)
        }
        .onPreferenceChange(MaxSizePreferenceKey.self) { labelWidth = max(labelWidth, $0) }
    }
    
    
    var sortMenu: some View {
        Menu {
            Button {
                categorySortMode = .title
            } label: {
                Label {
                    Text("Title")
                } icon: {
                    Image(systemName: categorySortMode == .title ? "checkmark" : "textformat.abc")
                }
            }
            
            Button {
                categorySortMode = .listOrder
            } label: {
                Label {
                    Text("Custom")
                } icon: {
                    Image(systemName: categorySortMode == .listOrder ? "checkmark" : "list.bullet")
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
        }
    }
    
    var selectButton: some View {
        Button {
            categories = categories.isEmpty ? catModel.categories : []
        } label: {
            Image(systemName: categories.isEmpty ? "checklist.checked" : "checklist.unchecked")
        }
    }    
}


fileprivate struct LineItem: View {
    @AppStorage("lineItemIndicator") var lineItemIndicator: LineItemIndicator = .emoji
    
    var cat: CBCategory
    @Binding var categories: [CBCategory]
    var labelWidth: CGFloat
    
    var body: some View {
        HStack {
            Image(systemName: lineItemIndicator == .dot ? "circle.fill" : (cat.emoji ?? "circle.fill"))
                .foregroundStyle(cat.color.gradient)
                .frame(minWidth: labelWidth, alignment: .center)
                .maxViewWidthObserver()
            Text(cat.title)
            Spacer()
            Image(systemName: "checkmark")
                .opacity(categories.contains(cat) ? 1 : 0)
        }
        .contentShape(Rectangle())
        .onTapGesture { doIt(cat) }
    }
    
    func doIt(_ category: CBCategory) {
        print("-- \(#function)")
        if categories.contains(category) {
            categories.removeAll(where: { $0.id == category.id })
        } else {
            categories.append(category)
        }
    }
}


