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

struct TevLogSheet: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @Environment(CalendarModel.self) private var calModel

    var title: String
    let itemID: String
    let logType: LogType
    @State private var logGroups: [CBLogGroup] = []
    
    @State private var showLoadingSpinner = true
    @State private var showNoLogs = false
    
    let columnGrid = Array(repeating: GridItem(.flexible(), spacing: 0), count: 3)
            
    var body: some View {
        VStack {
            if showNoLogs {
                Spacer()
                ContentUnavailableView("No Logs", systemImage: "text.page.slash", description: Text("Logs will appear here when changes are made."))
                Spacer()
            } else {
                StandardContainerWithToolbar(showNoLogs ? .scrolling : .list) {
                    content
                }
            }
        }
        .navigationTitle("Change Logs")
        .navigationSubtitle(title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { refreshButton }
            //ToolbarItem(placement: .topBarTrailing) { closeButton }
        }
        #endif
        .task {
            await fetchLogs()
        }
    }
    
    var content: some View {
        ForEach(logGroups) { group in
            Section {
                ForEach(group.logs) { log in
                    Button {
                        restoreLog(from: log)
                    } label: {
                        LazyVGrid(columns: columnGrid, alignment: .leading, spacing: 10) {
                            Text(LogField.pretty(for: log.field) ?? "N/A")
                            Text(log.old ?? "-")
                            Text(log.new ?? "-")
                        }
                        .font(.caption2)
                    }
                    .buttonStyle(.plain)
                    
                }
            } header: {
                VStack(alignment: .leading, spacing: 0) {
                    LazyVGrid(columns: columnGrid, alignment: .leading, spacing: 10) {
                        Text("What Field")
                        Text("Old")
                        Text("New")
                    }
                    .font(.caption2)
                    .bold()
                }
            } footer: {
                HStack {
                    UserAvatar(user: group.enteredBy)
                    Text("\(group.enteredBy.initials) - \(group.enteredDate.string(to: .monthDayShortYear)) - \(group.enteredDate.string(to: .timeAmPm))")
                }
            }
        }
        #if os(iOS)
        .listSectionSpacing(50)
        #endif
    }
    
    func restoreLog(from log: CBLog) {
        switch log.logType {
        case .transaction:
            
            let trans = calModel.getTransaction(by: itemID)
            
            switch log.field {
            case .title:
                trans.title = log.old ?? ""
            case .amount:
                break
            case .payMethod:
                break
            case .category:
                break
            case .notes:
                break
            case .factorInCalculations:
                break
            case .color:
                break
            case .tags:
                break
            case .notificationOffset:
                break
            case .notifyOnDueDate:
                break
            case .trackingNumber:
                break
            case .orderNumber:
                break
            case .url:
                break
            case .date:
                break
            case .christmasGiftStatus:
                break
            }
        case .paymentMethod:
            break
        case .category:
            break
        case .keyword:
            break
        case .repeatingTransaction:
            break
        }
        
        
        
    }
    
    
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
                        .schemeBasedForegroundStyle()
                }
            }
        }
    }
    
    
    
//    var closeButton: some View {
//        Button {
//            dismiss()
//        } label: {
//            Image(systemName: "xmark")
//                .schemeBasedForegroundStyle()
//        }
//        //.buttonStyle(.glassProminent)
//    }
    
    
    @MainActor
    func fetchLogs() async {
        print("-- \(#function)")
        LogManager.log()
        let model = RequestModel(requestType: "fetch_logs", model: FetchLogModel(itemID: itemID, logType: logType))
        
        typealias ResultResponse = Result<Array<CBLogGroup>?, AppError>
        async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
                    
        switch await result {
        case .success(let model):
            LogManager.networkingSuccessful()
            if let model {
                if model.isEmpty {
                    showNoLogs = true
                } else {
                    logGroups = model.sorted { $0.enteredDate > $1.enteredDate }
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
