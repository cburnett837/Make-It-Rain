//
//  AllBudgetsTable.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/8/26.
//

import SwiftUI
import Charts


struct TagRequestModel: Encodable {
    var tagId: String
    
    
    enum CodingKeys: CodingKey { case tag_id, user_id, account_id, device_uuid }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(tagId, forKey: .tag_id)
        try container.encode(AppState.shared.user?.id, forKey: .user_id)
        try container.encode(AppState.shared.user?.accountID, forKey: .account_id)
        try container.encode(AppState.shared.deviceUUID, forKey: .device_uuid)
    }
}


struct AllBudgetsTable: View {
    @Environment(CalendarModel.self) var calModel
    
    @State private var budgetEditID: CBBudget.ID?
    @State private var editBudget: CBBudget?

    var body: some View {
        List {
            ForEach(calModel.budgets.filter {$0.item?.budgetType == .tag}) { budget in
                
                NavigationLink {
                    if let tag = budget.tag {
                        TagTransList(budget: budget, tag: tag)
                    } else {
                        Text("Invalid tag")
                    }
                    
                } label: {
                    Text("#\(budget.item?.title ?? "N/A")")
                }

                
                    
            }
        }
        .navigationTitle("All Budgets")
        .onChange(of: budgetEditID) { oldId, newId in
            if let newId {
                if let editBudget = calModel.sMonth.budgets.first(where: { $0.id == newId }) {
                    self.editBudget = editBudget
                    
                } else if let editBudget = calModel.appSuiteBudgets.first(where: { $0.id == newId }) {
                    self.editBudget = editBudget
                    
                } else {
                    self.editBudget = CBBudget(uuid: newId)
                }
                
            } else if newId == nil && oldId != nil {
                var budget: CBBudget?
                
                if let editBudget = calModel.sMonth.budgets.first(where: { $0.id == oldId! }) {
                    budget = editBudget
                    
                } else if let editBudget = calModel.appSuiteBudgets.first(where: { $0.id == oldId! }) {
                    budget = editBudget
                    
                } else {
                 
                }
                
                if let budget = budget {
                    guard let item = budget.item else {
                        calModel.sMonth.budgets.removeAll(where: { $0.id == oldId! })
                        return
                    }
                    
                    if item.title.isEmpty {
                        print("Title is empty, deleting budget")
                        calModel.sMonth.budgets.removeAll(where: { $0.id == oldId! })
                    } else {
                        Task {
                            if budget.hasChanges() || budget.action == .add {
                                await calModel.submit(budget)
                            }
                        }
                    }
                } else {
                    print("cant find budget or item")
                }
            }
        }
        .sheet(item: $editBudget, onDismiss: {
            budgetEditID = nil
            //calculateDataFunction()
        }) { budget in
            BudgetEditView(budget: budget, calModel: calModel)
                .presentationSizing(.page)
        }
    }
}

struct TagTransList: View {
    @Environment(CalendarModel.self) var calModel

    var budget: CBBudget
    var tag: CBTag
    
    //@State private var transactions: [CBTransaction] = []
    @State private var transEditID: String?
    @State private var editTrans: CBTransaction?
    @State private var transDay: CBDay? = CBDay(date: Date())
    
    var totalExpenses: Double {
        return calModel.dashboardTransactions.map {$0.amount}.reduce(0, +)
    }
    
    var body: some View {
        List {
            Section("Budget") {
                
                theChart
                
                //Text("\(budget.amount.currencyWithDecimals())")
            }
            
            
            Section("Transactions") {
                ForEach(calModel.dashboardTransactions) { trans in
                    TransactionListLine(trans: trans, withDate: true, withPhotos: true) {
                        self.transEditID = trans.id
                    }
                }
            }
        }
        .navigationTitle("#\(tag.title)")
        .task {
            await fetchTransactions()
        }
        .transactionEditSheetAndLogic(
            transEditID: $transEditID,
            selectedDay: $transDay,
            findTransactionWhere: .constant(.dashboardList)
        )
        .onDisappear {
            calModel.dashboardTransactions.removeAll()
        }
    }
    
    var theChart: some View {
        Chart {
            BarMark(
                x: .value("Amount", budget.amount),
                y: .value("Key", "Budget \(budget.amount.currencyWithDecimals())")
            )
            .foregroundStyle(budget.category?.color ?? .gray)
        
            BarMark(
                x: .value("Amount", totalExpenses),
                y: .value("Key", "Expenses \(totalExpenses.currencyWithDecimals())")
            )
            .foregroundStyle(.gray)
        }
        .chartLegend(.hidden)
        .chartXAxis { xAxis() }
    }
    
    @AxisContentBuilder
    func xAxis() -> some AxisContent {
        AxisMarks(values: .automatic) {
            AxisGridLine()
            if let value = $0.as(Int.self) {
                AxisValueLabel {
                    Text("$\(value)")
                }
            }
            
        }
    }
    
    
    @MainActor
    func fetchTransactions() async {
        
        let requestModel = TagRequestModel(tagId: tag.id)
        
        /// Do networking.
        let model = RequestModel(requestType: "fetch_transactions_for_tag", model: requestModel)
        typealias ResultResponse = Result<Array<CBTransaction>?, AppError>
        async let result: ResultResponse = await NetworkManager().arrayRequest(requestModel: model)

        switch await result {
        case .success(let model):
            if let model {
                for each in model {
                    await each.payMethod?.loadLogoFromCoreDataIfNeeded()
                }
                
                withAnimation {
                    calModel.dashboardTransactions = model
                }
            }

        case .failure (let error):
            switch error {
            case .taskCancelled:
                /// Task get cancelled when switching years. So only show the alert if the error is not related to the task being cancelled.
                print("\(#function) Task Cancelled")
            default:
                LogManager.error(error.localizedDescription)
                AppState.shared.showAlert("There was a problem trying to fetch the dashboard.")
            }
        }
    }
}
