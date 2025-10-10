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
//            .filter { $0.isAllowedToBeViewedByThisUser }
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
//            .filter { $0.isAllowedToBeViewedByThisUser }
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
//                return meth.isAllowedToBeViewedByThisUser
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
                .foregroundStyle(colorScheme == .dark ? .white : .black)
                .lineLimit(1)
            
            Spacer()
            HStack(spacing: 0) {
                VStack(alignment: .trailing, spacing: 0) {
                    HStack(spacing: 2) {
                        Text("\(calModel.sPayMethod?.title ?? "")")
                            .padding(.leading, -2)
                    }
                    .font(.callout)
                    .foregroundStyle(.gray)
                    .contentShape(Rectangle())
                    
                    if !calModel.sCategories.isEmpty {
                        selectedCategoriesView
                    }
                                        
                    if isCurrentMonth {
                        currentBalanceView
                    }
                }
//                Image(systemName: "chevron.right")
//                    .foregroundStyle(.gray)
            }
        }
    }
    
    var selectedCategoriesView: some View {
        Text("(\(categoryFilterTitle))")
            .font(.callout)
            .foregroundStyle(.gray)
            .contentShape(Rectangle())
            .italic()
    }
    
    @ViewBuilder var currentBalanceView: some View {
        if let meth = calModel.sPayMethod {
            if meth.isUnified {
                if meth.isDebit {
                    sumLine("\(funcModel.getPlaidDebitSums().currencyWithDecimals(useWholeNumbers ? 0 : 2))")
                    
                } else {
                    sumLine("\(funcModel.getPlaidCreditSums().currencyWithDecimals(useWholeNumbers ? 0 : 2))")
                }
            } else {
                if let balance = funcModel.getPlaidBalance() {
                    sumLine("\(balance.amount.currencyWithDecimals(useWholeNumbers ? 0 : 2)) (\(calProps.timeSinceLastBalanceUpdate))")
                }
            }
        }
    }
    
    @ViewBuilder func sumLine(_ text: String) -> some View {
        Text(text)
            .font(.callout)
            .foregroundStyle(.gray)
            .lineLimit(1)
    }
    
}
