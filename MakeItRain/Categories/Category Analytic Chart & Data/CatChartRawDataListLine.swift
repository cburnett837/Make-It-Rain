//
//  CategoryAnalyticChartRawDataListLineItem.swift
//  MakeItRain
//
//  Created by Cody Burnett on 12/10/25.
//


import SwiftUI

struct CatChartRawDataListLine: View {
    
    @Environment(\.colorScheme) var colorScheme
    #if os(macOS)
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    #endif
    @Environment(CalendarModel.self) var calModel
    @Environment(AppStore.self) var store
    
    @Bindable var category: CBCategory
    var data: CategoryAnalyticData
    var labelType: CatChartRawDataListLineDisplayLabel
    var model: CatChartViewModel
    
    @State private var backgroundColor: Color = .clear
    
    var body: some View {
        Button {
            openMonthlySheet()
        } label: {
            switch labelType {
            case .date: dateLabel
            case .category: categoryLabel
            }
        }
        .tint(.none)
        .schemeBasedForegroundStyle()
        .background(backgroundColor)
        .onHover { backgroundColor = $0 ? .gray.opacity(0.2) : .clear }
    }
    
    
    var categoryLabel: some View {
        HStack {
            StandardCategoryLabel(cat: category, labelWidth: 30, showCheckmarkCondition: false)
            Text(model.getMetric(for: data).currencyWithDecimals())
        }
    }
    
    
    var dateLabel: some View {
        HStack {
            Text("\(data.date, format: .dateTime.month(.wide)) \(String(data.year))")
            Spacer()            
            Text(model.getMetric(for: data).currencyWithDecimals())
        }
    }
    
    
    func openMonthlySheet() {
        calModel.sPayMethodBeforeFilterWasSetByCategoryPage = calModel.sPayMethod
        calModel.sPayMethod = nil
        calModel.sCategories = [category]
        
        store.categoryFilterWasSetByCategoryPage = true
        let monthEnum = NavDest.getMonthFromInt(data.month)
        calModel.sYear = data.year
        
        #if os(iOS)
        if AppState.shared.isIpad {
            /// Block the navigation stack from trying to change to the calendar section on iPad.
            calModel.isShowingFullScreenCoverOnIpad = true
        }
        
        NavigationManager.shared.selectedMonth = monthEnum
        calModel.showMonth = true
        
        #else
        AppState.shared.monthlySheetWindowTitle = "\(category.title) Expenses For \(monthEnum?.displayName ?? "N/A") \(String(calModel.sYear))"
        dismissWindow(id: "monthlyWindow")
        openWindow(id: "monthlyWindow", value: monthEnum)
        //calModel.windowMonth = monthEnum
        //openWindow(id: "monthlyWindow")
        #endif
    }
}
