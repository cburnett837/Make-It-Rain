//
//  EventModel.swift
//  MakeItRain
//
//  Created by Cody Burnett on 1/20/25.
//

import Foundation
import SwiftUI

//
//struct CBEventFetchModel: Decodable {
//    var events: Array<CBEvent>
//    var invitations: Array<CBEventParticipant>
//    
//    
//    enum CodingKeys: CodingKey { case events, invitations }
//    
//    
//    init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        events = try container.decode(Array<CBEvent>.self, forKey: .events)
//        invitations = try container.decode(Array<CBEventInvite>.self, forKey: .invitations)
//    }
//}


@MainActor
@Observable
class EventModel {
    static let shared = EventModel()
    var isThinking = false
    
    //var eventEditID: Int?
    var events: Array<CBEvent> = []
    var invitations: Array<CBEventParticipant> = []
    //var pendingTransactionsToSave: Array<CBTransaction> = []
    //var pendingTransactionsToDelete: Array<CBTransaction> = []
    var revokedEvent: CBEvent?
    //var claimedTransaction: CBEvent?
    
    //var refreshTask: Task<Void, Error>?
    var fuckYouSwiftuiTableRefreshID: UUID = UUID()
    
    var justTransactions: Array<CBEventTransaction> {
        events.flatMap { $0.transactions }
    }
    
    func doesTransactionExist(with id: String) -> Bool {
        return !justTransactions.filter { $0.id == id }.isEmpty
    }
    
    func getTransactionIndex(for id: String) -> Int? {
        return justTransactions.firstIndex(where: { $0.id == id })
    }
    
    func getEventThatContainsTransaction(transactionID: String) -> CBEvent? {
        return events.filter { $0.transactions.map {$0.id}.contains(transactionID) }.first
    }
    
    
    func doesExist(_ event: CBEvent) -> Bool {
        return !events.filter { $0.id == event.id }.isEmpty
    }
    
    func getEvent(by id: String) -> CBEvent {
        return events.filter { $0.id == id }.first ?? CBEvent(uuid: id)
    }
    
    func upsert(_ event: CBEvent) {
        if !doesExist(event) {
            events.append(event)
        }
    }
    
    func revoke(_ event: CBEvent) {
        events.removeAll(where: {$0.id == event.id})
        revokedEvent = event
    }
    
    func getIndex(for event: CBEvent) -> Int? {
        return events.firstIndex(where: { $0.id == event.id })
    }
    
    func doesExist(_ participant: CBEventParticipant) -> Bool {
        return !invitations.filter { $0.id == participant.id }.isEmpty
    }
    
    func getInvitation(by id: String) -> CBEventParticipant {
        return invitations.filter { $0.id == id }.first!
    }
    
    func upsert(_ participant: CBEventParticipant) {
        if !doesExist(participant) {
            invitations.append(participant)
        }
    }
    
    func getIndex(for participant: CBEventParticipant) -> Int? {
        return invitations.firstIndex(where: { $0.id == participant.id })
    }
    
        
    
    func saveEvent(id: String, calModel: CalendarModel) {
        let event = getEvent(by: id)
        Task {
            /// Validate that the title is not empty.
            if event.title.isEmpty {
                if event.action != .add && event.title.isEmpty {
                    event.title = event.deepCopy?.title ?? ""
                    AppState.shared.showAlert("Removing a title is not allowed. If you want to delete \(event.title), please use the delete button instead.")
                } else {
                    #warning("idk if this makes sense...")
                    events.removeAll { $0.id == id }
                }
                return
            }
                                
            if event.hasChanges() {
                print("The event has changes")
                
                var relatedIDs: [TempRelatedID] = []
                
                struct TempRelatedID {
                    var eventTransID: String
                    var relatedID: String?
                }
                                
                event.transactions.forEach { trans in
                    /// Save the actions before the submit to server so I can translate them to the real transactions.
                    trans.actionBeforeSave = trans.action
                    
                    /// Save the related ID's. If unclaiming an transaction, the relatedID get's wiped out. So retain the relatedID so I can delete the realTrans.
                    relatedIDs.append(TempRelatedID(eventTransID: trans.id, relatedID: trans.relatedTransactionID))
                    
                    /// Blank out the relatedID since it has been retained above. This will set it to null on the server.
                    if trans.isBeingUnClaimed { trans.relatedTransactionID = nil }
                }
                
                /// Save the event
                let _ = await submit(event)
                
                /// If a transaction was added, go update the temp list with the new real ID from the server.
                event.transactions.forEach { trans in
                    if let index = relatedIDs.firstIndex(where: { $0.eventTransID == trans.uuid }) {
                        relatedIDs[index].eventTransID = trans.id
                        
                        /// This would normally happen in the `submit()`, but I need it here.
                        trans.uuid = nil
                    }
                }

                
                for eventTrans in event.transactions {
                    var relatedID = relatedIDs.filter {$0.eventTransID == eventTrans.id}.first!.relatedID
                    
                    print("eventTrans Title: \(eventTrans.title) - ID: \(eventTrans.id) - Active: \(eventTrans.active) ActionBeforeSave: \(eventTrans.actionBeforeSave)")
                                        
                    
                    /// Determine what to do to the realTransaction
                    switch eventTrans.actionBeforeSave {
                    case .add:
                        if eventTrans.isBeingClaimed {
                            /// If adding and claiming.
                            print("eventTrans \(eventTrans.id) is being claimed")
                            eventTrans.actionForRealTransaction = .add
                            
                            /// Create a related ID that will be used for the realTrans that will be created.
                            if relatedID == nil {
                                let uuid = UUID().uuidString
                                eventTrans.relatedTransactionID = uuid
                                relatedID = uuid
                            }
                            
                            
                        } else {
                            /// If adding doing nothing regarding claim.
                            eventTrans.actionForRealTransaction = nil
                        }
                        
                    case .edit:
                        if eventTrans.isBeingClaimed {
                            /// If editing and claiming
                            print("eventTrans \(eventTrans.id) is being claimed")
                            eventTrans.actionForRealTransaction = .add
                            
                            /// Create a related ID that will be used for the realTrans that will be created.
                            if relatedID == nil {
                                print("Creating realTrans ID for eventTrans \(eventTrans.id)")
                                let uuid = UUID().uuidString
                                eventTrans.relatedTransactionID = uuid
                                relatedID = uuid
                            }
                            
                        } else if eventTrans.isBeingUnClaimed {
                            print("eventTrans \(eventTrans.id) is being unclaimed")
                            /// if editing and unclaiming
                            eventTrans.actionForRealTransaction = .delete
                                                                               
                        } else if relatedID != nil {
                            print("eventTrans \(eventTrans.id) relatedID \(relatedID!) is not nil")
                            /// if doing nothing regarding claim, but the transaction appears to exist.
                            eventTrans.actionForRealTransaction = .edit
                            
                        } else {
                            print("else ignore")
                            /// if doing nothing regarding claim, and the transaction does not exist.
                            eventTrans.actionForRealTransaction = nil
                        }
                        
                    case .delete:
                        /// if deleting, delete.
                        eventTrans.actionForRealTransaction = .delete
                        
                        /// If the transaction exists locally, remove it.
                        if calModel.doesTransactionExist(with: relatedID!, from: .normalList) {
                            print("realTrans \(String(describing: relatedID)) does exist in cal Model")
                            event.transactions.removeAll(where: { $0.id == eventTrans.id })
                        } else {
                            print("realTrans \(String(describing: relatedID)) does NOT exist in calModel")
                        }
                    }
                    
                    
                    
                    if let _ = eventTrans.actionForRealTransaction, let relatedID = relatedID {
                        calModel.saveTransactionFromEvent(eventTrans: eventTrans, relatedID: relatedID)
                    }
                }
            } else {
                print("The event has no changes")
            }
        }
    }
    
    
    @MainActor
    func fetchEvents(file: String = #file, line: Int = #line, function: String = #function) async {
        NSLog("\(file):\(line) : \(function)")
        LogManager.log()
        
        /// Do networking.
        let model = RequestModel(requestType: "fetch_events", model: AppState.shared.user)
        typealias ResultResponse = Result<Array<CBEvent>?, AppError>
        async let result: ResultResponse = await NetworkManager().arrayRequest(requestModel: model)
        
        switch await result {
        case .success(let model):
            
            /// For testing bad network connection.
            //try? await Task.sleep(nanoseconds: UInt64(10 * Double(NSEC_PER_SEC)))

            LogManager.networkingSuccessful()
            if let model {
                if !model.isEmpty {
                    var activeIds: Array<String> = []
                    for event in model {
                        activeIds.append(event.id)
                        
                        let index = events.firstIndex(where: { $0.id == event.id })
                        if let index {
                            /// If the payment method is already in the list, update it from the server.
                            events[index].setFromAnotherInstance(event: event)
                        } else {
                            /// Add the payment method to the list (like when the payment method was added on another device).
                            events.append(event)
                        }
                    }
                    
                    /// Delete from cache and model.
                    for event in events {
                        if !activeIds.contains(event.id) {
                            events.removeAll { $0.id == event.id }
                        }
                    }
                }
            }
            /// Update the progress indicator.
            AppState.shared.downloadedData.append(.events)
            
        case .failure (let error):
            switch error {
            case .taskCancelled:
                /// Task get cancelled when switching years. So only show the alert if the error is not related to the task being cancelled.
                print("eventModel fetchFrom Server Task Cancelled")
            default:
                LogManager.error(error.localizedDescription)
                AppState.shared.showAlert("There was a problem trying to fetch the events.")
            }
        }
    }
    
    
    
    @MainActor
    func fetchInvitations(file: String = #file, line: Int = #line, function: String = #function) async {
        NSLog("\(file):\(line) : \(function)")
        LogManager.log()
        
        /// Do networking.
        let model = RequestModel(requestType: "fetch_invitations", model: AppState.shared.user)
        typealias ResultResponse = Result<Array<CBEventParticipant>?, AppError>
        async let result: ResultResponse = await NetworkManager().arrayRequest(requestModel: model)
        
        switch await result {
        case .success(let model):
            
            /// For testing bad network connection.
            //try? await Task.sleep(nanoseconds: UInt64(10 * Double(NSEC_PER_SEC)))

            LogManager.networkingSuccessful()
            if let model {
                self.invitations = model
            }
            /// Update the progress indicator.
            AppState.shared.downloadedData.append(.events)
            
        case .failure (let error):
            switch error {
            case .taskCancelled:
                /// Task get cancelled when switching years. So only show the alert if the error is not related to the task being cancelled.
                print("keyModel fetchFrom Server Task Cancelled")
            default:
                LogManager.error(error.localizedDescription)
                AppState.shared.showAlert("There was a problem trying to fetch the events invitations.")
            }
        }
    }
    
    
    
    
    @MainActor
    func submit(_ event: CBEvent) async -> Bool {
        isThinking = true
        
        //LoadingManager.shared.startDelayedSpinner()
        LogManager.log()
        
        let model = RequestModel(requestType: event.action.serverKey, model: event)
        /// Used to test the snapshot data race
        //try? await Task.sleep(nanoseconds: UInt64(6 * Double(NSEC_PER_SEC)))
         
        typealias ResultResponse = Result<EventIdModel?, AppError>
        async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
        
        
        //print(event.action)
                    
        switch await result {
        case .success(let model):
            print("🥰 Event update successful")
            LogManager.networkingSuccessful()
            /// Get the new ID from the server after adding a new activity.
            if event.action != .delete {
                if event.action == .add {
                    event.id = model?.eventID ?? "0"
                    event.uuid = nil
                    event.action = .edit
                }
                
                for each in model?.participantIds ?? [] {
                    let index = event.participants.firstIndex(where: { $0.uuid == each.uuid })
                    if let index {
                        let participant = event.participants[index]
                        if participant.action == .add {
                            participant.id = String(each.id)
                            participant.uuid = nil
                            participant.action = .edit
                        }
                    }
                }
                
                for each in model?.items ?? [] {
                    let index = event.items.firstIndex(where: { $0.uuid == each.uuid })
                    if let index {
                        let item = event.items[index]
                        if item.action == .add {
                            item.id = String(each.id)
                            item.uuid = nil
                            item.action = .edit
                        }
                    }
                }
                
                
                for each in model?.transactions ?? [] {
                    let index = event.transactions.firstIndex(where: { $0.uuid == each.uuid })
                    if let index {
                        let trans = event.transactions[index]
                        if trans.action == .add {
                            trans.id = String(each.id)
                            //trans.uuid = nil /// Don't blank this out because I need it to update the temp list related to saving realTrans.
                            trans.action = .edit
                        }
                    }
                }
            }
            
            //event.participantsToRemove.removeAll()
            
            //event.invitationsToSend.removeAll()
            isThinking = false
            event.action = .edit
            #if os(macOS)
            fuckYouSwiftuiTableRefreshID = UUID()
            #endif
            return true
            
        case .failure(let error):
            LogManager.error(error.localizedDescription)
            AppState.shared.showAlert("There was a problem syncing the event. Will try again at a later time.")
//            event.deepCopy(.restore)
//
//            switch event.action {
//            case .add: events.removeAll { $0.id == event.id }
//            case .edit: break
//            case .delete: events.append(event)
//            }
        }
        
        isThinking = false
        event.action = .edit
        #if os(macOS)
        fuckYouSwiftuiTableRefreshID = UUID()
        #endif
        return false
    }
    
    
    func delete(_ event: CBEvent, andSubmit: Bool) async {
        event.action = .delete
        event.participants.forEach { $0.action = .delete }
        event.items.forEach { $0.action = .delete }
        events.removeAll { $0.id == event.id }
        
        if andSubmit {
            let _ = await submit(event)
        }
    }
    
    
    func deleteAll() async {
        for event in events {
            event.action = .delete
            let _ = await submit(event)
        }
                
        //print("SaveResult: \(saveResult)")
        events.removeAll()
    }
    
    
    @MainActor
    func leave(_ event: CBEvent) async -> Bool {
        print("-- \(#function)")
        
        
        event.action = .delete        
        events.removeAll { $0.id == event.id }
        
        LogManager.log()
        let model = RequestModel(requestType: "budget_app_leave_event", model: event)
        
        typealias ResultResponse = Result<ResultCompleteModel?, AppError>
        async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
                    
        switch await result {
        case .success:
            LogManager.networkingSuccessful()
            return true
            
        case .failure(let error):
            LogManager.error(error.localizedDescription)
            AppState.shared.showAlert("There was a problem trying to save the repeating transaction.")
            #warning("Undo behavior")
            return false
        }
        //LoadingManager.shared.stopDelayedSpinner()
    }
    
    
    @MainActor
    func respondToInvitation(_ response: CBEventInviteResponse) async -> Bool {
        print("-- \(#function)")
        LogManager.log()
        let model = RequestModel(requestType: "budget_app_respond_to_event_invite", model: response)
        
        typealias ResultResponse = Result<ResultCompleteModel?, AppError>
        async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
                    
        switch await result {
        case .success:
            LogManager.networkingSuccessful()
            return true
            
        case .failure(let error):
            LogManager.error(error.localizedDescription)
            AppState.shared.showAlert("There was a problem trying to save the repeating transaction.")
            #warning("Undo behavior")
            return false
        }
        //LoadingManager.shared.stopDelayedSpinner()
    }
    
    
    
    
    @MainActor
    func verifyInviteEmailExists(_ invite: CBEventParticipant) async -> CBEventUserVerificationModel? {
        print("-- \(#function)")
        LogManager.log()
        let model = RequestModel(requestType: "budget_app_verify_event_invite_email", model: invite)
        
        typealias ResultResponse = Result<CBEventUserVerificationModel?, AppError>
        async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
                    
        switch await result {
        case .success(let model):
            LogManager.networkingSuccessful()
            if let model {
                return model
            } else {
                return nil
            }
            
        case .failure(let error):
            LogManager.error(error.localizedDescription)
            AppState.shared.showAlert("There was a problem trying to save the repeating transaction.")
            #warning("Undo behavior")
            return nil
        }
        //LoadingManager.shared.stopDelayedSpinner()
    }
}



enum InvitationVerificationResult {
    case found, notFound, alreadyInvited
    
    static func fromString(_ theString: String) -> Self {
        switch theString {
        case "found": return .found
        case "not_found": return .notFound
        case "already_invited": return .alreadyInvited
        default: return .notFound
        }
    }
}


struct CBEventUserVerificationModel: Decodable {
    var verificationResult: InvitationVerificationResult
    var user: CBUser?
    
    
    enum CodingKeys: CodingKey { case result, user }
    
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let result = try container.decode(String.self, forKey: .result)
        self.verificationResult = InvitationVerificationResult.fromString(result)
        
        user = try container.decode(CBUser?.self, forKey: .user)
    }
}

struct CBEventInviteResponse: Encodable {
    var id: String
    var uuid: String?
    var participantID: String
    var eventID: String
    var isAccepted: Bool = false

    init(eventID: String, participantID: String, isAccepted: Bool) {
        let uuid = UUID().uuidString
        self.id = uuid
        self.uuid = uuid
        self.eventID = eventID
        self.participantID = participantID
        self.isAccepted = isAccepted
    }

    enum CodingKeys: CodingKey { case id, uuid, event_id, participant_id, user_id, account_id, device_uuid, is_accepted }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(uuid, forKey: .uuid)
        try container.encode(participantID, forKey: .participant_id)
        try container.encode(eventID, forKey: .event_id)

        try container.encode(AppState.shared.user?.id, forKey: .user_id)
        try container.encode(AppState.shared.user?.accountID, forKey: .account_id)
        try container.encode(AppState.shared.deviceUUID, forKey: .device_uuid)
        try container.encode(isAccepted ? 1 : 0, forKey: .is_accepted)
    }
}
