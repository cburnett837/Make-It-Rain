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
    var categoryFilterWasSetByCategoryPage = false
    var tempTransactions: [CBTransaction] = []
    var searchedTransactions: [CBTransaction] = []
    var dashboardTransactions: [CBTransaction] = []
    var receiptTransactions: [CBTransaction] = []
    var tagBudgetTransactions: [CBTransaction] = []
    var suggestedTitles: [CBSuggestedTitle] = []
    var suggestedLocations: [CBSuggestedLocation] = []
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
    
    var sMonth: CBMonth = CBMonth(num: 1)
    var sYear: Int = AppState.shared.todayYear
    var sCategory: CBCategory?
    var sCategories: [CBCategory] = []
    var sCategoryGroups: [CBCategoryGroup] = []
    var sCategoriesForAnalysis: [CBCategory] = []
    var sCategoryGroupsForAnalysis: [CBCategoryGroup] = []
    
    var sPayMethodWhenSearchWasFocused: CBPaymentMethod? = nil
    var sPayMethod: CBPaymentMethod? {
        didSet {
            Task { @MainActor in
                let _ = await CalcHelper.calculateTotal(for: self.sMonth, store: self)
            }
        }
    }
    
    
    // MARK: - TagModel
    var tags: [CBTag] = []
    
    
    // MARK: - BudgetModel
    var budgets: [CBBudgetItem] = []
    var globalBudget: CBBudget = CBBudget()
    
    
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
    
    
    func removeAll() {
        sPayMethod = nil
        sCategory = nil
        globalBudget = CBBudget()
                
        /// Remove all transactions and starting amounts for all months.
        months.forEach { month in
            month.startingAmounts.removeAll()
            month.days.forEach { $0.transactions.removeAll() }
            month.budgets.removeAll()
            month.hasBeenPopulated = false
            month.hasBeenLoadedFromServer = false
        }
        
        /// Remove all extra downloaded data.
        tempTransactions.removeAll()
        searchedTransactions.removeAll()
        dashboardTransactions.removeAll()
        receiptTransactions.removeAll()
        tagBudgetTransactions.removeAll()
        suggestedTitles.removeAll()
        sCategories.removeAll()
        sCategoryGroups.removeAll()
        sCategoriesForAnalysis.removeAll()
        sCategoryGroupsForAnalysis.removeAll()
        tags.removeAll()
        budgets.removeAll()
        paymentMethods.removeAll()
        keywords.removeAll()
        categories.removeAll()
        categoryGroups.removeAll()
        repTransactions.removeAll()
        banks.removeAll()
        trans.removeAll()
        balances.removeAll()        
    }
}
