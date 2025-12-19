//
//  Month.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/18/24.
//

import Foundation
import UniformTypeIdentifiers
import SwiftUI

extension UTType {
    static let transaction = UTType(exportedAs: "com.codyburnett.MakeItRain")
}

//struct EndOfDayAmounts {
//    var day: Int
//    var amounts: [EndOfDayAmount]
//}
//
//struct EndOfDayAmount {
//    var paymentMethod: CBPaymentMethod
//    var amount: Double
//}


enum PrevNext {
    case prev, next
}

extension [CBMonth] {
//    func get(actualNum: Int, year: Int) -> CBMonth? {
//        first(where: { $0.actualNum == actualNum && $0.year == year })
//    }
    
    func get(by pair: (Int, Int)) -> CBMonth? {
        first(where: { $0.actualNum == pair.0 && $0.year == pair.1 })
    }
    
    func get(byNum num: Int) -> CBMonth? {
        first(where: { $0.num == num })
    }
    
    func get(byEnumId enumId: NavDestination) -> CBMonth {
        first(where: { $0.enumID == enumId })!
    }
    
    func getDay(by date: Date) -> CBDay? {
        first(where: { $0.actualNum == date.month && $0.year == date.year })?.getDay(by: date)
    }
    
    func getAdjacent(num: Int, direction: PrevNext) -> CBMonth? {
        switch direction {
        case .prev:
            first(where: { $0.num == num + 1 })
        case .next:
            first(where: { $0.num == num - 1 })
        }
    }
}

@Observable
class CBMonth: Identifiable, Hashable, Equatable, Encodable {
    var id: UUID = UUID()
    var num: Int = 0
    var actualNum: Int {
        num == 13 ? 1 : num == 0 ? 12 : num
    }
//    var actualYear: Int {
//        num == 13 ? self.year + 1 : num == 0 ? self.year - 1 : year
//    }
    /// This is needed so this class can calculate its `dayCount`. This is set with a didSet on the ``Model`` `year` property.
    var year: Int
    var days: Array<CBDay> = []
    var startingAmounts: Array<CBStartingAmount> = []
    var budgets: Array<CBBudget> = []
    var budgetGroups: Array<CBBudget> = []
    var hasBeenPopulated = false
    /// Control the main spinner that covers the calendar during initial download, and during a user-initiated refresh.
    /// When refreshing via long poll or scene change, this spinner is ignored.
    var showCalendarLoadingSpinner = false
    
    /// Control the secondary loading spinner. This is used on the insights sheet month picker, for example.
    /// It should always show when a download is happening - regardless of the download technique.
    var showSecondaryLoadingSpinner = false
    
    
    var prettyName: String {
        if (year == 1901 && actualNum == 1) || (year == 1899 && actualNum == 12) || year == 1900 {
            return "\(self.name) Playground"
        } else {
            return "\(self.name) \(String(self.year))"
        }
    }
    
    func changeLoadingSpinners(toShowing: Bool, includeCalendar: Bool) {
        if toShowing {
            if includeCalendar {
                showCalendarLoadingSpinner = true
            }
            showSecondaryLoadingSpinner = true
        } else {
            showSecondaryLoadingSpinner = false
            showCalendarLoadingSpinner = false
            
        }
    }
    
    var legitDays: Array<CBDay> {
        days.filter { !$0.isPlaceholder }
    }
    
//    @MainActor var eods: Array<EndOfDayAmounts> {
//        var returns: Array<EndOfDayAmounts> = []
//        
//        for payMeth in PayMethodModel.shared.paymentMethods {
//            let startingAmount = startingAmounts.filter { $0.payMethod.id == payMeth.id }.first ?? CBStartingAmount()
//            var currentAmount = startingAmount.amount
//            
//            for day in days {
//                var amounts: Array<EndOfDayAmount> = []
//                
//                if payMeth.accountType == .checking {
//                    let dayTotal = day.transactions
//                        .filter { $0.payMethod?.id == payMeth.id }
//                        .filter { $0.active }
//                        .filter { $0.factorInCalculations == true }
//                        .map { $0.amount }
//                        
//                    currentAmount += dayTotal.reduce(0.0, +)
//                    
//                    let thing = EndOfDayAmount(paymentMethod: payMeth, amount: currentAmount)
//                    amounts.append(thing)
//                }
//                
//                let final = EndOfDayAmounts(day: day.id, amounts: amounts)
//                returns.append(final)
//            }
//                                    
//        }
//        
//        return returns
//    }
    
    
    var justTransactions: Array<CBTransaction> {
        self.days.flatMap { $0.transactions }
    }
    
//    var transactionCount: Int {
//        justTransactions.count
//    }
    
    var transactionTotals: Double {
        justTransactions.map {$0.amount}.reduce(0.0, +)
    }
    
    var dayCount: Int {
        let cal = Calendar.current
        var comps = DateComponents(calendar: cal, year: self.year, month: actualNum)
        comps.setValue(actualNum + 1, for: .month)
        comps.setValue(0, for: .day)
        let date = cal.date(from: comps)!
        return cal.component(.day, from: date)
    }
    
    var firstWeekdayOfMonth: Int {
        let cal = Calendar.current
        let comps = DateComponents(calendar: cal, year: self.year, month: actualNum)
        let date = cal.date(from: comps)!
        return cal.component(.weekday, from: date)
    }
    
    var name: String {
        switch actualNum {
        case 1:
            return "January"
        case 2:
            return "February"
        case 3:
            return "March"
        case 4:
            return "April"
        case 5:
            return "May"
        case 6:
            return "June"
        case 7:
            return "July"
        case 8:
            return "August"
        case 9:
            return "September"
        case 10:
            return "October"
        case 11:
            return "November"
        case 12:
            return "December"
        case 100000:
            return ""
        default:
            return "Improper Month"
        }
    }
        
    var abbreviatedName: String {
        switch actualNum {
        case 1:
            return "Jan"
        case 2:
            return "Feb"
        case 3:
            return "Mar"
        case 4:
            return "Apr"
        case 5:
            return "May"
        case 6:
            return "Jun"
        case 7:
            return "Jul"
        case 8:
            return "Aug"
        case 9:
            return "Sep"
        case 10:
            return "Oct"
        case 11:
            return "Nov"
        case 12:
            return "Dec"
        case 100000:
            return ""
        default:
            return "Improper Month"
        }
    }
    
    var enumID: NavDestination {
        switch num {
        case 0:
            return .lastDecember
        case 1:
            return .january
        case 2:
            return .february
        case 3:
            return .march
        case 4:
            return .april
        case 5:
            return .may
        case 6:
            return .june
        case 7:
            return .july
        case 8:
            return .august
        case 9:
            return .september
        case 10:
            return .october
        case 11:
            return .november
        case 12:
            return .december
        case 13:
            return .nextJanuary
        case 100000:
            return .placeholderMonth
        default:
            return .january
        }
    }
    
    
    init(num: Int) {
        self.num = num
        if num == 0 {
            self.year = Calendar.current.component(.year, from: Date()) - 1
        } else if num == 13 {
            self.year = Calendar.current.component(.year, from: Date()) + 1
        } else {
            self.year = Calendar.current.component(.year, from: Date())
        }
    }
    
    
    enum CodingKeys: CodingKey { case month, year, user_id, account_id, device_uuid }
        
    func encode(to encoder: Encoder) throws {
        let formatter = NumberFormatter()
        formatter.minimumIntegerDigits = 2
                      
        let optionalString = formatter.string(from: actualNum as NSNumber)!
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(optionalString, forKey: .month)
        try container.encode(String(year), forKey: .year)
        try container.encode(AppState.shared.user?.id, forKey: .user_id)
        try container.encode(AppState.shared.user?.accountID, forKey: .account_id)
        try container.encode(AppState.shared.deviceUUID, forKey: .device_uuid)
    }
                
    
    static func == (lhs: CBMonth, rhs: CBMonth) -> Bool {
        if lhs.num == rhs.num
            && lhs.year == rhs.year
            && lhs.days == rhs.days
            && lhs.startingAmounts == rhs.startingAmounts
            && lhs.budgets == rhs.budgets
            && lhs.budgetGroups == rhs.budgetGroups
            && lhs.hasBeenPopulated == rhs.hasBeenPopulated
        {
            return true
        }
        return false
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    
    func getDay(by date: Date) -> CBDay? {
        return days.first(where: { $0.date == date })
    }
    
    func getDay(by dayNum: Int) -> CBDay? {
        return days.first(where: { $0.dateComponents?.day == dayNum })
    }
    
//    static var empty: CBMonth {
//        CBMonth(num: 1)
//    }
    
    
//    var deepCopy: CBMonth?
//    func deepCopy(_ mode: ShadowCopyAction) {
//        switch mode {
//        case .create:
//            let copy = CBMonth.empty
//            copy.id = self.id
//            copy.num = self.num
//            copy.year = self.year
//            copy.days = self.days
//            copy.startingAmounts = self.startingAmounts
//            self.deepCopy = copy
//        case .restore:
//            if let deepCopy = self.deepCopy {
//                self.id = deepCopy.id
//                self.num = deepCopy.num
//                self.year = deepCopy.year
//                self.days = deepCopy.days
//                self.startingAmounts = deepCopy.startingAmounts
//            }
//        }
//    }
    
    
//    func setFromAnotherInstance(month: CBMonth) {
//        self.num = month.num
//        self.year = month.year
//        self.days = month.days
//        self.startingAmounts = month.startingAmounts
//    }
    
    
    
//    func changeYear(_ year: Int) {
//        days.removeAll()
//        startingAmounts.removeAll()
//        self.year = year
//    }

    // MARK: - Budgets
    func isExisting(_ budget: CBBudget) -> Bool {
        return !budgets.filter { $0.id == budget.id }.isEmpty
    }
    
    func getBudget(by id: String) -> CBBudget {
        return budgets.filter { $0.id == id }.first ?? CBBudget.empty
    }
    
    func getIndex(for budget: CBBudget) -> Int? {
        return budgets.firstIndex(where: { $0.id == budget.id })
    }

    func upsert(_ budget: CBBudget) {
        if !isExisting(budget) {
            budgets.append(budget)
        }
    }
    
    func delete(_ budget: CBBudget) {
        budgets.removeAll(where: { $0.id == budget.id })
    }            
}
