//
//  MultiYearSheet.swift
//  MakeItRain
//
//  Created by Cody Burnett on 1/7/25.
//

import SwiftUI

struct MultiYearSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme

    @Binding var years: Array<Int>
    
    var yearOptions: [Int] { Array(2000...2099).map { $0 } }
    var nowishYears: [Int] { [AppState.shared.todayYear - 1, AppState.shared.todayYear, AppState.shared.todayYear + 1] }
    
    @State private var searchText = ""
    
    var filteredYears: Array<Int> {
        yearOptions.filter { searchText.isEmpty ? true : String($0).localizedStandardContains(searchText) }
    }
    
    var body: some View {
        NavigationStack {
            StandardContainerWithToolbar(.list) {
                content
            }
            #if os(iOS)
            .searchable(text: $searchText, prompt: "Search")
            .navigationTitle("Years")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { selectButton }
                ToolbarItem(placement: .topBarTrailing) { closeButton }
            }
            #endif
        }
        .task {
            if !years.contains(AppState.shared.todayYear) {
                years.append(AppState.shared.todayYear)
            }
        }
    }
    
    
    @ViewBuilder
    var content: some View {
        Section("Now(ish) Years") {
            ForEach(nowishYears) { year in
                LineItem(year: year, years: $years)
            }
        }
                                
        Section("All Years") {
            if filteredYears.isEmpty {
                ContentUnavailableView("No years found", systemImage: "exclamationmark.magnifyingglass")
            } else {
                ForEach(filteredYears) { year in
                    LineItem(year: year, years: $years)
                }
            }
        }
    }
    
    
    
    var selectButton: some View {
        Button {
            years = years.isEmpty ? yearOptions : []
        } label: {
            Image(systemName: years.isEmpty ? "checklist.checked" : "checklist.unchecked")
                .foregroundStyle(colorScheme == .dark ? .white : .black)
        }
    }
    
    
    var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .foregroundStyle(colorScheme == .dark ? .white : .black)
        }
    }
}


fileprivate struct LineItem: View {
    var year: Int
    @Binding var years: [Int]
    
    var body: some View {
        HStack {
            Text("\(String(year))")
            Spacer()
            Image(systemName: "checkmark")
                .opacity(years.contains(year) ? 1 : 0)
        }
        .contentShape(Rectangle())
        .onTapGesture { doIt(year) }
    }
    
    func doIt(_ year: Int) {
        if years.contains(year) {
            years.removeAll(where: { $0 == year })
        } else {
            years.append(year)
        }
    }
}
