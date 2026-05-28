//
//  DashboardActivityByCategoryChart.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/16/26.
//


import SwiftUI
import Charts

struct DashboardActivityByCategoryChart: View {
    enum Tabs: String { case bar, pie, guage }
    @AppStorage("dashboardSelectedChartPageTabThing") var selectedTab: Tabs = .bar
    @Environment(CalendarModel.self) private var calModel
    @Environment(AppStore.self) private var store
    
    @Bindable var model: DashboardModel
    @Bindable var data: DashboardData
    var isForSelectedMonth: Bool
    
    @State private var selectedCategory: CBCategory?
    
    //let columnGrid = Array(repeating: GridItem(.flexible(), spacing: 0, alignment: .top), count: 6)
    
    enum ChartRow: String {
        case budget = "Budget"
        case spending = "Spending"
        case income = "Money In"
    }
    
    var amount: Double {
        data.categoryAndGroupBudget - (model.shouldUseTotalSpending ? data.allAmounts.totalSpend : data.allAmounts.actualSpend)
    }
    
    var isOver: Bool { amount < 0 }
    var overUnder: String { abs(amount).currencyWithDecimals() }
    
    var message: AttributedString {
        let leftovers = calculateLeftovers()
        let spendingAmount = model.shouldUseTotalSpending ? data.allAmounts.totalSpend : data.allAmounts.actualSpend
        
        return AttributedString.build {
            if isForSelectedMonth {
                "Your cash flow \(leftovers.1 ? "increased by" : "decreased by") "
                
                "\(leftovers.0)"
                    .foreground(leftovers.1 ? .green : .red)
                
                ", and you are currently "
            } else {
                "You are currently "
            }
            
            overUnder
                .foreground(isOver ? .red : .green)

            " \(isOver ? "over" : "under") your budget of "
            "\(data.categoryAndGroupBudget.currencyWithDecimals()), having spent "

            spendingAmount
                .currencyWithDecimals()
                .bold()
            "."
        }
    }
    
    
    func calculateLeftovers() -> (String, Bool) {
        var amount: Double = 0.0
        if let start = calModel.sMonth.startingAmounts.filter({ $0.payMethod.isUnifiedDebit }).first {
            let eom = CalcHelper.calculateTotal(for: calModel.sMonth, using: start.payMethod, and: .giveMeLastDayEod, store: store)
            let change = eom - start.amount
            amount = change
                        
            if start.payMethod.isCreditOrLoan || start.payMethod.isUnifiedCredit {
                return (abs(amount).currencyWithDecimals(), change < 0)
            } else {
                return (abs(amount).currencyWithDecimals(), change > 0)
            }
        } else {
            return ((0.0).currencyWithDecimals(), false)
        }
    }
    
    
    var body: some View {
        VStack {
            Text(message)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 10)
            
            Divider()
            
            TabView(selection: $selectedTab) {
                Tab(value: Tabs.bar) {
                    VStack {
                        DashboardActivityByCategoryBarChart(model: model, data: data, selectedCategory: $selectedCategory)
                        Spacer()
                    }
                } label: {
                    Image(systemName: "chart.bar.yaxis")
                }
                
                Tab(value: Tabs.pie) {
                    VStack {
                        DashboardActivityByCategoryPieChart(model: model, data: data, selectedCategory: $selectedCategory)
                        Spacer()
                    }
                } label: {
                    Image(systemName: "chart.pie")
                }
            }
            .frame(height: 200)
            .tabViewStyle(.page)
            .padding(.bottom, -20) /// Remove the padding under the page indicators
            .overlay(alignment: .top) {
                if let category = selectedCategory {
                    DashboardActivityByCategoryAnnotation(category: category)
                }
            }
            /// Tab indicators don't show in light mode.
            .onAppear {
                UIPageControl.appearance().currentPageIndicatorTintColor = UIColor.label
                UIPageControl.appearance().pageIndicatorTintColor = UIColor.secondaryLabel.withAlphaComponent(0.35)
            }
        }
    }
}
