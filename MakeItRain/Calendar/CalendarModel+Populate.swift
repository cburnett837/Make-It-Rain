//
//  CalendarModel+Populate.swift
//  MakeItRain
//
//  Created by Cody Burnett on 8/31/26.
//

import Foundation

extension CalendarModel {
    func populate(options: PopulateOptions, repTransactions: Array<CBRepeatingTransaction>/*, categories: Array<CBCategory>, categoryGroups: Array<CBCategoryGroup>*/) {
        print("-- \(#function)")
        //let dateFormatter = DateFormatter()
        
        var repsToServer: Array<CBRepTransactionCreateModel> = []
        //var repTransToServer: Array<CBTransaction> = []
        var budgetsToServer: Array<CBBudgetItem> = []
        //var budgetGroupsToServer: Array<CBBudgetItemGroup> = []
        
        
        for meth in options.paymentMethods {
            if meth.doIt {
                for repTrans in repTransactions.filter({ $0.payMethod?.id == meth.id && $0.include }) {
                    let repID = repTrans.id
                    let uuid = UUID().uuidString
                    
//                    var monthID = 0
//                    if sMonth.enumID == .nextJanuary {
//                        monthID = 1
//                    } else if sMonth.enumID == .lastDecember {
//                        monthID = 12
//                    } else {
//                        monthID = sMonth.num
//                    }
                                        
                    let isRelevantToSelectedMonth = !repTrans.when.filter({ $0.active && $0.whenType == .month && $0.monthNum == sMonth.actualNum }).isEmpty
                    
                    /// Only if the month checkbox in the repeating is checked.
                    if isRelevantToSelectedMonth {
                        
                        /// Target the currently viewed month.
                        let targetMonth = months.filter { $0.enumID == sMonth.enumID }.first!
                    
                        for when in repTrans.when.filter({ $0.active }) {
                            
                            /// Transactions that have a day of month specifiied.
                            if when.whenType == .dayOfMonth {
                                /// Find the day from the when record.
                                if let targetDay = targetMonth.days.filter({ $0.dateComponents?.day == Int(when.when.replacing("day", with: "")) ?? 0 }).first {
                                    /// Make sure transaction was not already added.
                                    let addedTrans = targetDay.transactions.filter { $0.repID == repID }.first
                                    if addedTrans == nil {
                                        if repTrans.repeatingTransactionType != .regular {
                                            processThing(
                                                uuid: uuid,
                                                repTrans: repTrans,
                                                targetDay: targetDay,
                                                //repTransToServer: &repTransToServer,
                                                toServer: &repsToServer
                                            )
                                        } else {
                                            let newTrans = CBTransaction(
                                                uuid: uuid,
                                                repTrans: repTrans,
                                                date: targetDay.date!,
                                                payMethod: repTrans.payMethod,
                                                amountString: repTrans.amountString
                                            )
                                            targetDay.transactions.append(newTrans)
                                            //repTransToServer.append(newTrans)
                                            repsToServer.append(
                                                CBRepTransactionCreateModel(
                                                    uuid: uuid,
                                                    repID: repTrans.id,
                                                    payMethodID: repTrans.payMethod?.id,
                                                    date: targetDay.date!
                                                )
                                            )
                                        }
                                    }
                                } else {
                                    /// If the day can't be found above, the transaction exists on a day that this month doesn't have (like having a date of the 31st in February).
                                    /// Add to the last day of the month.
                                    if Int(when.when.replacing("day", with: "")) ?? 0 > targetMonth.dayCount {
                                        if repTrans.repeatingTransactionType == .regular {
                                            if let targetDay = targetMonth.days.last {
                                                let newTrans = CBTransaction(
                                                    uuid: uuid,
                                                    repTrans: repTrans,
                                                    date: targetDay.date!,
                                                    payMethod: repTrans.payMethod,
                                                    amountString: repTrans.amountString
                                                )
                                                targetDay.transactions.append(newTrans)
                                                //repTransToServer.append(newTrans)
                                                repsToServer.append(
                                                    CBRepTransactionCreateModel(
                                                        uuid: uuid,
                                                        repID: repTrans.id,
                                                        payMethodID: repTrans.payMethod?.id,
                                                        date: targetDay.date!
                                                    )
                                                )
                                            }
                                        } else {
                                            if let targetDay = targetMonth.days.last {
                                                processThing(
                                                    uuid: uuid,
                                                    repTrans: repTrans,
                                                    targetDay: targetDay,
                                                    //repTransToServer: &repTransToServer,
                                                    toServer: &repsToServer
                                                )
                                            }
                                        }
                                    }
                                }
                                
                            /// For specific weekdays.
                            } else if when.whenType == .weekday {
                                let weekdays = targetMonth.days
                                    .filter { $0.date != nil }
                                    .filter { AppState.shared.dateFormatter.weekdaySymbols[Calendar.current.component(.weekday, from: $0.date!) - 1].lowercased() == when.when.lowercased() }
                                
                                for weekday in weekdays {
                                    /// Make sure transaction was not already added via the day of the month trigger.
                                    let addedTrans = weekday.transactions.filter { $0.repID == repID }.first
                                    if addedTrans == nil {
                                        let newTrans = CBTransaction(
                                            uuid: uuid,
                                            repTrans: repTrans,
                                            date: weekday.date!,
                                            payMethod: repTrans.payMethod,
                                            amountString: repTrans.amountString
                                        )
                                        weekday.transactions.append(newTrans)
                                        //repTransToServer.append(newTrans)
                                        repsToServer.append(
                                            CBRepTransactionCreateModel(
                                                uuid: uuid,
                                                repID: repTrans.id,
                                                payMethodID: repTrans.payMethod?.id,
                                                date: weekday.date!
                                            )
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        if options.budget {
            sMonth.amountString = store.globalBudget.amountString
            
            for group in store.categoryGroups {
                let budgetExists = !sMonth.budgetGroups.filter { $0.id == group.id }.isEmpty
                if !budgetExists {
                    let budget = CBBudgetItem(type: .categoryGroup)
                    budget.monthId = sMonth.populatedId
                    //budget.month = sMonth.actualNum
                    //budget.year = sMonth.year
                    budget.amountString = group.amountString ?? ""
                    budget.categoryGroup = group
                    
                    budgetsToServer.append(budget)
                    sMonth.budgets.append(budget)
                }
            }
            
            for cat in store.categories {
                /// Ignore any categories that are in a group, or are of type income.
                let catExistsInGroup = !store.categoryGroups.filter { $0.categories.contains(where: { $0.id == cat.id }) }.isEmpty
                let budgetExists = !sMonth.budgets.filter { $0.category?.id == cat.id }.isEmpty
                
                //if !budgetExists, !catExistsInGroup, !cat.isIncome {
                
                
                /// For income categories, we hide the budgets from view through out the app.
                /// But we still want to create one for the income categories because that allows us to access the budget overview page from the dashboard.
                if !budgetExists, !catExistsInGroup {
                    let budget = CBBudgetItem(type: .category)
                    budget.monthId = sMonth.populatedId
                    //budget.month = sMonth.actualNum
                    //budget.year = sMonth.year
                    budget.amountString = cat.amountString ?? ""
                    budget.category = cat
                    
                    budgetsToServer.append(budget)
                    sMonth.budgets.append(budget)
                }
            }
        }
        
//        if repTransToServer.isEmpty && budgetsToServer.isEmpty {
//            return
//        }
        
        if repsToServer.isEmpty && budgetsToServer.isEmpty {
            return
        }
        
        let _ = CalcHelper.calculateTotal(for: sMonth, store: store)
        sMonth.hasBeenPopulated = true
        
        Task {
            //await addMultiple(trans: repTransToServer, budgets: budgetsToServer, isTransfer: false)
            await sendPopulatedTransactionsAndBudgetsToServer(trans: repsToServer, budgets: budgetsToServer, isTransfer: false)
        }
        
        
        
        func processThing(
            uuid: String,
            repTrans: CBRepeatingTransaction,
            targetDay: CBDay,
            //repTransToServer: inout [CBTransaction],
            toServer: inout [CBRepTransactionCreateModel]
        ) {
            let fromTrans = CBTransaction(
                uuid: uuid,
                repTrans: repTrans,
                date: targetDay.date!,
                payMethod: repTrans.payMethod,
                amountString: repTrans.amountString
            )
            
            let secondUUID = UUID().uuidString
            let toTrans = CBTransaction(
                uuid: secondUUID,
                repTrans: repTrans,
                date: targetDay.date!,
                payMethod: repTrans.payMethodPayTo,
                amountString: repTrans.amountString
            )
            
            var fromTranz = CBRepTransactionCreateModel(uuid: uuid, repID: repTrans.id, payMethodID: repTrans.payMethod?.id, date: targetDay.date!)
            
            var toTranz = CBRepTransactionCreateModel(uuid: secondUUID, repID: repTrans.id, payMethodID: repTrans.payMethodPayTo?.id, date: targetDay.date!)
            
            
            
            
            fromTrans.relatedTransactionID = toTrans.id
            fromTrans.relatedTransactionType = .transaction// XrefModel.getItem(from: .relatedTransactionType, byEnumID: .transaction)
            fromTranz.relatedID = toTranz.id
                                                                                                    
            if repTrans.repeatingTransactionType == .payment {
                fromTrans.title = "Payment to \(repTrans.payMethodPayTo?.title ?? "")"
                fromTrans.isPaymentOrigin = true
                fromTranz.isPaymentOrigin = true
            } else {
                fromTrans.title = "Transfer to \(repTrans.payMethodPayTo?.title ?? "")"
                fromTrans.isTransferOrigin = true
                fromTranz.isTransferOrigin = true
            }
            
            toTrans.relatedTransactionID = fromTrans.id
            toTrans.relatedTransactionType = .transaction //XrefModel.getItem(from: .relatedTransactionType, byEnumID: .transaction)
            toTranz.relatedID = fromTranz.id
            
            
            if repTrans.repeatingTransactionType == .payment {
                toTrans.title = "Payment from \(repTrans.payMethod?.title ?? "")"
                toTrans.isPaymentDest = true
                toTranz.isPaymentDest = true
            } else {
                toTrans.title = "Transfer from \(repTrans.payMethod?.title ?? "")"
                toTrans.isTransferDest = true
                toTranz.isTransferDest = true
            }
                                                        
            if fromTrans.isExpense && repTrans.repeatingTransactionType != .payment {
                toTrans.amountString = toTrans.amountString.replacing("-", with: "")
            }
            
            
            targetDay.transactions.append(fromTrans)
            //repTransToServer.append(fromTrans)
            
            targetDay.transactions.append(toTrans)
            //repTransToServer.append(toTrans)
            
            
            toServer.append(toTranz)
            toServer.append(fromTranz)
        }
    }
    
    
    @MainActor
    private func sendPopulatedTransactionsAndBudgetsToServer(trans: Array<CBRepTransactionCreateModel>, budgets: Array<CBBudgetItem>, isTransfer: Bool) async {
        #if os(iOS)
        var backgroundTaskId = AppState.shared.beginBackgroundTask()
        #endif
        /// If the dashboard is open in the inspector on iPad, it won't be recalculate its data on its own.
        /// So we use the ``DataChangeTriggers`` class to send a notification to the view to tell it to recalculate.
        DataChangeTriggers.shared.viewDidChange(.calendar)
                
        LogManager.log()
        
        let repModel = PopulateSubmissionModel(
            month: sMonth.actualNum,
            year: sMonth.year,
            transactions: trans,
            budgets: budgets,
            isTransfer: isTransfer,
            budget: store.globalBudget.amount
        )
        
        let model = RequestModel(requestType: "add_populated_transactions_and_budgets", model: repModel)
        typealias ResultResponse = Result<PopulatedMonthResultModel?, AppError>
        let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
                    
        switch result {
        case .success(let model):
            LogManager.networkingSuccessful()
            if let model {
                if let populatedId = model.populatedId {
                    self.sMonth.populatedId = populatedId
                }
                
                for idModel in model.recordInfos {
                    let targetMonth = months.get(byEnumId: sMonth.enumID)
                    
                    if idModel.type == "transaction" {
                        let targetDays = targetMonth.days
                        let transactions = targetDays.flatMap({ $0.transactions })
                                                                        
                        if let index = transactions.firstIndex(where: { $0.id == idModel.uuid ?? "" }) {
                            transactions[index].serverID = String(idModel.id)
                            transactions[index].action = .edit
                            transactions[index].intendedServerAction = .edit
                            transactions[index].status = .saveSuccess
                            if let relatedID = idModel.relatedID {
                                transactions[index].relatedTransactionID = String(relatedID)
                            }
                            performLineItemAnimations(for: transactions[index], wasSuccessful: true)
                        }
                    } else {
                        if let index = targetMonth.budgets.firstIndex(where: { $0.id == idModel.uuid }) {
                            targetMonth.budgets[index].id = idModel.id
                            targetMonth.budgets[index].action = .edit
                        }
                    }
                }
            }
            
            #if os(iOS)
            AppState.shared.endBackgroundTask(&backgroundTaskId)
            #endif
            
        case .failure(let error):
            LogManager.error(error.localizedDescription)
            AppState.shared.showAlert("There was a problem trying to add multiple transactions.")
            
//            for each in trans {
//                performLineItemAnimations(for: each, wasSuccessful: false)
//            }
            
            #if os(iOS)
            AppState.shared.endBackgroundTask(&backgroundTaskId)
            #endif
        }
    }
}
