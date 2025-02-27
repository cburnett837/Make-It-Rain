//
//  CategoryAnalysisSheet.swift
//  MakeItRain
//
//  Created by Cody Burnett on 12/26/24.
//

import SwiftUI
import Charts

struct AnalysisSheet: View {
    #if os(macOS)
    @Environment(\.dismiss) private var dismiss
    #endif
    @AppStorage("useWholeNumbers") var useWholeNumbers = false
    @Environment(CalendarModel.self) private var calModel
    @Environment(EventModel.self) private var eventModel
    @Binding var showAnalysisSheet: Bool
        
    struct CumTotal {
        var day: Int
        var total: Double
    }
    
    struct ChartData: Identifiable {
        let id = UUID().uuidString
        let category: CBCategory
        var budget: Double
        var expenses: Double
    }
    

    @State private var transactions: [CBTransaction] = []
    @State private var totalSpent: Double = 0.0
    @State private var budget: Double = 0.0
    @State private var chartData: [ChartData] = []
    
    @State private var transEditID: String?
    @State private var editTrans: CBTransaction?
    
    @State private var transDay: CBDay?
    @State private var cumTotals: [CumTotal] = []
    @State private var showCategorySheet = false
    let columnGrid = Array(repeating: GridItem(.flexible(), spacing: 0), count: 4)
    
    var showCategorySheetButton: some View {
        Button {
            showCategorySheet = true
        } label: {
            Image(systemName: "list.bullet")
        }
    }
    
    var body: some View {
        @Bindable var calModel = calModel
        VStack {
            SheetHeader(
                title: "Analyze Categories",
                close: {
                    #if os(iOS)
                    withAnimation {
                        showAnalysisSheet = false
                    }
                    #else
                    dismiss()
                    #endif
                },
                view1: { showCategorySheetButton }
            )
            .padding()
            
            Divider()
                        
            List {
                Section {
                    HStack {
                        Text("Total Items:")
                        Spacer()
                        Text("\(transactions.count)")
                    }
                    
                    HStack {
                        Text("Total Budget:")
                        Spacer()
                        Text(budget.currencyWithDecimals(useWholeNumbers ? 0 : 2))
                    }
                    
                    HStack {
                        Text("Total Expenses:")
                        Spacer()
                        Text((totalSpent * -1).currencyWithDecimals(useWholeNumbers ? 0 : 2))
                    }
                    
                    HStack {
                        Text("Over/Under:")
                        Spacer()
                        Text((budget - (totalSpent * -1)).currencyWithDecimals(useWholeNumbers ? 0 : 2))
                            .foregroundStyle(budget - (totalSpent * -1) < 0 ? .red : .green)
                    }
                    
                    chartSection
                } header: {
                    Text("Details")
                }
                                                
                Section {
                    LazyVGrid(columns: columnGrid, alignment: .leading, spacing: 10) {
                        Text("Category")
                        Text("Budget")
                        Text("Expenses")
                        Text("Over/Under")
                    }
                    .font(.caption2)
                    
                    ForEach(chartData) { metric in
                        LazyVGrid(columns: columnGrid, alignment: .leading, spacing: 10) {
                            HStack(alignment: .circleAndTitle, spacing: 5) {
                                Circle()
                                    .fill(metric.category.color)
                                    .frame(maxWidth: 8, maxHeight: 8) // 8 seems to be the default from charts
                                    .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
                                
                                
                                Text(metric.category.title)
                                    .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
                            }
                            
                            Text(metric.budget.currencyWithDecimals(2))
                            Text((metric.expenses * -1).currencyWithDecimals(2))
                            let overUnder = metric.budget + (metric.expenses)
                            
                            Text(abs(overUnder).currencyWithDecimals(useWholeNumbers ? 0 : 2))
                                .foregroundStyle(overUnder < 0 ? .red : .green)
                        }
                        .font(.caption2)
                    }
                } header: {
                    Text("Breakdown")
                }
                
                
                                    
                ForEach(calModel.sMonth.days) { day in
                    let doesHaveTransactions = transactions
                        .filter { $0.dateComponents?.day == day.date?.day }
                        .count > 0
                    
                    let dailyTotal = transactions
                        .filter { $0.dateComponents?.day == day.date?.day }
                        .map { $0.payMethod?.accountType == .credit ? $0.amount * -1 : $0.amount }
                        .reduce(0.0, +)
                    
                    let dailyCount = transactions
                        .filter { $0.dateComponents?.day == day.date?.day }
                        .count
                    
                    
                    if day.date?.day == AppState.shared.todayDay && day.date?.month == AppState.shared.todayMonth && day.date?.year == AppState.shared.todayYear {
                        Section {
                            if doesHaveTransactions {
                                ForEach(transactions.filter { $0.dateComponents?.day == day.date?.day }) { trans in
                                    TransactionListLine(trans: trans)
                                        .onTapGesture {
                                            self.transDay = day
                                            self.transEditID = trans.id
                                        }
                                }
                            } else {
                                EmptyView()
                            }
                        } header: {
                            HStack {
                                Text("TODAY")
                                    .foregroundStyle(.green)
                                VStack {
                                    Divider()
                                        .overlay(.green)
                                }
                            }
                        } footer: {
                            if doesHaveTransactions {
                                SectionFooter(day: day, dailyCount: dailyCount, dailyTotal: dailyTotal, cumTotals: cumTotals)
                            }
                        }
                    } else {
                        if doesHaveTransactions {
                            Section {
                                ForEach(transactions.filter { $0.dateComponents?.day == day.date?.day }) { trans in
                                    TransactionListLine(trans: trans)
                                        .onTapGesture {
                                            self.transDay = day
                                            self.transEditID = trans.id
                                        }
                                }
                            } header: {
                                Text(day.date?.string(to: .monthDayShortYear) ?? "")
                            } footer: {
                                SectionFooter(day: day, dailyCount: dailyCount, dailyTotal: dailyTotal, cumTotals: cumTotals)
                            }
                        }
                    }
                }
            }
        }
        .task {
            if calModel.sCategoriesForAnalysis.isEmpty {
                showCategorySheet = true
            } else {
                prepareData()
                //analyzeTransactions()
            }
        }
        .sheet(isPresented: $showCategorySheet, onDismiss: {
            //analyzeTransactions()
        }, content: {
            MultiCategorySheet(categories: $calModel.sCategoriesForAnalysis)
            #if os(macOS)
                .frame(minWidth: 300, minHeight: 500)
                .presentationSizing(.fitted)
            #endif
            //CategorySheet(category: $calModel.sCategory)
        })
        .onChange(of: showCategorySheet) { oldValue, newValue in
            if newValue == false {
                prepareData()
                //analyzeTransactions()
            }
        }
        
        .sheet(item: $editTrans) { trans in
            TransactionEditView(trans: trans, transEditID: $transEditID, day: transDay!, isTemp: false)
                .onDisappear { transEditID = nil }
        }
        .onChange(of: transEditID, { oldValue, newValue in
            print(".onChange(of: CategoryAnalysisSheet.transEditID)")
            /// When `newValue` is false, save to the server. We have to use this because `.popover(isPresented:)` has no onDismiss option.
            if oldValue != nil && newValue == nil {
                calModel.saveTransaction(id: oldValue!, day: transDay!, eventModel: eventModel)
                transDay = nil
                calModel.pictureTransactionID = nil
            } else {
                editTrans = calModel.getTransaction(by: transEditID!, from: .normalList)
            }
        })        
        .sensoryFeedback(.selection, trigger: transEditID) { $1 != nil }
    }
    
    
    struct SectionFooter: View {
        @AppStorage("useWholeNumbers") var useWholeNumbers = false
        var day: CBDay
        var dailyCount: Int
        var dailyTotal: Double
        var cumTotals: [CumTotal]
                
        var body: some View {
            HStack {
                Text("Cumulative Total: \((cumTotals.filter { $0.day == day.date!.day }.first?.total ?? 0.0).currencyWithDecimals(useWholeNumbers ? 0 : 2))")
                
                Spacer()
                if dailyCount > 1 {
                    Text(dailyTotal.currencyWithDecimals(useWholeNumbers ? 0 : 2))
                }
            }
        }
    }
        
    
    
    
    var chartSection: some View {
        Group {
            
            VStack {
                Chart(chartData) { metric in
                    BarMark(
                        x: .value("Amount", metric.budget),
                        y: .value("Key", "Budget")
                    )
                    .foregroundStyle(metric.category.color)
//                    .annotation(position: .overlay, alignment: .center) {
//                        HStack {
//                            Text(metric.budget.currencyWithDecimals(useWholeNumbers ? 0 : 2))
//                                .font(.caption2)
//                            Spacer()
//                        }
//                    }
                    
                    BarMark(
                        x: .value("Amount", metric.expenses * -1),
                        y: .value("Key", "Expenses")
                    )
                    .foregroundStyle(metric.category.color)
//                    .annotation(position: .overlay, alignment: .center) {
//                        HStack {
//                            Text(metric.expenses.currencyWithDecimals(useWholeNumbers ? 0 : 2))
//                                .font(.caption2)
//
//                            Spacer()
//                        }
//                    }
                }
                .chartLegend(.hidden)
                
                
                
                
                ScrollView(.horizontal) {
                    ZStack {
                        Spacer()
                            .containerRelativeFrame([.horizontal])
                            .frame(height: 1)
                                                    
                        HStack(spacing: 0) {
                            ForEach(chartData) { item in
                                HStack(alignment: .circleAndTitle, spacing: 5) {
                                    Circle()
                                        .fill(item.category.color)
                                        .frame(maxWidth: 8, maxHeight: 8) // 8 seems to be the default from charts
                                        .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.category.title)
                                            .foregroundStyle(Color.secondary)
                                            .font(.caption2)
                                            .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
//
//                                        Text(item.expenses.currencyWithDecimals(2))
//                                            .foregroundStyle(Color.secondary)
//                                            .font(.caption2)
                                    }
                                }
                                .padding(.horizontal, 4)
                                .contentShape(Rectangle())
    //                            #if os(macOS)
    //                            .onContinuousHover { phase in
    //                                switch phase {
    //                                case .active:
    //                                    selectedBudget = item.category.title
    //                                case .ended:
    //                                    selectedBudget = nil
    //                                }
    //                            }
    //                            #endif
                            }
                            Spacer()
                        }
                    }
                }
                .scrollBounceBehavior(.basedOnSize)
                .contentMargins(.bottom, 10, for: .scrollContent)
                
                
            }
            
                                        
        }
            
        
    }
    
    func graphColors(for data: [ChartData]) -> [Color] {
        var returnColors = [Color]()
        for metric in data {
            returnColors.append(metric.category.color)
        }
        return returnColors
    }
    
    
    func prepareData() {
        transactions = calModel.justTransactions
            .filter { calModel.sCategoriesForAnalysis.map{ $0.id }.contains($0.category?.id) }
            .filter { $0.dateComponents?.month == calModel.sMonth.actualNum }
            .filter { $0.dateComponents?.year == calModel.sMonth.year }
            .sorted { $0.dateComponents?.day ?? 0 < $1.dateComponents?.day ?? 0 }
        
        totalSpent = transactions
            .map { $0.payMethod?.accountType == .credit ? $0.amount * -1 : $0.amount }
            .reduce(0.0, +)
        
        budget = calModel.justBudgets
            .filter { $0.month == calModel.sMonth.actualNum }
            .filter { $0.year == calModel.sMonth.year }
            .filter { calModel.sCategoriesForAnalysis.map{ $0.id }.contains($0.category?.id) }
            .map { $0.amount }
            .reduce(0.0, +)
        
        chartData = calModel.sCategoriesForAnalysis.map { cat in
            let budget = calModel.justBudgets
                .filter { $0.month == calModel.sMonth.actualNum && $0.year == calModel.sMonth.year && $0.category?.id == cat.id }
                .first?
                .amount ?? 0.0
            
           let expenses = calModel.justTransactions
                .filter {
                    calModel.sCategoriesForAnalysis.map{ $0.id }.contains($0.category?.id)
                    && $0.dateComponents?.month == calModel.sMonth.actualNum
                    && $0.dateComponents?.year == calModel.sMonth.year
                    && $0.category?.id == cat.id
                }
                .sorted { $0.dateComponents?.day ?? 0 < $1.dateComponents?.day ?? 0 }
                .map { $0.payMethod?.accountType == .credit ? $0.amount * -1 : $0.amount }
                .reduce(0.0, +)
            
            return ChartData(category: cat, budget: budget, expenses: expenses)
            
        }
        
        /// Analyze Data
        cumTotals.removeAll()
        
        var total: Double = 0.0
        calModel.sMonth.days.forEach { day in
            let doesHaveTransactions = !transactions.filter { $0.dateComponents?.day == day.date?.day }.isEmpty
            let dailyTotal = transactions
                .filter { $0.dateComponents?.day == day.date?.day }
                .map { $0.payMethod?.accountType == .credit ? $0.amount * -1 : $0.amount }
                .reduce(0.0, +)
            
            
            if doesHaveTransactions {
                total += dailyTotal
                cumTotals.append(CumTotal(day: day.date!.day, total: total))
            }

        }
    }
    
//    func analyzeTransactions() {
//        cumTotals.removeAll()
//        
//        var total: Double = 0.0
//        calModel.sMonth.days.forEach { day in
//            let doesHaveTransactions = !transactions.filter { $0.dateComponents?.day == day.date?.day }.isEmpty
//            let dailyTotal = transactions
//                .filter { $0.dateComponents?.day == day.date?.day }
//                .map { $0.payMethod?.accountType == .credit ? $0.amount * -1 : $0.amount }
//                .reduce(0.0, +)
//            
//            
//            if doesHaveTransactions {
//                total += dailyTotal
//                cumTotals.append(CumTotal(day: day.date!.day, total: total))
//            }
//
//        }
//    }
    
    
}
