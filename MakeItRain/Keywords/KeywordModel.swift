//
//  KeywordModel.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/28/24.
//

import Foundation
import GRDB

@MainActor
@Observable
class KeywordModel {
    //static let shared = KeywordModel()
    var isThinking = false
    
    //var keywordEditID: Int?
    var keywords: Array<CBKeyword> = []
    //var refreshTask: Task<Void, Error>?
    var fuckYouSwiftuiTableRefreshID: UUID = UUID()
    
    func doesExist(_ keyword: CBKeyword) -> Bool {
        return !keywords.filter { $0.id == keyword.id }.isEmpty
    }
    
    func getKeyword(by id: String) -> CBKeyword {
        return keywords.filter { $0.id == id }.first ?? CBKeyword(uuid: id)
    }
    
    func upsert(_ keyword: CBKeyword) {
        if !doesExist(keyword) {
            keywords.append(keyword)
        }
    }
    
    func getIndex(for keyword: CBKeyword) -> Int? {
        return keywords.firstIndex(where: { $0.id == keyword.id })
    }
    
    func saveKeyword(id: String) {
        let keyword = getKeyword(by: id)
        Task {            
            if keyword.keyword.isEmpty {
                if keyword.action != .add && keyword.keyword.isEmpty {
                    keyword.keyword = keyword.deepCopy?.keyword ?? ""
                    AppState.shared.showAlert("Removing a title is not allowed. If you want to delete \(keyword.keyword), please use the delete button instead.")
                } else {
                    keywords.removeAll { $0.id == id }
                }
                return
            }
                                
            if keyword.hasChanges() {
                keyword.updatedBy = AppState.shared.user!
                keyword.updatedDate = Date()
                let _ = await submit(keyword)
            }
        }
    }
    
    func updateCache(for keyword: CBKeyword) async -> Result<Bool, CoreDataError> {
        let context = DataManager.shared.createContext()
        return await context.perform {
            if let entity = DataManager.shared.getOne(context: context, type: PersistentKeyword.self, predicate: .byId(.string(keyword.id)), createIfNotFound: false),
               let categoryEntity = DataManager.shared.getOne(context: context, type: PersistentCategory.self, predicate: .byId(.string(keyword.category?.id ?? "0")), createIfNotFound: false) {
                
                entity.id = keyword.id
                entity.keyword = keyword.keyword
                entity.category = categoryEntity
                entity.triggerType = keyword.triggerType.rawValue
                entity.action = "edit"
                entity.isPending = false
                
                entity.enteredByID = Int64(keyword.enteredBy.id)
                entity.updatedByID = Int64(keyword.updatedBy.id)
                entity.enteredDate = keyword.enteredDate
                entity.updatedDate = keyword.updatedDate
                
                return DataManager.shared.save(context: context)
                
            } else {
                return .failure(.notFound)
            }
        }
    }
    
    
    
//    @MainActor
//    func fetchKeywordsNEW(file: String = #file, line: Int = #line, function: String = #function) async {
//        NSLog("\(file):\(line) : \(function)")
//        LogManager.log()
//        
//        let start = CFAbsoluteTimeGetCurrent()
//        
//        /// Do networking.
//        let model = RequestModel(requestType: "fetch_keywords", model: AppState.shared.user)
//        typealias ResultResponse = Result<Array<CBKeyword>?, AppError>
//        async let result: ResultResponse = await NetworkManager().arrayRequest(requestModel: model)
//        
//        switch await result {
//        case .success(let model):
//            
//            /// For testing bad network connection.
//            try? await Task.sleep(nanoseconds: UInt64(20 * Double(NSEC_PER_SEC)))
//            
//            
//            do {
//                let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("cache_directory.sqlite")
//                let dbQueue = try DatabaseQueue(path: url.path)
//                try await dbQueue.write { db in
//
//                    // Call this somewhere during app startup, e.g. in your database setup:
//                    var migrator = DatabaseMigrator()
//
//                    migrator.registerMigration("createCBKeyword") { db in
//                        try db.create(table: "cbKeyword") { t in
//                            t.column("id", .text).notNull().primaryKey()
//                            t.column("keyword", .text).notNull()
//                            t.column("trigger_type", .text).notNull()
//                            t.column("category", .text)  // Adjust the type if this is a foreign key or ID
//                            t.column("active", .boolean).notNull().defaults(to: true)
//                            t.column("entered_by", .text)
//                            t.column("updated_by", .text)
//                            t.column("entered_date", .datetime)
//                            t.column("updated_date", .datetime)
//                            
//                            // Add a primary key if needed
//                            // t.primaryKey(["keyword", "trigger_type"])  // Composite key if those are unique
//                        }
//                    }
//
//                    // Later in your code:
//                    try migrator.migrate(dbQueue)
//                }
//            } catch {
//                
//            }
//            
//            
//            LogManager.networkingSuccessful()
//            if let model {
//                if !model.isEmpty {
//                    var activeIds: Array<String> = []
//                    for keyword in model {
//                        activeIds.append(keyword.id)
//                        
//                        do {
//                            let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("cache_directory.sqlite")
//                            let dbQueue = try DatabaseQueue(path: url.path)
//                            try await dbQueue.write { db in
//                                try keyword.upsert(db)
//                            }
//                        } catch {
//                            print(error.localizedDescription)
//                        }
//                        
//                        
//                        
//                        
//                        
//                        
//                        
//                                                                                                            
//                        let index = keywords.firstIndex(where: { $0.id == keyword.id })
//                        if let index {
//                            /// If the payment method is already in the list, update it from the server.
//                            keywords[index].setFromAnotherInstance(keyword: keyword)
//                        } else {
//                            /// Add the payment method to the list (like when the payment method was added on another device).
//                            keywords.append(keyword)
//                        }
//                    }
//                    
//                    /// Delete from model.
//                    for keyword in keywords {
//                        if !activeIds.contains(keyword.id) {
//                            keywords.removeAll { $0.id == keyword.id }
//                        }
//                    }
//                    
////                    
////                    let man = CacheManager<CBKeyword>(file: .keywords)
////                    man.saveMany(self.keywords)
//                    
//                } else {
//                    keywords.removeAll()
//                }
//            }
//            
//            /// Update the progress indicator.
//            AppState.shared.downloadedData.append(.keywords)
//            
//            let currentElapsed = CFAbsoluteTimeGetCurrent() - start
//            print("⏰It took \(currentElapsed) seconds to fetch the keywords")
//            
//        case .failure (let error):
//            switch error {
//            case .taskCancelled:
//                /// Task get cancelled when switching years. So only show the alert if the error is not related to the task being cancelled.
//                print("keyModel fetchFrom Server Task Cancelled")
//            default:
//                LogManager.error(error.localizedDescription)
//                AppState.shared.showAlert("There was a problem trying to fetch the keywords.")
//            }
//        }
//    }
//    
//    
//    
    @MainActor
    func fetchKeywords(file: String = #file, line: Int = #line, function: String = #function) async {
        NSLog("\(file):\(line) : \(function)")
        let context = DataManager.shared.createContext()
        LogManager.log()
        
        let start = CFAbsoluteTimeGetCurrent()
        
        /// Do networking.
        let model = RequestModel(requestType: "fetch_keywords", model: AppState.shared.user)
        typealias ResultResponse = Result<Array<CBKeyword>?, AppError>
        async let result: ResultResponse = await NetworkManager().arrayRequest(requestModel: model)
        
        switch await result {
        case .success(let model):
            
            /// For testing bad network connection.
            
            //try? await Task.sleep(nanoseconds: UInt64(20 * Double(NSEC_PER_SEC)))

            LogManager.networkingSuccessful()
            if let model {
                if !model.isEmpty {
                    var activeIds: Array<String> = []
//                    let man = CacheManager<CBKeyword>(filename: "keywords.json")
//                    man.saveMany(model)
                    
                    for keyword in model {
                        activeIds.append(keyword.id)
                                                                                                                                                                                                
                        let index = keywords.firstIndex(where: { $0.id == keyword.id })
                        if let index {
                            /// If the payment method is already in the list, update it from the server.
                            keywords[index].setFromAnotherInstance(keyword: keyword)
                        } else {
                            /// Add the payment method to the list (like when the payment method was added on another device).
                            keywords.append(keyword)
                        }
                                                           
                        /// Find the keyword in cache.
                        await context.perform {
                            let entity = DataManager.shared.getOne(context: context, type: PersistentKeyword.self, predicate: .byId(.string(keyword.id)), createIfNotFound: true)
                            let categoryEntity = DataManager.shared.getOne(context: context, type: PersistentCategory.self, predicate: .byId(.string(keyword.category?.id ?? "0")), createIfNotFound: true)
                            
                            /// Update the cache and add to model (if applicable).
                            /// This should always be true because the line above creates the entity if it's not found.
                            if let entity, let categoryEntity {
                                entity.id = keyword.id
                                entity.keyword = keyword.keyword
                                entity.triggerType = keyword.triggerType.rawValue
                                entity.action = "edit"
                                entity.isPending = false
                                
                                entity.enteredByID = Int64(keyword.enteredBy.id)
                                entity.updatedByID = Int64(keyword.updatedBy.id)
                                entity.enteredDate = keyword.enteredDate
                                entity.updatedDate = keyword.updatedDate
                                
                                if categoryEntity.id == nil {
                                    categoryEntity.id = keyword.category?.id
                                    categoryEntity.title = keyword.category?.title
                                    categoryEntity.amount = keyword.category?.amount ?? 0.0
                                    categoryEntity.hexCode = keyword.category?.color.toHex()
                                    //entity.hexCode = category.color.description
                                    categoryEntity.emoji = keyword.category?.emoji
                                    categoryEntity.action = "edit"
                                    categoryEntity.isPending = false
                                }
                                
                                entity.category = categoryEntity
                                let _ = DataManager.shared.save(context: context)
                            }
                        }
                    }
                    
                    /// Delete from cache and model.
                    for keyword in keywords {
                        if !activeIds.contains(keyword.id) {
                            keywords.removeAll { $0.id == keyword.id }
                            /// Does so in its own perform block.
                            DataManager.shared.delete(context: context, type: PersistentKeyword.self, predicate: .byId(.string(keyword.id)))
                        }
                    }
                } else {
                    keywords.removeAll()
                }
            }
            
            /// Update the progress indicator.
            AppState.shared.downloadedData.append(.keywords)
            
            let currentElapsed = CFAbsoluteTimeGetCurrent() - start
            print("⏰It took \(currentElapsed) seconds to fetch the keywords")
            
        case .failure (let error):
            switch error {
            case .taskCancelled:
                /// Task get cancelled when switching years. So only show the alert if the error is not related to the task being cancelled.
                print("keyModel fetchFrom Server Task Cancelled")
            default:
                LogManager.error(error.localizedDescription)
                AppState.shared.showAlert("There was a problem trying to fetch the keywords.")
            }
        }
    }
    
    
    
    @MainActor
    func submit(_ keyword: CBKeyword) async -> Bool {
        isThinking = true
        //LoadingManager.shared.startDelayedSpinner()
        LogManager.log()
                
        let context = DataManager.shared.createContext()
        await context.perform {
            let entity = DataManager.shared.getOne(context: context, type: PersistentKeyword.self, predicate: .byId(.string(keyword.id)), createIfNotFound: true)
            let categoryEntity = DataManager.shared.getOne(context: context, type: PersistentCategory.self, predicate: .byId(.string(keyword.category?.id ?? "0")), createIfNotFound: true)
        
            if let entity, let categoryEntity {
                entity.id = keyword.id
                entity.keyword = keyword.keyword
                entity.triggerType = keyword.triggerType.rawValue
                entity.action = keyword.action.rawValue
                entity.isPending = true
                entity.category = categoryEntity
                
                entity.enteredByID = Int64(keyword.enteredBy.id)
                entity.updatedByID = Int64(keyword.updatedBy.id)
                entity.enteredDate = keyword.enteredDate
                entity.updatedDate = keyword.updatedDate
                
                let _ = DataManager.shared.save(context: context)
            }
        }
        
        
        let model = RequestModel(requestType: keyword.action.serverKey, model: keyword)
        /// Used to test the snapshot data race
        //try? await Task.sleep(nanoseconds: UInt64(6 * Double(NSEC_PER_SEC)))
        
        typealias ResultResponse = Result<ReturnIdModel?, AppError>
        async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
                                
        switch await result {
        case .success(let model):
            LogManager.networkingSuccessful()
            
            if keyword.action != .delete {
                await context.perform {
                    if let entity = DataManager.shared.getOne(context: context, type: PersistentKeyword.self, predicate: .byId(.string(keyword.id)), createIfNotFound: true) {
                        if keyword.action == .add {
                            entity.id = model?.id ?? String(0)
                            entity.action = "edit"
                        }
                        entity.isPending = false
                        let _ = DataManager.shared.save(context: context)
                    }
                }
                                
                /// Get the new ID from the server after adding a new activity.
                if keyword.action == .add {
                    keyword.id = model?.id ?? String(0)
                    keyword.uuid = nil
                    keyword.action = .edit
                }
                
            } else {
                /// Does so in its own perform block.
                DataManager.shared.delete(context: context, type: PersistentKeyword.self, predicate: .byId(.string(keyword.id)))
            }
            
            isThinking = false
            keyword.action = .edit
            #if os(macOS)
            fuckYouSwiftuiTableRefreshID = UUID()
            #endif
            return true
            
        case .failure(let error):
            LogManager.error(error.localizedDescription)
            AppState.shared.showAlert("There was a problem syncing the keyword. Will try again at a later time.")
//            keyword.deepCopy(.restore)
//            
//            switch keyword.action {
//            case .add: keywords.removeAll { $0.id == keyword.id }
//            case .edit: break
//            case .delete: keywords.append(keyword)
//            }
        }
        
        isThinking = false
        keyword.action = .edit
        #if os(macOS)
        fuckYouSwiftuiTableRefreshID = UUID()
        #endif
        return false
    }
    
    
//    @MainActor
//    func submitOG(_ keyword: CBKeyword) async -> Bool {
//        isThinking = true
//        
//        //LoadingManager.shared.startDelayedSpinner()
//        LogManager.log()
//                                        
//        guard let entity = DataManager.shared.getOne(type: PersistentKeyword.self, predicate: .byId(.string(keyword.id)), createIfNotFound: true) else { return false }
//                        
//        entity.id = keyword.id
//        entity.keyword = keyword.keyword
//        entity.triggerType = keyword.triggerType.rawValue
//        entity.action = keyword.action.rawValue
//        entity.isPending = true
//        
//        
//        guard let categoryEntity = DataManager.shared.getOne(type: PersistentCategory.self, predicate: .byId(.string(keyword.category?.id ?? "0")), createIfNotFound: true) else { return false }
//        entity.category = categoryEntity
//        
//        let _ = DataManager.shared.save()
//        
//        
//        
//        let model = RequestModel(requestType: keyword.action.serverKey, model: keyword)
//        /// Used to test the snapshot data race
//        //try? await Task.sleep(nanoseconds: UInt64(6 * Double(NSEC_PER_SEC)))
//        
//        typealias ResultResponse = Result<ReturnIdModel?, AppError>
//        async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
//        
//        
//        //print(keyword.action)
//                    
//        switch await result {
//        case .success(let model):
//            LogManager.networkingSuccessful()
//            /// Get the new ID from the server after adding a new activity.
//            if keyword.action != .delete {
//                guard let entity = DataManager.shared.getOne(type: PersistentKeyword.self, predicate: .byId(.string(keyword.id)), createIfNotFound: true) else { return false }
//                
//                if keyword.action == .add {
//                    keyword.id = model?.id ?? "0"
//                    keyword.uuid = nil
//                    keyword.action = .edit
//                    entity.id = model?.id ?? "0"
//                    entity.action = "edit"
//                }
//                
//                entity.isPending = false
//                let _ = DataManager.shared.save()
//            } else {
//                let _ = await DataManager.shared.delete(type: PersistentKeyword.self, predicate: .byId(.string(keyword.id)))
//            }
//            
//            isThinking = false
//            keyword.action = .edit
//            #if os(macOS)
//            fuckYouSwiftuiTableRefreshID = UUID()
//            #endif
//            return true
//            
//        case .failure(let error):
//            LogManager.error(error.localizedDescription)
//            AppState.shared.showAlert("There was a problem syncing the keyword. Will try again at a later time.")
////            keyword.deepCopy(.restore)
////
////            switch keyword.action {
////            case .add: keywords.removeAll { $0.id == keyword.id }
////            case .edit: break
////            case .delete: keywords.append(keyword)
////            }
//        }
//        
//        isThinking = false
//        keyword.action = .edit
//        #if os(macOS)
//        fuckYouSwiftuiTableRefreshID = UUID()
//        #endif
//        return false
//    }
//    
    
    func delete(_ keyword: CBKeyword, andSubmit: Bool) async {
        let context = DataManager.shared.createContext()
        keyword.action = .delete
        keywords.removeAll { $0.id == keyword.id }
        
        if andSubmit {
            let _ = await submit(keyword)
        } else {
            DataManager.shared.delete(context: context, type: PersistentKeyword.self, predicate: .byId(.string(keyword.id)))
        }
    }
    
    
    func deleteAll() async {
        let context = DataManager.shared.createContext()
        for keyword in keywords {
            keyword.action = .delete
            let _ = await submit(keyword)
        }
        
        let _ = DataManager.shared.deleteAll(context: context, for: PersistentKeyword.self)
        let _ = DataManager.shared.save(context: context)
        //print("SaveResult: \(saveResult)")
        keywords.removeAll()
    }
}
