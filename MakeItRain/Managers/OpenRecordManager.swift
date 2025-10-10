//
//  OpenRecordManager.swift
//  MakeItRain
//
//  Created by Cody Burnett on 3/31/25.
//

import Foundation
import SwiftUI

@Observable
class OpenRecordManager {
    static let shared = OpenRecordManager()
    
    var openOrClosedRecords: Array<CBOpenOrClosedRecord> = []
    var localOpenOrClosedRecords: Array<CBOpenOrClosedRecord> = []
    
    
    @MainActor
    func markRecordAsOpenOrClosed(_ openOrClosed: CBOpenOrClosedRecord) async -> Bool {
        print("-- \(#function)")
        
        #if os(iOS)
        var backgroundTaskID = AppState.shared.beginBackgroundTask()
        #endif
        
        LogManager.log()
        let model = RequestModel(requestType: "mark_record_as_open_or_closed", model: openOrClosed)
        
        typealias ResultResponse = Result<ReturnIdModel?, AppError>
        async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
                    
        switch await result {
        case .success(let model):
            LogManager.networkingSuccessful()
            
            switch openOrClosed.openOrClosed {
            case .open:
                localOpenOrClosedRecords.append(openOrClosed)
                
            case .closed:
                localOpenOrClosedRecords.removeAll { $0.id == openOrClosed.recordID || $0.user.id == AppState.shared.user?.id }
                openOrClosedRecords.removeAll { $0.id == openOrClosed.recordID || $0.user.id == AppState.shared.user?.id }
            }
            
            openOrClosed.id = model?.id ?? "0"
            openOrClosed.uuid = nil
                        
            #if os(iOS)
            AppState.shared.endBackgroundTask(&backgroundTaskID!)
            #endif
            return true
            
        case .failure(let error):
            LogManager.error(error.localizedDescription)
            AppState.shared.showAlert("There was a problem trying to mark the event as open or closed: \(error.localizedDescription)")
            #if os(iOS)
            AppState.shared.endBackgroundTask(&backgroundTaskID!)
            #endif
            return false
        }
        //LoadingManager.shared.stopDelayedSpinner()
    }
    
    
    @MainActor
    func batchMark(_ asWhat: OpenOrClosed) async -> Bool {
        print("-- \(#function)")
        
        #if os(iOS)
        var backgroundTaskID = AppState.shared.beginBackgroundTask()
        #endif
        
        let thing = CBBatchOpenOrClosed(openOrClosed: asWhat, records: self.localOpenOrClosedRecords)
        
        LogManager.log()
        let model = RequestModel(requestType: "mark_multiple_records_as_open_or_closed", model: thing)
        
        typealias ResultResponse = Result<ResultCompleteModel?, AppError>
        async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
                    
        switch await result {
        case .success:
            LogManager.networkingSuccessful()
                        
            #if os(iOS)
            AppState.shared.endBackgroundTask(&backgroundTaskID!)
            #endif
            return true
            
        case .failure(let error):
            LogManager.error(error.localizedDescription)
            AppState.shared.showAlert("There was a problem trying to mark the event as open or closed")
            #if os(iOS)
            AppState.shared.endBackgroundTask(&backgroundTaskID!)
            #endif
            return false
        }
        //LoadingManager.shared.stopDelayedSpinner()
    }
    
    
    
    @MainActor
    func fetchOpenOrClosed() async {
        print("-- \(#function)")
        
        LogManager.log()
        let model = RequestModel(requestType: "fetch_open_or_closed_records", model: AppState.shared.user!)
        
        typealias ResultResponse = Result<Array<CBOpenOrClosedRecord>?, AppError>
        async let result: ResultResponse = await NetworkManager().arrayRequest(requestModel: model)
                    
        switch await result {
        case .success(let model):
            LogManager.networkingSuccessful()
            
            if let model = model {
                withAnimation {
                    openOrClosedRecords = model
                }
            }
            
        case .failure(let error):
            LogManager.error(error.localizedDescription)
            print("⚠️ \(error.localizedDescription)")
            AppState.shared.showAlert("There was a problem trying to fetch the open or closed events.")
            #warning("Undo behavior")
        }
        //LoadingManager.shared.stopDelayedSpinner()
    }
    
    // MARK: - Open Events
    func doesExist(_ open: CBOpenOrClosedRecord, what: XrefEnum) -> Bool {
        return !openOrClosedRecords.filter { $0.id == open.id && $0.recordType.enumID == what }.isEmpty
    }
    
    func deleteOpen(id openID: String, what: XrefEnum) {
        /// If someone opens and closed a record quickly, allow time for the initial actions animation to complete before running the 2nd action. If now, this will lead to inconsistent state in the UI.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation {
                self.openOrClosedRecords.removeAll(where: { $0.id == openID && $0.recordType.enumID == what })
            }
        }
    }
    
    func getIndex(for open: CBOpenOrClosedRecord, what: XrefEnum) -> Int? {
        return openOrClosedRecords.firstIndex(where: { $0.id == open.id && $0.recordType.enumID == what })
    }
    
    func upsert(_ open: CBOpenOrClosedRecord, what: XrefEnum) {
        if !doesExist(open, what: what) {
            /// If someone opens and closed a record quickly, allow time for the initial actions animation to complete before running the 2nd action. If now, this will lead to inconsistent state in the UI.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation {
                    self.openOrClosedRecords.append(open)
                }
            }
        }
    }
}

