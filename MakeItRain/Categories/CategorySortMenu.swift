//
//  CategorySortMenu.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/28/25.
//

import SwiftUI

struct CategorySortMenu: View {
    @AppStorage("categorySortMode") var categorySortMode: SortMode = .title
    @Environment(CategoryModel.self) private var catModel
    @Environment(CalendarModel.self) private var calModel
    
    var body: some View {
        Menu {
            Section("Choose Sort Order") {
                titleButton
                listOrderButton
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
                .schemeBasedForegroundStyle()
        }
    }
    
    var titleButton: some View {
        Button {
            categorySortMode = .title
            performSort()
        } label: {
            Label {
                Text("Alphabetically")
            } icon: {
                Image(systemName: categorySortMode == .title ? "checkmark" : "textformat.abc")
            }
        }
    }
    
    
    var listOrderButton: some View {
        Button {
            categorySortMode = .listOrder
            performSort()
        } label: {
            Label {
                Text("Custom")
            } icon: {
                Image(systemName: categorySortMode == .listOrder ? "checkmark" : "list.bullet")
            }
        }
    }
    
    func performSort() {
        withAnimation {
            #if os(macOS)
            sortOrder = [KeyPathComparator(\CBCategory.title)]
            #else
            catModel.categories.sort(by: Helpers.categorySorter())
            calModel.months.forEach { $0.budgets.sort(by: Helpers.budgetSorter()) }
            //catModel.categories.sort { ($0.title).lowercased() < ($1.title).lowercased() }
            #endif
        }
    }
}
