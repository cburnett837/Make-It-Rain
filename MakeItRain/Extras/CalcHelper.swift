//
//  CalcHelper.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/8/26.
//

import Foundation

struct CalcHelper {
    enum DoWhatWhenCalculating { case updateEod, giveMeLastDayEod, giveMeEodAsOfToday }
    
    @discardableResult
    static func updateUnifiedStartingAmount(month: CBMonth, for unifiedAccountType: AccountType) -> Double {
        /// This is called via `calculateTotal()` and via `PayMethodSheet.task{}`
        var targetAccountTypes: [AccountType]
        if unifiedAccountType == .unifiedCredit {
            targetAccountTypes = [.credit]
        } else {
            targetAccountTypes = [.checking, .cash]
        }
        
        let startingBalance = month.startingAmounts
            .filter { targetAccountTypes.contains($0.payMethod.accountType) }
            .filter { $0.payMethod.isPermitted }
            .filter { !$0.payMethod.isHidden }
            .filter { $0.payMethod.matchesFilter() }
            .map { $0.amount }
            .reduce(0.0, +)
        
        //print("\(#function) -- \(startingBalance)")
                                
        let index = month.startingAmounts.firstIndex(where: { $0.payMethod.accountType == unifiedAccountType })
        if let index {
            month.startingAmounts[index].amountString = startingBalance.currencyWithDecimals()
        }
        
        return startingBalance
    }
                
    
    @discardableResult
    static func calculateTotal(for month: CBMonth, using paymentMethod: CBPaymentMethod? = nil, and doWhat: DoWhatWhenCalculating = .updateEod, store: AppStore) -> Double {
        var theMethod: CBPaymentMethod?
        if paymentMethod == nil {
            theMethod = store.sPayMethod
        } else {
            theMethod = paymentMethod
        }

        if theMethod?.accountType == .unifiedChecking {
            return CalcHelper.calculateUnifiedChecking(for: month, and: doWhat)
            
        } else if theMethod?.accountType == .unifiedCredit {
            return CalcHelper.calculateUnifiedCredit(for: month, and: doWhat, store: store)
                                                
        } else if [.credit, .loan].contains(theMethod?.accountType) {
            return CalcHelper.calculateCredit(for: month, using: theMethod, and: doWhat)
            
        } else if [.checking, .cash, .savings, .investment, .k401].contains(theMethod?.accountType) {
            return CalcHelper.calculateChecking(for: month, using: theMethod, and: doWhat)
            
        } else {
            return CalcHelper.calculateSumForDay(for: month, and: doWhat, store: store)
        }
    }
    
    
    static private func calculateUnifiedChecking(for month: CBMonth, and doWhat: DoWhatWhenCalculating) -> Double {
        var finalEodTotal: Double = 0.0
        let startingBalance = updateUnifiedStartingAmount(month: month, for: .unifiedChecking)
        var currentAmount = startingBalance
        
        month.days.forEach { day in
            let amounts = day.transactions
                .filter { trans in
                    if let meth = trans.payMethod {
                        return meth.isDebitOrCash
                        && trans.active
                        && trans.factorInCalculations
                        && meth.isPermittedAndNotHidden
                        && meth.matchesFilter()
                    } else {
                        return false
                    }
                }
                .map { $0.amount }
            
            currentAmount += amounts.reduce(0.0, +)
            switch doWhat {
            case .updateEod:
                day.eodTotal = currentAmount
                
            case .giveMeLastDayEod:
                if day.id == month.days.last?.id {
                    finalEodTotal = currentAmount
                }
            case .giveMeEodAsOfToday:
                if day.id == AppState.shared.todayDay && day.dateComponents?.month == AppState.shared.todayMonth && day.dateComponents?.year == AppState.shared.todayYear {
                    finalEodTotal = currentAmount
                }
            }
        }
        return finalEodTotal
    }
    
    
    static private func calculateUnifiedCredit(for month: CBMonth, and doWhat: DoWhatWhenCalculating, store: AppStore) -> Double {
        //let creditEodView = CreditEodView.fromString(UserDefaults.standard.string(forKey: "creditEodView") ?? "")
        let creditEodView = LocalStorage.shared.creditEodView
        
        var finalEodTotal: Double = 0.0
        let startingBalance = updateUnifiedStartingAmount(month: month, for: .unifiedCredit)
        var currentAmount = 0.0
        
        switch creditEodView {
        case .availableCredit:
            /// To show available credit.
            let cumulativeLimits = store
                .paymentMethods
                .filter { $0.isCreditOrLoan }
                .filter { $0.isPermittedAndNotHidden }
                .filter { $0.matchesFilter() }
//                .filter {
//                    switch AppSettings.shared.paymentMethodFilterMode {
//                    case .all:
//                        return true
//                    case .justPrimary:
//                        return $0.holderOne?.id == AppState.shared.user?.id
//                    case .primaryAndSecondary:
//                        return $0.holderOne?.id == AppState.shared.user?.id
//                        || $0.holderTwo?.id == AppState.shared.user?.id
//                        || $0.holderThree?.id == AppState.shared.user?.id
//                        || $0.holderFour?.id == AppState.shared.user?.id
//                    }
//                }
                .map { $0.limit ?? 0.0 }
                .reduce(0.0, +)
            
            currentAmount = cumulativeLimits - startingBalance
            
        case .remainingBalance:
            currentAmount = startingBalance
        }
                            
        month.days.forEach { day in
            let amounts = day.transactions
                .filter { trans in
                    if let meth = trans.payMethod {
                        return meth.isCreditOrLoan
                        && trans.active
                        && trans.factorInCalculations
                        && meth.isPermittedAndNotHidden
                        && meth.matchesFilter()
                    } else {
                        return false
                    }
                }
//                .filter {
//                    ($0.payMethod?.isCreditOrLoan ?? false)
//                    && $0.active
//                    && $0.factorInCalculations
//                    && ($0.payMethod?.isPermitted ?? true)
//                    && !($0.payMethod?.isHidden ?? true)
//                }
//                .filter {
//                    switch AppSettings.shared.paymentMethodFilterMode {
//                    case .all:
//                        return true
//                    case .justPrimary:
//                        return $0.payMethod?.holderOne?.id == AppState.shared.user?.id
//                    case .primaryAndSecondary:
//                        return $0.payMethod?.holderOne?.id == AppState.shared.user?.id
//                        || $0.payMethod?.holderTwo?.id == AppState.shared.user?.id
//                        || $0.payMethod?.holderThree?.id == AppState.shared.user?.id
//                        || $0.payMethod?.holderFour?.id == AppState.shared.user?.id
//                    }
//                }
                .map { $0.amount }
            
            switch creditEodView {
            case .availableCredit: currentAmount -= amounts.reduce(0.0, +)
            case .remainingBalance: currentAmount += amounts.reduce(0.0, +)
            }
                        
            switch doWhat {
            case .updateEod:
                day.eodTotal = currentAmount
                
            case .giveMeLastDayEod:
                if day.id == month.days.last?.id {
                    finalEodTotal = currentAmount
                }
            case .giveMeEodAsOfToday:
                if day.id == AppState.shared.todayDay && day.dateComponents?.month == AppState.shared.todayMonth && day.dateComponents?.year == AppState.shared.todayYear {
                    finalEodTotal = currentAmount
                }
            }
            
        }
        return finalEodTotal
    }
    
    
    static private func calculateCredit(for month: CBMonth, using paymentMethod: CBPaymentMethod?, and doWhat: DoWhatWhenCalculating) -> Double {
        //let creditEodView = CreditEodView.fromString(UserDefaults.standard.string(forKey: "creditEodView") ?? "")
        let creditEodView = LocalStorage.shared.creditEodView
        
        var finalEodTotal: Double = 0.0
        let startingBalance = month.startingAmounts.filter { $0.payMethod.id == paymentMethod?.id }.filter { !$0.payMethod.isHidden }.first
        var currentAmount = 0.0
        
        if let startingBalance {
            switch creditEodView {
            case .availableCredit: currentAmount = (paymentMethod?.limit ?? 0.0) - startingBalance.amount
            case .remainingBalance: currentAmount = startingBalance.amount
            }
            
            month.days.forEach { day in
                let amounts = day.transactions
                    .filter { trans in
                        if let meth = trans.payMethod {
                            return meth.id == paymentMethod?.id
                            && trans.active
                            && trans.factorInCalculations
                            && meth.isPermittedAndNotHidden
                            && meth.matchesFilter()
                        } else {
                            return false
                        }
                    }
                
//                    .filter {
//                        $0.payMethod?.id == paymentMethod?.id
//                        && $0.active
//                        && $0.factorInCalculations
//                        && ($0.payMethod?.isPermitted ?? true)
//                        && !($0.payMethod?.isHidden ?? true)
//                    }
//                    .filter {
//                        switch AppSettings.shared.paymentMethodFilterMode {
//                        case .all:
//                            return true
//                        case .justPrimary:
//                            return $0.payMethod?.holderOne?.id == AppState.shared.user?.id
//                        case .primaryAndSecondary:
//                            return $0.payMethod?.holderOne?.id == AppState.shared.user?.id
//                            || $0.payMethod?.holderTwo?.id == AppState.shared.user?.id
//                            || $0.payMethod?.holderThree?.id == AppState.shared.user?.id
//                            || $0.payMethod?.holderFour?.id == AppState.shared.user?.id
//                        }
//                    }
                    .map { $0.amount }
                
                switch creditEodView {
                case .availableCredit: currentAmount -= amounts.reduce(0.0, +)
                case .remainingBalance: currentAmount += amounts.reduce(0.0, +)
                }
                                    
                switch doWhat {
                case .updateEod:
                    day.eodTotal = currentAmount
                    
                case .giveMeLastDayEod:
                    if day.id == month.days.last?.id {
                        finalEodTotal = currentAmount
                    }
                    
                case .giveMeEodAsOfToday:
                    if day.id == AppState.shared.todayDay && day.dateComponents?.month == AppState.shared.todayMonth && day.dateComponents?.year == AppState.shared.todayYear {
                        finalEodTotal = currentAmount
                    }
                }
            }
        } else {
            print("COULDNT DETERMINE CURRENT BALANCE")
        }
        return finalEodTotal
    }
    
    /// Not private so it can get the daily cash to show in the overall debit total at the top of the calendar.
    /*private*/ static func calculateChecking(for month: CBMonth, using paymentMethod: CBPaymentMethod?, and doWhat: DoWhatWhenCalculating) -> Double {
        var finalEodTotal: Double = 0.0
        let startingAmount = month.startingAmounts.filter { $0.payMethod.id == paymentMethod?.id }.filter { !$0.payMethod.isHidden }.first ?? CBStartingAmount()
        var currentAmount = startingAmount.amount
        
        month.days.forEach { day in
            let amounts = day.transactions
                .filter { trans in
                    if let meth = trans.payMethod {
                        return meth.id == paymentMethod?.id
                        && trans.active
                        && trans.factorInCalculations
                        && meth.isPermittedAndNotHidden
                        && meth.matchesFilter()
                    } else {
                        return false
                    }
                }
            
//                .filter {
//                    $0.payMethod?.id == paymentMethod?.id
//                    && $0.active
//                    && $0.factorInCalculations
//                    && ($0.payMethod?.isPermitted ?? true)
//                    && !($0.payMethod?.isHidden ?? true)
//                }
//                .filter {
//                    switch AppSettings.shared.paymentMethodFilterMode {
//                    case .all:
//                        return true
//                    case .justPrimary:
//                        return $0.payMethod?.holderOne?.id == AppState.shared.user?.id
//                    case .primaryAndSecondary:
//                        return $0.payMethod?.holderOne?.id == AppState.shared.user?.id
//                        || $0.payMethod?.holderTwo?.id == AppState.shared.user?.id
//                        || $0.payMethod?.holderThree?.id == AppState.shared.user?.id
//                        || $0.payMethod?.holderFour?.id == AppState.shared.user?.id
//                    }
//                }
                .map { $0.amount }
            
            currentAmount += amounts.reduce(0.0, +)
            switch doWhat {
            case .updateEod:
                day.eodTotal = currentAmount
                
            case .giveMeLastDayEod:
                if day.id == month.days.last?.id {
                    finalEodTotal = currentAmount
                }
                
            case .giveMeEodAsOfToday:
                if day.id == AppState.shared.todayDay && day.dateComponents?.month == AppState.shared.todayMonth && day.dateComponents?.year == AppState.shared.todayYear {
                    finalEodTotal = currentAmount
                }
            }
        }
        return finalEodTotal
    }
    
    
    static func calculateSumForDay(for month: CBMonth, and doWhat: DoWhatWhenCalculating, store: AppStore) -> Double {
        var finalEodTotal: Double = 0.0
        
        month.days.forEach { day in
            let amount = day.transactions
                .filter { trans in
                    if let meth = trans.payMethod {
                        return trans.active
                        && trans.factorInCalculations
                        && meth.isPermittedAndNotHidden
                        && meth.matchesFilter()
                        && (store.categoryFilterWasSetByCategoryPage ? store.sCategories.map({ $0.id }).contains(trans.category?.id) : true)
                    } else {
                        return false
                    }
                }
            
//                .filter {
//                    $0.active
//                    && $0.factorInCalculations
//                    && $0.payMethod?.isPermittedAndNotHidden ?? true
//                    && (self.categoryFilterWasSetByCategoryPage ? self.sCategories.map({ $0.id }).contains($0.category?.id) : true)
//                }
//                .filter {
//                    switch AppSettings.shared.paymentMethodFilterMode {
//                    case .all:
//                        return true
//                    case .justPrimary:
//                        return $0.payMethod?.holderOne?.id == AppState.shared.user?.id
//                    case .primaryAndSecondary:
//                        return $0.payMethod?.holderOne?.id == AppState.shared.user?.id
//                        || $0.payMethod?.holderTwo?.id == AppState.shared.user?.id
//                        || $0.payMethod?.holderThree?.id == AppState.shared.user?.id
//                        || $0.payMethod?.holderFour?.id == AppState.shared.user?.id
//                    }
//                }
                //.filter { ($0.payMethod?.isPermitted ?? true) }
                //.filter { !($0.payMethod?.isHidden ?? true) }
                .map { ($0.payMethod?.isCreditOrLoan ?? false) ? $0.amount * -1 : $0.amount }
                .reduce(0.0, +)
            
            //print("\(#function) - \(day.date?.day) - \(amount)")
                        
            switch doWhat {
            case .updateEod:
                day.eodTotal = amount
                
            case .giveMeLastDayEod:
                if day.id == month.days.last?.id {
                    finalEodTotal = amount
                }
                
            case .giveMeEodAsOfToday:
                if day.id == AppState.shared.todayDay && day.dateComponents?.month == AppState.shared.todayMonth && day.dateComponents?.year == AppState.shared.todayYear {
                    finalEodTotal = amount
                }
            }
        }
        /// This isn't used anywhere
        return finalEodTotal
    }
}
