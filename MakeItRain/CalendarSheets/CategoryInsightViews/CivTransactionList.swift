//
//  TransactionList.swift
//  MakeItRain
//
//  Created by Cody Burnett on 12/19/25.
//


import SwiftUI
import Charts

struct CivTransactionList: View {
    @AppStorage("transactionListDisplayMode") var transactionListDisplayMode: TransactionListDisplayMode = .condensed
    @AppStorage("transactionListDisplayModeShowEmptyDaysInFull") var transactionListDisplayModeShowEmptyDaysInFull: Bool = false
    
    @Local(\.transactionSortMode) var transactionSortMode
    @Local(\.categorySortMode) var categorySortMode
    @Local(\.useWholeNumbers) var useWholeNumbers
    
    @Environment(CalendarModel.self) private var calModel
    
    @Bindable var data: CivMonthlyData
    @Bindable var model: CivViewModel
        
    @State private var transEditID: String?
    @State private var transDay: CBDay?
    @State private var searchText = ""


    var body: some View {
        theView
            .searchable(text: $searchText, prompt: Text("Search"))
            .navigationTitle("\(data.dataPoint.titleString)")
            .navigationSubtitle("\(data.month.name) \(String(data.month.year))")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { viewModeMenu }
            }
            .transactionEditSheetAndLogic(transEditID: $transEditID, selectedDay: $transDay)
    }
    
    @ViewBuilder
    var theView: some View {
        if data.trans.isEmpty {
        //if getTransactions(month: data.month).isEmpty {
            ContentUnavailableView("No Transactions", systemImage: "rectangle.stack.slash.fill")
        } else {
            StandardContainerWithToolbar(.list) {
                Section("Breakdown") {
                    
                    switch data.dataPoint {
                    case .moneyIn:
                        breakdownLine(title: "Money In…", value: data.breakdown.moneyIn)
                    case .cashOut:
                        breakdownLine(title: "Cash out…", value: data.breakdown.cashOut * -1)
                    case .totalSpending:
                        breakdownLine(title: "Total spending…", value: data.breakdown.spending * -1)
                    case .actualSpending:
                        breakdownLine(title: "Actual spending…", value: data.breakdown.actualSpending * -1)
                            .bold()
                    case .all:
                        breakdownLine(title: "Money In…", value: data.breakdown.moneyIn)
                        breakdownLine(title: "Cash out…", value: data.breakdown.cashOut * -1)
                        breakdownLine(title: "Total spending…", value: data.breakdown.spending * -1)
                        breakdownLine(title: "Actual spending…", value: data.breakdown.actualSpending * -1)
                            .bold()
                    }                                        
                }
                
                switch transactionListDisplayMode {
                case .full:
                    fullView(for: data.month)
                case .condensed:
                    condensedView(for: data.month)
                }
            }
        }
    }
    
    
    @ViewBuilder
    func breakdownLine(title: String, value: Double) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text("\(value.currencyWithDecimals(useWholeNumbers ? 0 : 2))")
                //.foregroundStyle(.gray)
        }
    }
    
    
    var viewModeMenu: some View {
        Menu {
            Section("Display Mode") {
                ForEach(TransactionListDisplayMode.allCases, id: \.self) { opt in
                    Button {
                        withAnimation {
                            transactionListDisplayMode = opt
                        }
                        
                    } label: {
                        HStack {
                            Text(opt.prettyValue)
                            Spacer()
                            if opt == transactionListDisplayMode {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    
                    if opt == .full && transactionListDisplayMode == .full {
                        Menu("Show empty days") {
                            emptyDayButton(show: true)
                            emptyDayButton(show: false)
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "line.3.horizontal")
                .schemeBasedForegroundStyle()
        }
    }
    
    
    @ViewBuilder
    func emptyDayButton(show: Bool) -> some View {
        Button {
            withAnimation {
                transactionListDisplayModeShowEmptyDaysInFull = show
            }
        } label: {
            HStack {
                Text(show ? "Yes" : "No")
                Spacer()
                if transactionListDisplayModeShowEmptyDaysInFull == show {
                    Image(systemName: "checkmark")
                }
            }
        }
    }
    
    
    @ViewBuilder
    func fullView(for month: CBMonth) -> some View {
        ForEach(month.legitDays) { day in
            let trans = getTransactions(month: month, day: day)
            let doesHaveTransactions = !trans.isEmpty
            
            if transactionListDisplayModeShowEmptyDaysInFull {
                theSection(day: day, trans: trans) {
                    if doesHaveTransactions {
                        transLoop(trans: trans)
                    } else {
                        Text("No Transactions")
                            .foregroundStyle(.gray)
                    }
                }
            } else {
                if doesHaveTransactions {
                    theSection(day: day, trans: trans) {
                        transLoop(trans: trans)
                    }
                }
            }
        }
    }
    
    
    @ViewBuilder
    func condensedView(for month: CBMonth) -> some View {
        let trans = getTransactions(month: month)
        transLoop(trans: trans)
    }
    
    
    @ViewBuilder
    func transLoop(trans: Array<CBTransaction>) -> some View {
        ForEach(trans) { trans in
            TransactionListLine(trans: trans, withDate: transactionListDisplayMode == .condensed)
                .onTapGesture {
                    let day = data.month.days.filter { $0.id == trans.dateComponents?.day }.first
                    self.transDay = day
                    self.transEditID = trans.id
                }
        }
    }
    
    
    @ViewBuilder
    func theSection(day: CBDay, trans: Array<CBTransaction>, @ViewBuilder content: () -> some View) -> some View {
        let doesHaveTransactions = !trans.isEmpty
        let dailyTotal = trans
            .map { ($0.payMethod?.isCreditOrLoan ?? false) ? $0.amount * -1 : $0.amount }
            .reduce(0.0, +)

        Section {
            content()
        } header: {
            if let date = day.date, date.isToday {
                todayIndicatorLine
            } else {
                Text(day.date?.string(to: .monthDayShortYear) ?? "")
            }
            
        } footer: {
            if doesHaveTransactions {
                sectionFooter(day: day, dailyCount: trans.count, dailyTotal: dailyTotal)
            }
        }
    }
    
    
    var todayIndicatorLine: some View {
        HStack {
            Text("TODAY")
                .foregroundStyle(Color.theme)
            VStack {
                Divider()
                    .overlay(Color.theme)
            }
        }
    }
    
    
    @ViewBuilder
    func sectionFooter(day: CBDay, dailyCount: Int, dailyTotal: Double) -> some View {
        HStack {
//            Text("Cumulative Total: \((model.cumTotals.filter { $0.day == day.date!.day }.first?.total ?? 0.0).currencyWithDecimals(useWholeNumbers ? 0 : 2))")
//            
            Spacer()
            if dailyCount > 1 {
                Text(dailyTotal.currencyWithDecimals(useWholeNumbers ? 0 : 2))
            }
        }
    }
    
    
    func getTransactions(month: CBMonth, day: CBDay? = nil) -> Array<CBTransaction> {
        data.trans
            .filter { searchText.isEmpty ? true : $0.title.localizedCaseInsensitiveContains(searchText) }
            .filter { transaction in
                guard
                    let comps = transaction.dateComponents,
                    comps.month == month.actualNum,
                    comps.year == month.year
                else { return false }

                // If a specific day is provided, it must match.
                if let day = day?.id {
                    return comps.day == day
                }

                // Otherwise, ignore the day.
                return true
            }
            .sorted {
                if transactionListDisplayMode == .full {
                    if transactionSortMode == .title {
                        return $0.title < $1.title
                        
                    } else if transactionSortMode == .enteredDate {
                        return $0.enteredDate < $1.enteredDate
                        
                    } else {
                        if categorySortMode == .title {
                            return ($0.category?.title ?? "").lowercased() < ($1.category?.title ?? "").lowercased()
                        } else {
                            return $0.category?.listOrder ?? 10000000000 < $1.category?.listOrder ?? 10000000000
                        }
                    }
                } else {
                    return $0.date ?? Date() < $1.date ?? Date()
                }
                
            }
    }
}
