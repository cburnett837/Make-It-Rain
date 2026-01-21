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
    @Environment(PayMethodModel.self) private var payModel
    @Environment(CategoryModel.self) private var catModel

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
                        logLine(for: log)
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
    
    
    @ViewBuilder
    func logLine(for log: CBLog) -> some View {
        LazyVGrid(columns: columnGrid, alignment: .leading, spacing: 10) {
            Text(LogField.pretty(for: log.field) ?? "N/A")
            
            if log.field == .amount {
                if let old = log.old, let oldDouble = Double(old) {
                    Text("\(oldDouble.currencyWithDecimals())")
                }
                if let new = log.new, let newDouble = Double(new) {
                    Text("\(newDouble.currencyWithDecimals())")
                }
                
            } else if log.field == .payMethod {
                if let old = log.old {
                    let meth = payModel.getPaymentMethod(by: old)
                    HStack {
                        BusinessLogo(config: .init(parent: meth, fallBackType: .color, size: 20))
                        Text(meth.title)
                    }
                }
                if let new = log.new {
                    let meth = payModel.getPaymentMethod(by: new)
                    HStack {
                        BusinessLogo(config: .init(parent: meth, fallBackType: .color, size: 20))
                        Text(meth.title)
                    }
                }
                
            } else if log.field == .category {
                if let old = log.old {
                    let cat = catModel.getCategory(by: old)
                    StandardCategoryLabel(cat: cat, labelWidth: 20, showCheckmarkCondition: false)
                }
                if let new = log.new {
                    let cat = catModel.getCategory(by: new)
                    StandardCategoryLabel(cat: cat, labelWidth: 20, showCheckmarkCondition: false)
                }
                
            } else {
                if let old = log.old {
                    Text(old.isEmpty ? "[Nothing]" : old)
                        .foregroundStyle(old.isEmpty ? .gray : .primary)
                }
                if let new = log.new {
                    Text(new.isEmpty ? "[Nothing]" : new)
                        .foregroundStyle(new.isEmpty ? .gray : .primary)
                }
            }
        }
        .font(.caption2)
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
