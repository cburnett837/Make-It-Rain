//
//  Model.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/18/24.
//

import Foundation
import SwiftUI
import PhotosUI
import CoreTransferable
#if canImport(AppKit)
import AppKit
#else
import UIKit
#endif


@MainActor
@Observable
class CalendarModel {
    @ObservationIgnored let store: AppStore
    init(store: AppStore) {
        self.store = store
        self.dashboardModel = DashboardModel(store: store, isForSelectedMonth: true)
    }
    
    var dashboardModel: DashboardModel
    
    
    // MARK: - State Variables
    var isThinking = false
    var showMonth = false
    var currentReceiptId: CBTransaction.ID?
    
    #if os(iOS)
    var isShowingFullScreenCoverOnIpad = false
    #endif
    
    var transactionViewHasBeenWarmedUp = false
    var isFirstCalendarLoad = true
    var windowMonth: NavDest?
    
    var sPayMethodBeforeFilterWasSetByCategoryPage: CBPaymentMethod?
    
    var sMonth: CBMonth {
        get { store.sMonth }
        set { store.sMonth = newValue }
    }
    var sYear: Int {
        get { store.sYear }
        set { store.sYear = newValue }
    }
    var sPayMethod: CBPaymentMethod? {
        get { store.sPayMethod }
        set { store.sPayMethod = newValue }
    }
    var sCategory: CBCategory? {
        get { store.sCategory }
        set { store.sCategory = newValue }
    }
    var sCategories: [CBCategory] {
        get { store.sCategories }
        set { store.sCategories = newValue }
    }
    var sCategoryGroups: [CBCategoryGroup] {
        get { store.sCategoryGroups }
        set { store.sCategoryGroups = newValue }
    }
    var sCategoriesForAnalysis: [CBCategory] {
        get { store.sCategoriesForAnalysis }
        set { store.sCategoriesForAnalysis = newValue }
    }
    var sCategoryGroupsForAnalysis: [CBCategoryGroup] {
        get { store.sCategoryGroupsForAnalysis }
        set { store.sCategoryGroupsForAnalysis = newValue }
    }
    
    var isPlayground: Bool { sYear == 1900 }
    var searchText = ""
    var searchWhat = CalendarSearchWhat.titles
    
    
    // MARK: - Loading Spinner Variables
    var showLoadingSpinner = false
    var loadingSpinnerTimer: Timer?
    
    
    // MARK: - Photo Variables
    var isUploadingSmartTransactionFile: Bool = false
    var smartTransactionDate: Date?
        
    
    // MARK: - Visual Variables
    var transactionToCopy: CBTransaction?
    var transactionIdToCopy: String?
    var dragTarget: CBDay?
        
    
    // MARK: - Multi-Select Variables
    var isInMultiSelectMode = false
    var multiSelectTransactions: Array<CBTransaction> = []
    var multiSelectTags: [CBTag] = []
    
    
    // MARK: - Data Container Variables
    var months: [CBMonth] {
        get { store.months }
        set { store.months = newValue }
    }
    var tempTransactions: [CBTransaction] {
        get { store.tempTransactions }
        set { store.tempTransactions = newValue }
    }
    var searchedTransactions: [CBTransaction] {
        get { store.searchedTransactions }
        set { store.searchedTransactions = newValue }
    }
    var dashboardTransactions: [CBTransaction] {
        get { store.dashboardTransactions }
        set { store.dashboardTransactions = newValue }
    }
    var receiptTransactions: [CBTransaction] {
        get { store.receiptTransactions }
        set { store.receiptTransactions = newValue }
    }
    var suggestedTitles: [CBSuggestedTitle] {
        get { store.suggestedTitles }
        set { store.suggestedTitles = newValue }
    }
    var suggestedLocations: [CBSuggestedLocation] {
        get { store.suggestedLocations }
        set { store.suggestedLocations = newValue }
    }
    
    
    // MARK: - Computed Helper Variables
    var justTransactions: Array<CBTransaction> {
        get { store.justTransactions }
    }
    
    var justBudgets: Array<CBBudgetItem> {
        months.flatMap { $0.budgets }
    }
    
    var isUnifiedPayMethod: Bool {
        self.sPayMethod?.accountType == .unifiedChecking || self.sPayMethod?.accountType == .unifiedCredit
    }
    
    var transCountForCurrentPayMethod: Int {
        if let meth = sPayMethod {
            sMonth.justTransactions.filter({ $0.payMethod?.id == meth.id }).count
        } else {
            sMonth.justTransactions.count
        }
    }
    
    
    // MARK: - Functions
    func setSelectedMonthFromNavigation(navID: NavDest, calculateStartingAndEod: Bool, shouldLoadDashboard: Bool) {
        let month = months.get(byEnumId: navID)
        sMonth = month
                       
        /// When a user performs navigation, this will run.
        /// Likewise, when the ``FuncModel`` does the initial download, this will not run.
        if calculateStartingAndEod {
            /// Needed for the mac to show the unified starting amount
            //prepareStartingAmount(for: self.sPayMethod)
            
            /// Get starting amounts, and refresh all the EOD totals.
            /// For example, If I go to another month, and fill out a starting amount, and don't run this, the EOD totals would be wrong when going back to the current month.
            CalcHelper.calculateTotal(for: sMonth, store: store)
        }
        
        if shouldLoadDashboard {
            self.dashboardModel.resetSelf()
            
            if let firstDate = month.legitDays.first?.date,
               let lastDate = month.legitDays.last?.date {
                
                self.dashboardModel.beginDate = firstDate
                self.dashboardModel.endDate = lastDate
                
                Task {
                    await self.dashboardModel.initialFetchIfApplicable(calModel: self)
                }
            }
        }
    }
    
    
    @MainActor
    func handleIncoming(titles: [CBSuggestedTitle], incomingDataType: IncomingDataType) {
        self.suggestedTitles = titles
    }
    
    
    @MainActor
    func handleIncoming(locations: [CBSuggestedLocation], incomingDataType: IncomingDataType) {
        self.suggestedLocations = locations
    }
    
    
    @MainActor
    func fetchReceiptsFromServer(funcModel: FuncModel) async {
        let fetchModel = GenericUserInfoModel()
        
        let start = CFAbsoluteTimeGetCurrent()
        
        let model = RequestModel(requestType: "fetch_receipts", model: fetchModel)
        typealias ResultResponse = Result<Array<CBTransaction>?, AppError>
        let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
        
        switch result {
        case .success(let model):
            if let model {
                if self.receiptTransactions.isEmpty {
                    for trans in model {
                        await trans.payMethod?.loadLogoFromCoreDataIfNeeded()
                        self.receiptTransactions.append(trans)
                    }
                    
                    await withTaskGroup(of: Void.self) { group in
                        for trans in self.receiptTransactions.prefix(3) {
                            if let files = trans.files?.filter({ $0.active }), !files.isEmpty, let firstFile = files.first {
                                group.addTask {
                                    await funcModel.downloadFile(file: firstFile)
                                }
                            }
                        }
                    }
                } else {
                    for trans in model {
                        if let index = self.receiptTransactions.firstIndex(where: { $0.id == trans.id }) {
                            self.receiptTransactions[index].setFromAnotherInstance(transaction: trans)
                        } else {
                            await trans.payMethod?.loadLogoFromCoreDataIfNeeded()
                            self.receiptTransactions.insert(trans, at: 0)
                        }
                    }
                }
                
                currentReceiptId = model.first?.id
            }
            
            print("⏰ It took \(CFAbsoluteTimeGetCurrent() - start) seconds to fetch the receipts.")
                
        case .failure (let error):
            switch error {
            case .taskCancelled:
                /// Task get cancelled when switching years. So only show the alert if the error is not related to the task being cancelled.
                print("receiptView fetchFromServer Server Task Cancelled")
            default:
                LogManager.error(error.localizedDescription)
                AppState.shared.showAlert("There was a problem trying to fetch fit transactions.")
            }
        }
    }
}
