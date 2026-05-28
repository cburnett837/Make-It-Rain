//
//  DashboardNetWorthChange.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/16/26.
//


import SwiftUI
import Charts

struct DashboardNetWorthChange: View {
    @Environment(CalendarModel.self) private var calModel
    @Environment(AppStore.self) private var store
    
    @State private var showAllAccounts = false
    
    var allDebitStart: CBStartingAmount? {
        calModel.sMonth.startingAmounts.filter { $0.payMethod.isUnifiedDebit }.first
    }
    
    var allCreditStart: CBStartingAmount? {
        calModel.sMonth.startingAmounts.filter { $0.payMethod.isUnifiedCredit }.first
    }
    
    var starts: Array<CBStartingAmount> {
        calModel.sMonth.startingAmounts
            .filter { $0.payMethod.isPermittedAndNotHidden }
            .filter { !$0.payMethod.isUnified }
            .filter {
                $0.payMethod.matchesFilter()
//                switch AppSettings.shared.paymentMethodFilterMode {
//                case .all:
//                    return true
//                    
//                case .justPrimary:
//                    return $0.payMethod.holderOne?.id == AppState.shared.user?.id
//                    
//                case .primaryAndSecondary:
//                    return $0.payMethod.holderOne?.id == AppState.shared.user?.id
//                    || $0.payMethod.holderTwo?.id == AppState.shared.user?.id
//                    || $0.payMethod.holderThree?.id == AppState.shared.user?.id
//                    || $0.payMethod.holderFour?.id == AppState.shared.user?.id
//                }
            }
            .sorted { Helpers.paymentMethodSorter()($0.payMethod, $1.payMethod) }
    }
    
    var allStart: Double {
        let allDebitAssets = allDebitStart?.amount ?? 0.0
        let allOtherAssets = starts.filter {
            $0.payMethod.accountType == .savings
            || [.investment, .brokerage, .k401, .crypto, .cash].contains($0.payMethod.accountType)
        }
        .map { $0.amount }
        .reduce(0.0, +)
                    
        let allCreditLiabilities = allCreditStart?.amount ?? 0.0
        let allOtherLiabilities = starts.filter {
            $0.payMethod.accountType == .loan
        }
        .map { $0.amount }
        .reduce(0.0, +)
        
        let allAssets = allDebitAssets + allOtherAssets
        let allLiabilities = allCreditLiabilities + allOtherLiabilities
        
        let networth = allAssets - allLiabilities
        return networth
//            let start = CBStartingAmount()
//            start.month = calModel.sMonth.actualNum
//            start.year = calModel.sMonth.year
//            start.amountString = String(networth)
//            start.payMethod.title = "All Accounts"
//            return start
    }
    
    var body: some View {
        Grid(alignment: .leading) {
            GridRow {
                Text("Account")
                Text("Start")
                Text("End")
                Text("Differ")
                Text("Percent")
            }
            .bold()
            
            Divider()
            
            GridRow {
                AllAccountsNetWorthChangeView(startingAmount: allStart)
            }
            //Divider()
            
            Divider()
                
            
            if let allDebitStart {
                GridRow {
                    NetWorthChangeView(startingAmount: allDebitStart)
                }
                //.padding(.top, 20)
                Divider()
            }
            
            if let allCreditStart {
                GridRow {
                    NetWorthChangeView(startingAmount: allCreditStart)
                }
                .padding(.bottom, 20)
                //Divider()
            }
                                    
            if showAllAccounts {
//                Divider()
//                    .padding(.top, 20)
                
                ForEach(starts) { star in
                    GridRow {
                        NetWorthChangeView(startingAmount: star)
                    }
                    Divider()
                }
                
            }
            
            Button(showAllAccounts ? "Hide Individual Accounts" : "Show Individual Accounts") {
                showAllAccounts.toggle()
            }
        }
        .font(.caption)
    }
            
    
    struct NetWorthChangeView: View {
        @Environment(DataChangeTriggers.self) var dataChangeTriggers
        @Environment(CalendarModel.self) private var calModel
        @Environment(AppStore.self) private var store
        
        var startingAmount: CBStartingAmount
        @State private var eom: Double = 0.0
        @State private var change: Double = 0.0
        @State private var percentage: Double = 0.0
        @State private var isBeneficial: Bool = true
        
        var body: some View {
            Group {
                HStack {
                    BusinessLogo(config: .init(
                        parent: startingAmount.payMethod,
                        fallBackType: startingAmount.payMethod.isUnified ? .gradient : .color,
                        size: 20
                    ))
                    
                    Text(startingAmount.payMethod.title)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Text(startingAmount.amount.currencyWithDecimals())
                
                Text("\(eom.currencyWithDecimals())")
                
                Text("\(change.currencyWithDecimals())")
                    .foregroundStyle(isBeneficial ? Color.red : Color.green)
                
                Text("\(percentage.decimals(1))%")
                    .foregroundStyle(isBeneficial ? Color.red : Color.green)
            }
            .task {
                calculate()
            }
            .onChange(of: DataChangeTriggers.shared.calendarDidChange) { oldValue, newValue in
                calculate()
            }
        }
        
        func calculate() {
            eom = CalcHelper.calculateTotal(for: calModel.sMonth, using: startingAmount.payMethod, and: .giveMeLastDayEod, store: store)
            let change = eom - startingAmount.amount
            self.change = abs(change)
            percentage = abs(Helpers.netWorthPercentageChange(start: startingAmount.amount, end: eom))
            
            if startingAmount.payMethod.isCreditOrLoan || startingAmount.payMethod.isUnifiedCredit {
                isBeneficial = change > 0
            } else {
                isBeneficial = change < 0
            }
        }
    }
    
    
    struct AllAccountsNetWorthChangeView: View {
        @Environment(DataChangeTriggers.self) var dataChangeTriggers
        @Environment(CalendarModel.self) private var calModel
        
        var startingAmount: Double
        @State private var eom: Double = 0.0
        @State private var change: Double = 0.0
        @State private var percentage: Double = 0.0
        @State private var isBeneficial: Bool = true
        
        var body: some View {
            Group {
                HStack {
                    let rainbowGradient = Gradient(colors: [.red, .yellow, .green, .blue, .purple, .red])
                    
                    Image(systemName: "circle.fill")
                        .font(Font.system(size: 20))
                        .imageScale(.medium)
                        .frame(width: 20, height: 20, alignment: .center)
                        .foregroundStyle(AngularGradient(gradient: rainbowGradient, center: .center))
                                        
                    Text("All Accounts")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Text(startingAmount.currencyWithDecimals())
                
                Text("\(eom.currencyWithDecimals())")
                
                Text("\(change.currencyWithDecimals())")
                    .foregroundStyle(isBeneficial ? Color.red : Color.green)
                
                Text("\(percentage.decimals(1))%")
                    .foregroundStyle(isBeneficial ? Color.red : Color.green)
            }
            .task {
                calculate()
            }
            .onChange(of: DataChangeTriggers.shared.calendarDidChange) { oldValue, newValue in
                calculate()
            }
        }
        
        
        func calculate() {
            eom = calculateBalance()
            
            let change = eom - startingAmount
            self.change = abs(change)
            percentage = abs(Helpers.netWorthPercentageChange(start: startingAmount, end: eom))
            
            if startingAmount < 0 && eom < 0 {
                isBeneficial = eom < startingAmount
            } else {
                isBeneficial = eom > startingAmount
            }
        }
        
        
        private func calculateBalance() -> Double {
            var finalEodTotal: Double = 0.0
            var currentAmount = startingAmount
            
            calModel.sMonth.days.forEach { day in
                let amounts = day.transactions
                    .filter { $0.active }
                    .filter { $0.factorInCalculations }
                    .filter { ($0.payMethod?.isPermittedAndNotHidden ?? true) }
                    .map { ($0.payMethod?.isCreditOrLoan ?? false) ? $0.amount * -1 : $0.amount }
                    //.map { $0.amount }
                
                currentAmount += amounts.reduce(0.0, +)
                if day.id == calModel.sMonth.days.last?.id {
                    finalEodTotal = currentAmount
                }
            }
            return finalEodTotal
        }
    }
}
