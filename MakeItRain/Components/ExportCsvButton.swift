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
            let budget = $0.budget
            let expense = ($0.expenses == 0 ? 0 : $0.expenses * -1)
            let income = ($0.income)
            let overUnder1 = $0.budget + ($0.expenses + $0.income)
            let overUnder2 = abs(overUnder1)
            
            return [$0.category.title, String(budget), String(expense), String(income), String(overUnder2)]
        }
    }
    
    var body: some View {
        ExportCsvButton(fileName: "Breakdown-\(calModel.sMonth.name)-\(calModel.sYear).csv", headers: ["Category", "Budget", "Expenses", "Income", "Variance"], rows: rows)
    }
    
    
}

struct ExportCsvButton: View {
    var fileName: String
    var headers: [String]
    var rows: [[String]]
    var body: some View {
        ShareLink(item: generateCsv()) {
            Text("Export CSV")
            //Label("Export CSV", systemImage: "tablecells")
        }
        .buttonStyle(.borderedProminent)
        .font(.subheadline)
    }
    
    func generateCsv() -> URL {
        return Helpers.generateCsv(fileName: fileName, headers: headers, rows: rows)
    }
}
