//
//  CBDay.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/19/24.
//

import Foundation
import UniformTypeIdentifiers
import SwiftUI

@Observable
class CBDay: Identifiable, Hashable, Equatable {
    var id = UUID()
    var date: Date?
    var dateComponents: DateComponents? {
        if let date = self.date {
            return Calendar.current.dateComponents(in: .current, from: date)
        } else {
            return nil
        }        
    }
    
    var weekday: String {
        AppState.shared.dateFormatter.weekdaySymbols[Calendar.current.component(.weekday, from: self.date!) - 1]
    }
    
    
    var transactions: Array<CBTransaction> = []
    var eodTotal: Double = 0.0
    var dailySpend: Double {
        return transactions.map{$0.amount}.reduce(0.0, +)
    }
    
    var displayDate: String {
        return "\(dateComponents?.month ?? 0)/" + "\(dateComponents?.day ?? 0)/" + "\(dateComponents?.year ?? 0)"
    }
    
    
    init(date: Date?, transactions: Array<CBTransaction> = []) {
        self.id = UUID()
        self.date = date
        self.transactions = transactions
    }
    
    static func == (lhs: CBDay, rhs: CBDay) -> Bool {
        if lhs.id == rhs.id && lhs.transactions == rhs.transactions {
            return true
        }
        return false
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    func isExisting(_ transaction: CBTransaction) -> Bool {
        return !transactions.filter { $0.id == transaction.id }.isEmpty
    }
    
    func upsert(_ transaction: CBTransaction) {
        if !isExisting(transaction) {
            transactions.append(transaction)
        }
    }
    
    func remove(_ transaction: CBTransaction) {
        transactions.removeAll(where: { $0.id == transaction.id })
    }
    
    func getIndex(for transaction: CBTransaction) -> Int? {
        return transactions.firstIndex(where: { $0.id == transaction.id })
    }
}
