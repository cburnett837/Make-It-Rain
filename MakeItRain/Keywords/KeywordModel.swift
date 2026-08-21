//
//  KeywordModel.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/28/24.
//

import Foundation
import SwiftUI

@MainActor
@Observable
class KeywordModel {
    @ObservationIgnored private let store: AppStore
    init(store: AppStore) {
        self.store = store
    }
    
    var keywords: [CBKeyword] {
        get { store.keywords }
        set { store.keywords = newValue }
    }
    
    var isThinking = false
    //var keywords: Array<CBKeyword> = []
    var fuckYouSwiftuiTableRefreshID: UUID = UUID()
    
    func doesExist(_ keyword: CBKeyword) -> Bool {
        return !keywords.filter { $0.id == keyword.id }.isEmpty
    }
    
    func getKeyword(by id: String) -> CBKeyword? {
        return keywords.first(where: { $0.id == id })
    }
    
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
    
    func saveKeyword(id: String, file: String = #file, line: Int = #line, function: String = #function) async -> Bool {
        print("-- \(#function) -- Called from: \(file):\(line) : \(function)")

        guard let keyword = getKeyword(by: id) else { return true }
        
        if keyword.action == .delete {
            keyword.updatedBy = AppState.shared.user!
            keyword.updatedDate = Date()
            return await delete(keyword, andSubmit: true)
        }
        
        /// User blanked out the title of an existing keyword.
        if keyword.action == .edit && keyword.keyword.isEmpty {
            keyword.keyword = keyword.deepCopy?.keyword ?? ""
            AppState.shared.showAlert("Removing a title is not allowed. If you want to delete \(keyword.keyword), please use the delete button instead.")
            return false
        }
        
        /// User is entering a new keyword but forgot the payment method.
        /// Remove the dud that is in `.add` mode since it's being upserted into the list on creation.
        if ((keyword.category == nil || keyword.category?.isNil ?? false) && keyword.renameTo == nil) && !keyword.keyword.isEmpty {
            AppState.shared.showAlert(title: "A condition is required", subtitle: "\(keyword.keyword) was not saved.")
            return await delete(keyword, andSubmit: false)
        }
                            
        if keyword.hasChanges() {
            keyword.updatedBy = AppState.shared.user!
            keyword.updatedDate = Date()
            return await submit(keyword)
        }
        
        return false
    }
    
    
    @MainActor
    func handleIncoming(keys: Array<CBKeyword>, incomingDataType: IncomingDataType) async {
        if keys.isEmpty {
            keywords.removeAll()
            return
        }
        
        for keyword in keys.sorted(by: { $0.keyword.lowercased() < $1.keyword.lowercased() }) {
            if self.doesExist(keyword) {
                if !keyword.active {
                    await self.delete(keyword, andSubmit: false)
                    continue
                } else if let index = self.getIndex(for: keyword) {
                    self.keywords[index].setFromAnotherInstance(keyword: keyword)
                    self.keywords[index].deepCopy?.setFromAnotherInstance(keyword: keyword)
                }
            } else if keyword.active {
                withAnimation { self.upsert(keyword) }
            }
            
            await keyword.updateCoreData(action: .edit, isPending: false, createIfNotFound: incomingDataType == .viaStandardRefresh)
        }
        
        /// When downloading everything from the server, if we find a local object that is not in the server payload, it means it is no longer valid and must be deleted from the local copies.
        if incomingDataType == .viaStandardRefresh {
            for keyword in self.keywords {
                if keys.filter({ $0.id == keyword.id }).isEmpty {
                    await delete(keyword, andSubmit: false)
                }
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
        await keyword.updateCoreData(action: keyword.action, isPending: true, createIfNotFound: true)
        
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
    @discardableResult
    func delete(_ keyword: CBKeyword, andSubmit: Bool) async -> Bool {
        keyword.action = .delete
        withAnimation { keywords.removeAll { $0.id == keyword.id }}
        
        if andSubmit {
            return await submit(keyword)
        } else {
            let context = DataManager.shared.createContext()
            DataManager.shared.delete(context: context, type: PersistentKeyword.self, predicate: .byId(.string(keyword.id)))
            return false
        }
    }
    
    
    @MainActor
    func populateFromCoreData() async {
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
