//
//  DashboardDetailSection.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/16/26.
//


import SwiftUI
import Charts

struct DashboardDetailSection: View {
    @Bindable var model: DashboardModel
    @Bindable var data: DashboardData
        
    var body: some View {
        DashboardWidget(showFilterText: !model.allCatsSelected, title: "Details") {
            NavigationLink(value: NavDest.dashboardNumericBreakdown) {
                HStack {
                    Grid(alignment: .leading) {
                        GridRow {
                            Text("Spending")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .lineLimit(1)
                            
                            if model.payMethod?.isDebitOrUnified ?? true {
                                Text("Income")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .lineLimit(1)
                            }
                            
                            if model.payMethod?.isCreditOrUnified ?? true {
                                Text("Credit Payments")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .lineLimit(1)
                            }
                            
                        }
                        .bold()
                        
                        Divider()
                        
                        GridRow {
                            Text((model.shouldUseTotalSpending ? data.allAmounts.totalSpend : data.allAmounts.actualSpend).currencyWithDecimals())
                                .contentTransition(.numericText())
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .lineLimit(1)
                                .bold()
                            
                            if model.payMethod?.isDebitOrUnified ?? true {
                                Text((data.debitAmounts.regularIncome + data.debitAmounts.irregularIncome).currencyWithDecimals())
                                    .contentTransition(.numericText())
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .lineLimit(1)
                            }
                            
                            if model.payMethod?.isCreditOrUnified ?? true {
                                Text((data.creditAmounts.creditPayment ?? 0.0).currencyWithDecimals())
                                    .contentTransition(.numericText())
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .lineLimit(1)
                            }
                        }
                    }
                    .font(.caption)
                    .frame(maxWidth: .infinity)
                    
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.tertiary)
                        .font(.footnote)
                }
                
            }
            .schemeBasedForegroundStyle()
        }
    }
}
