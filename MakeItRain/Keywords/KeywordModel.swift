//
//  KeywordModel.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/28/24.
//

import Foundation

@MainActor
@Observable
class KeywordModel {
    static let shared = KeywordModel()
    var isThinking = false
    
    var keywordEditID: Int?
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
                let _ = await submit(keyword)
            }
        }
    }
    
    func updateCache(for keyword: CBKeyword) -> Result<Bool, CoreDataError> {
        guard let entity = DataManager.shared.getOne(type: PersistentKeyword.self, predicate: .byId(.string(keyword.id)), createIfNotFound: false) else { return .failure(.reason("notFound")) }
        
        guard let categoryEntity = DataManager.shared.getOne(type: PersistentCategory.self, predicate: .byId(.string(keyword.category?.id ?? "0")), createIfNotFound: false) else { return .failure(.reason("notFound"))}
        
        entity.id = keyword.id
        entity.keyword = keyword.keyword
        entity.category = categoryEntity
        entity.triggerType = keyword.triggerType.rawValue
        entity.action = "edit"
        entity.isPending = false
        
        let saveResult = DataManager.shared.save()
        return saveResult
    }
    
    @MainActor
    func fetchKeywords(file: String = #file, line: Int = #line, function: String = #function) async {
        NSLog("\(file):\(line) : \(function)")
        LogManager.log()
        
        /// Do networking.
        let model = RequestModel(requestType: "fetch_keywords", model: AppState.shared.user)
        typealias ResultResponse = Result<Array<CBKeyword>?, AppError>
        async let result: ResultResponse = await NetworkManager().arrayRequest(requestModel: model)
        
        switch await result {
        case .success(let model):
            
            /// For testing bad network connection.
            //try? await Task.sleep(nanoseconds: UInt64(10 * Double(NSEC_PER_SEC)))

            LogManager.networkingSuccessful()
            if let model {
                if !model.isEmpty {
                    var activeIds: Array<String> = []
                    for keyword in model {
                        activeIds.append(keyword.id)
                        
                        /// Find the keyword in cache.
                        let entity = DataManager.shared.getOne(type: PersistentKeyword.self, predicate: .byId(.string(keyword.id)), createIfNotFound: true)
                        
                        /// Update the cache and add to model (if appolicable).
                        /// This should always be true because the line above creates the entity if it's not found.
                        if let entity {
                            guard let categoryEntity = DataManager.shared.getOne(type: PersistentCategory.self, predicate: .byId(.string(keyword.category?.id ?? "0")), createIfNotFound: true) else { return }
                            
                            
                            
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
                            
                            
                            
                            entity.id = keyword.id
                            entity.keyword = keyword.keyword
                            entity.category = categoryEntity
                            entity.triggerType = keyword.triggerType.rawValue
                            entity.action = "edit"
                            entity.isPending = false
                            
                                                                                    
                            let index = keywords.firstIndex(where: { $0.id == keyword.id })
                            if let index {
                                /// If the payment method is already in the list, update it from the server.
                                keywords[index].setFromAnotherInstance(keyword: keyword)
                            } else {
                                /// Add the payment method to the list (like when the payment method was added on another device).
                                keywords.append(keyword)
                            }
                        }
                    }
                    
                    /// Delete from cache and model.
                    for keyword in keywords {
                        if !activeIds.contains(keyword.id) {
                            keywords.removeAll { $0.id == keyword.id }
                            let _ = DataManager.shared.delete(type: PersistentKeyword.self, predicate: .byId(.string(keyword.id)))
                        }
                    }
            
                    /// Save the cache.
                    let _ = DataManager.shared.save()
                }
            }
            
            /// Update the progress indicator.
            AppState.shared.downloadedData.append(.keywords)
            
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
        
        
        
        
        
        guard let entity = DataManager.shared.getOne(type: PersistentKeyword.self, predicate: .byId(.string(keyword.id)), createIfNotFound: true) else { return false }
                        
        entity.id = keyword.id
        entity.keyword = keyword.keyword
        entity.triggerType = keyword.triggerType.rawValue
        entity.action = keyword.action.rawValue
        entity.isPending = true
        
        
        guard let categoryEntity = DataManager.shared.getOne(type: PersistentCategory.self, predicate: .byId(.string(keyword.category?.id ?? "0")), createIfNotFound: true) else { return false }
        entity.category = categoryEntity
        
        let _ = DataManager.shared.save()
        
        
        
        let model = RequestModel(requestType: keyword.action.serverKey, model: keyword)
        /// Used to test the snapshot data race
        //try? await Task.sleep(nanoseconds: UInt64(6 * Double(NSEC_PER_SEC)))
        
        typealias ResultResponse = Result<ReturnIdModel?, AppError>
        async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
        
        
        //print(keyword.action)
                    
        switch await result {
        case .success(let model):
            LogManager.networkingSuccessful()
            /// Get the new ID from the server after adding a new activity.
            if keyword.action != .delete {
                guard let entity = DataManager.shared.getOne(type: PersistentKeyword.self, predicate: .byId(.string(keyword.id)), createIfNotFound: true) else { return false }
                
                if keyword.action == .add {
                    keyword.id = model?.id ?? "0"
                    keyword.uuid = nil
                    keyword.action = .edit
                    entity.id = model?.id ?? "0"
                    entity.action = "edit"
                }
                
                entity.isPending = false
                let _ = DataManager.shared.save()
            } else {
                let _ = DataManager.shared.delete(type: PersistentKeyword.self, predicate: .byId(.string(keyword.id)))
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
    
    
    func delete(_ keyword: CBKeyword, andSubmit: Bool) async {
        keyword.action = .delete
        keywords.removeAll { $0.id == keyword.id }
        
        if andSubmit {
            let _ = await submit(keyword)
        } else {
            let _ = DataManager.shared.delete(type: PersistentKeyword.self, predicate: .byId(.string(keyword.id)))
        }
    }
    
    
    func deleteAll() async {
        for keyword in keywords {
            keyword.action = .delete
            let _ = await submit(keyword)
        }
        
        let _ = DataManager.shared.deleteAll(for: PersistentKeyword.self)
        //print("SaveResult: \(saveResult)")
        keywords.removeAll()
    }
}
