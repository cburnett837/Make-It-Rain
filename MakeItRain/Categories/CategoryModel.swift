//
//  CategoryModel.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/28/24.
//

import Foundation
import SwiftUI

@MainActor
@Observable
class CategoryModel {
    var categories: Array<CBCategory> = []
    var categoryGroups: Array<CBCategoryGroup> = []
    var fuckYouSwiftuiTableRefreshID: UUID = UUID()
    
    func doesExist(_ category: CBCategory) -> Bool {
        return !categories.filter { $0.id == category.id }.isEmpty
    }
    
    func getCategory(by id: String) -> CBCategory {
        return categories.filter { $0.id == id }.first ?? CBCategory(uuid: id)
    }
    
    func upsert(_ category: CBCategory) {
        if doesExist(category), let index = getIndex(for: category) {
            categories[index].setFromAnotherInstance(category: category)
        } else {
            categories.append(category)
        }
    }
    
    func getIndex(for category: CBCategory) -> Int? {
        return categories.firstIndex(where: { $0.id == category.id })
    }
    
    func getNil() -> CBCategory? {
        categories.filter { $0.isNil }.first
    }
    
    
    func saveCategory(id: String, calModel: CalendarModel, keyModel: KeywordModel) {
        let category = getCategory(by: id)
        
        if category.action == .delete {
            category.updatedBy = AppState.shared.user!
            category.updatedDate = Date()
            delete(category, andSubmit: true, calModel: calModel, keyModel: keyModel)
            return
        }
        
        /// User blanked out the title of an existing category.
        if category.title.isEmpty {
            if category.action == .edit {
                category.title = category.deepCopy?.title ?? ""
                AppState.shared.showAlert("Removing a title is not allowed. If you want to delete \(category.title), please use the delete button instead.")
            } else {
                /// Remove the dud that is in `.add` mode since it's being upserted into the list on creation.
                withAnimation { categories.removeAll { $0.id == id } }
            }
            return
        }
        
        if category.hasChanges() {
            Task {
                category.updatedBy = AppState.shared.user!
                category.updatedDate = Date()
                
                /// Do this to allow new items to be sorted. Something weird happens and it tried to move the second to last item if you don't sort when adding
                if category.action == .add {
                    category.listOrder = categories.filter { !$0.isNil }.count
                    categories.sort(by: Helpers.categorySorter())
                }
                
                let wasSuccessful = await submit(category)
                if wasSuccessful {
                    var budgetsToServer: Array<CBBudget> = []
                    
                    /// Update the category info on the associated keywords.
                    //let context = DataManager.shared.createContext()
                    
                    for keyword in keyModel.keywords.filter({ $0.category?.id == category.id }) {
                        keyword.category?.setFromAnotherInstance(category: category)
                    }
                    
                    await _updatePersistentKeywords(category: category)
                    
                    
                    calModel.months.forEach { month in
                        /// Update the local transactions with the new category info.
                        month.days.forEach { day in
                            day.transactions.filter { $0.category?.id == category.id }.forEach { transaction in
                                transaction.category = category
                            }
                        }
                        
                        /// Handle normal categories.
                        if category.appSuiteKey == nil {
                            if let index = month.budgets.firstIndex(where: { $0.category?.id == category.id }) {
                                /// Update the months budget with the new category info (if applicable).
                                month.budgets[index].category = category
                                
                            } else if !month.budgets.isEmpty {
                                /// If a budget has already been created for the month, add the new category (if applicable).
                                
                                let budget = CBBudget()
                                budget.month = month.actualNum
                                budget.year = month.year
                                budget.amountString = category.amountString ?? ""
                                budget.category = category
                                
                                budgetsToServer.append(budget)
                                month.budgets.append(budget)
                            }
                        }
                        /// Handle special categories (Like the christmas budget)
                        else {
                            //print("HERE!!!!")
                            //                            if let index = month.budgets.firstIndex(where: { $0.category?.id == category.id }) {
                            //                                calModel.appSuiteBudgets[index].category = category
                            //                            }
                            
                            if let index = calModel.appSuiteBudgets.firstIndex(where: { $0.category?.id == category.id }) {
                                calModel.appSuiteBudgets[index].category = category
                            }
                        }
                    }
                    
                    if !budgetsToServer.isEmpty {
                        let _ = await submitNewBudgets(budgets: budgetsToServer, calModel: calModel)
                    }
                }
            }
        }
        
        
        /// Updated for concurrency rules.
        func _updatePersistentKeywords(category: CBCategory) async {
            let categoryID = category.id
            let keywordInfos = keyModel.keywords.map { (id: $0.id, categoryId: $0.category?.id) }
            
            let context = DataManager.shared.createContext()
            await DataManager.shared.perform(context: context) {
                for keyword in keywordInfos.filter({ $0.categoryId == categoryID }) {
                    if let entity = DataManager.shared.getOne(
                        context: context,
                        type: PersistentKeyword.self,
                        predicate: .byId(.string(keyword.id)),
                        createIfNotFound: false
                    ),
                    let categoryEntity = DataManager.shared.getOne(
                        context: context,
                        type: PersistentCategory.self,
                        predicate: .byId(.string(keyword.categoryId ?? "0")),
                        createIfNotFound: false
                    ) {
                        entity.category = categoryEntity
                    }
                }
                
                DataManager.shared.save(context: context)
            }
        }
    }
    
    
//    @MainActor
//    func fetchCategories(file: String = #file, line: Int = #line, function: String = #function) async {
//        LogManager.log()
//        
//        let start = CFAbsoluteTimeGetCurrent()
//        
//        /// For testing bad network connection.
//        //try? await Task.sleep(nanoseconds: UInt64(10 * Double(NSEC_PER_SEC)))
//        
//        /// Do networking.
//        let model = RequestModel(requestType: "fetch_categories", model: AppState.shared.user)
//        typealias ResultResponse = Result<Array<CBCategory>?, AppError>
//        async let result: ResultResponse = await NetworkManager().arrayRequest(requestModel: model)
//        
//        switch await result {
//        case .success(let model):
//            LogManager.networkingSuccessful()
//            if let model {
//                if !model.isEmpty {
//                    for category in model.sorted(by: Helpers.categorySorter()) {
//                        upsert(category)
//                        await category.updateCoreData(action: .edit, isPending: false, createIfNotFound: true)
//                    }
//                    
//                    /// Delete from cache and local list.
//                    for category in categories {
//                        if model.filter({ $0.id == category.id }).isEmpty {
//                            categories.removeAll { $0.id == category.id }
//                        }
//                    }
//                } else {
//                    categories.removeAll()
//                }
//            }
//            
//            let currentElapsed = CFAbsoluteTimeGetCurrent() - start
//            print("⏰It took \(currentElapsed) seconds to fetch the categories")
//            
//        case .failure (let error):
//            switch error {
//            case .taskCancelled:
//                /// Task get cancelled when switching years. So only show the alert if the error is not related to the task being cancelled.
//                print("catModel fetchFrom Server Task Cancelled")
//            default:
//                LogManager.error(error.localizedDescription)
//                AppState.shared.showAlert("There was a problem trying to fetch the categories.")
//            }
//        }
//    }
    
    
//    @MainActor
//    func handleDownloadedCategories(categories: Array<CBCategory>?, file: String = #file, line: Int = #line, function: String = #function) async {
//        if let categories {
//            if !categories.isEmpty {
//                for category in categories.sorted(by: Helpers.categorySorter()) {
//                    upsert(category)
//                    await category.updateCoreData(action: .edit, isPending: false, createIfNotFound: true)
//                }
//                
//                /// Delete from cache and local list.
//                for category in self.categories {
//                    if categories.filter({ $0.id == category.id }).isEmpty {
//                        self.categories.removeAll { $0.id == category.id }
//                    }
//                }
//            } else {
//                self.categories.removeAll()
//            }
//        }
//    }
    
    
    
    @MainActor
    func handleIncoming(cats: Array<CBCategory>, calModel: CalendarModel, keyModel: KeywordModel, repModel: RepeatingTransactionModel, incomingDataType: IncomingDataType) async {
        if cats.isEmpty {
            categories.removeAll()
            return
        }
        
        for category in categories.sorted(by: Helpers.categorySorter()) {
            if self.doesExist(category) {
                if !category.active {
                    self.delete(category, andSubmit: false, calModel: calModel, keyModel: keyModel)
                    continue
                } else {
                    if let index = self.getIndex(for: category) {
                        self.categories[index].setFromAnotherInstance(category: category)
                        self.categories[index].deepCopy?.setFromAnotherInstance(category: category)
                    }
                }
            } else {
                if category.active {
                    withAnimation { self.upsert(category) }
                }
            }
            
            await category.updateCoreData(action: .edit, isPending: false, createIfNotFound: incomingDataType == .viaStandardRefresh)
            
            calModel.justTransactions.filter { $0.category?.id == category.id }.forEach { $0.category = category }
            repModel.repTransactions.filter { $0.category?.id == category.id }.forEach { $0.category = category }
        }
        
        /// When downloading everything from the server, if we find a local object that is not in the server payload, it means it is no longer valid and must be deleted from the local copies.
        if incomingDataType == .viaStandardRefresh {
            for category in self.categories {
                if categories.filter({ $0.id == category.id }).isEmpty {
                    self.categories.removeAll { $0.id == category.id }
                }
            }
        }
    }
    
    
    
    
    @MainActor
    @discardableResult
    func submit(_ category: CBCategory) async -> Bool {
        print("-- \(#function)")
        
        /// Allow more time to save if the user enters the background.
        #if os(iOS)
        var backgroundTaskId = AppState.shared.beginBackgroundTask()
        #endif
        
        LogManager.log()
        
        /// Used to test the snapshot data race
        //try? await Task.sleep(nanoseconds: UInt64(6 * Double(NSEC_PER_SEC)))
        
        /// Stuff in core data in case something goes wrong in the networking.
        /// If something goes wrong, the isPending flag will cause it to be queued for syncing on next successful connection.
        await category.updateCoreData(action: category.action, isPending: true, createIfNotFound: true)
                       
        let model = RequestModel(requestType: category.action.serverKey, model: category)
        typealias ResultResponse = Result<ReturnIdModel?, AppError>
        async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
        
        switch await result {
        case .success(let model):
            LogManager.networkingSuccessful()
            
            if category.action == .delete {
                DataManager.shared.delete(context: DataManager.shared.createContext(), type: PersistentCategory.self, predicate: .byId(.string(category.id)))
                
            } else if let serverID = model?.id {
                /// If adding, the keyword ID will be the UUID, which is what would have been used to save the item to core data initially, so pass it as the lookupID.
                /// Pass the new serverID as the id so it gets set on the keyword.
                await category.updateAfterSubmit(
                    id: category.action == .add ? serverID : category.id,
                    lookupId: category.id,
                    action: category.action
                )
            }
            
        case .failure(let error):
            LogManager.error(error.localizedDescription)
            AppState.shared.showAlert("There was a problem syncing the category. Will try again at a later time.")
        }
                
        #if os(macOS)
        fuckYouSwiftuiTableRefreshID = UUID()
        #endif
        
        #if os(iOS)
        AppState.shared.endBackgroundTask(&backgroundTaskId)
        #endif
        
        return (await result).isSuccess
        
    }
    
    
    func delete(_ category: CBCategory, andSubmit: Bool, calModel: CalendarModel, keyModel: KeywordModel) {
        category.action = .delete
        category.deepCopy?.action = .delete
        withAnimation {
            categories.removeAll { $0.id == category.id }
            keyModel.keywords.removeAll { $0.category?.id == category.id }
            
            calModel.justTransactions.filter { $0.category?.id == category.id }.forEach { $0.category = nil }
            calModel.months.forEach { $0.budgets.removeAll { $0.category?.id == category.id } }
            //eventModel.events.forEach { $0.transactions.removeAll { $0.category?.id == category.id } }
        }
        
        if andSubmit {
            Task { @MainActor in
                let _ = await submit(category)
            }
        } else {
            let context = DataManager.shared.createContext()
            DataManager.shared.delete(context: context, type: PersistentCategory.self, predicate: .byId(.string(category.id)))
        }
    }
    
    
    func deleteAll() async {
        let context = DataManager.shared.createContext()
        for meth in categories {
            meth.action = .delete
            let _ = await submit(meth)
        }
        
        let _ = DataManager.shared.deleteAll(context: context, for: PersistentCategory.self)
        let _ = DataManager.shared.save(context: context)
        //print("SaveResult: \(saveResult)")
        categories.removeAll()
    }
    
    
    //@MainActor
    func fetchExpensesByCategory(_ analModel: AnalysisRequestModel) async -> Array<CategoryAnalysisResponseModel>? {
        print("-- \(#function)")
        //LoadingManager.shared.startDelayedSpinner()
        LogManager.log()
        
        /// Networking
        let model = RequestModel(requestType: "fetch_expenses_by_category", model: analModel)
        
        typealias ResultResponse = Result<Array<CategoryAnalysisResponseModel>?, AppError>
        async let result: ResultResponse = await NetworkManager().arrayRequest(requestModel: model)
        
        switch await result {
        case .success(let model):
            LogManager.networkingSuccessful()
            return model
            
        case .failure(let error):
            
            switch error {
            case .taskCancelled:
                print("Task cancelled")
                return nil
            default:
                LogManager.error(error.localizedDescription)
                AppState.shared.showAlert("There was a problem trying to fetch the analytics.")
                return nil
            }
        }
        //LoadingManager.shared.stopDelayedSpinner()
    }
    
    
//    @MainActor
//    func handleLongPollCategories(_ categories: Array<CBCategory>, calModel: CalendarModel, keyModel: KeywordModel, repModel: RepeatingTransactionModel) async {
//        print("-- \(#function)")
//        for category in categories {
//            if self.doesExist(category) {
//                if !category.active {
//                    self.delete(category, andSubmit: false, calModel: calModel, keyModel: keyModel)
//                    continue
//                } else {
//                    if let index = self.getIndex(for: category) {
//                        self.categories[index].setFromAnotherInstance(category: category)
//                        self.categories[index].deepCopy?.setFromAnotherInstance(category: category)
//                    }
//                }
//            } else {
//                if category.active {
//                    withAnimation { self.upsert(category) }
//                }
//            }
//            
//            await category.updateCoreData(action: .edit, isPending: false, createIfNotFound: false)
//            
//            calModel.justTransactions.filter { $0.category?.id == category.id }.forEach { $0.category = category }
//            repModel.repTransactions.filter { $0.category?.id == category.id }.forEach { $0.category = category }
//        }
//        
//        //let categorySortMode = SortMode.fromString(UserDefaults.standard.string(forKey: "categorySortMode") ?? "")
//                           
//        withAnimation {
//            self.categories.sort(by: Helpers.categorySorter())
//        }
//    }
    
    
    @MainActor
    func populateFromCoreData() async {
        let context = DataManager.shared.createContext()

        let categoryIDs: [String] = await DataManager.shared.perform(context: context) {
            let entities = DataManager.shared.getMany(context: context, type: PersistentCategory.self) ?? []
            return entities.compactMap(\.id)
        }

        guard !categoryIDs.isEmpty else { return }

        var loadedCategories: [CBCategory] = []
        loadedCategories.reserveCapacity(categoryIDs.count)

        for id in categoryIDs {
            if let category = await CBCategory.loadFromCoreData(id: id) {
                loadedCategories.append(category)
            }
        }

        for category in loadedCategories {
            self.upsert(category)
        }

        self.categories.sort(by: Helpers.categorySorter())
    }
    
    
    @MainActor
    func setListOrders(calModel: CalendarModel) async -> Array<ListOrderUpdate> {
        var updates: Array<ListOrderUpdate> = []
        var index = 1
        
        for category in self.categories.filter({ !$0.isNil && $0.appSuiteKey == nil }) {
            print("New list order \(category.title) - \(index)")
            
            category.listOrder = index
            updates.append(ListOrderUpdate(id: category.id, listorder: index))
            index += 1
            
            calModel.months.forEach { month in
                month.days.forEach { day in
                    day.transactions.filter { $0.category?.id == category.id }.forEach { transaction in
                        transaction.category?.listOrder = category.listOrder
                    }
                }
                
                if let index = month.budgets.firstIndex(where: { $0.category?.id == category.id }) {
                    month.budgets[index].category?.listOrder = category.listOrder
                }
            }
        }
        await persistListOrders(updates: updates)
        return updates
    }
    
    
    func persistListOrders(updates: [ListOrderUpdate]) async {
        let context = DataManager.shared.createContext()
        await context.perform {
            for update in updates {
                if let entity = DataManager.shared.getOne(context: context, type: PersistentCategory.self, predicate: .byId(.string(update.id)), createIfNotFound: false) {
                    entity.listOrder = Int64(update.listorder)
                }
            }
            
            let _ = DataManager.shared.save(context: context)
        }
    }
    
    
    @MainActor
    func submitNewBudgets(budgets: Array<CBBudget>, calModel: CalendarModel) async -> Bool {
        print("-- \(#function)")
        /// Allow more time to save if the user enters the background.
        #if os(iOS)
        var backgroundTaskId = AppState.shared.beginBackgroundTask()
        #endif
                
        let model = RequestModel(requestType: "add_budgets_to_months", model: budgets)
        
        typealias ResultResponse = Result<Array<ReturnIdModel>?, AppError>
        async let result: ResultResponse = await NetworkManager().arrayRequest(requestModel: model)
        
        switch await result {
        case .success(let model):
            LogManager.networkingSuccessful()
            if let model {
                for idModel in model {
                    if let targetMonth = calModel.months.filter({$0.budgets.map {$0.id}.contains(idModel.uuid)}).first {
                        let index = targetMonth.budgets.firstIndex(where: { $0.id == idModel.uuid })
                        if let index {
                            targetMonth.budgets[index].id = idModel.id
                            targetMonth.budgets[index].uuid = nil
                            targetMonth.budgets[index].action = .edit
                        }
                    }
                }
            }
            
        case .failure(let error):
            LogManager.error(error.localizedDescription)
            AppState.shared.showAlert("There was a problem trying to add the new budgets to the server.")
        }
        
        #if os(iOS)
        AppState.shared.endBackgroundTask(&backgroundTaskId)
        #endif
        
        return (await result).isSuccess
    }
}







// MARK: - Groups
extension CategoryModel {
    func doesExist(_ group: CBCategoryGroup) -> Bool {
        return !categoryGroups.filter { $0.id == group.id }.isEmpty
    }
    
    func getCategoryGroup(by id: String) -> CBCategoryGroup {
        return categoryGroups.filter { $0.id == id }.first ?? CBCategoryGroup(uuid: id)
    }
    
    func upsert(_ group: CBCategoryGroup) {
        if doesExist(group), let index = getIndex(for: group) {
            categoryGroups[index].setFromAnotherInstance(group: group)
        } else {
            categoryGroups.append(group)
        }
    }
    
    func getIndex(for group: CBCategoryGroup) -> Int? {
        return categoryGroups.firstIndex(where: { $0.id == group.id })
    }
    
    
    func saveCategoryGroup(id: String) {
        let group = getCategoryGroup(by: id)
        
        if group.action == .delete {
            group.updatedBy = AppState.shared.user!
            group.updatedDate = Date()
            delete(group, andSubmit: true)
            return
        }
                
        if group.title.isEmpty {
            /// User blanked out the title of an existing transaction.
            if group.action == .edit {
                group.title = group.deepCopy?.title ?? ""
                AppState.shared.showAlert("Removing a title is not allowed. If you want to delete \(group.title), please use the delete button instead.")
            } else {
                /// Remove the dud that is in `.add` mode since it's being upserted into the list on creation.
                withAnimation { categoryGroups.removeAll { $0.id == id } }
            }
            return
        }
                                                
        if group.hasChanges() {
            group.updatedBy = AppState.shared.user!
            group.updatedDate = Date()
            Task {
                let _ = await submit(group)
            }
        }
    }
    
    
//    @MainActor
//    func fetchCategoryGroups(file: String = #file, line: Int = #line, function: String = #function) async {
//        NSLog("\(file):\(line) : \(function)")
//        LogManager.log()
//        
//        let start = CFAbsoluteTimeGetCurrent()
//        
//        /// For testing bad network connection.
//        //try? await Task.sleep(nanoseconds: UInt64(10 * Double(NSEC_PER_SEC)))
//        
//        /// Do networking.
//        let model = RequestModel(requestType: "fetch_category_groups", model: AppState.shared.user)
//        typealias ResultResponse = Result<Array<CBCategoryGroup>?, AppError>
//        async let result: ResultResponse = await NetworkManager().arrayRequest(requestModel: model)
//        
//        switch await result {
//        case .success(let model):
//            LogManager.networkingSuccessful()
//            if let model {
//                if !model.isEmpty {
//                    for group in model {
//                        upsert(group)
//                        await group.updateCoreData(action: .edit, isPending: false, createIfNotFound: true)
//                    }
//                    
//                    /// Delete from cache and local list.
//                    for group in categoryGroups {
//                        if model.filter({ $0.id == group.id }).isEmpty {
//                            categoryGroups.removeAll { $0.id == group.id }
//                        }
//                    }
//                } else {
//                    categoryGroups.removeAll()
//                }
//            }
//            
//            let currentElapsed = CFAbsoluteTimeGetCurrent() - start
//            print("⏰It took \(currentElapsed) seconds to fetch the category groups")
//            
//        case .failure (let error):
//            switch error {
//            case .taskCancelled:
//                /// Task get cancelled when switching years. So only show the alert if the error is not related to the task being cancelled.
//                print("catModel fetchFrom Server Task Cancelled")
//            default:
//                LogManager.error(error.localizedDescription)
//                AppState.shared.showAlert("There was a problem trying to fetch the category groups.")
//            }
//        }
//    }
    
    
//    @MainActor
//    func handleDownloadedCategoryGroups(groups: Array<CBCategoryGroup>?, file: String = #file, line: Int = #line, function: String = #function) async {
//        if let groups {
//            if !groups.isEmpty {
//                for group in groups {
//                    upsert(group)
//                    await group.updateCoreData(action: .edit, isPending: false, createIfNotFound: true)
//                }
//                
//                /// Delete from cache and local list.
//                for group in categoryGroups {
//                    if groups.filter({ $0.id == group.id }).isEmpty {
//                        categoryGroups.removeAll { $0.id == group.id }
//                    }
//                }
//            } else {
//                categoryGroups.removeAll()
//            }
//        }
//    }
    
    
    @MainActor
    func handleIncoming(groups: Array<CBCategoryGroup>, incomingDataType: IncomingDataType) async {
        if groups.isEmpty {
            categoryGroups.removeAll()
            return
        }
        
        for group in groups {
            if self.doesExist(group) {
                if !group.active {
                    self.delete(group, andSubmit: false)
                    continue
                } else {
                    if let index = self.getIndex(for: group) {
                        self.categoryGroups[index].setFromAnotherInstance(group: group)
                        self.categoryGroups[index].deepCopy?.setFromAnotherInstance(group: group)
                    }
                }
            } else {
                if group.active {
                    withAnimation { self.upsert(group) }
                }
            }
            
            await group.updateCoreData(action: .edit, isPending: false, createIfNotFound: incomingDataType == .viaStandardRefresh)
        }
        
        /// When downloading everything from the server, if we find a local object that is not in the server payload, it means it is no longer valid and must be deleted from the local copies.
        if incomingDataType == .viaStandardRefresh {
            for group in categoryGroups {
                if groups.filter({ $0.id == group.id }).isEmpty {
                    categoryGroups.removeAll { $0.id == group.id }
                }
            }
        }
    }
    
    
    @MainActor
    @discardableResult
    func submit(_ group: CBCategoryGroup) async -> Bool {
        print("-- \(#function)")
        /// Allow more time to save if the user enters the background.
        #if os(iOS)
        var backgroundTaskId = AppState.shared.beginBackgroundTask()
        #endif
                        
        LogManager.log()
        
        /// Used to test the snapshot data race
        //try? await Task.sleep(nanoseconds: UInt64(6 * Double(NSEC_PER_SEC)))
        
        /// Stuff in core data in case something goes wrong in the networking.
        /// If something goes wrong, the isPending flag will cause it to be queued for syncing on next successful connection.
        await group.updateCoreData(action: group.action, isPending: true, createIfNotFound: true)
        
        let model = RequestModel(requestType: group.action.serverKey, model: group)
        typealias ResultResponse = Result<ReturnIdModel?, AppError>
        async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
                    
        switch await result {
        case .success(let model):
            LogManager.networkingSuccessful()
            
            if group.action == .delete {
                DataManager.shared.delete(context: DataManager.shared.createContext(), type: PersistentCategoryGroup.self, predicate: .byId(.string(group.id)))
                
            } else if let serverID = model?.id {
                /// If adding, the keyword ID will be the UUID, which is what would have been used to save the item to core data initially, so pass it as the lookupID.
                /// Pass the new serverID as the id so it gets set on the keyword.
                await group.updateAfterSubmit(
                    id: group.action == .add ? serverID : group.id,
                    lookupId: group.id,
                    action: group.action
                )
            }

        case .failure(let error):
            LogManager.error(error.localizedDescription)
            AppState.shared.showAlert("There was a problem syncing the category. Will try again at a later time.")
        }
        
        #if os(macOS)
        fuckYouSwiftuiTableRefreshID = UUID()
        #endif
        
        #if os(iOS)
        AppState.shared.endBackgroundTask(&backgroundTaskId)
        #endif
        
        return (await result).isSuccess
    }
    
    
    func delete(_ group: CBCategoryGroup, andSubmit: Bool) {
        group.action = .delete
        group.deepCopy?.action = .delete
        withAnimation { categoryGroups.removeAll { $0.id == group.id } }
        
        if andSubmit {
            Task { @MainActor in
                let _ = await submit(group)
            }
        } else {
            let context = DataManager.shared.createContext()
            DataManager.shared.delete(context: context, type: PersistentCategoryGroup.self, predicate: .byId(.string(group.id)))
        }
    }
    
    
    @MainActor
    func populateCategoryGroupsFromCoreData() async {
        let context = DataManager.shared.createContext()

        let groupIDs: [String] = await DataManager.shared.perform(context: context) {
            let entities = DataManager.shared.getMany(context: context, type: PersistentCategoryGroup.self) ?? []
            return entities.compactMap(\.id)
        }

        guard !groupIDs.isEmpty else { return }

        var loadedGroups: [CBCategoryGroup] = []
        loadedGroups.reserveCapacity(groupIDs.count)

        for id in groupIDs {
            if let group = await CBCategoryGroup.loadFromCoreData(id: id) {
                loadedGroups.append(group)
            }
        }

        for group in loadedGroups {
            self.upsert(group)
        }
    }

    
    
    
//    @MainActor
//    func handleLongPollCategoryGroups(_ groups: Array<CBCategoryGroup>) async {
//        print("-- \(#function)")
//        for group in groups {
//            if self.doesExist(group) {
//                if !group.active {
//                    self.delete(group, andSubmit: false)
//                    continue
//                } else {
//                    if let index = self.getIndex(for: group) {
//                        self.categoryGroups[index].setFromAnotherInstance(group: group)
//                        self.categoryGroups[index].deepCopy?.setFromAnotherInstance(group: group)
//                    }
//                }
//            } else {
//                if group.active {
//                    withAnimation { self.upsert(group) }
//                }
//            }
//            
//            await group.updateCoreData(action: .edit, isPending: false, createIfNotFound: false)
//        }
//    }
    
    
    
    
//    
//    func updateCache(
//        for group: CBCategoryGroup,
//        createIfNotFound: Bool,
//        findById: String,
//        action: CategoryGroupAction,
//        isPending: Bool
//    ) async -> Result<Bool, CoreDataError> {
//        
//        // Extract value-type data only
//        let id = group.id
//        let title = group.title
//        let amount = group.amount ?? 0.0
//        let actionRaw = action.rawValue
//        let enteredByID = Int64(group.enteredBy.id)
//        let updatedByID = Int64(group.updatedBy.id)
//        let enteredDate = group.enteredDate
//        let updatedDate = group.updatedDate
//        
//        // Extract categories as value types before crossing boundary
//        let categories = group.categories.map { cat in
//            return (
//                id: cat.id,
//                title: cat.title,
//                amount: cat.amount ?? 0.0,
//                hexCode: cat.color.toHex(),
//                emoji: cat.emoji ?? "",
//                action: cat.action.rawValue,
//                isPending: false,
//                isHidden: cat.isHidden,
//                typeID: Int64(cat.type.id),
//                listOrder: Int64(cat.listOrder ?? 0),
//                isNil: cat.isNil,
//                enteredByID: Int64(cat.enteredBy.id),
//                updatedByID: Int64(cat.updatedBy.id),
//                enteredDate: cat.enteredDate,
//                updatedDate: cat.updatedDate,
//                appSuiteKey: cat.appSuiteKey?.rawValue
//            )
//        }
//        
//        let context = DataManager.shared.createContext()
//        
//        return await context.perform {
//            print("Looking for group by id \(findById) with real id \(id)")
//            guard let entity = DataManager.shared.getOne(
//                context: context,
//                type: PersistentCategoryGroup.self,
//                predicate: .byId(.string(findById)),
//                createIfNotFound: createIfNotFound
//            ) else {
//                return .failure(.notFound)
//            }
//            
//            entity.id = id
//            entity.title = title
//            entity.amount = amount
//            entity.action = actionRaw
//            entity.enteredByID = enteredByID
//            entity.updatedByID = updatedByID
//            entity.enteredDate = enteredDate
//            entity.updatedDate = updatedDate
//            
//            var newSet: Set<PersistentCategory> = []
//            
//            for cat in categories {
//                guard let catEntity = DataManager.shared.getOne(
//                    context: context,
//                    type: PersistentCategory.self,
//                    predicate: .byId(.string(cat.id)),
//                    createIfNotFound: true
//                ) else {
//                    return .failure(.notFound)
//                }
//                
//                // Update category (safe because we’re in the context queue)
//                catEntity.id = cat.id
//                catEntity.title = cat.title
//                catEntity.amount = cat.amount
//                catEntity.hexCode = cat.hexCode
//                catEntity.emoji = cat.emoji
//                catEntity.action = cat.action
//                catEntity.isPending = cat.isPending
//                catEntity.isHidden = cat.isHidden
//                catEntity.typeID = cat.typeID
//                catEntity.listOrder = cat.listOrder
//                catEntity.isNil = cat.isNil
//                catEntity.enteredByID = cat.enteredByID
//                catEntity.updatedByID = cat.updatedByID
//                catEntity.enteredDate = cat.enteredDate
//                catEntity.updatedDate = cat.updatedDate
//                catEntity.appSuiteKey = cat.appSuiteKey
//                
//                newSet.insert(catEntity)
//            }
//            
//            entity.categories = newSet as NSSet
//            
//            return DataManager.shared.save(context: context)
//        }
//    }
}
