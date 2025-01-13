////
////  TagModel.swift
////  MakeItRain
////
////  Created by Cody Burnett on 9/28/24.
////
//
//import Foundation
//
//@MainActor
//@Observable
//class TagModel {
//    var tagEditID: Int?
//    var tags: Array<CBTag> = []
//    //var refreshTask: Task<Void, Error>?
//    var fuckYouSwiftuiTableRefreshID: UUID = UUID()
//    
//    func doesExist(_ tag: CBTag) -> Bool {
//        return !tags.filter { $0.id == tag.id }.isEmpty
//    }
//    
//    func getTag(by id: Int) -> CBTag {
//        return tags.filter { $0.id == id }.first ?? CBTag.empty
//    }
//    
//    func upsert(_ tag: CBTag) {
//        if !doesExist(tag) {
//            tags.append(tag)
//        }
//    }
//    
//    func getIndex(for tag: CBTag) -> Int? {
//        return tags.firstIndex(where: { $0.id == tag.id })
//    }
//    
//    func saveTag(id: Int) {
//        let tag = getTag(by: id)
//        Task {
//            
//            if tag.tag.isEmpty {
//                if tag.id != 0 && tag.tag.isEmpty {
//                    tag.tag = tag.deepCopy?.tag ?? ""
//                    AppState.shared.showAlert("Removing a title is not allowed. If you want to delete \(tag.tag), please use the delete button instead.")
//                } else {
//                    tags.removeAll { $0.id == 0 }
//                }
//                return
//            }
//                                
//            if tag.hasChanges() {
//                await submit(tag)
//            }
//        }
//    }
//    
//    func updateCache(for tag: CBTag) -> Result<Bool, CoreDataError> {
//        guard let entity = DataManager.shared.getOne(type: PersistentTag.self, predicate: .byId(.int(tag.id)), createIfNotFound: false) else { return .failure(.reason("notFound")) }
//                
//        entity.id = Int64(tag.id)
//        entity.tag = tag.tag
//        
//        let saveResult = DataManager.shared.save()
//        return saveResult
//    }
//    
//    @MainActor
//    func fetchTags() async {
//        LogManager.log()
//        
//        /// Do networking.
//        let model = RequestModel(requestType: "fetch_tags", model: AppState.shared.user)
//        typealias ResultResponse = Result<Array<CBTag>?, AppError>
//        async let result: ResultResponse = await NetworkManager().arrayRequest(requestModel: model)
//        
//        switch await result {
//        case .success(let model):
//            
//            /// For testing bad network connection.
//            //try? await Task.sleep(nanoseconds: UInt64(10 * Double(NSEC_PER_SEC)))
//
//            LogManager.networkingSuccessful()
//            if let model {
//                if !model.isEmpty {
//                    var activeIds: Array<Int> = []
//                    for tag in model {
//                        activeIds.append(tag.id)
//                        
//                        /// Find the tag in cache.
//                        let entity = DataManager.shared.getOne(type: PersistentTag.self, predicate: .byId(.int(tag.id)), createIfNotFound: true)
//                        
//                        /// Update the cache and add to model (if appolicable).
//                        /// This should always be true because the line above creates the entity if it's not found.
//                        if let entity {
//                            entity.id = Int64(tag.id)
//                            entity.tag = tag.tag
//                            
//                            let index = tags.firstIndex(where: { $0.id == tag.id })
//                            if let index {
//                                /// If the payment method is already in the list, update it from the server.
//                                tags[index].setFromAnotherInstance(tag: tag)
//                            } else {
//                                /// Add the payment method to the list (like when the payment method was added on another device).
//                                tags.append(tag)
//                            }
//                        }
//                    }
//                    
//                    /// Delete from cache and model.
//                    for tag in tags {
//                        if !activeIds.contains(tag.id) {
//                            tags.removeAll { $0.id == tag.id }
//                            let _ = DataManager.shared.delete(type: PersistentTag.self, predicate: .byId(.int(tag.id)))
//                        }
//                    }
//            
//                    /// Save the cache.
//                    let _ = DataManager.shared.save()
//                }
//            }
//            
//            /// Update the progress indicator.
//            AppState.shared.downloadedData.append(.tags)
//            
//        case .failure (let error):
//            switch error {
//            case .taskCancelled:
//                /// Task get cancelled when switching years. So only show the alert if the error is not related to the task being cancelled.
//                print("keyModel fetchFrom Server Task Cancelled")
//            default:
//                LogManager.error(error.localizedDescription)
//                AppState.shared.showAlert("There was a problem trying to fetch the tags.")
//            }
//        }
//    }
//    
//    
//    @MainActor
//    func submit(_ tag: CBTag) async {
//        //LoadingManager.shared.startDelayedSpinner()
//        LogManager.log()
//        let model = RequestModel(requestType: tag.action.serverKey, model: tag)
//            
//        /// Used to test the snapshot data race
//        //try? await Task.sleep(nanoseconds: UInt64(6 * Double(NSEC_PER_SEC)))
//        
//        typealias ResultResponse = Result<ResultCompleteModel?, AppError>
//        async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
//        
//        
//        print(tag.action)
//                    
//        switch await result {
//        case .success(let model):
//            LogManager.networkingSuccessful()
//            /// Get the new ID from the server after adding a new activity.
//            if tag.action != .delete {
//                guard let entity = DataManager.shared.getOne(type: PersistentTag.self, predicate: .byId(.int(tag.id)), createIfNotFound: true) else { return }
//                
//                if tag.action == .add {
//                    tag.id = Int(model?.result ?? "0") ?? 0
//                    tag.action = .edit
//                    entity.id = Int64(model?.result ?? "0") ?? 0
//                }
//                                
//                entity.tag = tag.tag
//                                                                
//                let _ = DataManager.shared.save()
//            } else {
//                let _ = DataManager.shared.delete(type: PersistentTag.self, predicate: .byId(.int(tag.id)))
//            }
//            
//        case .failure(let error):
//            LogManager.error(error.localizedDescription)
//            AppState.shared.showAlert("There was a problem trying to save the tag.")
//            tag.deepCopy(.restore)
//            
//            switch tag.action {
//            case .add: tags.removeAll { $0.id == 0 }
//            case .edit: break
//            case .delete: tags.append(tag)
//            }
//        }
//        
//        tag.action = .edit
//        fuckYouSwiftuiTableRefreshID = UUID()
//    }
//    
//    
//    func delete(_ tag: CBTag, andSubmit: Bool) async {
//        tag.action = .delete
//        tags.removeAll { $0.id == tag.id }
//        
//        if andSubmit {
//            await submit(tag)
//        } else {
//            let _ = DataManager.shared.delete(type: PersistentTag.self, predicate: .byId(.int(tag.id)))
//        }
//    }
//    
//    
//    func deleteAll() async {
//        for tag in tags {
//            tag.action = .delete
//            await submit(tag)
//        }
//        
//        let saveResult = DataManager.shared.deleteAll(for: PersistentTag.self)
//        print("SaveResult: \(saveResult)")
//        tags.removeAll()
//    }
//}
