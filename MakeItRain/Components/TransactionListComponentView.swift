////
////  TransactionListComponentView.swift
////  MakeItRain
////
////  Created by Cody Burnett on 9/27/25.
////
//
//import SwiftUI
//
//struct CumTotal {
//    var day: Int
//    var total: Double
//}
//
//struct TransactionListComponentView/*<Content: View>*/: View {
//    @AppStorage("transactionSortMode") var transactionSortMode: TransactionSortMode = .title
//    @AppStorage("categorySortMode") var categorySortMode: CategorySortMode = .title
//    
//    @Local(\.colorTheme) var colorTheme
//    @Environment(CalendarModel.self) private var calModel
//    var transactions: [CBTransaction]
//    
//    @Binding var transEditID: String?
//    @Binding var editTrans: CBTransaction?
//    @Binding var transDay: CBDay
//    var footerLeadingText: String
//    var footerLeadingTextColor: Color
//    //@ViewBuilder var sectionFooter: Content
//    
//    var body: some View {
//        ForEach(calModel.sMonth.days.filter { $0.date != nil }) { day in
//            let doesHaveTransactions = transactions
//                .filter { $0.dateComponents?.day == day.date?.day }
//                .count > 0
//            
//            let dailyTotal = transactions
//                .filter { $0.dateComponents?.day == day.date?.day }
//                .map { $0.payMethod?.accountType == .credit ? $0.amount * -1 : $0.amount }
//                .reduce(0.0, +)
//            
//            let dailyCount = transactions
//                .filter { $0.dateComponents?.day == day.date?.day }
//                .count
//                                                
//            Section {
//                if doesHaveTransactions {
//                    ForEach(getTransactions(for: day)) { trans in
//                        TransactionListLine(trans: trans)
//                            .onTapGesture {
//                                self.transDay = day
//                                self.transEditID = trans.id
//                            }
//                    }
//                } else {
//                    Text("No Transactions")
//                        .foregroundStyle(.gray)
//                }
//            } header: {
//                if let date = day.date, date.isToday {
//                    HStack {
//                        Text("TODAY")
//                            .foregroundStyle(Color.fromName(colorTheme))
//                        VStack {
//                            Divider()
//                                .overlay(Color.fromName(colorTheme))
//                        }
//                    }
//                } else {
//                    Text(day.date?.string(to: .monthDayShortYear) ?? "")
//                }
//                
//            } footer: {
//                if doesHaveTransactions {
//                    //sectionFooter
//                    TransactionListComponentViewSectionFooter(
//                        dailyCount: dailyCount,
//                        dailyTotal: dailyTotal,
//                        leadingText: footerLeadingText,
//                        leadingTextColor: footerLeadingTextColor
//                    )
//                    //SectionFooter(day: day, dailyCount: dailyCount, dailyTotal: dailyTotal, cumTotals: cumTotals)
//                }
//            }
//        }
//    }
//    
//    func getTransactions(for day: CBDay) -> Array<CBTransaction> {
//        transactions
//            .filter { $0.dateComponents?.day == day.date?.day }
//            .filter { ($0.payMethod?.isAllowedToBeViewedByThisUser ?? true) }
//            .filter { !($0.payMethod?.isHidden ?? false) }
//            .sorted {
//                if transactionSortMode == .title {
//                    return $0.title < $1.title
//                    
//                } else if transactionSortMode == .enteredDate {
//                    return $0.enteredDate < $1.enteredDate
//                    
//                } else {
//                    if categorySortMode == .title {
//                        return ($0.category?.title ?? "").lowercased() < ($1.category?.title ?? "").lowercased()
//                    } else {
//                        return $0.category?.listOrder ?? 10000000000 < $1.category?.listOrder ?? 10000000000
//                    }
//                }
//            }
//    }
//}
//
//
//
//struct TransactionListComponentViewSectionFooter: View {
//    @Local(\.useWholeNumbers) var useWholeNumbers
//    var dailyCount: Int
//    var dailyTotal: Double
//    var leadingText: String
//    var leadingTextColor: Color
//            
//    var body: some View {
//        HStack {
//            Text(leadingText)
//                .foregroundStyle(leadingTextColor)
//            
//            Spacer()
//            if dailyCount > 1 {
//                Text(dailyTotal.currencyWithDecimals(useWholeNumbers ? 0 : 2))
//            }
//        }
//    }
//}
