//
//  MonthMiddleMan.swift
//  MakeItRain
//
//  Created by Cody Burnett on 12/19/25.
//


import SwiftUI
import Charts

struct CivMonthMiddleMan: View {
    @Local(\.useWholeNumbers) var useWholeNumbers
    @Environment(CalendarProps.self) private var calProps

    var monthlyData: [CivMonthlyData]
    @Binding var selectedMonth: CivMonthlyData?
    @Bindable var model: CivViewModel
    //@Binding var navPath: Array<ChildNavDestination>
    @Binding var navPath: NavigationPath
    
    var monthsThatHaveTrans: [CivMonthlyData] {
        monthlyData.filter { !$0.trans.isEmpty }
            .sorted {
                if $0.month.year != $1.month.year {
                    return $0.month.year < $1.month.year
                }
                return $0.month.actualNum < $1.month.actualNum
            }
//            .sorted(by: { $0.month.year < $1.month.year })
//            .sorted(by: { $0.month.actualNum < $1.month.actualNum })
    }
    
    var body: some View {
        Group {
            if monthlyData.filter({ !$0.trans.isEmpty }).isEmpty {
                //if getTransactions(month: monthlyData.month).isEmpty {
                ContentUnavailableView("No Transactions", systemImage: "rectangle.stack.slash.fill")
            } else {
                StandardContainerWithToolbar(.list) {
                    Section("Monetary Breakdown") {
                        Chart(monthsThatHaveTrans) { month in
                            let value = switch monthlyData.first?.dataPoint {
                            case .moneyIn:          month.breakdown.moneyIn
                            case .cashOut:          month.breakdown.cashOut
                            case .totalSpending:    month.breakdown.spending
                            case .actualSpending:   month.breakdown.actualSpending
                            case .all:              0.0
                            case nil:               0.0
                            }
                            
                            let date = Calendar.current.date(from: DateComponents(year: month.month.year, month: month.month.actualNum, day: 1))!
                            
                            LineMark(
                                x: .value("Month", date),
                                y: .value("Amount", abs(value))
                            )
                            .interpolationMethod(.cardinal)
                            .foregroundStyle(Color.theme)
                            .symbol(by: .value("Month", "month"))
                        }
                        .chartLegend(.hidden)
                        .chartXAxis { model.chartXAxis }
                    }
                    
                    
                    Section("Transaction Count") {
                        Chart(monthsThatHaveTrans) { month in
                            let date = Calendar.current.date(from: DateComponents(year: month.month.year, month: month.month.actualNum, day: 1))!
                            LineMark(
                                x: .value("Month", date),
                                y: .value("Amount", month.trans.count)
                            )
                            .interpolationMethod(.cardinal)
                            .foregroundStyle(Color.theme)
                            .symbol(by: .value("Month", "month"))
                        }
                        .chartLegend(.hidden)
                        .chartXAxis { model.chartXAxis }
                    }
                    
                    monthList
                }
            }
        }
        
        .navigationTitle(monthlyData.first?.dataPoint.titleString ?? "Unknown Data Point")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
    
    @ViewBuilder
    var monthList: some View {
        ForEach(monthsThatHaveTrans) { data in
            //Text(monthlyData.first?.dataPoint.titleString ?? "Unknown Data Point")
            //let transCount = data.trans.filter { $0.dateComponents?.month == data.month.actualNum }.count
            CivFakeNavLink {
                //Text(data.dataPoint.titleString ?? "N/A")
                line(data)
            } action: {
                selectedMonth = data
                navPath.append(CivNavDestination.transactionList)
            }
        }
    }
    
    @ViewBuilder func line(_ monthlyData: CivMonthlyData) -> some View {
        let transCount = monthlyData.trans.filter { $0.dateComponents?.month == monthlyData.month.actualNum }.count
        HStack {
            VStack(alignment: .leading) {
                Text("\(monthlyData.month.name) \(String(monthlyData.month.year))")
                
                
                switch monthlyData.dataPoint {
                case .moneyIn:
                    Text("\(monthlyData.breakdown.moneyIn.currencyWithDecimals(useWholeNumbers ? 0 : 2))")
                        .foregroundStyle(.gray)
                        .contentTransition(.numericText())
                case .cashOut:
                    Text("\(monthlyData.breakdown.cashOut.currencyWithDecimals(useWholeNumbers ? 0 : 2))")
                        .foregroundStyle(.gray)
                        .contentTransition(.numericText())
                case .totalSpending:
                    Text("\(monthlyData.breakdown.spending.currencyWithDecimals(useWholeNumbers ? 0 : 2))")
                        .foregroundStyle(.gray)
                        .contentTransition(.numericText())
                case .actualSpending:
                    Text("\(monthlyData.breakdown.actualSpending.currencyWithDecimals(useWholeNumbers ? 0 : 2))")
                        .foregroundStyle(.gray)
                        .contentTransition(.numericText())
                    
                case .all:
                    Text("N/A")
                }
            }
            Spacer()
            TextWithCircleBackground(text: "\(transCount)")
        }
    }
}
