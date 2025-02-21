//
//  CategoryModel.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/28/24.
//

import Foundation

@MainActor
@Observable
class CategoryModel {
    var isThinking = false
    
    var categoryEditID: Int?
    var categories: Array<CBCategory> = []
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
    
    func setListOrders(calModel: CalendarModel) {
        var index = 0
        for category in categories {
            category.listOrder = index
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
        
        Task {
            await submitListOrders()
        }
    }
    
    func saveCategory(id: String, calModel: CalendarModel) {
        let category = getCategory(by: id)
        Task {
            
            if category.title.isEmpty {
                if category.action != .add && category.title.isEmpty {
                    category.title = category.deepCopy?.title ?? ""
                    AppState.shared.showAlert("Removing a title is not allowed. If you want to delete \(category.title), please use the delete button instead.")
                } else {
                    categories.removeAll { $0.id == id }
                }
                return
            }
                                                    
            if category.hasChanges() {
                let wasSuccessful = await submit(category)
                if wasSuccessful {
                    calModel.months.forEach { month in
                        month.days.forEach { day in
                            day.transactions.filter { $0.category?.id == category.id }.forEach { transaction in
                                transaction.category = category
                            }
                        }
                        
                        if let index = month.budgets.firstIndex(where: { $0.category?.id == category.id }) {
                            month.budgets[index].category = category
                        }
                        
                        
                        if !month.budgets.isEmpty {
                            /// Instead of re-writing all the logic, just call `calModel.populate()` with a blank transaction array and the category we need
                            let options = PopulateOptions()
                            options.budget = true
                            options.paymentMethods = []
                            calModel.populate(options: options, repTransactions: [], categories: [category])
                        }
                    }
                }
                
                
                
                
                
            }
        }
    }
    
    func updateCache(for category: CBCategory) -> Result<Bool, CoreDataError> {
        guard let entity = DataManager.shared.getOne(type: PersistentCategory.self, predicate: .byId(.string(category.id)), createIfNotFound: false) else { return .failure(.reason("notFound")) }
        
        entity.id = category.id
        entity.title = category.title
        entity.amount = category.amount ?? 0.0
        entity.hexCode = category.color.toHex()
        //entity.hexCode = category.color.description
        entity.emoji = category.emoji ?? ""
        entity.action = "edit"
        entity.isPending = false
        entity.isIncome = category.isIncome
        entity.listOrder = Int64(category.listOrder ?? 0)
        let saveResult = DataManager.shared.save()
        return saveResult
    }
    
    
    @MainActor
    func fetchCategories(file: String = #file, line: Int = #line, function: String = #function) async {
        NSLog("\(file):\(line) : \(function)")
        LogManager.log()
        
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
                        activeIds.append(category.id)
                        
                        /// Find the category in cache.
                        let entity = DataManager.shared.getOne(type: PersistentCategory.self, predicate: .byId(.string(category.id)), createIfNotFound: true)
                        
                        /// Update the cache.
                        /// This should always be true because the line above creates the entity if it's not found.
                        if let entity {
                            entity.id = category.id
                            entity.title = category.title
                            entity.amount = category.amount ?? 0.0
                            entity.hexCode = category.color.toHex()
                            //entity.hexCode = category.color.description
                            entity.emoji = category.emoji
                            entity.action = "edit"
                            entity.isPending = false
                            entity.isIncome = category.isIncome
                            
                            let index = categories.firstIndex(where: { $0.id == category.id })
                            if let index {
                                /// If the category is already in the list, update it from the server.
                                categories[index].setFromAnotherInstance(category: category)
                            } else {
                                /// Add the category to the list (like when the category was added on another device).
                                categories.append(category)
                            }
                        }
                    }
                    
                    /// Delete from cache and model.
                    for category in categories {
                        if !activeIds.contains(category.id) {
                            categories.removeAll { $0.id == category.id }
                            let _ = DataManager.shared.delete(type: PersistentCategory.self, predicate: .byId(.string(category.id)))
                        }
                    }
            
                    /// Save the cache.
                    let _ = DataManager.shared.save()
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
    func submit(_ category: CBCategory) async -> Bool {
        print("-- \(#function)")
        
        isThinking = true
        
        
//        guard let entity = DataManager.shared.getOne(type: TempCategory.self, predicate: .byId(.string(category.id)), createIfNotFound: true) else { return false }
//        
//        entity.id = category.id
//        entity.title = category.title
//        entity.amount = category.amount ?? 0.0
//        entity.hexCode = category.color.toHex()
//        entity.emoji = category.emoji ?? ""
//        entity.action = category.action.rawValue
//        let _ = DataManager.shared.save()
//        
        
        
        
        
        guard let entity = DataManager.shared.getOne(type: PersistentCategory.self, predicate: .byId(.string(category.id)), createIfNotFound: true) else { return false }
        entity.id = category.id
        entity.title = category.title
        entity.amount = category.amount ?? 0.0
        entity.hexCode = category.color.toHex()
        //entity.hexCode = category.color.description
        entity.emoji = category.emoji ?? ""
        entity.action = category.action.rawValue
        entity.isIncome = category.isIncome
        entity.isPending = true
                                                        
        let _ = DataManager.shared.save()
        
        
        
        
        
        
        //LoadingManager.shared.startDelayedSpinner()
        LogManager.log()
        let model = RequestModel(requestType: category.action.serverKey, model: category)
            
        /// Used to test the snapshot data race
        //try? await Task.sleep(nanoseconds: UInt64(6 * Double(NSEC_PER_SEC)))
        
        typealias ResultResponse = Result<ReturnIdModel?, AppError>
        async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
                    
        switch await result {
        case .success(let model):
            LogManager.networkingSuccessful()
            //let _ = DataManager.shared.delete(type: TempCategory.self, predicate: .byId(.string(category.id)))
            
            /// Get the new ID from the server after adding a new activity.
            if category.action != .delete {
                guard let entity = DataManager.shared.getOne(type: PersistentCategory.self, predicate: .byId(.string(category.id)), createIfNotFound: true) else { return false }
                
                
                if category.action == .add {
                    do {
                        let pred = NSPredicate(format: "isPending == %@", NSNumber(value: true))
                        guard let entities = try DataManager.shared.getMany(type: PersistentKeyword.self, predicate: .single(pred)) else { return false }
                        
                        if !entities.isEmpty {
                            //print("FOUND TEMPS")
                            entities
                                .filter { $0.category?.id == category.id }
                                .forEach { $0.category?.id = model?.id ?? "0" }
                        }
                    } catch {
                        
                    }
                    
                    category.id = model?.id ?? "0"
                    category.uuid = nil
                    category.action = .edit
                    entity.id = model?.id ?? "0"
                    entity.action = "edit"
                }
                
                entity.isPending = false
                let _ = DataManager.shared.save()
            } else {
                let _ = DataManager.shared.delete(type: PersistentCategory.self, predicate: .byId(.string(category.id)))
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
    func submitListOrders() async -> Bool {
        print("-- \(#function)")
                        
        for category in categories {
            if let listOrder = category.listOrder {
                guard let entity = DataManager.shared.getOne(type: PersistentCategory.self, predicate: .byId(.string(category.id)), createIfNotFound: false) else { return false }
                entity.listOrder = Int64(listOrder)
            }
        }
                                                                        
        let saveResult = DataManager.shared.save()
        print(saveResult)
        
        //LoadingManager.shared.startDelayedSpinner()
        LogManager.log()
        let model = RequestModel(requestType: "alter_category_list_orders", model: CategoryListOrderUpdatModel(categories: categories))
            
        /// Used to test the snapshot data race
        //try? await Task.sleep(nanoseconds: UInt64(6 * Double(NSEC_PER_SEC)))
        
        typealias ResultResponse = Result<ResultCompleteModel?, AppError>
        async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
                    
        switch await result {
        case .success:
            LogManager.networkingSuccessful()
                                                
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
            
            #if os(macOS)
            fuckYouSwiftuiTableRefreshID = UUID()
            #endif
            return false
        }
        
        
    }
    
    
    
    
    func delete(_ category: CBCategory, andSubmit: Bool, calModel: CalendarModel, keyModel: KeywordModel, eventModel: EventModel) async {
        category.action = .delete
        category.deepCopy?.action = .delete
        categories.removeAll { $0.id == category.id }        
        
        calModel.justTransactions.filter { $0.category?.id == category.id }.forEach { $0.category = nil }        
        calModel.months.forEach { $0.budgets.removeAll(where: { $0.category?.id == category.id }) }
        keyModel.keywords.removeAll(where: { $0.category?.id == category.id })
        eventModel.events.forEach {$0.transactions.removeAll(where: { $0.category?.id == category.id })}
        
        if andSubmit {
            let _ = await submit(category)
        } else {
            let _ = DataManager.shared.delete(type: PersistentCategory.self, predicate: .byId(.string(category.id)))
        }
    }
    
    
    func deleteAll() async {
        for meth in categories {
            meth.action = .delete
            let _ = await submit(meth)
        }
        
        let _ = DataManager.shared.deleteAll(for: PersistentCategory.self)
        //print("SaveResult: \(saveResult)")
        categories.removeAll()
    }
}
