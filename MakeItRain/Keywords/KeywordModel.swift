//
//  KeywordModel.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/28/24.
//

import Foundation
//import GRDB
import SwiftUI

@MainActor
@Observable
class KeywordModel {
    var isThinking = false
    var keywords: Array<CBKeyword> = []
    var fuckYouSwiftuiTableRefreshID: UUID = UUID()
    
    func doesExist(_ keyword: CBKeyword) -> Bool {
        return !keywords.filter { $0.id == keyword.id }.isEmpty
    }
    
    func getKeyword(by id: String) -> CBKeyword {
        return keywords.filter { $0.id == id }.first ?? CBKeyword(uuid: id)
    }
    
//    func upsert(_ keyword: CBKeyword) {
//        if !doesExist(keyword) {
//            keywords.append(keyword)
//        }
//    }
    
    func upsert(_ keyword: CBKeyword) {
        if doesExist(keyword), let index = getIndex(for: keyword) {
            keywords[index].setFromAnotherInstance(keyword: keyword)
        } else {
            keywords.append(keyword)
        }
    }
    
    func getIndex(for keyword: CBKeyword) -> Int? {
        return keywords.firstIndex(where: { $0.id == keyword.id })
    }
    
    func saveKeyword(id: String, file: String = #file, line: Int = #line, function: String = #function) {
        print("-- \(#function) -- Called from: \(file):\(line) : \(function)")

        let keyword = getKeyword(by: id)
        
        if keyword.action == .delete {
            keyword.updatedBy = AppState.shared.user!
            keyword.updatedDate = Date()
            delete(keyword, andSubmit: true)
            return
        }
        
        /// User blanked out the title of an existing keyword.
        if keyword.action == .edit && keyword.keyword.isEmpty {
            keyword.keyword = keyword.deepCopy?.keyword ?? ""
            AppState.shared.showAlert("Removing a title is not allowed. If you want to delete \(keyword.keyword), please use the delete button instead.")
            return
        }
        
        /// User is entering a new keyword but forgot the payment method.
        /// Remove the dud that is in `.add` mode since it's being upserted into the list on creation.
        if ((keyword.category == nil || keyword.category?.isNil ?? false) && keyword.renameTo == nil) && !keyword.keyword.isEmpty {
            AppState.shared.showAlert(title: "A condition is required", subtitle: "\(keyword.keyword) was not saved.")
            delete(keyword, andSubmit: false)
            return
        }
                            
        if keyword.hasChanges() {
            keyword.updatedBy = AppState.shared.user!
            keyword.updatedDate = Date()
            Task {
                let _ = await submit(keyword)
            }
        }
    }
    
//    func updateCache(for keyword: CBKeyword) async -> Result<Bool, CoreDataError> {
//        let keywordID = keyword.id
//        let theKeyword = keyword.keyword
//        let categoryID = keyword.category?.id ?? "0"
//        let renameTo = keyword.renameTo
//        let triggerType = keyword.triggerType.rawValue
//        //let action = "edit"
//        //let isPending = false
//        let enteredByID = Int64(keyword.enteredBy.id)
//        let updatedByID = Int64(keyword.updatedBy.id)
//        let enteredDate = keyword.enteredDate
//        let updatedDate = keyword.updatedDate
//        let isIgnoredSuggestion = keyword.isIgnoredSuggestion
//                        
//        let context = DataManager.shared.createContext()
//        return await context.perform {
//            if let entity = DataManager.shared.getOne(
//                context: context,
//                type: PersistentKeyword.self,
//                predicate: .byId(.string(keywordID)),
//                createIfNotFound: false
//            ) {
//                entity.id = keywordID
//                entity.keyword = theKeyword
//                
//                if let categoryEntity = DataManager.shared.getOne(
//                    context: context,
//                    type: PersistentCategory.self,
//                    predicate: .byId(.string(categoryID)),
//                    createIfNotFound: false
//                ) {
//                    entity.category = categoryEntity
//                }
//                                
//                entity.triggerType = triggerType
//                entity.action = "edit"
//                entity.isPending = false
//                entity.renameTo = renameTo
//                entity.isIgnoredSuggestion = isIgnoredSuggestion
//                
//                entity.enteredByID = enteredByID
//                entity.updatedByID = updatedByID
//                entity.enteredDate = enteredDate
//                entity.updatedDate = updatedDate
//                
//                return DataManager.shared.save(context: context)
//                
//            } else {
//                return .failure(.notFound)
//            }
//        }
//    }
    
    
//    func updateCoreData(for snapshot: CBKeyword.Snapshot) async -> Result<Bool, CoreDataError> {
//        let context = DataManager.shared.createContext()
//        return await context.perform {
//            if let entity = DataManager.shared.getOne(
//                context: context,
//                type: PersistentKeyword.self,
//                predicate: .byId(.string(snapshot.id)),
//                createIfNotFound: false
//            ) {
//                entity.id = snapshot.id
//                entity.keyword = snapshot.keyword
//                entity.triggerType = snapshot.triggerTypeRaw
//                entity.action = "edit"
//                entity.isPending = false
//                entity.renameTo = snapshot.renameTo
//                entity.isIgnoredSuggestion = snapshot.isIgnoredSuggestion
//                entity.enteredByID = Int64(snapshot.enteredByID)
//                entity.updatedByID = Int64(snapshot.updatedByID)
//                entity.enteredDate = snapshot.enteredDate
//                entity.updatedDate = snapshot.updatedDate
//                
//                if let categoryID = snapshot.categoryID, let categoryEntity = DataManager.shared.getOne(
//                    context: context,
//                    type: PersistentCategory.self,
//                    predicate: .byId(.string(categoryID)),
//                    createIfNotFound: false
//                ) {
//                    entity.category = categoryEntity
//                }
//                
//                return DataManager.shared.save(context: context)
//                
//            } else {
//                return .failure(.notFound)
//            }
//        }
//    }
    
    
    @MainActor
    func fetchKeywords(file: String = #file, line: Int = #line, function: String = #function) async {
        NSLog("\(file):\(line) : \(function)")
        LogManager.log()
        
        let start = CFAbsoluteTimeGetCurrent()
        
        /// For testing bad network connection.
        //try? await Task.sleep(for: .seconds(10))
        
        /// Do networking.
        let model = RequestModel(requestType: "fetch_keywords", model: AppState.shared.user)
        typealias ResultResponse = Result<Array<CBKeyword>?, AppError>
        async let result: ResultResponse = await NetworkManager().arrayRequest(requestModel: model)
        
        switch await result {
        case .success(let model):
            LogManager.networkingSuccessful()
            if let model {
                if !model.isEmpty {
                    for keyword in model.sorted(by: { $0.keyword.lowercased() < $1.keyword.lowercased() }) {
                        upsert(keyword)
                        await keyword.updateCoreData(action: .edit, isPending: false, createIfNotFound: true)
                    }
                    
                    /// Delete from cache and local list.
                    for keyword in keywords {
                        if model.filter({ $0.id == keyword.id }).isEmpty {
                            delete(keyword, andSubmit: false)
                        }
                    }
                } else {
                    keywords.removeAll()
                }
            }                        
            
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
    @discardableResult
    func submit(_ keyword: CBKeyword, file: String = #file, line: Int = #line, function: String = #function) async -> Bool {
        print("-- \(#function) -- Called from: \(file):\(line) : \(function)")
        
        /// Allow more time to save if the user enters the background.
        #if os(iOS)
        var backgroundTaskId = AppState.shared.beginBackgroundTask()
        #endif
        
        LogManager.log()
        
        /// Used to test the snapshot data race
        //try? await Task.sleep(nanoseconds: UInt64(6 * Double(NSEC_PER_SEC)))
        
        /// Stuff in core data in case something goes wrong in the networking.
        /// If something goes wrong, the isPending flag will cause it to be queued for syncing on next successful connection.
        await keyword.updateCoreData(action: keyword.action, isPending: true, createIfNotFound: false)
        
        let model = RequestModel(requestType: keyword.action.serverKey, model: keyword)
        typealias ResultResponse = Result<ReturnIdModel?, AppError>
        async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
                                
        switch await result {
        case .success(let model):
            LogManager.networkingSuccessful()
                        
            if keyword.action == .delete {
                DataManager.shared.delete(context: DataManager.shared.createContext(), type: PersistentKeyword.self, predicate: .byId(.string(keyword.id)))
                
            } else if let serverID = model?.id {
                /// If adding, the keyword ID will be the UUID, which is what would have been used to save the item to core data initially, so pass it as the lookupID.
                /// Pass the new serverID as the id so it gets set on the keyword.
                await keyword.updateAfterSubmit(id: keyword.action == .add ? serverID : keyword.id, lookupId: keyword.id, action: keyword.action)
            }
            
        case .failure(let error):
            LogManager.error(error.localizedDescription)
            AppState.shared.showAlert("There was a problem syncing the keyword. Will try again at a later time.")
        }
                
        #if os(macOS)
        fuckYouSwiftuiTableRefreshID = UUID()
        #endif
        
        /// End the background task.
        #if os(iOS)
        AppState.shared.endBackgroundTask(&backgroundTaskId)
        #endif
        
        return (await result).isSuccess                
    }
    
    
    /// - Parameters:
    ///    - keyword: The keyword to be deleted.
    ///    - andSubmit: Via a user action = true. Via longpoll = false.
    func delete(_ keyword: CBKeyword, andSubmit: Bool) {
        keyword.action = .delete
        withAnimation { keywords.removeAll { $0.id == keyword.id }}
        
        if andSubmit {
            Task { @MainActor in
                let _ = await submit(keyword)
            }
        } else {
            let context = DataManager.shared.createContext()
            DataManager.shared.delete(context: context, type: PersistentKeyword.self, predicate: .byId(.string(keyword.id)))
        }
    }
    
    
    func handleLongPoll(_ keywords: Array<CBKeyword>) async {
        print("-- \(#function)")
        for keyword in keywords {
            if self.doesExist(keyword) {
                if !keyword.active {
                    self.delete(keyword, andSubmit: false)
                    continue
                } else {
                    if let index = self.getIndex(for: keyword) {
                        self.keywords[index].setFromAnotherInstance(keyword: keyword)
                        self.keywords[index].deepCopy?.setFromAnotherInstance(keyword: keyword)
                    }
                }
            } else {
                if keyword.active {
                    withAnimation { self.upsert(keyword) }
                }
            }
            let _ = await keyword.updateCoreData(action: .edit, isPending: false, createIfNotFound: false)
            //print("SaveResult: \(saveResult)")
        }
    }
    
    @MainActor
    func populateFromCache() async {
        let context = DataManager.shared.createContext()

        let keywordIDs: [String] = await DataManager.shared.perform(context: context) {
            let entities = DataManager.shared.getMany(context: context, type: PersistentKeyword.self) ?? []
            return entities.compactMap(\.id)
        }

        guard !keywordIDs.isEmpty else { return }

        var loadedKeywords: [CBKeyword] = []
        loadedKeywords.reserveCapacity(keywordIDs.count)

        for id in keywordIDs {
            if let keyword = await CBKeyword.loadFromCoreData(id: id) {
                loadedKeywords.append(keyword)
            }
        }

        loadedKeywords.sort { $0.keyword.lowercased() < $1.keyword.lowercased() }

        for keyword in loadedKeywords {
            self.upsert(keyword)
        }
    }
}
