//
//  AnalyticChart.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/7/25.
//

import SwiftUI
import Charts

struct CatAnalyticView: View {
    @Local(\.useWholeNumbers) var useWholeNumbers
    //@Local(\.colorTheme) var colorTheme
    @State private var chartVisibleYearCount: CategoryAnalyticChartRange = .year1
    //@AppStorage("monthlyCategoryAnalyticChartVisibleYearCount") var chartVisibleYearCount: CategoryAnalyticChartRange = .year1
    @AppStorage("showAverageOnCategoryAnalyticChart") var showAverage: Bool = true
    @AppStorage("showBudgetOnCategoryAnalyticChart") var showBudget: Bool = true
    @AppStorage("showExpensesOnCategoryAnalyticChart") var showExpenses: Bool = true
    
    //@AppStorage(LocalKeys.Charts.CategoryAnalytics.displayedMetric) var displayedMetric: CategoryAnalyticChartDisplayedMetric = .expenses
    //@Environment(CalendarModel.self) private var calModel
    //@Environment(CategoryModel.self) private var catModel
        
    
    
    var isForGroup: Bool
    var category: CBCategory?
    var categoryGroup: CBCategoryGroup?
    @Binding var navPath: NavigationPath
    @Bindable var model: CatChartViewModel
    @Bindable var calModel: CalendarModel
    @Bindable var catModel: CategoryModel
    
    
    var body: some View {
        /// This has to be in a Vstack to allow the chart overlay to be visible. If not it will be cut off by the list cell.
        VStack {
            chartVisibleYearPicker
            chartHeader
            //Divider()
//            Rectangle()
//                .fill(Color(.separator))
//                .frame(height: 1)
//                .padding(.vertical, 4)
            
            CatChart(model: model)
        }        
//        .toolbar {
//            ToolbarItem(placement: .topBarLeading) {
//                CatChartRefreshButton(model: model)
//            }
//        }
        
        if model.isForGroup {
            NavigationLink {
                CatChartRawDataListForGroup(model: model)
            } label: {
                Text("Show All")
            }
        } else {
            NavigationLink {
                CatChartRawDataList(model: model)
            } label: {
                Text("Show All")
            }
        }
        
        toggleSwitchSection
    }
    
    
    var chartVisibleYearPicker: some View {
        /// Animaiton is handled inside the view model.
        Picker("", selection: $model.chartVisibleYearCount/*.animation()*/) {
            Text("1Y").tag(CategoryAnalyticChartRange.year1)
            Text("2Y").tag(CategoryAnalyticChartRange.year2)
            Text("3Y").tag(CategoryAnalyticChartRange.year3)
            Text("4Y").tag(CategoryAnalyticChartRange.year4)
            Text("5Y").tag(CategoryAnalyticChartRange.year5)
            Text("10Y").tag(CategoryAnalyticChartRange.year10)
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .onChange(of: model.chartVisibleYearCount) { model.setChartScrolledToDate($1) }
    }
    
        
    var chartHeader: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack {
                    Text(model.displayedMetric.prettyValue)
                        .contentTransition(.interpolate)
                        .foregroundStyle(.gray)
                        .font(.title3)
                        .bold()
                    
                    Spacer()
                    
                    Text("\(model.visibleTotal.currencyWithDecimals(useWholeNumbers ? 0 : 2))")
                        .contentTransition(.numericText())
                }
                                                
                
                HStack(spacing: 5) {
                    let currentYear = Calendar.current.component(.year, from: .now)
                    let years = (0..<model.chartVisibleYearCount.rawValue).map { currentYear - $0 }
                    
                    Text(String(years.last!))
                    Text("-")
                        .opacity(years.last! == currentYear ? 0 : 1)
                    Text(String(currentYear))
                        .opacity(years.last! == currentYear ? 0 : 1)
                }
                .foregroundStyle(.gray)
                .font(.caption)
            }
            
            Spacer()
        }
    }
    
    
    var toggleSwitchSection: some View {
        Section {
            Toggle("Show Budget", isOn: $showBudget.animation())
                .tint(isForGroup ? Color.theme : category!.color)
            
            Toggle("Show Average", isOn: $showAverage.animation())
                .tint(isForGroup ? Color.theme : category!.color)
                        
            Picker("Metrics", selection: $model.displayedMetric.animation()) {
                /// Filter out the budget options since we have a line dedicated to that
                ForEach(CategoryAnalyticChartDisplayedMetric.allCases.filter { $0.id != .budget }) { opt in
                    Text(opt.prettyValue)
                        .tag(opt.id)
                }
            }
            .tint(isForGroup ? .gray : category!.color)
        } header: {
            Text("Options")
        }
    }
        
    
    
    
    //func numberOfDays(_ num: Int) -> Int { (3600 * 24) * num }
}





