//
//  EventModel.swift
//  MakeItRain
//
//  Created by Cody Burnett on 1/20/25.
//

import Foundation
import SwiftUI
import PhotosUI
#if canImport(AppKit)
import AppKit
#else
import UIKit
#endif

@MainActor
@Observable
class EventModel: FileUploadCompletedDelegate {
    func alertUploadingSmartReceiptIfApplicable() {}
    var message = ""
    var id = UUID()

    //static let shared = EventModel()
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
    
    func removeInvitation(by partID: String) {
        return invitations.removeAll(where: { $0.id == partID })
    }
    
    func upsert(_ participant: CBEventParticipant) {
        if !doesExist(participant) {
            invitations.append(participant)
        }
    }
    
    func getIndex(for participant: CBEventParticipant) -> Int? {
        return invitations.firstIndex(where: { $0.id == participant.id })
    }
        
    
    func saveEvent(id: String, calModel: CalendarModel) -> Bool {
        let event = getEvent(by: id)
        
        /// Validate that the title is not empty.
        if event.title.isEmpty {
            if event.action != .add && event.title.isEmpty {
                event.title = event.deepCopy?.title ?? ""
                AppState.shared.showAlert("Removing a title is not allowed. If you want to delete \(event.title), please use the delete button instead.")
            } else {
                #warning("idk if this makes sense...")
                events.removeAll { $0.id == id }
            }
            return false
        }
        
        if event.hasChanges() {
            print("The event has changes")
            Task {
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
                    
                    //print("eventTrans Title: \(eventTrans.title) - ID: \(eventTrans.id) - Active: \(eventTrans.active) ActionBeforeSave: \(eventTrans.actionBeforeSave)")
                                        
                    
                    /// Determine what to do to the realTransaction
                    switch eventTrans.actionBeforeSave {
                    case .add:
                        if eventTrans.isBeingClaimed {
                            /// If adding and claiming.
                            //print("eventTrans \(eventTrans.id) is being claimed")
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
                            //print("eventTrans \(eventTrans.id) is being claimed")
                            eventTrans.actionForRealTransaction = .add
                            
                            /// Create a related ID that will be used for the realTrans that will be created.
                            if relatedID == nil {
                                //print("Creating realTrans ID for eventTrans \(eventTrans.id)")
                                let uuid = UUID().uuidString
                                eventTrans.relatedTransactionID = uuid
                                relatedID = uuid
                            }
                            
                        } else if eventTrans.isBeingUnClaimed {
                            //print("eventTrans \(eventTrans.id) is being unclaimed")
                            /// if editing and unclaiming
                            eventTrans.actionForRealTransaction = .delete
                                                                               
                        } else if relatedID != nil {
                            //print("eventTrans \(eventTrans.id) relatedID \(relatedID!) is not nil")
                            /// if doing nothing regarding claim, but the transaction appears to exist.
                            eventTrans.actionForRealTransaction = .edit
                            
                        } else {
                            //print("else ignore")
                            /// if doing nothing regarding claim, and the transaction does not exist.
                            eventTrans.actionForRealTransaction = nil
                        }
                        
                    case .delete:
                        /// if deleting, delete.
                        eventTrans.actionForRealTransaction = .delete
                        if let relatedID = relatedID {
                            /// If the transaction exists locally, remove it.
                            if calModel.doesTransactionExist(with: relatedID, from: .normalList) {
                                //print("realTrans \(relatedID) does exist in cal Model")
                                event.transactions.removeAll(where: { $0.id == eventTrans.id })
                            } else {
                                //print("realTrans \(relatedID) does NOT exist in calModel")
                            }
                        } else {
                            //print("realTrans does NOT exist in calModel (related ID is nil)")
                        }
                    }
                    
                    if let _ = eventTrans.actionForRealTransaction, let relatedID = relatedID {
                        //calModel.saveTransactionFromEvent(eventTrans: eventTrans, relatedID: relatedID)
                    }
                }
            }
            return true
        } else {
            print("The event has no changes")
            return false
        }
    }
    
    
    // MARK: - Fetch Functions
    @MainActor
    func fetchEvents(file: String = #file, line: Int = #line, function: String = #function) async {
        NSLog("\(file):\(line) : \(function)")
        LogManager.log()
        
        let start = CFAbsoluteTimeGetCurrent()
        
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
                            events[index].setFromAnotherInstance(event: event)
                        } else {
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
            
            let currentElapsed = CFAbsoluteTimeGetCurrent() - start
            print("⏰It took \(currentElapsed) seconds to fetch the events")
            
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
        
        let start = CFAbsoluteTimeGetCurrent()
        
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
                self.invitations.removeAll()
                self.invitations = model
            }
            /// Update the progress indicator.
            AppState.shared.downloadedData.append(.events)
            
            let currentElapsed = CFAbsoluteTimeGetCurrent() - start
            print("⏰It took \(currentElapsed) seconds to fetch the event invitations")
            
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
    
    
    
    // MARK: - Submit Functions
    @MainActor
    func submitOG(_ event: CBEvent) async -> Bool {
        print("-- \(#function)")
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
                
//                for each in model?.items ?? [] {
//                    let index = event.items.firstIndex(where: { $0.uuid == each.uuid })
//                    if let index {
//                        let item = event.items[index]
//                        if item.action == .add {
//                            item.id = String(each.id)
//                            item.uuid = nil
//                            item.action = .edit
//                        }
//                    }
//                }
                
//                for each in model?.categories ?? [] {
//                    let index = event.categories.firstIndex(where: { $0.uuid == each.uuid })
//                    if let index {
//                        let cat = event.categories[index]
//                        if cat.action == .add {
//                            cat.id = String(each.id)
//                            cat.uuid = nil
//                            cat.action = .edit
//                        }
//                    }
//                }
//                
                
//                for each in model?.transactions ?? [] {
//                    let index = event.transactions.firstIndex(where: { $0.uuid == each.uuid })
//                    if let index {
//                        let trans = event.transactions[index]
//                        if trans.action == .add {
//                            trans.id = String(each.id)
//                            //trans.uuid = nil /// Don't blank this out because I need it to update the temp list related to saving realTrans.
//                            trans.action = .edit
//                        }
//                    }
//                }
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
    
        
    
    @MainActor
    func submit(_ event: CBEvent) async -> Bool {
        print("-- \(#function)")
        isThinking = true
        
        //LoadingManager.shared.startDelayedSpinner()
        LogManager.log()
        
        let model = RequestModel(requestType: event.action.serverKey, model: event)
        /// Used to test the snapshot data race
        //try? await Task.sleep(nanoseconds: UInt64(6 * Double(NSEC_PER_SEC)))
         
        typealias ResultResponse = Result<ReturnIdModel?, AppError>
        async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
        
        
        //print(event.action)
                    
        switch await result {
        case .success(let model):
            print("🥰 Event update successful")
            LogManager.networkingSuccessful()
            /// Get the new ID from the server after adding a new activity.
            ///
            if event.action == .add {
                event.id = model?.id ?? "0"
                event.uuid = nil
                event.action = .edit
            }
            
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
    
    
    @MainActor
    func submit(_ trans: CBEventTransaction) async -> Bool {
        print("-- \(#function)")
        isThinking = true
        //LoadingManager.shared.startDelayedSpinner()
        LogManager.log()
        
        let model = RequestModel(requestType: trans.action.serverKey, model: trans)
        
        /// Used to test the snapshot data race
        //try? await Task.sleep(nanoseconds: UInt64(6 * Double(NSEC_PER_SEC)))
         
        typealias ResultResponse = Result<ParentChildIdModel?, AppError>
        async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
        switch await result {
        case .success(let model):
            print("🥰 Event trans update successful")
            LogManager.networkingSuccessful()
            /// Get the new ID from the server after adding a new activity.
            if trans.action == .add {
                trans.id = model?.parentID.id ?? "0"
                trans.uuid = nil
                trans.action = .edit
            }
            
            
            for each in trans.locations {
                if each.action == .add {
                    let realId = model?.childIDs.filter {$0.uuid == each.uuid}.first
                    if let realId {
                        each.id = realId.id
                        each.uuid = nil
                        each.action = .edit
                    }
                }                
            }
            
            isThinking = false
            trans.action = .edit
            #if os(macOS)
            fuckYouSwiftuiTableRefreshID = UUID()
            #endif
            return true
            
        case .failure(let error):
            LogManager.error(error.localizedDescription)
            AppState.shared.showAlert("There was a problem saving the event transaction.")
//            event.deepCopy(.restore)
//
//            switch event.action {
//            case .add: events.removeAll { $0.id == event.id }
//            case .edit: break
//            case .delete: events.append(event)
//            }
        }
        
        isThinking = false
        trans.action = .edit
        #if os(macOS)
        fuckYouSwiftuiTableRefreshID = UUID()
        #endif
        return false
    }
    
    
    @MainActor
    func submit(_ category: CBEventCategory) async -> Bool {
        print("-- \(#function)")
        isThinking = true
        //LoadingManager.shared.startDelayedSpinner()
        LogManager.log()
        
        let model = RequestModel(requestType: category.action.serverKey, model: category)
        
        /// Used to test the snapshot data race
        //try? await Task.sleep(nanoseconds: UInt64(6 * Double(NSEC_PER_SEC)))
         
        typealias ResultResponse = Result<ReturnIdModel?, AppError>
        async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
        switch await result {
        case .success(let model):
            print("🥰 Event category update successful")
            LogManager.networkingSuccessful()
            /// Get the new ID from the server after adding a new activity.
            if category.action == .add {
                category.id = model?.id ?? "0"
                category.uuid = nil
                category.action = .edit
            }
            
            isThinking = false
            category.action = .edit
            #if os(macOS)
            fuckYouSwiftuiTableRefreshID = UUID()
            #endif
            return true
            
        case .failure(let error):
            LogManager.error(error.localizedDescription)
            AppState.shared.showAlert("There was a problem saving the event category.")
//            event.deepCopy(.restore)
//
//            switch event.action {
//            case .add: events.removeAll { $0.id == event.id }
//            case .edit: break
//            case .delete: events.append(event)
//            }
        }
        
        isThinking = false
        category.action = .edit
        #if os(macOS)
        fuckYouSwiftuiTableRefreshID = UUID()
        #endif
        return false
    }
    
        
    @MainActor
    func submit(_ item: CBEventItem) async -> Bool {
        print("-- \(#function)")
        isThinking = true
        //LoadingManager.shared.startDelayedSpinner()
        LogManager.log()
        
        let model = RequestModel(requestType: item.action.serverKey, model: item)
        
        /// Used to test the snapshot data race
        //try? await Task.sleep(nanoseconds: UInt64(6 * Double(NSEC_PER_SEC)))
         
        typealias ResultResponse = Result<ReturnIdModel?, AppError>
        async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
        switch await result {
        case .success(let model):
            print("🥰 Event item update successful")
            LogManager.networkingSuccessful()
            /// Get the new ID from the server after adding a new activity.
            if item.action == .add {
                item.id = model?.id ?? "0"
                item.uuid = nil
                item.action = .edit
            }
            
            isThinking = false
            item.action = .edit
            #if os(macOS)
            fuckYouSwiftuiTableRefreshID = UUID()
            #endif
            return true
            
        case .failure(let error):
            LogManager.error(error.localizedDescription)
            AppState.shared.showAlert("There was a problem saving the event item.")
//            event.deepCopy(.restore)
//
//            switch event.action {
//            case .add: events.removeAll { $0.id == event.id }
//            case .edit: break
//            case .delete: events.append(event)
//            }
        }
        
        isThinking = false
        item.action = .edit
        #if os(macOS)
        fuckYouSwiftuiTableRefreshID = UUID()
        #endif
        return false
    }
        
    
    @MainActor
    func submit(_ participant: CBEventParticipant) async -> Bool {
        print("-- \(#function)")
        isThinking = true
        //LoadingManager.shared.startDelayedSpinner()
        LogManager.log()
        
        let model = RequestModel(requestType: participant.action.serverKey, model: participant)
        
        /// Used to test the snapshot data race
        //try? await Task.sleep(nanoseconds: UInt64(6 * Double(NSEC_PER_SEC)))
         
        typealias ResultResponse = Result<ReturnIdModel?, AppError>
        async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
        switch await result {
        case .success(let model):
            print("🥰 Event participant update successful")
            LogManager.networkingSuccessful()
            /// Get the new ID from the server after adding a new activity.
            if participant.action == .add {
                participant.id = model?.id ?? "0"
                participant.uuid = nil
                participant.action = .edit
            }
            
            isThinking = false
            participant.action = .edit
            #if os(macOS)
            fuckYouSwiftuiTableRefreshID = UUID()
            #endif
            return true
            
        case .failure(let error):
            LogManager.error(error.localizedDescription)
            AppState.shared.showAlert("There was a problem saving the event participant.")
//            event.deepCopy(.restore)
//
//            switch event.action {
//            case .add: events.removeAll { $0.id == event.id }
//            case .edit: break
//            case .delete: events.append(event)
//            }
        }
        
        isThinking = false
        participant.action = .edit
        #if os(macOS)
        fuckYouSwiftuiTableRefreshID = UUID()
        #endif
        return false
    }
    
    
    @MainActor
    func submit(_ option: CBEventTransactionOption) async -> Bool {
        print("-- \(#function)")
        isThinking = true
        //LoadingManager.shared.startDelayedSpinner()
        LogManager.log()
        
        let model = RequestModel(requestType: option.action.serverKey, model: option)
        
        /// Used to test the snapshot data race
        //try? await Task.sleep(nanoseconds: UInt64(6 * Double(NSEC_PER_SEC)))
         
        typealias ResultResponse = Result<ParentChildIdModel?, AppError>
        async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
        switch await result {
        case .success(let model):
            print("🥰 Event transaction option update successful")
            LogManager.networkingSuccessful()
            /// Get the new ID from the server after adding a new activity.
            if option.action == .add {
                option.id = model?.parentID.id ?? "0"
                option.uuid = nil
                option.action = .edit
            }
            
            
            for each in option.locations {
                if each.action == .add {
                    let realId = model?.childIDs.filter {$0.uuid == each.uuid}.first
                    if let realId {
                        each.id = realId.id
                        each.uuid = nil
                        each.action = .edit
                    }
                }
            }
            
            
            
            isThinking = false
            option.action = .edit
            #if os(macOS)
            fuckYouSwiftuiTableRefreshID = UUID()
            #endif
            return true
            
        case .failure(let error):
            LogManager.error(error.localizedDescription)
            AppState.shared.showAlert("There was a problem saving the transaction item.")
//            event.deepCopy(.restore)
//
//            switch event.action {
//            case .add: events.removeAll { $0.id == event.id }
//            case .edit: break
//            case .delete: events.append(event)
//            }
        }
        
        isThinking = false
        option.action = .edit
        #if os(macOS)
        fuckYouSwiftuiTableRefreshID = UUID()
        #endif
        return false
    }
    
    
    
    
    
    
    // MARK: - Delete Functions
    
    func delete(_ event: CBEvent, andSubmit: Bool) async {
        event.action = .delete
        event.participants.forEach { $0.action = .delete }
        event.items.forEach { $0.action = .delete }
        event.categories.forEach { $0.action = .delete }
        event.transactions.forEach { $0.action = .delete }
        events.removeAll { $0.id == event.id }
        
        if andSubmit {
            let _ = await submit(event)
        }
    }
        
    
    func delete(_ trans: CBEventTransaction, andSubmit: Bool) async {
        trans.action = .delete
        if andSubmit {
            let _ = await submit(trans)
        }
    }
    
    
    func delete(_ category: CBEventCategory, andSubmit: Bool) async {
        category.action = .delete
        if andSubmit {
            let _ = await submit(category)
        }
    }
    
    
    func delete(_ item: CBEventItem, andSubmit: Bool) async {
        item.action = .delete
        if andSubmit {
            let _ = await submit(item)
        }
    }
    
    
    func delete(_ part: CBEventParticipant, andSubmit: Bool) async {
        part.action = .delete
        if andSubmit {
            let _ = await submit(part)
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
    
    
    
    // MARK: - Invitation Functions
    @MainActor
    func leave(_ part: CBEventParticipant) async -> Bool {
        print("-- \(#function)")
                
        part.action = .delete
        
        if part.user.id == AppState.shared.user?.id {
            events.removeAll { $0.id == part.eventID }
        }
        
        LogManager.log()
        let model = RequestModel(requestType: "budget_app_leave_event", model: part)
        
        typealias ResultResponse = Result<ResultCompleteModel?, AppError>
        async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
                    
        switch await result {
        case .success:
            LogManager.networkingSuccessful()
            return true
            
        case .failure(let error):
            LogManager.error(error.localizedDescription)
            AppState.shared.showAlert("There was a problem trying to leave the event.")
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
            AppState.shared.showAlert("There was a problem trying to respond to the invitation.")
            #warning("Undo behavior")
            return false
        }
        //LoadingManager.shared.stopDelayedSpinner()
    }
    
    
    @MainActor
    func invitePersonViaEmail(event: CBEvent, email: String) async -> Bool {
        print("-- \(#function)")
        LogManager.log()
        
        
        var part = CBEventParticipant(user: AppState.shared.user!, eventID: event.id, email: email)
        part.status = XrefModel.getItem(from: .eventInviteStatus, byEnumID: .pending)
        
        
        let model = RequestModel(requestType: "invite_person", model: part)
        
        typealias ResultResponse = Result<CBEventUserVerificationModel?, AppError>
        async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
                    
        switch await result {
        case .success(let model):
            LogManager.networkingSuccessful()
            if let model {
                switch model.verificationResult {
                case .found:
                    if let _ = model.participant {
                        part = model.participant!
                        part.user = model.user!
                        part.inviteTo = model.user!
                        event.participants.append(part)
                    }
                    return true
                    
                case .notFound:
                    AppState.shared.showAlert("That email is not available to invite.")
                    return false
                    
                case .alreadyInvited:
                    AppState.shared.showAlert("That person has already been invited.")
                    return false
                }
                
            } else {
                AppState.shared.showAlert("Problem adding person to event.")
                return false
            }
            
        case .failure(let error):
            LogManager.error(error.localizedDescription)
            AppState.shared.showAlert("There was a problem trying to verify the email exists.")
            #warning("Undo behavior")
            return false
        }
        //LoadingManager.shared.stopDelayedSpinner()
    }
    
    
    // MARK: - Photo Stuff
    func addPlaceholderFile(recordID: String, uuid: String, parentType: XrefItem, fileType: FileType) {
        let picture = CBFile(relatedID: recordID, uuid: uuid, parentType: parentType.enumID, fileType: fileType)
        picture.isPlaceholder = true
        
        if parentType.enumID == .eventTransaction {
            if let index = justTransactions.firstIndex(where: { $0.id == recordID }) {
                let trans = justTransactions[index]
                
                if let _ = trans.files {
                    trans.files!.append(picture)
                } else {
                    trans.files = [picture]
                }
                
            }
        }
        
        if parentType.enumID == .event {
            if let index = events.firstIndex(where: { $0.id == recordID }) {
                let event = events[index]
                
                if let _ = event.files {
                    event.files!.append(picture)
                } else {
                    event.files = [picture]
                }
            }
        }
    }
    
    func markPlaceholderFileAsReadyForDownload(recordID: String, uuid: String, parentType: XrefItem, fileType: FileType) {
        if parentType.enumID == .eventTransaction {
            if let trans = justTransactions.filter({ $0.id == recordID }).first {
                let index = trans.files?.firstIndex(where: { $0.uuid == uuid })
                if let index {
                    trans.files?[index].isPlaceholder = false
                }
            }
        }
        
        if parentType.enumID == .event {
            if let event = events.filter({ $0.id == recordID }).first {
                let index = event.files?.firstIndex(where: { $0.uuid == uuid })
                if let index {
                    event.files?[index].isPlaceholder = false
                }
            }
        }
    }
    
    func markFileAsFailedToUpload(recordID: String, uuid: String, parentType: XrefItem, fileType: FileType) {
        if parentType.enumID == .eventTransaction {
            if let trans = justTransactions.filter({ $0.id == recordID }).first {
                let index = trans.files?.firstIndex(where: { $0.uuid == uuid })
                if let index {
                    trans.files?[index].active = false
                }
            }
        }
        
        if parentType.enumID == .event {
            if let event = events.filter({ $0.id == recordID }).first {
                let index = event.files?.firstIndex(where: { $0.uuid == uuid })
                if let index {
                    event.files?[index].active = false
                }
            }
        }
    }
    
    func displayCompleteAlert(recordID: String, parentType: XrefItem, fileType: FileType) {
        
    }
    
    func delete(file: CBFile, parentType: XrefItem, fileType: FileType) async {
        if await FileModel.shared.delete(file) {
            if parentType.enumID == .eventTransaction {
                if let trans = justTransactions.filter({ $0.id == file.relatedID }).first {
                    if let _ = trans.files?.firstIndex(where: { $0.id == file.id }) {
                        trans.files?.removeAll { $0.id == file.id || $0.uuid == file.uuid }
                    }
                }
            }
            
            if parentType.enumID == .event {
                if let event = events.filter({ $0.id == file.relatedID }).first {
                    if let _ = event.files?.firstIndex(where: { $0.id == file.id }) {
                        event.files?.removeAll { $0.id == file.id || $0.uuid == file.uuid }
                    }
                }
            }
            
        } else {
            AppState.shared.showAlert("There was a problem trying to delete the picture.")
        }
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
