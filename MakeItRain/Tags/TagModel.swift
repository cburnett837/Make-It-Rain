////
////  TagModel.swift
////  MakeItRain
////
////  Created by Cody Burnett on 9/28/24.
////
//
import Foundation
import SwiftUI


@MainActor
@Observable
class TagModel {
    @ObservationIgnored private let store: AppStore
    init(store: AppStore) {
        self.store = store
    }
    
    var tags: [CBTag] {
        get { store.tags }
        set { store.tags = newValue }
    }
  
    
    @MainActor
    func handleIncoming(tags: Array<CBTag>, incomingDataType: IncomingDataType) async {
        self.tags.removeAll()
        for tag in tags {
            let index = self.tags.firstIndex(where: { $0.id == tag.id })
            if let index {
                self.tags[index].setFromAnotherInstance(tag: tag)
            } else {
                self.tags.append(tag)
            }
        }
    }
    
    
    /// Only used to hide a tag.
    @MainActor
    func submit(_ tag: CBTag) async {
        LogManager.log()
        
        /// Allow more time to save if the user enters the background.
        #if os(iOS)
        var backgroundTaskId = AppState.shared.beginBackgroundTask()
        #endif

        /// Do networking.
        let model = RequestModel(requestType: "edit_cb_tag", model: tag)
        typealias ResultResponse = Result<ResultCompleteModel?, AppError>
        async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)

        switch await result {
        case .success:
            LogManager.networkingSuccessful()
            
            /// End the background task.
            #if os(iOS)
            AppState.shared.endBackgroundTask(&backgroundTaskId)
            #endif
            
        case .failure (let error):
            switch error {
            case .taskCancelled:
                /// Task get cancelled when switching years. So only show the alert if the error is not related to the task being cancelled.
                print("\(#function) Task Cancelled")
            default:
                LogManager.error(error.localizedDescription)
                AppState.shared.showAlert("There was a problem trying to hide the tag.")
            }
            
            /// End the background task.
            #if os(iOS)
            AppState.shared.endBackgroundTask(&backgroundTaskId)
            #endif
        }
    }
    
    
    func updateParents(store: AppStore, tag: CBTag) {
        for trans in store.justTransactions.filter({ $0.tags.map({ $0.id }).contains(tag.id) }) {
            if let index = trans.tags.firstIndex(where: {$0.id == tag.id}) {
                trans.tags[index].title = tag.title
            }
        }
        
        for budget in store.budgets.filter({ $0.type == .tag && $0.item?.id == tag.id }) {
            budget.tag?.title = tag.title
        }
    }
}
