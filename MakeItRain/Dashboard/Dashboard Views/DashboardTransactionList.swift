//
//  DashboardTransactionList.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/16/26.
//


import SwiftUI
import Charts

struct DashboardTransactionList: View {
    @Environment(CalendarModel.self) private var calModel
    var data: DashboardData
    var category: CBCategory
    
    @State private var transactions: [CBTransaction] = []
    @State private var transEditID: String?
    @State private var editTrans: CBTransaction?
    @State private var transDay: CBDay? = CBDay(date: Date())
    
    @State private var isLoading = true
    
    var expenses: [CBTransaction] {
        calModel.dashboardTransactions.filter { $0.isExpense }
    }
    
    var income: [CBTransaction] {
        calModel.dashboardTransactions.filter { $0.isIncome }
    }
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView()
                    .tint(.none)
            } else if calModel.dashboardTransactions.isEmpty {
                ContentUnavailableView("No Transactions", systemImage: "square.stack.3d.up.slash.fill")
            } else {
                List {
                    if !expenses.isEmpty {
                        
                        Section {
                            ForEach(expenses) { trans in
                                TransactionListLine(trans: trans, withDate: true, withTags: true, withPhotos: true) {
                                    self.transEditID = trans.id
                                }
                            }
                        } header: {
                            Text("Expenses")
                        } footer: {
                            Text("Total: \((category.allAmounts?.actualSpend ?? 0).currencyWithDecimals())")
                        }
                    }
                    
                    if !income.isEmpty {
                        Section {
                            ForEach(income) { trans in
                                TransactionListLine(trans: trans, withDate: true, withTags: true, withPhotos: true) {
                                    self.transEditID = trans.id
                                }
                            }
                        } header: {
                            Text("Income")
                        } footer: {
                            Text("Total: \(((category.allAmounts?.regularIncome ?? 0) + (category.allAmounts?.irregularIncome ?? 0)).currencyWithDecimals())")
                        }
                    }
                }
            }
        }
        .navigationTitle("Transactions")
        .navigationSubtitle(category.title)
        .transactionEditSheetAndLogic(
            transEditID: $transEditID,
            selectedDay: $transDay,
            findTransactionWhere: .constant(.dashboardList)
        )
        .task {
            await search(calModel: calModel, sortOrder: .reverse)
        }
        .onDisappear {
            calModel.dashboardTransactions.removeAll()
        }
    }
    
    @MainActor
    func search(calModel: CalendarModel, sortOrder: SortOrder) async {
        print("-- \(#function)")
        let searchModel = AdvancedSearchModel()
        searchModel.categories = [category]
        searchModel.beginDate = data.beginDate
        searchModel.endDate = data.endDate
        LogManager.log()
        
        //print(category.id)
        //return
        
        let model = RequestModel(requestType: "new_advanced_search", model: searchModel)
        typealias ResultResponse = Result<Array<CBTransaction>?, AppError>
        async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
        
        switch await result {
        case .success(let model):
            LogManager.networkingSuccessful()
            if let model {
                for each in model {
                    await each.payMethod?.loadLogoFromCoreDataIfNeeded()
                }
                
                if sortOrder == .forward {
                    calModel.dashboardTransactions = model.sorted { $0.date ?? Date() > $1.date ?? Date() }
                } else {
                    calModel.dashboardTransactions = model.sorted { $0.date ?? Date() < $1.date ?? Date() }
                }
            }
            
        case .failure (let error):
            switch error {
            case .taskCancelled:
                /// Task get cancelled when switching years. So only show the alert if the error is not related to the task being cancelled.
                print("calModel fetchFrom Server Task Cancelled")
            default:
                LogManager.error(error.localizedDescription)
                AppState.shared.showAlert("There was a problem trying to fetch transactions.")
            }
        }
        
        isLoading = false
    }
}
