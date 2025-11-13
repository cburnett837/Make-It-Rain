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
    //static let shared = CategoryModel()
    var isThinking = false
    
    //var categoryEditID: Int?
    var categories: Array<CBCategory> = []
    var categoryGroups: Array<CBCategoryGroup> = []
    //var refreshTask: Task<Void, Error>?
    var fuckYouSwiftuiTableRefreshID: UUID = UUID()
    
    func doesExist(_ category: CBCategory) -> Bool {
        return !categories.filter { $0.id == category.id }.isEmpty
    }
    
    func getCategory(by id: String) -> CBCategory {
        return categories.filter { $0.id == id }.first ?? CBCategory(uuid: id)
    }
    
    func upsert(_ category: CBCategory) {
        if !doesExist(category) {
            categories.append(category)
        }
    }
    
    func getIndex(for category: CBCategory) -> Int? {
        return categories.firstIndex(where: { $0.id == category.id })
    }
        
    func doesExist(_ group: CBCategoryGroup) -> Bool {
        return !categoryGroups.filter { $0.id == group.id }.isEmpty
    }
    
    func getCategoryGroup(by id: String) -> CBCategoryGroup {
        return categoryGroups.filter { $0.id == id }.first ?? CBCategoryGroup(uuid: id)
    }
    
    func upsert(_ group: CBCategoryGroup) {
        if !doesExist(group) {
            categoryGroups.append(group)
        }
    }
    
    func getIndex(for group: CBCategoryGroup) -> Int? {
        return categoryGroups.firstIndex(where: { $0.id == group.id })
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
                    
                    if !budgetsToServer.isEmpty {
                        let _ = await submitNewBudgets(budgets: budgetsToServer, calModel: calModel)
                    }
                    
                }
            }
        }
        
        
        /// Updated for concurrency rules.
        func _updatePersistentKeywords(category: CBCategory) async {
            let categoryID = category.id
            // Copy only the simple data you need
            let keywordInfos = await MainActor.run {
                keyModel.keywords.map { (id: $0.id, categoryId: $0.category?.id) }
            }
            
            let context = DataManager.shared.createContext()
            await context.perform {
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
                
                _ = DataManager.shared.save(context: DataManager.shared.container.viewContext)
            }
        }
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
    
    
    @MainActor
    func submitNewBudgets(budgets: Array<CBBudget>, calModel: CalendarModel) async -> Bool {
        print("-- \(#function)")
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
            return true
        case .failure(let error):
            LogManager.error(error.localizedDescription)
            AppState.shared.showAlert("There was a problem trying to add the new budgets to the server.")
            //showSaveAlert = true
            #warning("Undo behavior")
            //let listActivity = activities.filter { $0.id == activity.id }.first ?? DailyActivity.emptyActivity
            //listActivity.deepCopy(.restore)
            return false
        }
    }
    
//    func updateCache(for category: CBCategory) async -> Result<Bool, CoreDataError> {
//        let context = DataManager.shared.createContext()
//        return await context.perform {
//            if let entity = DataManager.shared.getOne(
//                context: context,
//                type: PersistentCategory.self,
//                predicate: .byId(.string(category.id)),
//                createIfNotFound: false
//            ) {
//                entity.id = category.id
//                entity.title = category.title
//                entity.amount = category.amount ?? 0.0
//                entity.hexCode = category.color.toHex()
//                //entity.hexCode = category.color.description
//                entity.emoji = category.emoji ?? ""
//                entity.action = "edit"
//                entity.isPending = false
//                entity.typeID = Int64(category.type.id)
//                entity.listOrder = Int64(category.listOrder ?? 0)
//                entity.isNil = category.isNil
//                
//                entity.enteredByID = Int64(category.enteredBy.id)
//                entity.updatedByID = Int64(category.updatedBy.id)
//                entity.enteredDate = category.enteredDate
//                entity.updatedDate = category.updatedDate
//                
//                return DataManager.shared.save(context: context)
//            } else {
//                return .failure(.notFound)
//            }
//        }
//    }
    
    /// Updated for concurrency rules.
    func updateCache(for category: CBCategory) async -> Result<Bool, CoreDataError> {
        // Extract only value-type data before crossing the actor boundary
        let id = category.id
        let title = category.title
        let amount = category.amount ?? 0.0
        let hexCode = category.color.toHex()
        let emoji = category.emoji ?? ""
        let action = "edit"
        let isPending = false
        let typeID = Int64(category.type.id)
        let listOrder = Int64(category.listOrder ?? 0)
        let isNil = category.isNil
        let enteredByID = Int64(category.enteredBy.id)
        let updatedByID = Int64(category.updatedBy.id)
        let enteredDate = category.enteredDate
        let updatedDate = category.updatedDate

        let context = DataManager.shared.createContext()
        return await context.perform {
            guard let entity = DataManager.shared.getOne(
                context: context,
                type: PersistentCategory.self,
                predicate: .byId(.string(id)),
                createIfNotFound: false
            ) else {
                return .failure(.notFound)
            }

            entity.id = id
            entity.title = title
            entity.amount = amount
            entity.hexCode = hexCode
            entity.emoji = emoji
            entity.action = action
            entity.isPending = isPending
            entity.typeID = typeID
            entity.listOrder = listOrder
            entity.isNil = isNil
            entity.enteredByID = enteredByID
            entity.updatedByID = updatedByID
            entity.enteredDate = enteredDate
            entity.updatedDate = updatedDate

            return DataManager.shared.save(context: context)
        }
    }
    
    /// Updated for concurrency rules.
    @MainActor
    func fetchCategories(file: String = #file, line: Int = #line, function: String = #function) async {
        NSLog("\(file):\(line) : \(function)")
        LogManager.log()
        let context = DataManager.shared.createContext()
        /// Do networking.
        let model = RequestModel(requestType: "fetch_categories", model: AppState.shared.user)
        typealias ResultResponse = Result<Array<CBCategory>?, AppError>
        async let result: ResultResponse = await NetworkManager().arrayRequest(requestModel: model)
        
        switch await result {
        case .success(let model):
            
            /// For testing bad network connection.
            //try? await Task.sleep(nanoseconds: UInt64(10 * Double(NSEC_PER_SEC)))

            LogManager.networkingSuccessful()
            if let model {
                if !model.isEmpty {
                    var activeIds: Array<String> = []
                    for category in model {
                        
                        let id = category.id
                        let title = category.title
                        let amount = category.amount ?? 0.0
                        let hexCode = category.color.toHex()
                        let emoji = category.emoji ?? ""
                        let action = category.action
                        let typeID = Int64(category.type.id)
                        //let listOrder = Int64(category.listOrder ?? 0)
                        let isNil = category.isNil
                        let enteredByID = Int64(category.enteredBy.id)
                        let updatedByID = Int64(category.updatedBy.id)
                        let enteredDate = category.enteredDate
                        let updatedDate = category.updatedDate
                        
                        
                        activeIds.append(id)
                        let index = categories.firstIndex(where: { $0.id == id })
                        if let index {
                            /// If the category is already in the list, update it from the server.
                            categories[index].setFromAnotherInstance(category: category)
                        } else {
                            /// Add the category to the list (like when the category was added on another device).
                            categories.append(category)
                        }
                        
                        /// Update the cache.
                        await context.perform {
                            /// Find the category in cache.
                            /// This should always be true because the line above creates the entity if it's not found.
                            if let entity = DataManager.shared.getOne(context: context, type: PersistentCategory.self, predicate: .byId(.string(id)), createIfNotFound: true) {
                                entity.id = id
                                entity.title = title
                                entity.amount = amount
                                entity.hexCode = hexCode
                                //entity.hexCode = category.color.description
                                entity.emoji = emoji
                                entity.action = action.rawValue
                                entity.isPending = false
                                entity.typeID = typeID
                                entity.isNil = isNil
                                entity.enteredByID = enteredByID
                                entity.updatedByID = updatedByID
                                entity.enteredDate = enteredDate
                                entity.updatedDate = updatedDate
                                
                                let _ = DataManager.shared.save(context: context)
                            }
                        }
                    }
                    
                    /// Delete from cache and model.
                    for category in categories {
                        if !activeIds.contains(category.id) {
                            categories.removeAll { $0.id == category.id }
                            /// Does so in its own perform block.
                            DataManager.shared.delete(context: context, type: PersistentCategory.self, predicate: .byId(.string(category.id)))
                        }
                    }                    
                } else {
                    categories.removeAll()
                }
            }
            
            /// Update the progress indicator.
            AppState.shared.downloadedData.append(.categories)
            
        case .failure (let error):
            switch error {
            case .taskCancelled:
                /// Task get cancelled when switching years. So only show the alert if the error is not related to the task being cancelled.
                print("catModel fetchFrom Server Task Cancelled")
            default:
                LogManager.error(error.localizedDescription)
                AppState.shared.showAlert("There was a problem trying to fetch the categories.")
            }
        }
    }
    
    
    
    @MainActor
    func fetchCategoryGroups(file: String = #file, line: Int = #line, function: String = #function) async {
        NSLog("\(file):\(line) : \(function)")
        LogManager.log()
        
        /// Do networking.
        let model = RequestModel(requestType: "fetch_category_groups", model: AppState.shared.user)
        typealias ResultResponse = Result<Array<CBCategoryGroup>?, AppError>
        async let result: ResultResponse = await NetworkManager().arrayRequest(requestModel: model)
        
        switch await result {
        case .success(let model):
            
            /// For testing bad network connection.
            //try? await Task.sleep(nanoseconds: UInt64(10 * Double(NSEC_PER_SEC)))

            LogManager.networkingSuccessful()
            if let model {
                if !model.isEmpty {
                    var activeIds: Array<String> = []
                    for group in model {
                        activeIds.append(group.id)
                        let index = categoryGroups.firstIndex(where: { $0.id == group.id })
                        if let index {
                            /// If the category is already in the list, update it from the server.
                            categoryGroups[index].setFromAnotherInstance(group: group)
                        } else {
                            /// Add the category to the list (like when the category was added on another device).
                            categoryGroups.append(group)
                        }
                    }
                    
                    /// Delete from cache and model.
                    for group in categoryGroups {
                        if !activeIds.contains(group.id) {
                            categoryGroups.removeAll { $0.id == group.id }
                        }
                    }
            
                } else {
                    categoryGroups.removeAll()
                }
            }
            
            /// Update the progress indicator.
            AppState.shared.downloadedData.append(.categories)
            
        case .failure (let error):
            switch error {
            case .taskCancelled:
                /// Task get cancelled when switching years. So only show the alert if the error is not related to the task being cancelled.
                print("catModel fetchFrom Server Task Cancelled")
            default:
                LogManager.error(error.localizedDescription)
                AppState.shared.showAlert("There was a problem trying to fetch the categories.")
            }
        }
    }
    
    
    /// Updated for concurrency rules.
    @MainActor
    func submit(_ category: CBCategory) async -> Bool {
        print("-- \(#function)")
        isThinking = true
        //LoadingManager.shared.startDelayedSpinner()
        LogManager.log()
        
        let id = category.id
        let title = category.title
        let amount = category.amount ?? 0.0
        let hexCode = category.color.toHex()
        let emoji = category.emoji ?? ""
        let action = category.action
        let typeID = Int64(category.type.id)
        //let listOrder = Int64(category.listOrder ?? 0)
        let isNil = category.isNil
        let enteredByID = Int64(category.enteredBy.id)
        let updatedByID = Int64(category.updatedBy.id)
        let enteredDate = category.enteredDate
        let updatedDate = category.updatedDate
        
        /// Add the edited category into core data.
        let context = DataManager.shared.createContext()
        await context.perform {
            if let entity = DataManager.shared.getOne(
                context: context,
                type: PersistentCategory.self,
                predicate: .byId(.string(id)),
                createIfNotFound: true
            ) {
                entity.id = id
                entity.title = title
                entity.amount = amount
                entity.hexCode = hexCode
                //entity.hexCode = category.color.description
                entity.emoji = emoji
                entity.action = action.rawValue
                entity.typeID = typeID
                entity.isPending = true
                entity.isNil = isNil
                
                entity.enteredByID = enteredByID
                entity.updatedByID = updatedByID
                entity.enteredDate = enteredDate
                entity.updatedDate = updatedDate
                
                let _ = DataManager.shared.save(context: context)
            }
        }
                        
        let model = RequestModel(requestType: category.action.serverKey, model: category)
            
        /// Used to test the snapshot data race
        //try? await Task.sleep(nanoseconds: UInt64(6 * Double(NSEC_PER_SEC)))
        
        typealias ResultResponse = Result<ReturnIdModel?, AppError>
        async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
                    
        switch await result {
        case .success(let model):
            LogManager.networkingSuccessful()            
                       
            let modelID = model?.id ?? String(0)
            
            if category.action != .delete {
                await context.perform {
                    if let entity = DataManager.shared.getOne(
                        context: context,
                        type: PersistentCategory.self,
                        predicate: .byId(.string(id)),
                        createIfNotFound: true
                    ) {
                        /// If adding a new category, update core data with the server ID by finding it via the UUID.
                        if action == .add {
                            entity.id = modelID
                            entity.action = "edit"
                        }
                        /// Set pending = false since the internet connection would have worked if we made it to this point.
                        entity.isPending = false
                        
                        let _ = DataManager.shared.save(context: context)
                    }
                }
            
                /// Get the new ID from the server after adding a new activity.
                if category.action == .add {
                    category.id = model?.id ?? String(0)
                    category.uuid = nil
                    category.action = .edit
                }
                
            } else {
                /// Does so in its own perform block.
                DataManager.shared.delete(context: context, type: PersistentCategory.self, predicate: .byId(.string(category.id)))
            }
            
            isThinking = false
            category.action = .edit
            #if os(macOS)
            fuckYouSwiftuiTableRefreshID = UUID()
            #endif
            return true
            
        case .failure(let error):
            LogManager.error(error.localizedDescription)
            AppState.shared.showAlert("There was a problem syncing the category. Will try again at a later time.")
            //AppState.shared.showAlert("There was a problem trying to save the category.")
//            category.deepCopy(.restore)
//            
//            switch category.action {
//            case .add: categories.removeAll { $0.id == category.id }
//            case .edit: break
//            case .delete: categories.append(category)
//            }
            
            isThinking = false
            category.action = .edit
            #if os(macOS)
            fuckYouSwiftuiTableRefreshID = UUID()
            #endif
            return false
        }
        
        
    }
    
    
    
    @MainActor
    func submit(_ group: CBCategoryGroup) async -> Bool {
        print("-- \(#function)")
        
        isThinking = true
        
        //LoadingManager.shared.startDelayedSpinner()
        LogManager.log()
        let model = RequestModel(requestType: group.action.serverKey, model: group)
            
        /// Used to test the snapshot data race
        //try? await Task.sleep(nanoseconds: UInt64(6 * Double(NSEC_PER_SEC)))
        
        typealias ResultResponse = Result<ReturnIdModel?, AppError>
        async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
                    
        switch await result {
        case .success(let model):
            LogManager.networkingSuccessful()
            //let _ = DataManager.shared.delete(type: TempCategory.self, predicate: .byId(.string(category.id)))
            
            /// Get the new ID from the server after adding a new activity.
            if group.action != .delete {
                if group.action == .add {
                    group.id = model?.id ?? "0"
                    group.uuid = nil
                    group.action = .edit
                }
            }
            
            isThinking = false
            group.action = .edit
            #if os(macOS)
            fuckYouSwiftuiTableRefreshID = UUID()
            #endif
            return true
            
        case .failure(let error):
            LogManager.error(error.localizedDescription)
            AppState.shared.showAlert("There was a problem syncing the category. Will try again at a later time.")
            //AppState.shared.showAlert("There was a problem trying to save the category.")
//            category.deepCopy(.restore)
//
//            switch category.action {
//            case .add: categories.removeAll { $0.id == category.id }
//            case .edit: break
//            case .delete: categories.append(category)
//            }
            
            isThinking = false
            group.action = .edit
            #if os(macOS)
            fuckYouSwiftuiTableRefreshID = UUID()
            #endif
            return false
        }
        
        
    }
    
    
    @MainActor
    func setListOrders(calModel: CalendarModel) async -> Array<ListOrderUpdate> {
        var updates: Array<ListOrderUpdate> = []
        var index = 1
        
        for category in self.categories.filter({ !$0.isNil }) {
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
    
    
    
    
//    @MainActor
//    func submitListOrders() async -> Bool {
//        print("-- \(#function)")
//                        
//        for category in categories {
//            if let listOrder = category.listOrder {
//                guard let entity = DataManager.shared.getOne(type: PersistentCategory.self, predicate: .byId(.string(category.id)), createIfNotFound: false) else { return false }
//                entity.listOrder = Int64(listOrder)
//            }
//        }
//                                                                        
//        let saveResult = DataManager.shared.save()
//        print(saveResult)
//        
//        //LoadingManager.shared.startDelayedSpinner()
//        LogManager.log()
//        let model = RequestModel(requestType: "alter_category_list_orders", model: CategoryListOrderUpdateModel(categories: categories))
//            
//        /// Used to test the snapshot data race
//        //try? await Task.sleep(nanoseconds: UInt64(6 * Double(NSEC_PER_SEC)))
//        
//        typealias ResultResponse = Result<ResultCompleteModel?, AppError>
//        async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
//                    
//        switch await result {
//        case .success:
//            LogManager.networkingSuccessful()
//                                                
//            #if os(macOS)
//            fuckYouSwiftuiTableRefreshID = UUID()
//            #endif
//            return true
//            
//        case .failure(let error):
//            LogManager.error(error.localizedDescription)
//            AppState.shared.showAlert("There was a problem syncing the category. Will try again at a later time.")
//            //AppState.shared.showAlert("There was a problem trying to save the category.")
////            category.deepCopy(.restore)
////
////            switch category.action {
////            case .add: categories.removeAll { $0.id == category.id }
////            case .edit: break
////            case .delete: categories.append(category)
////            }
//            
//            #if os(macOS)
//            fuckYouSwiftuiTableRefreshID = UUID()
//            #endif
//            return false
//        }
//        
//        
//    }
    
    
    
    
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
    
    
    func delete(_ group: CBCategoryGroup, andSubmit: Bool) {
        group.action = .delete
        group.deepCopy?.action = .delete
        withAnimation { categoryGroups.removeAll { $0.id == group.id } }
        
        if andSubmit {
            Task { @MainActor in
                let _ = await submit(group)
            }
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
    
    
    
    @MainActor
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
            LogManager.error(error.localizedDescription)
            AppState.shared.showAlert("There was a problem trying to fetch the analytics.")
            return nil
            //showSaveAlert = true
            #warning("Undo behavior")
        }
        //LoadingManager.shared.stopDelayedSpinner()
    }
}
