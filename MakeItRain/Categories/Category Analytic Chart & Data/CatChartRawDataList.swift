//
//  CategoryAnalyticChartRawDataList.swift
//  MakeItRain
//
//  Created by Cody Burnett on 12/10/25.
//

import SwiftUI
import Charts

struct CatChartRawDataList: View {
    @Environment(CalendarModel.self) private var calModel
    @Bindable var model: CatChartViewModel
    
    var displayRange: ClosedRange<Int> {
        let years = model.data.map { $0.year }
        return min((years.min() ?? 0), model.fetchYearStart)...max((years.max() ?? 0), model.fetchYearEnd)
    }
        
    var body: some View {
        List {
            /// Don't use `displayData` here since when viewing YTD, it will ommit the rest of the data and will look like it's missing.
            ForEach(Array(displayRange.reversed()), id: \.self) { year in
                let data = model.data.filter { $0.year == year }.sorted(by: { $0.date > $1.date })
                yearlySections(for: year, with: data)
            }
            
            Section {
                fetchMoreButton
            }
        }
        .tint(Color.theme)
        .navigationTitle("\(model.category!.title) Data")
        .navigationSubtitle("\(String(model.fetchYearStart)) - \(String(AppState.shared.todayYear))")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                CatChartRefreshButton(model: model)
            }
        }
        #endif
        .onChange(of: calModel.showMonth) {
            if !$1 && $0 {
                Task { await model.fetchHistory(setChartAsNew: false) }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .updateCategoryAnalytics, object: nil)) { _ in
            Task { await model.fetchHistory(setChartAsNew: false) }
        }
    }
    
    
    @ViewBuilder
    func yearlySections(for year: Int, with data: Array<CategoryAnalyticData>) -> some View {
        Section(String(year)) {
            if data.isEmpty {
                Text("No Transactions")
                    .foregroundStyle(.gray)
            } else {
                ForEach(data) { data in
                    CatChartRawDataListLine(
                        category: model.category!,
                        data: data,
                        labelType: .date,
                        model: model
                    )
                }
            }
        }
    }
    
    
    var fetchMoreButton: some View {
        Button("Fetch \(String(model.fetchYearStart - 10)) - \(String(model.fetchYearEnd - 10))", action: model.fetchMoreHistory)
            .tint(model.category!.color)
    }
}







