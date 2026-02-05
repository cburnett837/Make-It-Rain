//
//  CategorySortMenu.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/28/25.
//

import SwiftUI

enum SortMenuDisplayStyle {
    case inlineWithMenu, standalone
}

struct CategorySortMenu: View {
    @Environment(CategoryModel.self) private var catModel
    @Environment(CalendarModel.self) private var calModel
    var displayStyle: SortMenuDisplayStyle = .standalone
    
    @State private var isAlpha = false
    @State private var isCustom = false
    
    var body: some View {
        Group {
            switch displayStyle {
            case .inlineWithMenu:
                content
            case .standalone:
                theMenu
            }
        }
        .onAppear {
            switch AppSettings.shared.categorySortMode {
            case .title:
                isAlpha = true
            case .listOrder:
                isCustom = true
            }
        }
        .onChange(of: isAlpha) {
            if $1 {
                isCustom = false
                AppSettings.shared.categorySortMode = .title
                performSort()
            }
        }
        .onChange(of: isCustom) {
            if $1 {
                isAlpha = false
                AppSettings.shared.categorySortMode = .listOrder
                performSort()
            }
        }
        .onChange(of: AppSettings.shared.categorySortMode) { oldValue, newValue in
            AppSettings.shared.sendToServer(setting: .init(settingId: 60, setting: newValue.rawValue))
        }
    }
    
    var theMenu: some View {
        Menu {
            content
        } label: {
            Image(systemName: "arrow.up.arrow.down")
                .schemeBasedForegroundStyle()
        }
    }
    
    var content: some View {
        Section("Choose Sort Order") {
            Toggle(isOn: $isAlpha) {
                Label("Alphabetically", systemImage: "textformat.abc")
            }
            Toggle(isOn: $isCustom) {
                Label("Custom", systemImage: "list.bullet")
            }
        }
    }
   
    
    func performSort() {
        withAnimation {
            #if os(macOS)
            //sortOrder = [KeyPathComparator(\CBCategory.title)]
            #else
            catModel.categories.sort(by: Helpers.categorySorter())
            calModel.months.forEach { $0.budgets.sort(by: Helpers.budgetSorter()) }
            //catModel.categories.sort { ($0.title).lowercased() < ($1.title).lowercased() }
            #endif
        }
    }
}
