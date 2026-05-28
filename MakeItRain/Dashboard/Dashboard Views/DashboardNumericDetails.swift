//
//  DashboardNumericDetails.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/16/26.
//


import SwiftUI
import Charts

/// Not fileprivate because it is used in the navigation destination in ``CalendarViewPhone``
struct DashboardNumericDetails: View {
    @Bindable var model: DashboardModel
    var isForSelectedMonth: Bool
    //@Binding var showNumericBreakdownSheet
    
    var data: DashboardData {
        model.data
    }
    
    var body: some View {
        //NavigationStack {
            List {
                Section {
                    line(title: "Wages", value: data.debitAmounts.regularIncome)
                    line(title: "Cash Inflow", value: data.debitAmounts.irregularIncome)
//                    line(title: "Credit In", value: data.creditAmounts.irregularIncome)
                    line(title: "Total", value: (data.debitAmounts.regularIncome + data.debitAmounts.irregularIncome))
                        .bold()
                } header: {
                    Text("Income")
                } footer: {
                    Text("Wages + Cash Inflow = Total")
                }
                
                Section {
                    line(title: "Cash Outflow", value: data.debitAmounts.totalSpend)
                    line(title: "Credit Outflow", value: data.creditAmounts.totalSpend)
                    line(title: "Total", value: data.allAmounts.totalSpend)
                        .bold()
                    line(title: "Refunds & Reimbursements", value: (data.creditAmounts.irregularIncome + data.debitAmounts.irregularIncome))
                    line(title: "Total (after refunds)", value: data.allAmounts.actualSpend)
                        .bold()
                } header: {
                    Text("Spending")
                } footer: {
                    VStack(alignment: .leading) {
                        Text("Cash Outflow + Credit Outflow = Total")
                        Text("Total - Refunds & Reimbursement = Total (after refunds)")
                    }
                }
                
                Section {
                    line(title: "Outflow", value: data.creditAmounts.totalSpend)
                    line(title: "Inflow", value: data.creditAmounts.irregularIncome)
                    line(title: "Total", value: data.creditAmounts.actualSpend)
                        .bold()
                    
                    line(title: "Payments", value: data.creditAmounts.creditPayment ?? 0.0)
                    
                    line(title: "Total (after payments)", value: data.creditAmounts.actualSpendMinusPayment)
                        .bold()
                } header: {
                    Text("Credit")
                } footer: {
                    VStack(alignment: .leading) {
                        Text("Outflow - Inflow = Total")
                        Text("Total - Payments = Total (after payments)")
                    }
                    
                }
            }
            .navigationTitle("Details")
            .if(!isForSelectedMonth) {
                $0.navigationSubtitle("\(model.formattedDateRange)")
            }
//            .toolbar {
//                ToolbarItem(placement: .topBarTrailing) {
//                    Button {
//                        #if os(iOS)
//                        withAnimation {
//                            showNumericBreakdownSheet = false
//                        }
//                        #else
//                        dismiss()
//                        #endif
//                    } label: {
//                        Image(systemName: "xmark")
//                    }
//                    .tint(.none)
//                    #if os(macOS)
//                    .buttonStyle(.roundMacButton)
//                    #endif
//                }
//            }
        //}
    }
    
    @ViewBuilder
    func line(title: String, value: Double) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value.currencyWithDecimals())
                .contentTransition(.numericText())
        }
    }
}