//
//  CalcHelper.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/8/26.
//

import Foundation

struct CalcHelper {
    enum DoWhatWhenCalculating { case updateEod, giveMeLastDayEod, giveMeEodAsOfToday }
    
    @MainActor
    @discardableResult
    static func updateUnifiedStartingAmount(month: CBMonth, for unifiedAccountType: AccountType, store: AppStore) -> Decimal {
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
            .filter { $0.payMethod.accountHolderFilter() }
            .map { start in
                #warning("CURRENCY! FIX ME")
//                if let cunt = meth.payMethod.country {
//                    let setCunt = AppState.shared.country
//                    if cunt != setCunt {
//                        if let converted = Countries.convert(amount: meth.amount, from: cunt, to: setCunt) {
//                            return converted
//                        }
//                    }
//                }
//                
                
                let setCunt = AppState.shared.country
                let shouldRound = AppSettings.shared.useWholeNumbers
                
                #warning("if you change useWholeNumbers, the rounding can be off unless you leave the calendar (which triggers this function to run again)")
                if let methCunt = start.payMethod.country,
                   let fromRate = CurrencyHelpers.getExchangeRate(date: month.firstDateOfMonth, currencyCode: methCunt.currencyCode, months: store.months),
                   let toRate = CurrencyHelpers.getExchangeRate(date: month.firstDateOfMonth, currencyCode: setCunt.currencyCode, months: store.months),
                   let converted = CurrencyHelpers.convert(amount: start.amount, fromRate: fromRate, toRate: toRate) {
                    return shouldRound ? converted.rounded(scale: 0) : converted
                }
                
                
                
                
                return start.amount
            }
            .reduce(0.0, +)
                                
        let index = month.startingAmounts.firstIndex(where: { $0.payMethod.accountType == unifiedAccountType })
        if let index {
            month.startingAmounts[index].amountString = startingBalance.currencyWithDecimals()
        }
        
        return startingBalance
    }
                
    
    /// Runs when you...
    /// 1. Change a payment method
    /// 2. Save a transaction
    /// 3. Transactions come in from longpoll
    @MainActor
    @discardableResult
    static func calculateTotal(
        for month: CBMonth,
        using paymentMethod: CBPaymentMethod? = nil,
        and doWhat: DoWhatWhenCalculating = .updateEod,
        store: AppStore
    ) -> Decimal {
        var theMethod: CBPaymentMethod?
        if paymentMethod == nil {
            theMethod = store.sPayMethod
        } else {
            theMethod = paymentMethod
        }

        if theMethod?.accountType == .unifiedChecking {
            return Self.calculateUnifiedChecking(for: month, and: doWhat, store: store)
            
        } else if theMethod?.accountType == .unifiedCredit {
            return Self.calculateUnifiedCredit(for: month, and: doWhat, store: store)
                                                
        } else if [.credit, .loan].contains(theMethod?.accountType) {
            return Self.calculateCredit(for: month, using: theMethod, and: doWhat, store: store)
            
        } else if [.checking, .cash, .savings, .investment, .k401].contains(theMethod?.accountType) {
            return Self.calculateChecking(for: month, using: theMethod, and: doWhat, store: store)
            
        } else {
            return Self.calculateSumForDay(for: month, and: doWhat, store: store)
        }
    }
    
    
    @MainActor
    static private func calculateUnifiedChecking(for month: CBMonth, and doWhat: DoWhatWhenCalculating, store: AppStore) -> Decimal {
        var finalEodTotal: Decimal = 0.0
        let startingBalance = updateUnifiedStartingAmount(month: month, for: .unifiedChecking, store: store)
        var currentAmount = startingBalance
        
        month.days.forEach { day in
            let amounts = day.transactions
                .filter { trans in
                    if let meth = trans.payMethod {
                        return meth.isDebitOrCash
                        && trans.active
                        && trans.factorInCalculations
                        && meth.isPermittedAndNotHidden
                        && meth.accountHolderFilter()
                    } else {
                        return false
                    }
                }
                .map { trans in
                    return trans.amount
                    
                    let setCunt = AppState.shared.country
                    let shouldRound = AppSettings.shared.useWholeNumbers
                    
                    #warning("if you change useWholeNumbers, the rounding can be off unless you leave the calendar (which triggers this function to run again)")
                    if let transCunt = trans.country,
                       //transCunt != AppState.shared.country,
                       let date = trans.date,
                       let orig = trans.originalUnconvertedAmount,
                       let fromRate = CurrencyHelpers.getExchangeRate(date: date, currencyCode: transCunt.currencyCode, months: store.months),
                       let toRate = CurrencyHelpers.getExchangeRate(date: date, currencyCode: setCunt.currencyCode, months: store.months),
                       let converted = CurrencyHelpers.convert(amount: orig, fromRate: fromRate, toRate: toRate) {
                        print("-- \(#function) - converting \(trans.title) to \(converted)")
                        return shouldRound ? converted.rounded(scale: 0) : converted
                    } else {
                        print("-- \(#function) - did not convert \(trans.title)")
                    }
                    
                    return trans.amount
                }
            
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
    
    
    @MainActor
    static private func calculateUnifiedCredit(for month: CBMonth, and doWhat: DoWhatWhenCalculating, store: AppStore) -> Decimal {
        //let creditEodView = CreditEodView.fromString(UserDefaults.standard.string(forKey: "creditEodView") ?? "")
        let creditEodView = LocalStorage.shared.creditEodView
        
        var finalEodTotal: Decimal = 0.0
        let startingBalance = updateUnifiedStartingAmount(month: month, for: .unifiedCredit, store: store)
        var currentAmount: Decimal = 0.0
        
        switch creditEodView {
        case .availableCredit:
            /// To show available credit.
            let cumulativeLimits = store
                .paymentMethods
                .filter { $0.isCreditOrLoan }
                .filter { $0.isPermittedAndNotHidden }
                .filter { $0.accountHolderFilter() }
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
                        && meth.accountHolderFilter()
                    } else {
                        return false
                    }
                }
                .map { trans in
                    return trans.amount
                    
                    let setCunt = AppState.shared.country
                    let shouldRound = AppSettings.shared.useWholeNumbers
                    
                    #warning("if you change useWholeNumbers, the rounding can be off unless you leave the calendar (which triggers this function to run again)")
                    if let transCunt = trans.country,
                       //transCunt != AppState.shared.country,
                       let date = trans.date,
                       let orig = trans.originalUnconvertedAmount,
                       let fromRate = CurrencyHelpers.getExchangeRate(date: date, currencyCode: transCunt.currencyCode, months: store.months),
                       let toRate = CurrencyHelpers.getExchangeRate(date: date, currencyCode: setCunt.currencyCode, months: store.months),
                       let converted = CurrencyHelpers.convert(amount: orig, fromRate: fromRate, toRate: toRate) {
                        print("-- \(#function) - converting \(trans.title) to \(converted)")
                        return shouldRound ? converted.rounded(scale: 0) : converted
                    } else {
                        print("-- \(#function) - did not convert \(trans.title)")
                    }
                    
                    return trans.amount
                }
            
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
    
    
    @MainActor
    static private func calculateCredit(for month: CBMonth, using paymentMethod: CBPaymentMethod?, and doWhat: DoWhatWhenCalculating, store: AppStore) -> Decimal {
        //let creditEodView = CreditEodView.fromString(UserDefaults.standard.string(forKey: "creditEodView") ?? "")
        let creditEodView = LocalStorage.shared.creditEodView
        
        var finalEodTotal: Decimal = 0.0
        let startingBalance = month.startingAmounts.filter { $0.payMethod.id == paymentMethod?.id }.filter { !$0.payMethod.isHidden }.first
        var currentAmount: Decimal = 0.0
        
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
                            && meth.accountHolderFilter()
                        } else {
                            return false
                        }
                    }
                    .map { trans in
                        return trans.amount
                        
                        //print("\($0.title) \($0.amount)")
                        
                        let setCunt = AppState.shared.country
                        let shouldRound = AppSettings.shared.useWholeNumbers
                        
                        
                        if let orig = trans.originalUnconvertedAmount, paymentMethod?.country == trans.country {
                            return orig
                        }
                        
                        #warning("if you change useWholeNumbers, the rounding can be off unless you leave the calendar (which triggers this function to run again)")
                        if let transCunt = trans.country,
                           let methCunt = paymentMethod?.country,
                           transCunt != AppState.shared.country,
                           let date = trans.date,
                           let orig = trans.originalUnconvertedAmount,
                           let fromRate = CurrencyHelpers.getExchangeRate(date: date, currencyCode: transCunt.currencyCode, months: store.months),
                           let toRate = CurrencyHelpers.getExchangeRate(date: date, currencyCode: methCunt.currencyCode, months: store.months),
                           let converted = CurrencyHelpers.convert(amount: orig, fromRate: fromRate, toRate: toRate) {
                            print("-- \(#function) - converting \(trans.title) to \(converted)")
                            return shouldRound ? converted.rounded(scale: 0) : converted
                        }
                        
                        
                        
                        return trans.amount
                        
                        
                    }
                
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
    /*private*/
    @MainActor
    static func calculateChecking(for month: CBMonth, using paymentMethod: CBPaymentMethod?, and doWhat: DoWhatWhenCalculating, store: AppStore) -> Decimal {
        print("-- \(#function)")
        var finalEodTotal: Decimal = 0.0
        let startingAmount = month.startingAmounts.filter { $0.payMethod.id == paymentMethod?.id }.filter { !$0.payMethod.isHidden }.first ?? CBStartingAmount()
        
        print("-- \(#function) - The starting amount is \(startingAmount.amount)")
        
        var currentAmount = startingAmount.amount
        
        month.days.forEach { day in
            let amounts = day.transactions
                .filter { trans in
                    if let meth = trans.payMethod {
                        return meth.id == paymentMethod?.id
                        && trans.active
                        && trans.factorInCalculations
                        && meth.isPermittedAndNotHidden
                        && meth.accountHolderFilter()
                    } else {
                        return false
                    }
                }
                .map { trans in
                    return trans.amount
                    //print("\($0.title) \($0.amount)")
                    
                    let setCunt = AppState.shared.country
                    let shouldRound = AppSettings.shared.useWholeNumbers
                    
                    
                    if let orig = trans.originalUnconvertedAmount, paymentMethod?.country == trans.country {
                        return orig
                    }
                    
                    #warning("if you change useWholeNumbers, the rounding can be off unless you leave the calendar (which triggers this function to run again)")
                    if let transCunt = trans.country,
                       let methCunt = paymentMethod?.country,
                       transCunt != AppState.shared.country,
                       let date = trans.date,
                       let orig = trans.originalUnconvertedAmount,
                       let fromRate = CurrencyHelpers.getExchangeRate(date: date, currencyCode: transCunt.currencyCode, months: store.months),
                       let toRate = CurrencyHelpers.getExchangeRate(date: date, currencyCode: methCunt.currencyCode, months: store.months),
                       let converted = CurrencyHelpers.convert(amount: orig, fromRate: fromRate, toRate: toRate) {
                        print("-- \(#function) - converting \(trans.title) to \(converted)")
                        return shouldRound ? converted.rounded(scale: 0) : converted
                    }
                    
                    
                    
                    return trans.amount
                    
                    
                }
            
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
    
    
    static private func calculateSumForDay(for month: CBMonth, and doWhat: DoWhatWhenCalculating, store: AppStore) -> Decimal {
        var finalEodTotal: Decimal = 0.0
        
        month.days.forEach { day in
            let amount = day.transactions
                .filter { trans in
                    if let meth = trans.payMethod {
                        return trans.active
                        && trans.factorInCalculations
                        && meth.isPermittedAndNotHidden
                        && meth.accountHolderFilter()
                        && (store.categoryFilterWasSetByCategoryPage ? store.sCategories.map({ $0.id }).contains(trans.category?.id) : true)
                    } else {
                        return false
                    }
                }
                .map { $0.payMethod?.isCreditOrLoan == true ? $0.amount * -1 : $0.amount }
                .reduce(0.0, +)
            
                        
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
