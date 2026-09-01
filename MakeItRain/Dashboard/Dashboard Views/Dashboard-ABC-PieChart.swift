//
//  DashboardActivityByCategoryPieChart.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/16/26.
//


import SwiftUI
import Charts

struct DashboardActivityByCategoryPieChart: View {
    @Environment(CalendarModel.self) private var calModel
    @Bindable var model: DashboardModel
    @Bindable var data: DashboardData
    @Binding var selectedCategory: CBCategory?
    
    @State private var rawSelectedExpenseAngle: Decimal?
    @State private var rawSelectedIncomeAngle: Decimal?
    
    var body: some View {
        HStack {
            expensePieChart
            Spacer()
            incomePieChart
        }
        .sensoryFeedback(.selection, trigger: selectedCategory)
    }
    
    var expensePieChart: some View {
        Chart {
            if model.expenseCategories.isEmpty {
                dummySectorMark
            } else {
                ForEach(model.expenseCategories) { cat in
                    SectorMark(
                        angle: .value("Amount", max(0, (model.shouldUseTotalSpending ? cat.allAmounts?.totalSpend ?? 0 : cat.allAmounts?.actualSpend ?? 0))),
                        innerRadius: .ratio(0.6),
                        angularInset: 1.0
                    )
                    .cornerRadius(5)
                    .foregroundStyle(cat.color)
                    .opacity(selectedCategory == nil ? 1 : (cat.id == selectedCategory?.id ? 1 : 0.3))
                }
            }
        }
        //.chartBackground { donutLabel($0, "Spending") }
        .chartBackground {
            let text1 = model.expenseCategories.isEmpty ? "No Spending" : "Spending"
            let text2 = model.expenseCategories.isEmpty
            ? nil
            : (model.shouldUseTotalSpending ? data.allAmounts.totalSpend : data.allAmounts.actualSpend).currencyWithDecimals()
            
            donutLabel($0, text1, text2)
        }
        .chartAngleSelection(value: $rawSelectedExpenseAngle)
        //.frame(width: 150, height: 150)
        .frame(height: 150)
        .onChange(of: rawSelectedExpenseAngle) {
            updateSelectedCategoryFromExpensePie()
        }
    }
            
    
    @ViewBuilder
    var incomePieChart: some View {
        Chart {
            if model.incomeCategories.isEmpty {
                dummySectorMark
            } else {
                ForEach(model.incomeCategories) { cat in
                    SectorMark(
                        angle: .value("Amount", max(0, DashboardUtils.incomeAmount(for: cat))),
                        innerRadius: .ratio(0.6),
                        angularInset: 1.0
                    )
                    .cornerRadius(5)
                    .foregroundStyle(cat.color)
                    .opacity(selectedCategory == nil ? 1 : (cat.id == selectedCategory?.id ? 1 : 0.3))
                }
            }
            
        }
        .chartBackground {
            let text1 = model.incomeCategories.isEmpty ? "No Income" : "Income"
            let text2 = model.incomeCategories.isEmpty
            ? nil
            : (data.debitAmounts.regularIncome + data.debitAmounts.irregularIncome).currencyWithDecimals()
            donutLabel($0, text1, text2)
        }
        .chartAngleSelection(value: $rawSelectedIncomeAngle)
        //.frame(width: 150, height: 150)
        .frame(height: 150)
        .onChange(of: rawSelectedIncomeAngle) {
            updateSelectedCategoryFromIncomePie()
        }
    }

    
    @ChartContentBuilder
    var dummySectorMark: some ChartContent {
        SectorMark(
            angle: .value("Amount", 100),
            innerRadius: .ratio(0.6),
            angularInset: 1.0
        )
        .cornerRadius(5)
        .foregroundStyle(Color.secondary.opacity(0.1))
    }
    
    
    @ViewBuilder
    func donutLabel(_ chartProxy: ChartProxy, _ text1: String, _ text2: String? = nil) -> some View {
        GeometryReader { geometry in
            if let anchor = chartProxy.plotFrame {
                let frame = geometry[anchor]
                VStack {
                    Text(text1)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    
                    if let text2 = text2 {
                        Text(text2)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }
                }
                .contentTransition(.numericText())
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .position(x: frame.midX, y: frame.midY)
            }
        }
    }
    
    
    func updateSelectedCategoryFromExpensePie() {
        guard let rawSelectedExpenseAngle else {
            selectedCategory = nil
            return
        }
        
        selectedCategory = DashboardUtils.categoryOwningXRange(
            selectedXAmount: rawSelectedExpenseAngle,
            categories: model.expenseCategories
        ) { cat in
            max(Decimal(0), (model.shouldUseTotalSpending ? cat.allAmounts?.totalSpend ?? 0 : cat.allAmounts?.actualSpend ?? 0))
        }
    }
    
    
    func updateSelectedCategoryFromIncomePie() {
        guard let rawSelectedIncomeAngle else {
            selectedCategory = nil
            return
        }
        
        selectedCategory = DashboardUtils.categoryOwningXRange(
            selectedXAmount: rawSelectedIncomeAngle,
            categories: model.incomeCategories
        ) { cat in
            max(Decimal(0), DashboardUtils.incomeAmount(for: cat))
        }
    }
}
