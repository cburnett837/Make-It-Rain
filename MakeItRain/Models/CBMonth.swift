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

@Observable
class CBMonth: Identifiable, Hashable, Equatable, Encodable {
    var id: UUID = UUID()
    var num: Int = 0
    var actualNum: Int {
        num == 13 ? 1 : num == 0 ? 12 : num
    }
    
    /// This is needed so this class can calculate its `dayCount`. This is set with a didSet on the ``Model`` `year` property.
    var year: Int
    var days: Array<CBDay> = []
    var startingAmounts: Array<CBStartingAmount> = []
    var budgets: Array<CBBudget> = []
    var hasBeenPopulated = false
    
    var justTransactions: Array<CBTransaction> {
        self.days.flatMap { $0.transactions }
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
        default:
            return .january
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
    
    static func == (lhs: CBMonth, rhs: CBMonth) -> Bool {
        if lhs.num == rhs.num
            && lhs.year == rhs.year
            && lhs.days == rhs.days
            && lhs.startingAmounts == rhs.startingAmounts
            && lhs.budgets == rhs.budgets
            && lhs.hasBeenPopulated == rhs.hasBeenPopulated
        {
            return true
        }
        return false
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
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

    
    func isExisting(_ budget: CBBudget) -> Bool {
        return !budgets.filter { $0.id == budget.id }.isEmpty
    }
    
    func getBudget(by id: Int) -> CBBudget {
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
