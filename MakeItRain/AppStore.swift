//
//  AppStore.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/8/26.
//

import Foundation

@Observable
final class AppStore {
    // MARK: - CalendarModel
    var appSuiteBudgets: [CBBudget] = []
    var months: [CBMonth] = [
        CBMonth(num: 0),
        CBMonth(num: 1),
        CBMonth(num: 2),
        CBMonth(num: 3),
        CBMonth(num: 4),
        CBMonth(num: 5),
        CBMonth(num: 6),
        CBMonth(num: 7),
        CBMonth(num: 8),
        CBMonth(num: 9),
        CBMonth(num: 10),
        CBMonth(num: 11),
        CBMonth(num: 12),
        CBMonth(num: 13)
    ]
    
    var justTransactions: Array<CBTransaction> {
        months.flatMap { $0.days }.flatMap { $0.transactions }
    }
    
    // MARK: - PaymentMethodModel
    var paymentMethods: Array<CBPaymentMethod> = []
    
    
    // MARK: - KeywordModel
    var keywords: [CBKeyword] = []
    
    
    // MARK: - CategoryModel
    var categories: [CBCategory] = []
    var categoryGroups: [CBCategoryGroup] = []
    
    
    // MARK: - RepeatingTransactionModel
    var repTransactions: Array<CBRepeatingTransaction> = []
    
    
    // MARK: - Plaid
    var banks: Array<CBPlaidBank> = []
    var trans: Array<CBPlaidTransaction> = []
    var balances: Array<CBPlaidBalance> = []
}
