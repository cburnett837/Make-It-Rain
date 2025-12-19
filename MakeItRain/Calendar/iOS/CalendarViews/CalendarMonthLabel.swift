//
//  CalendarFakeNavHeaderMonthLabel.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/3/25.
//

import SwiftUI

struct CalendarMonthLabel: View {
    @Local(\.useWholeNumbers) var useWholeNumbers
    @Environment(\.colorScheme) var colorScheme
    @Environment(CalendarProps.self) private var calProps
    @Environment(CalendarModel.self) private var calModel
    @Environment(FuncModel.self) private var funcModel
    @Environment(PayMethodModel.self) private var payModel
    @Environment(PlaidModel.self) private var plaidModel
        
    var monthText: String {
        "\(calModel.sMonth.name)\(calModel.sMonth.year == calModel.sYear ? "" : " \(calModel.sMonth.year)")"
    }
            
    var categoryFilterTitle: String {
        let cats = calModel.sCategories
        if cats.isEmpty {
            return ""
            
        } else if cats.count == 1 {
            return cats.first!.title
            
        } else if cats.count == 2 {
            return "\(cats[0].title), \(cats[1].title)"
            
        } else {
            return "\(cats[0].title), \(cats[1].title), \(cats.count - 2)+"
        }
    }
    
    
    var isCurrentMonth: Bool {
        calModel.sMonth.actualNum == AppState.shared.todayMonth && calModel.sMonth.year == AppState.shared.todayYear
    }

    
//    var debitSum: Double {
//        let debitIDs = payModel.paymentMethods
//            .filter { $0.isDebit }
//            .filter { $0.isPermitted }
//            .filter { !$0.isHidden }
//            .map { $0.id }
//        
//        return plaidModel.balances.filter { debitIDs.contains($0.payMethodID) }.map { $0.amount }.reduce(0.0, +)
//    }
//    
//    
//    var creditSum: Double {
//        let creditIDs = payModel.paymentMethods
//            .filter { $0.isCredit }
//            .filter { $0.isPermitted }
//            .filter { !$0.isHidden }
//            .map { $0.id }
//        
//        return plaidModel.balances.filter { creditIDs.contains($0.payMethodID) }.map { $0.amount }.reduce(0.0, +)
//    }
//    
//    
//    var plaidBalance: CBPlaidBalance? {
//        plaidModel.balances
//        .filter({ $0.payMethodID == calModel.sPayMethod?.id })
//        .filter ({ bal in
//            if let meth = payModel.paymentMethods.filter({ $0.id == bal.payMethodID }).first {
//                return meth.isPermitted
//            } else {
//                return false
//            }
//        })
//        .filter ({ bal in
//            if let meth = payModel.paymentMethods.filter({ $0.id == bal.payMethodID }).first {
//                return !meth.isHidden
//            } else {
//                return false
//            }
//        })
//        .first
//    }
        
    
    var body: some View {
        //VStack(alignment: .leading, spacing: 0) {
        HStack(spacing: 0) {
            Text(monthText)
                .font(.largeTitle)
                .bold()
                .schemeBasedForegroundStyle()
                .lineLimit(1)
            
            Spacer()
            HStack(spacing: 0) {
                VStack(alignment: .trailing, spacing: 0) {
                    HStack(spacing: 2) {
                        Text("\(calModel.sPayMethod?.title ?? "All Transactions")")
                            .padding(.leading, -2)
                    }
                    .font(.callout)
                    .foregroundStyle(.gray)
                    .contentShape(Rectangle())
                    
                    if !calModel.sCategories.isEmpty {
                        selectedCategoriesView
                    }
                                        
                    if isCurrentMonth {
                        //currentBalanceView
                        if let meth = calModel.sPayMethod {
                            Text(funcModel.getPlaidBalancePrettyString(meth, useWholeNumbers: useWholeNumbers) ?? "N/A")
                                .font(.callout)
                                .foregroundStyle(.gray)
                                .lineLimit(1)
                        }
                    }
                }
//                Image(systemName: "chevron.right")
//                    .foregroundStyle(.gray)
            }
            .contentShape(.rect)
            .onTapGesture { showBalanceBreakdownAlert() }
        }
    }
    
    var selectedCategoriesView: some View {
        Text("(\(categoryFilterTitle))")
            .font(.callout)
            .foregroundStyle(.gray)
            .contentShape(Rectangle())
            .italic()
    }
    
    
//    @ViewBuilder var currentBalanceView: some View {
//        if let meth = calModel.sPayMethod {
//            if meth.isUnified {
//                if meth.isDebit {
//                    sumLine("\(funcModel.getPlaidDebitSums().currencyWithDecimals(useWholeNumbers ? 0 : 2))")
//                    
//                } else {
//                    sumLine("\(funcModel.getPlaidCreditSums().currencyWithDecimals(useWholeNumbers ? 0 : 2))")
//                }
//            } else {
//                if meth.accountType == .cash {
//                    let cashBal = calModel.calculateChecking(
//                        for: calModel.sMonth,
//                        using: calModel.sPayMethod,
//                        and: .giveMeEodAsOfToday
//                    )
//                    
//                    sumLine("\(cashBal.currencyWithDecimals(useWholeNumbers ? 0 : 2))")
//                    
//                } else if let balance = funcModel.getPlaidBalance(matching: calModel.sPayMethod) {
//                    sumLine("\(balance.amount.currencyWithDecimals(useWholeNumbers ? 0 : 2)) (\(calProps.timeSinceLastBalanceUpdate))")
//                }
//                
//            }
//        }
//    }
//    
//    @ViewBuilder func sumLine(_ text: String) -> some View {
//        Text(text)
//            .font(.callout)
//            .foregroundStyle(.gray)
//            .lineLimit(1)
//    }
    
    
    func showBalanceBreakdownAlert() {
        guard let selMeth = calModel.sPayMethod, selMeth.isUnified else { return }

        let views: Array<AlertConfig.ViewConfig> = payModel.paymentMethods
            .filter {
                $0.active
                && $0.isPermitted
                && !$0.isHidden
                && (selMeth.isUnifiedDebit ? $0.isDebit : $0.isCredit)
                && !$0.isUnified
            }
            .filter {
                switch LocalStorage.shared.paymentMethodFilterMode {
                case .all:
                    return true
                case .justPrimary:
                    return $0.holderOne?.id == AppState.shared.user?.id
                case .primaryAndSecondary:
                    return $0.holderOne?.id == AppState.shared.user?.id
                    || $0.holderTwo?.id == AppState.shared.user?.id
                    || $0.holderThree?.id == AppState.shared.user?.id
                    || $0.holderFour?.id == AppState.shared.user?.id
                }
            }
            
            .map { meth in
                let theView = HStack {
                    BusinessLogo(config: .init(
                        parent: meth,
                        fallBackType: meth.isUnified ? .gradient : .color
                    ))
                    VStack(alignment: .leading) {
                        Text(meth.title)
                        Text(funcModel.getPlaidBalancePrettyString(meth, useWholeNumbers: useWholeNumbers) ?? "N/A")
                            .foregroundStyle(.gray)
                            .font(.caption)
                    }
                    
                }
                
                return AlertConfig.ViewConfig(content: AnyView(theView))
            }
        
        let config = AlertConfig(
            title: "Accounts",
            subtitle: "These are the accounts being factored into the balance.",
            symbol: .init(name: "info.circle", color: .green),
            views: views
        )
        
        AppState.shared.showAlert(config: config)
    }
    
}
