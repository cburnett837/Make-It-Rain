//
//  LogModel.swift
//  MakeItRain
//
//  Created by Cody Burnett on 1/9/25.
//

import Foundation
import SwiftUI


enum LogField: String {
    /// Transaction
    case title = "title"
    case amount = "amount"
    case payMethod = "payment_method"
    case category = "category"
    case notes = "notes"
    case factorInCalculations = "factor_in_calculations"
    case color = "color"
    case tags = "tags"
    case notificationOffset = "notification_offset"
    case notifyOnDueDate = "notify_on_due_date"
    case trackingNumber = "tracking_number"
    case orderNumber = "order_number"
    case url = "url"
    case date = "date"
    
    
    static func pretty(for value: Self) -> String? {
        
        /// Transaction Changes
        if value == .title { return "Title" }
        else if value == .amount { return "Amount" }
        else if value == .payMethod { return "Pay Method" }
        else if value == .category { return "Category" }
        else if value == .notes { return "Notes" }
        else if value == .factorInCalculations { return "Factor In Calculations" }
        else if value == .color { return "Color" }
        else if value == .tags { return "Tags" }
        else if value == .notificationOffset { return "Notification Offset" }
        else if value == .notifyOnDueDate { return "Notify On Due Date" }
        else if value == .trackingNumber { return "Tracking Number" }
        else if value == .orderNumber { return "Order Number" }
        else if value == .url { return "URL" }
        else if value == .date { return "Date" }
        
        return nil
    }
    
}


enum LogType: String {
    case transaction = "transaction"
    case paymentMethod = "payment_method"
    case category = "category"
    case keyword = "keyword"
    case repeatingTransaction = "repeating_transaction"
}


@Observable
class CBLog: Codable, Identifiable, Transferable {
    var id: String
    var uuid: String?
    var itemID: String
    var logType: LogType
    var field: LogField
    var old: String?
    var new: String?
    var active: Bool
    var enteredBy: CBUser = AppState.shared.user!
    var updatedBy: CBUser = AppState.shared.user!
    var enteredDate: Date
    var updatedDate: Date
    
    init(itemID: String, logType: LogType, field: LogField, old: String?, new: String?) {
        let uuid = UUID().uuidString
        self.id = uuid
        self.uuid = uuid
        self.itemID = itemID
        self.logType = logType
        self.field = field
        self.old = old
        self.new = new
        self.active = true
        self.enteredBy = AppState.shared.user!
        self.updatedBy = AppState.shared.user!
        self.enteredDate = Date()
        self.updatedDate = Date()
    }
    
    init(transEntity: TempTransactionLog) {
        //self.isFromCoreData = true
        let uuid = UUID().uuidString
        self.id = uuid
        self.uuid = uuid
        self.itemID = transEntity.transactionID!
        self.logType = .transaction
        self.field = LogField(rawValue: transEntity.field ?? "")!
        self.old = transEntity.oldValue
        self.new = transEntity.newValue
        self.active = true
        self.enteredBy = AppState.shared.user!
        self.updatedBy = AppState.shared.user!
        self.enteredDate = Date()
        self.updatedDate = Date()
    }
    
    
    enum CodingKeys: CodingKey { case id, uuid, item_id, log_type, field, old, new, active, user_id, account_id, device_uuid, entered_by, updated_by, entered_date, updated_date }
    
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(uuid, forKey: .uuid)
        try container.encode(itemID, forKey: .item_id)
        try container.encode(logType.rawValue, forKey: .log_type)
        try container.encode(field.rawValue, forKey: .field)
        try container.encode(old, forKey: .old)
        try container.encode(new, forKey: .new)
        try container.encode(active ? 1 : 0, forKey: .active) // for the Transferable protocol
        try container.encode(AppState.shared.user?.id, forKey: .user_id)
        try container.encode(AppState.shared.user?.accountID, forKey: .account_id)
        try container.encode(AppState.shared.deviceUUID, forKey: .device_uuid)
        try container.encode(enteredBy, forKey: .entered_by) // for the Transferable protocol
        try container.encode(updatedBy, forKey: .updated_by) // for the Transferable protocol
        try container.encode(enteredDate.string(to: .serverDateTime), forKey: .entered_date) // for the Transferable protocol
        try container.encode(updatedDate.string(to: .serverDateTime), forKey: .updated_date) // for the Transferable protocol
    }
    
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        do {
            id = try String(container.decode(Int.self, forKey: .id))
        } catch {
            id = try container.decode(String.self, forKey: .id)
        }
        itemID = try container.decode(String.self, forKey: .item_id)
        
        let logType = try container.decode(String.self, forKey: .log_type)
        self.logType = LogType(rawValue: logType)!
        
        let field = try container.decode(String.self, forKey: .field)
        self.field = LogField(rawValue: field)!
        
        old = try container.decode(String?.self, forKey: .old)
        new = try container.decode(String?.self, forKey: .new)
        let active = try container.decode(Int.self, forKey: .active)
        self.active = active == 1
                        
        enteredBy = try container.decode(CBUser.self, forKey: .entered_by)
        updatedBy = try container.decode(CBUser.self, forKey: .updated_by)
        
        let enteredDate = try container.decode(String?.self, forKey: .entered_date)
        if let enteredDate {
            self.enteredDate = enteredDate.toDateObj(from: .serverDateTime)!
        } else {
            fatalError("Could not determine enteredDate date")
        }
        
        let updatedDate = try container.decode(String?.self, forKey: .updated_date)
        if let updatedDate {
            self.updatedDate = updatedDate.toDateObj(from: .serverDateTime)!
        } else {
            fatalError("Could not determine updatedDate date")
        }
    }
    
    
    @MainActor func createCoreDataEntity() -> TempTransactionLog? {
        guard let entity = DataManager.shared.createBlank(type: TempTransactionLog.self) else { return nil }
        entity.field = field.rawValue
        entity.oldValue = old
        entity.newValue = new
        entity.transactionID = itemID
        return entity
        
    }
 
    
    static func == (lhs: CBLog, rhs: CBLog) -> Bool {
        if lhs.id == rhs.id
        && lhs.uuid == rhs.uuid
        && lhs.itemID == rhs.itemID
        && lhs.logType == rhs.logType
        && lhs.field == rhs.field
        && lhs.old == rhs.old
        && lhs.new == rhs.new
        && lhs.enteredDate == rhs.enteredDate
        && lhs.updatedDate == rhs.updatedDate
        && lhs.enteredBy.id == rhs.enteredBy.id
        && lhs.updatedBy.id == rhs.updatedBy.id
        {
            return true
        }
        return false
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .transaction)
    }
}

