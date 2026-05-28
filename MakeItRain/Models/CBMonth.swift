//
//  Month.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/18/24.
//

import Foundation
import UniformTypeIdentifiers
import SwiftUI


@Observable
class CBMonth: Identifiable, Hashable, Equatable, Codable, IsEditableBudget {
    var id: UUID = UUID()
    var populatedId: Int
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
    /// This is the budget amount. It has to be called amount in order for this class to conform to ``IsEditableBudget``.
    var amount: Double { Double(amountString.replacing("$", with: "").replacing(",", with: "")) ?? 0.0 }
    var amountString: String
    
    /// Just a helper since the variable `amount` is ambigious.
    /// However, the variable `amount` is required for conformance to ``IsEditableBudget``.
    var budget: Double {
        return amount
    }
    
    var budgets: Array<CBBudgetItem> = []
    var budgetGroups: Array<CBBudgetItem> = []
    var hasBeenPopulated = false
    /// Control the main spinner that covers the calendar during initial download, and during a user-initiated refresh.
    /// When refreshing via long poll or scene change, this spinner is ignored.
    var showCalendarLoadingSpinner = false
    
    /// Control the secondary loading spinner. This is used on the insights sheet month picker, for example.
    /// It should always show when a download is happening - regardless of the download technique.
    var showSecondaryLoadingSpinner = false

    
    /// Use this to determine when we can navigate away from the splash screen when cold-launching from the plaid widget.
    var hasBeenLoadedFromServer = false
    
    var isTodayMonth: Bool {
        self.actualNum == AppState.shared.todayMonth && self.year == AppState.shared.todayYear
    }
    
    var prettyName: String {
        if (year == 1901 && actualNum == 1) || (year == 1899 && actualNum == 12) || year == 1900 {
            return "\(self.name) Playground"
        } else {
            return "\(self.name) \(String(self.year))"
        }
    }
    
    var legitDays: Array<CBDay> {
        days.filter { !$0.isPlaceholder }
    }
    
    var justTransactions: Array<CBTransaction> {
        self.days.flatMap { $0.transactions }
    }
    
    var transactionTotals: Double {
        justTransactions.map { $0.amount }.reduce(0.0, +)
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
    
    var enumID: NavDest {
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
            return .placeholderMonth
        }
    }
    
    var isPlaceholder: Bool {
        self.enumID == .placeholderMonth
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
        
        self.amountString = "0"
        self.populatedId = 0
    }
    
    
    enum CodingKeys: CodingKey { case month, year, user_id, account_id, device_uuid, is_today_month, budget, populated_id, id, budget_amount }
        
    func encode(to encoder: Encoder) throws {
        let formatter = NumberFormatter()
        formatter.minimumIntegerDigits = 2
                      
        let optionalString = formatter.string(from: actualNum as NSNumber)!
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(optionalString, forKey: .month)
        try container.encode(String(year), forKey: .year)
        try container.encode(amount, forKey: .budget)
        try container.encode(populatedId, forKey: .populated_id)
        try container.encode(Cody.shared.id, forKey: .user_id)
        try container.encode(Cody.shared.accountID, forKey: .account_id)
        try container.encode(Cody.shared.deviceUUID, forKey: .device_uuid)
        try container.encode(isTodayMonth ? 1 : 0, forKey: .is_today_month)
    }
    
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        num = try container.decode(Int.self, forKey: .month)
        year = try container.decode(Int.self, forKey: .year)
        amountString = String(try container.decode(Double.self, forKey: .budget_amount))
        populatedId = try container.decode(Int.self, forKey: .id)
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
    
    func hasChanges() -> Bool {
        if let deepCopy = deepCopy {
            if self.amount == deepCopy.amount {
                return false
            }
        }
        return true
    }
        
    var deepCopy: CBMonth?
    func deepCopy(_ mode: ShadowCopyAction) {
        switch mode {
        case .create:
            let month = CBMonth(num: self.num)
            month.amountString = self.amountString
            self.deepCopy = month
            
        case .restore:
            if let deepCopy = self.deepCopy {
                self.amountString = deepCopy.amountString
            }
        case .clear:
            break
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
    func isExisting(_ budget: CBBudgetItem) -> Bool {
        return !budgets.filter { $0.id == budget.id }.isEmpty
    }
    
    func getBudget(by id: String) -> CBBudgetItem {
        return budgets.filter { $0.id == id }.first ?? CBBudgetItem.empty
    }
    
    func getIndex(for budget: CBBudgetItem) -> Int? {
        return budgets.firstIndex(where: { $0.id == budget.id })
    }

    func upsert(_ budget: CBBudgetItem) {
        if !isExisting(budget) {
            budgets.append(budget)
        }
    }
    
    func delete(_ budget: CBBudgetItem) {
        budgets.removeAll(where: { $0.id == budget.id })
    }            
}


extension [CBMonth] {
    func get(by monthAndYear: (Int, Int)) -> CBMonth? {
        first(where: { $0.actualNum == monthAndYear.0 && $0.year == monthAndYear.1 })
    }
    
    func get(byNum num: Int) -> CBMonth? {
        first(where: { $0.num == num })
    }
    
    func get(byEnumId enumId: NavDest) -> CBMonth {
        first(where: { $0.enumID == enumId })!
    }
    
    func getDay(by date: Date) -> CBDay? {
        let targetMonth = first(where: { $0.actualNum == date.month && $0.year == date.year })
        let targetDay = targetMonth?.getDay(by: date.day)
        return targetDay
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
