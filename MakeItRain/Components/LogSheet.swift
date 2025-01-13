//
//  LogSheet.swift
//  MakeItRain
//
//  Created by Cody Burnett on 1/9/25.
//

import SwiftUI

class FetchLogModel: Encodable {
    var itemID: String
    var logType: LogType
    
    enum CodingKeys: CodingKey { case item_id, log_type, user_id, account_id, device_uuid }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(itemID, forKey: .item_id)
        try container.encode(logType.rawValue, forKey: .log_type)
        try container.encode(AppState.shared.user?.id, forKey: .user_id)
        try container.encode(AppState.shared.user?.accountID, forKey: .account_id)
        try container.encode(AppState.shared.deviceUUID, forKey: .device_uuid)
    }
    
    init(itemID: String, logType: LogType) {
        self.itemID = itemID
        self.logType = logType
    }
}

struct LogSheet: View {
    @Environment(\.dismiss) var dismiss
    
    let itemID: String
    let logType: LogType
    @State private var logs: [CBLog] = []
    
    @State private var showLoadingSpinner = true
    @State private var showNoLogs = false
    
    let columnGrid = Array(repeating: GridItem(.flexible(), spacing: 0), count: 5)
    
    
    var refreshButton: some View {
        Group {
            if showLoadingSpinner {
                ProgressView()
                    .opacity(showLoadingSpinner ? 1 : 0)
                    .tint(.none)
            } else {
                Button {
                    Task {
                        showLoadingSpinner = true
                        await fetchLogs()
                    }
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath")
                }
            }
        }
    }
    
    var body: some View {
        VStack {
            SheetHeader(
                title: "Change Logs",
                close: { dismiss() },
                view1: { refreshButton }
            )
            .padding(.bottom, 12)
            .padding(.horizontal, 20)
            .padding(.top)
            
            Divider()
            
            if showNoLogs {
                ContentUnavailableView("No Logs", systemImage: "square.stack.3d.up.slash.fill", description: Text("Logs will appear here when changes are made."))
            } else {
                List {
                    if !showLoadingSpinner {
                        LazyVGrid(columns: columnGrid, alignment: .leading, spacing: 10) {
                            Text("What")
                            Text("Old")
                            Text("New")
                            Text("Who")
                            Text("When")
                        }
                        .font(.caption2)
                        .bold()
                    }
                    
                    ForEach(logs) { log in
                        LazyVGrid(columns: columnGrid, alignment: .leading, spacing: 10) {
                            Text(LogField.pretty(for: log.field) ?? "N/A")
                            Text(log.old ?? "-")
                            Text(log.new ?? "-")
                            Text(log.enteredBy.initials)
                            Text(log.enteredDate.string(to: .monthDayHrMinAmPm))
                        }
                        .font(.caption2)
                    }
                }
                .listStyle(.plain)
            }
        }
        
        .task {
            await fetchLogs()
        }
    }
    
    
    @MainActor
    func fetchLogs() async {
        print("-- \(#function)")
        LogManager.log()
        let model = RequestModel(requestType: "fetch_logs", model: FetchLogModel(itemID: itemID, logType: logType))
        
        typealias ResultResponse = Result<Array<CBLog>?, AppError>
        async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
                    
        switch await result {
        case .success(let model):
            LogManager.networkingSuccessful()
            if let model {
                if model.isEmpty {
                    showNoLogs = true
                } else {
                    logs = model.sorted { $0.enteredDate > $1.enteredDate }
                }
            } else {
                showNoLogs = true
            }
            
            showLoadingSpinner = false
            
        case .failure(let error):
            showNoLogs = true
            showLoadingSpinner = false
            LogManager.error(error.localizedDescription)
            AppState.shared.showAlert("There was a problem fetching the logs.")
        }
    }
}
