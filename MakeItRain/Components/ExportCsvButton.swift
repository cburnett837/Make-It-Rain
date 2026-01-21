//
//  GenerateCsvButton.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/9/25.
//

import SwiftUI


struct BreakdownExportCsvButton:  View {
    @Environment(CalendarModel.self) private var calModel
    let chartData: [ChartData]
    
    // file rows
    var rows: [[String]] {
        chartData.map {
            let budget = $0.budgetForCategory
            let expense = ($0.expenses == 0 ? 0 : $0.expenses * -1)
            let income = $0.income
            let overUnder1 = ($0.budgetForCategory) + ($0.expenses + $0.income)
            let overUnder2 = abs(overUnder1)
            
            return [$0.category.title, String(budget), String(expense), String(income), String(overUnder2)]
        }
    }
    
    var body: some View {
        ExportCsvButton(fileName: "Breakdown-\(calModel.sMonth.name)-\(calModel.sYear).csv", headers: ["Category", "Budget", "Expenses", "Income", "Variance"], rows: rows) {
            Label("Export CSV", systemImage: "tablecells")
        }
    }
    
    
}

struct ExportCsvButton<Content: View>: View {
    var fileName: String
    var headers: [String]
    var rows: [[String]]
    //var showSymbol: Bool = false
    @ViewBuilder var label: Content
    
    var body: some View {
        ShareLink(item: generateCsv()) {
            label
//            if showSymbol {
//                Label("Export CSV", systemImage: "tablecells")
//            } else {
//                Text("Export CSV")
//            }
            
            
        }
        .buttonStyle(.borderedProminent)
        .font(.subheadline)
    }
    
    func generateCsv() -> URL {
        return Helpers.generateCsv(fileName: fileName, headers: headers, rows: rows)
    }
}
