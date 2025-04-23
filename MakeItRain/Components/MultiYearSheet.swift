//
//  MultiYearSheet.swift
//  MakeItRain
//
//  Created by Cody Burnett on 1/7/25.
//

import SwiftUI

struct MultiYearSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var years: Array<Int>
    
    var yearOptions: [Int] { Array(2000...2099).map { $0 } }
    var nowishYears: [Int] { [AppState.shared.todayYear - 1, AppState.shared.todayYear, AppState.shared.todayYear + 1] }
    
    var body: some View {
        StandardContainer(.list) {
            Section("Now(ish) Years") {
                ForEach(nowishYears) { year in
                    LineItem(year: year, years: $years)
                }
            }
                                    
            Section("All Years") {
                ForEach(yearOptions) { year in
                    LineItem(year: year, years: $years)
                }
            }
        } header: {
            SheetHeader(
                title: "Years",
                close: { dismiss() },
                view1: { selectButton }
            )
        }
        .task {
            if !years.contains(AppState.shared.todayYear) {
                years.append(AppState.shared.todayYear)
            }
        }
    }
    
    var selectButton: some View {
        Button {
            years = years.isEmpty ? yearOptions : []
        } label: {
            Image(systemName: years.isEmpty ? "checklist.checked" : "checklist.unchecked")
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
