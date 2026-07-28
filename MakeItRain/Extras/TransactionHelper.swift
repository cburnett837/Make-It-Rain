//
//  TransactionHelper.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/8/26.
//

import Foundation

enum TransactionHelper {
    enum Debit {
        enum Transactions {
            static func get(from t: Array<CBTransaction>) -> Array<CBTransaction> {
                return t
                    /// Only debit or cash accounts.
                    .filter { ($0.payMethod?.isDebitOrCash ?? false) }
                    /// Is not the origination transaction from the transfer utility.
                    .filter { !$0.isTransferOrigin }
                    /// Is not the destination transaction from the transfer utility.
                    .filter { !$0.isTransferDest }
            }
                
            static func regularIncome(from t: Array<CBTransaction>) -> Array<CBTransaction> {
                return Debit.Transactions.get(from: t)
                    .filter { $0.isRegularIncome }
            }
            
            static func irregularIncome(from t: Array<CBTransaction>) -> Array<CBTransaction> {
                return Debit.Transactions.get(from: t)
                    .filter { $0.isIrregularIncome }
            }
            
            static func totalSpend(from t: Array<CBTransaction>) -> Array<CBTransaction> {
                return Debit.Transactions.get(from: t)
                    /// Anything that has a positive dollar amount (income).
                    .filter { $0.isExpense }
            }
        }
        
        enum Amount {
            static func totalSpend(from t: Array<CBTransaction>) -> Decimal {
                return Debit.Transactions.get(from: t)
                    /// Anything that has a negative dollar amount (expenses).
                    .filter { $0.isExpense }
                    .map { $0.amount }
                    .reduce(0.0, +)
            }
            
            static func actualSpend(from t: Array<CBTransaction>) -> Decimal {
                let totalSpend = Debit.Amount.totalSpend(from: t)
                let irregularIncome = Debit.Amount.irregularIncome(from: t)
                return (totalSpend < 0 ? totalSpend * -1 : totalSpend) - irregularIncome
            }
            
            static func totalSpendMinusRegularIncome(from t: Array<CBTransaction>) -> Decimal {
                let totalSpend = Debit.Amount.totalSpend(from: t)
                let regularIncome = Debit.Amount.regularIncome(from: t)
                return (totalSpend < 0 ? totalSpend * -1 : totalSpend) - regularIncome
            }
            
            static func actualSpendMinusRegularIncome(from t: Array<CBTransaction>) -> Decimal {
                let actualSpend = Debit.Amount.actualSpend(from: t)
                let regularIncome = Debit.Amount.regularIncome(from: t)
                return (actualSpend < 0 ? actualSpend * -1 : actualSpend) - regularIncome
            }
            
            static func regularIncome(from t: Array<CBTransaction>) -> Decimal {
                return Debit.Transactions.get(from: t)
                    /// Anything that has a positive dollar amount (income).
                    //.filter { $0.isIncome || $0.isRegularIncome || $0.isIrregularIncome }
                    .filter { $0.isRegularIncome }
                    .map { $0.amount }
                    .reduce(0.0, +)
            }
                
            static func irregularIncome(from t: Array<CBTransaction>) -> Decimal {
                return Debit.Transactions.get(from: t)
                    /// Anything that has a positive dollar amount (income).
                    //.filter { $0.isIncome || $0.isRegularIncome || $0.isIrregularIncome }
                    .filter { $0.isIrregularIncome }
                    .map { $0.amount }
                    .reduce(0.0, +)
            }
            
            static func actualIncome(from t: Array<CBTransaction>) -> Decimal {
                let totalSpend = Debit.Amount.totalSpend(from: t)
                let regularIncome = Debit.Amount.regularIncome(from: t)
                let irregularIncome = Debit.Amount.irregularIncome(from: t)
                return totalSpend + regularIncome + irregularIncome
            }
            
            static func actualSpendMinusPayment(from t: Array<CBTransaction>) -> Decimal {
                let actualSpend = Debit.Amount.actualSpend(from: t)
                let payment = Credit.Amount.payments(from: t)
                return actualSpend - payment
            }
        }
    }
    
    
    enum Credit {
        enum Transactions {
            static func get(from t: Array<CBTransaction>) -> Array<CBTransaction> {
                return t
                /// Only credit or loans.
                    .filter { $0.payMethod?.isCreditOrLoan ?? false }
            }
            
            static func totalSpend(from t: Array<CBTransaction>) -> Array<CBTransaction> {
                return Credit.Transactions.get(from: t)
                    /// Anything that has a positive dollar amount (expenses).
                    .filter { $0.isExpense }
                    /// Exclude cash advances
                    .filter { !$0.isTransferOrigin }
            }
            
            static func payments(from t: Array<CBTransaction>) -> Array<CBTransaction> {
                let trans = Credit.Transactions.get(from: t)
                    /// Anything that has a negative dollar amount (payments).
                    .filter { $0.isIrregularIncome }
                    /// Is the destination transaction from the transfer utility.
                    .filter { $0.isPaymentDest }
                
                //trans.forEach { print("\($0.title) - \($0.amount)") }
                return trans
            }
            
            static func refundOrPerk(from t: Array<CBTransaction>) -> Array<CBTransaction> {
                return Credit.Transactions.get(from: t)
                    /// Anything that has a negative dollar amount (refunds, rewards, etc.).
                    .filter { $0.isIrregularIncome }
                    /// Is not the destination transaction from the transfer utility.
                    .filter { !$0.isPaymentDest }
            }
        }
        
        enum Amount {
            static func totalSpend(from t: Array<CBTransaction>) -> Decimal {
                return Credit.Transactions.totalSpend(from: t)
                    .map { $0.amount * -1 }
                    .reduce(0.0, +)
            }
            
            static func actualSpend(from t: Array<CBTransaction>) -> Decimal {
                let totalSpend = Credit.Amount.totalSpend(from: t)
                let refundOrPerk = Credit.Amount.refundOrPerk(from: t)
                return (totalSpend < 0 ? totalSpend * -1 : totalSpend) - refundOrPerk
            }
            
            static func payments(from t: Array<CBTransaction>) -> Decimal {
                return Credit.Transactions.payments(from: t)
                    .map { $0.amount }
                    .reduce(0.0, +)
            }
            
            static func refundOrPerk(from t: Array<CBTransaction>) -> Decimal {
                return Credit.Transactions.refundOrPerk(from: t)
                    .map { $0.amount * -1 }
                    .reduce(0.0, +)
            }
            
            static func actualSpendMinusPayment(from t: Array<CBTransaction>) -> Decimal {
                let actualSpend = Credit.Amount.actualSpend(from: t)
                let payments = Credit.Amount.payments(from: t)
                return actualSpend + payments
            }
        }
    }
    
    
    enum All {
        enum Transactions {
            static func income(from t: Array<CBTransaction>) -> Array<CBTransaction> {
                let perks = Credit.Transactions.refundOrPerk(from: t)
                let irregularIncome = Debit.Transactions.irregularIncome(from: t)
                return perks + irregularIncome
            }
            
            static func spend(from t: Array<CBTransaction>) -> Array<CBTransaction> {
                let debitSpend = Debit.Transactions.totalSpend(from: t)
                let creditSpend = Credit.Transactions.totalSpend(from: t)
                return debitSpend + creditSpend
            }
        }
        
        enum Amount {
            static func regularIncome(from t: Array<CBTransaction>) -> Decimal {
                return Debit.Amount.regularIncome(from: t)
            }
            
            static func irregularIncome(from t: Array<CBTransaction>) -> Decimal {
                return Debit.Amount.irregularIncome(from: t) + Credit.Amount.refundOrPerk(from: t)
            }
            
            static func totalSpend(from t: Array<CBTransaction>) -> Decimal {
                let debitSpend = Debit.Amount.totalSpend(from: t)
                let creditSpend = Credit.Amount.totalSpend(from: t)
                return debitSpend + creditSpend
            }
            
            static func spendMinusPayments(from t: Array<CBTransaction>) -> Decimal {
                let spend = All.Amount.totalSpend(from: t)
                let payments = Credit.Amount.payments(from: t)
                return spend - payments
            }
            
            static func spendMinusRegularIncome(from t: Array<CBTransaction>) -> Decimal {
                let totalSpend = All.Amount.totalSpend(from: t)
                let income = All.Amount.regularIncome(from: t)
                return (totalSpend < 0 ? totalSpend * -1 : totalSpend) - income
            }
            
            static func incomeMinusPayments(from t: Array<CBTransaction>) -> Decimal {
                let debitIncome = Debit.Amount.irregularIncome(from: t)
                let creditIncome = Credit.Amount.refundOrPerk(from: t)
                let payments = Credit.Amount.payments(from: t)
                return (debitIncome + creditIncome) - payments
            }
            
            static func actualSpend(from t: Array<CBTransaction>) -> Decimal {
                let totalSpend = All.Amount.totalSpend(from: t)
                let income = All.Amount.irregularIncome(from: t)
                return (totalSpend < 0 ? totalSpend * -1 : totalSpend) - income
            }
            
            static func actualIncome(from t: Array<CBTransaction>) -> Decimal {
                let irrIncome = All.Amount.irregularIncome(from: t)
                let regIncome = All.Amount.regularIncome(from: t)
                return irrIncome + regIncome
            }
        }
    }
    
    
    
    // MARK: - Debit Summary Helpers
//    static func getDebitTransactions(from transactions: Array<CBTransaction>) -> Array<CBTransaction> {
//        return transactions
//            /// Only debit or cash accounts.
//            .filter { ($0.payMethod?.isDebitOrCash ?? false) }
//            /// Is not the origination transaction from the transfer utility.
//            .filter { !$0.isTransferOrigin }
//            /// Is not the destination transaction from the transfer utility.
//            .filter { !$0.isTransferDest }
//    }
//        
//    static func getRegularDebitIncomeTransactions(from transactions: Array<CBTransaction>) -> Array<CBTransaction> {
//        return getDebitTransactions(from: transactions)
//            .filter { $0.isRegularIncome }
//    }
//    
//    static func getIrregularDebitIncomeTransactions(from transactions: Array<CBTransaction>) -> Array<CBTransaction> {
//        return getDebitTransactions(from: transactions)
//            .filter { $0.isIrregularIncome }
//    }
//    
////    static func getDebitIncomeTransactions(from transactions: Array<CBTransaction>) -> Array<CBTransaction> {
////        return getDebitTransactions(from: transactions)
////            /// Anything that has a negative dollar amount (expenses).
////            .filter { $0.isIncome }
////    }
//    
//    static func getDebitSpend(from transactions: Array<CBTransaction>) -> Double {
//        return getDebitTransactions(from: transactions)
//            /// Anything that has a negative dollar amount (expenses).
//            .filter { $0.isExpense }
//            .map { $0.amount }
//            .reduce(0.0, +)
//    }
//    
//    static func getRegularDebitIncome(from transactions: Array<CBTransaction>) -> Double {
//        return getDebitTransactions(from: transactions)
//            /// Anything that has a positive dollar amount (income).
//            //.filter { $0.isIncome || $0.isRegularIncome || $0.isIrregularIncome }
//            .filter { $0.isRegularIncome }
//            .map { $0.amount }
//            .reduce(0.0, +)
//    }
//        
//    static func getIrregularDebitIncome(from transactions: Array<CBTransaction>) -> Double {
//        return getDebitTransactions(from: transactions)
//            /// Anything that has a positive dollar amount (income).
//            //.filter { $0.isIncome || $0.isRegularIncome || $0.isIrregularIncome }
//            .filter { $0.isIrregularIncome }
//            .map { $0.amount }
//            .reduce(0.0, +)
//    }
//            
//    static func getDebitActualSpend(from transactions: Array<CBTransaction>) -> Double {
//        let spend = getDebitSpend(from: transactions)
//        let income = getIrregularDebitIncome(from: transactions)
//        return (spend * -1) - income
//    }
//    
//    static func getDebitActualIncome(from transactions: Array<CBTransaction>) -> Double {
//        return getDebitSpend(from: transactions) + getIrregularDebitIncome(from: transactions) + getRegularDebitIncome(from: transactions)
//    }
//        
//               
//    static func getDebitSpendTransactions(from transactions: Array<CBTransaction>) -> Array<CBTransaction> {
//        return getDebitTransactions(from: transactions)
//            /// Anything that has a positive dollar amount (income).
//            .filter { $0.isExpense }
//    }
//    
//    
//    
//    // MARK: - Credit Summary Helpers
//    static func getCreditTransactions(from transactions: Array<CBTransaction>) -> Array<CBTransaction> {
//        return transactions
//        /// Only credit or loans.
//            .filter { $0.payMethod?.isCreditOrLoan ?? false }
//    }
//    
//    static func getCreditSpendTransactions(from transactions: Array<CBTransaction>) -> Array<CBTransaction> {
//        return getCreditTransactions(from: transactions)
//            /// Anything that has a positive dollar amount (expenses).
//            .filter { $0.isExpense }
//            /// Exclude cash advances
//            .filter { !$0.isTransferOrigin }
//    }
//    
//    static func getCreditPaymentTransactions(from transactions: Array<CBTransaction>) -> Array<CBTransaction> {
//        return getCreditTransactions(from: transactions)
//            /// Anything that has a negative dollar amount (payments).
//            .filter { $0.isIncome }
//            /// Is the destination transaction from the transfer utility.
//            .filter { $0.isPaymentDest }
//    }
//    
//    static func getCreditRefundsOrPerkTransactions(from transactions: Array<CBTransaction>) -> Array<CBTransaction> {
//        return getCreditTransactions(from: transactions)
//            /// Anything that has a negative dollar amount (refunds, rewards, etc.).
//            .filter { $0.isIncome }
//            /// Is not the destination transaction from the transfer utility.
//            .filter { !$0.isPaymentDest }
//    }
//    
//    static func getCreditSpend(from transactions: Array<CBTransaction>) -> Double {
//        return getCreditSpendTransactions(from: transactions)
//            .map { $0.amount * -1 }
//            .reduce(0.0, +)
//    }
//    
//    static func getCreditPayments(from transactions: Array<CBTransaction>) -> Double {
//        return getCreditPaymentTransactions(from: transactions)
//            .map { $0.amount }
//            .reduce(0.0, +)
//    }
//    
//    static func getCreditRefundsOrPerks(from transactions: Array<CBTransaction>) -> Double {
//        return getCreditRefundsOrPerkTransactions(from: transactions)
//            .map { $0.amount * -1 }
//            .reduce(0.0, +)
//    }
//
//    
//    
//    
//    // MARK: - All Transactions Helpers
//    static func getActualSpend(from transactions: Array<CBTransaction>) -> Double {
//        let spend = getSpend(from: transactions)
//        let irregularIncome = getIrregularIncome(from: transactions)
//        
//        print("irregularIncome: \(irregularIncome)")
//        
//        return spend + irregularIncome
//        
//    }
//    
//    static func getActualIncome(from transactions: Array<CBTransaction>) -> Double {
//        return getIrregularIncome(from: transactions) + getRegularIncome(from: transactions)
//    }
//    
////    static func getIncomeTransactions(from transactions: Array<CBTransaction>) -> Array<CBTransaction> {
////        return getCreditRefundsOrPerkTransactions(from: transactions) + getDebitIncomeTransactions(from: transactions)
////    }
//    
//    static func getSpendTransactions(from transactions: Array<CBTransaction>) -> Array<CBTransaction> {
//        return getDebitSpendTransactions(from: transactions) + getCreditSpendTransactions(from: transactions)
//    }
//        
////    func getSpendMinusPaymentTransactions(from transactions: Array<CBTransaction>) -> Array<CBTransaction> {
////        return getSpendTransactions(from: transactions) - getCreditPaymentTransactions(from: transactions)
////    }
////
////    func getIncomeMinusPaymentTransactions(from transactions: Array<CBTransaction>) -> Array<CBTransaction> {
////        let debitIncome = getDebitIncomeTransactions(from: transactions)
////        let creditIncome = getCreditRefundsOrPerkTransactions(from: transactions)
////        let payments = getCreditPaymentTransactions(from: transactions)
////        return (debitIncome + creditIncome) - payments
////    }
//            
//    
//    
//    static func getRegularIncome(from transactions: Array<CBTransaction>) -> Double {
//        //let refunds = getCreditRefundsOrPerks(from: transactions)
//        return getRegularDebitIncome(from: transactions)
//        
//        //print(refunds, debitIncome)
//        //return refunds + debitIncome
//        
//        
//        //return getCreditRefundsOrPerks(from: transactions) + getDebitIncome(from: transactions)
//    }
//    
//    static func getIrregularIncome(from transactions: Array<CBTransaction>) -> Double {
//        return getCreditRefundsOrPerks(from: transactions) + getIrregularDebitIncome(from: transactions)
//        
//        
//        
//        //return getCreditRefundsOrPerks(from: transactions) + getDebitIncome(from: transactions)
//    }
//    
//    
//    
//    
//    static func getSpend(from transactions: Array<CBTransaction>) -> Double {
//        return getDebitSpend(from: transactions) + getCreditSpend(from: transactions)
//    }
//        
//    static func getSpendMinusPayments(from transactions: Array<CBTransaction>) -> Double {
//        return getSpend(from: transactions) - getCreditPayments(from: transactions)
//    }
//    
//    static func getIncomeMinusPayments(from transactions: Array<CBTransaction>) -> Double {
//        let debitIncome = getIrregularDebitIncome(from: transactions)
//        let creditIncome = getCreditRefundsOrPerks(from: transactions)
//        let payments = getCreditPayments(from: transactions)
//        return (debitIncome + creditIncome) - payments
//    }
//    
//    static func getSpendMinusRegularIncome(from transactions: Array<CBTransaction>) -> Double {
//        let expenses = getSpend(from: transactions)
//        let income = getRegularIncome(from: transactions)
//        print("HEYYYYYY \(expenses) \(income)")
//        return (expenses * -1) - income
//    }
//    
//    static func getSpendMinusIrregularIncome(from transactions: Array<CBTransaction>) -> Double {
//        return getSpend(from: transactions) + getIrregularIncome(from: transactions)
//    }
    
    
//    func getChartPercentage(expenses: Double, income: Double, budget: Double) -> ChartPercentage {
//        var chartPer = 0.0
//        var actualPer = 0.0
//        let expensesMinusIncome = (expenses + income) * -1
//
//        if budget == 0 {
//            actualPer = expensesMinusIncome
//        } else {
//            actualPer = (expensesMinusIncome / budget) * 100
//        }
//
//        if actualPer > 100 {
//            chartPer = 100
//        } else if actualPer < 0 {
//            chartPer = 0
//        } else {
//            chartPer = actualPer
//        }
//
//        return ChartPercentage(actual: actualPer, chart: chartPer, expensesMinusIncome: expensesMinusIncome)
//    }
    
    static func createChartData(
        transactions: Array<CBTransaction>,
        category: CBCategory,
        categoricalBudgetAmount: Decimal,
        categoryGroup: CBCategoryGroup?,
        groupBudgetAmount: Decimal?,
        budgets: Array<CBBudgetItem>?
    ) -> ChartData {
        //let categoricalBudgetAmount = budgets?.map { $0.amount }.reduce(0.0, +) ?? 0.0
        let expenses = TransactionHelper.All.Amount.totalSpend(from: transactions)
        let income = TransactionHelper.All.Amount.regularIncome(from: transactions)
        let incomeMinusPayments =  TransactionHelper.All.Amount.incomeMinusPayments(from: transactions)
        //let expensesMinusIncome = getSpendMinusIncome(from: transactions)
        
        var chartPer: Decimal = 0.0
        var actualPer: Decimal = 0.0
        let expensesMinusIncome = (expenses * -1) - income
        //let expensesMinusIncome = getSpendMinusIncome(from: transactions)
        
        if categoricalBudgetAmount == 0 {
            actualPer = expensesMinusIncome
        } else {
            actualPer = (expensesMinusIncome * -1 / categoricalBudgetAmount) * 100
        }
                                        
        if actualPer > 100 {
            chartPer = 100
        } else if actualPer < 0 {
            chartPer = 0
        } else {
            chartPer = actualPer
        }
        
        
        return ChartData(
            category: category,
            budgetForCategory: categoricalBudgetAmount,
            categoryGroup: categoryGroup,
            budgetForCategoryGroup: groupBudgetAmount,
            income: income,
            incomeMinusPayments: incomeMinusPayments,
            expenses: expenses,
            expensesMinusIncome: expensesMinusIncome,
            chartPercentage: chartPer,
            actualPercentage: actualPer,
            budgetObjects: budgets
        )
    }
}
