//
//  CBTransaction.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/19/24.
//

import Foundation
import UniformTypeIdentifiers
import SwiftUI

@Observable
class CBTransaction: Codable, Identifiable, Hashable, Equatable, Transferable {
    //var undoManager: TransUndoManager?
    
    var id: String
    var uuid: String?
    var fitID: String?
    var repID: String?
    var relatedTransactionID: String?
    var title: String
    var amount: Double {
        Double(amountString.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")) ?? 0.0
    }
    var amountString: String
    var date: Date?
    
    var prettyDate: String? {
        if let date = self.date {
            return date.string(to: .monthDayShortYear)
        }
        return nil
    }
    
    var dateComponents: DateComponents? {
        //return Calendar.current.dateComponents(in: .current, from: date)
        
        if let date = self.date {
            return Calendar.current.dateComponents(in: .current, from: date)
        } else {
            return nil
        }
    }
    var payMethod: CBPaymentMethod?
    var category: CBCategory?
    var notes: String = ""
    var active: Bool
    var color: Color
    var action: TransactionAction
    var actionBeforeSave: TransactionAction = .add
    var tempAction: TransactionAction = .add
    var factorInCalculations: Bool
    
    var enteredBy: CBUser = AppState.shared.user ?? CBUser()
    var updatedBy: CBUser = AppState.shared.user ?? CBUser()
    
    var enteredDate: Date
    var updatedDate: Date
    
    var pictures: Array<CBPicture>?
    var tags: Array<CBTag>
    
    var notificationOffset: Int? = 0
    var notifyOnDueDate: Bool = false
    
    var isFromCoreData = false
    var wasAddedFromPopulate = false
    
    var trackingNumber: String
    var orderNumber: String
    var url: String
    var relatedTransactionType: XrefItem?
    
    
    var isBudgetable: Bool { self.payMethod?.accountType == .cash || self.payMethod?.accountType == .checking }
    var isIncome: Bool { self.amount > 0 }
    var isExpense: Bool { self.amount < 0 }
    var logs: Array<CBLog> = []
    
    deinit {
        //print("KILLING CBTransaction - \(self.id) - \(self.title)")
    }
    
    
    init() {
        let uuid = UUID().uuidString
        self.id = uuid
        self.uuid = uuid
        self.title = ""
        self.amountString = ""
        self.date = nil
        self.action = .add
        self.factorInCalculations = true
        self.payMethod = nil
        //self.payMethod = CBPaymentMethod() // Changed 2/12/25
        self.color = .primary
        self.active = true
        self.enteredDate = Date()
        self.updatedDate = Date()
        self.notificationOffset = 0
        self.notifyOnDueDate = false
        self.trackingNumber = ""
        self.orderNumber = ""
        self.url = ""
        self.tags = []
        self.wasAddedFromPopulate = false
        
       // self.undoManager = TransUndoManager(trans: self)
    }
    
    init(uuid: String) {
        self.id = uuid
        self.uuid = uuid
        self.title = ""
        self.amountString = ""
        self.date = nil
        self.action = .add
        self.factorInCalculations = true
        self.payMethod = nil
        //self.payMethod = CBPaymentMethod() // Changed 2/12/25
        self.color = .primary
        self.active = true
        self.enteredDate = Date()
        self.updatedDate = Date()
        self.notificationOffset = 0
        self.notifyOnDueDate = false
        self.trackingNumber = ""
        self.orderNumber = ""
        self.url = ""
        self.tags = []
        self.wasAddedFromPopulate = false
        
        //self.undoManager = TransUndoManager(trans: self)
    }
    
    init(entity: TempTransaction, payMethod: CBPaymentMethod, category: CBCategory?, logs: Array<CBLog>) {
        self.isFromCoreData = true
        self.id = entity.id ?? ""
        self.title = entity.title ?? ""
        
        let useWholeNumbers = UserDefaults.standard.bool(forKey: "useWholeNumbers")
        self.amountString = entity.amount.currencyWithDecimals(useWholeNumbers ? 0 : 2)
        
        //self.category = CBCategory(from: entity)guard let entity = DataManager.shared.getOne(type: PersistentPaymentMethod.self, predicate: .byId(.string(entity.payMethodID ?? "0")), createIfNotFound: true) else { return }
        //self.payMethod = CBPaymentMethod(from: entity)
        self.payMethod = payMethod
        
        //guard let entity = DataManager.shared.getOne(type: PersistentCategory.self, predicate: .byId(.string(entity.categoryID)), createIfNotFound: true) else { return }
        //self.category = CBCategory(from: entity)
        self.category = category
        
        self.trackingNumber = entity.trackingNumber ?? ""
        self.orderNumber = entity.orderNumber ?? ""
        self.url = entity.url ?? ""
        
        self.date = entity.date
        self.notes = entity.notes ?? ""
        
        let color = Color.fromHex(entity.hexCode) ?? .primary
        if color == .white || color == .black {
            self.color = .primary
        } else {
            self.color = color
        }

        self.tags = []
        self.enteredDate = entity.enteredDate ?? Date()
        self.updatedDate = entity.updatedDate ?? Date()
        self.factorInCalculations = entity.factorInCalculations
        self.notificationOffset = Int(entity.notificationOffset)
        self.notifyOnDueDate = entity.notifyOnDueDate
        self.active = entity.active
        self.action = TransactionAction.fromString(entity.action!)
        self.tempAction = TransactionAction.fromString(entity.tempAction ?? "add")
        self.wasAddedFromPopulate = false
        
        self.logs = logs
        
        //self.undoManager = TransUndoManager(trans: self)
    }
    
    
    init(repTrans: CBRepeatingTransaction, date: Date) {
        let uuid = UUID().uuidString
        self.id = uuid
        self.uuid = uuid
        self.repID = repTrans.id
        self.title = repTrans.title
        self.amountString = repTrans.amountString
        self.action = .edit
        self.factorInCalculations = true
        self.payMethod = repTrans.payMethod
        self.category = repTrans.category
        self.date = date
        self.color = repTrans.color
        self.active = true
        self.enteredDate = Date()
        self.updatedDate = Date()
        self.trackingNumber = ""
        self.orderNumber = ""
        self.url = ""
        self.tags = []
        self.wasAddedFromPopulate = true
        
        //self.undoManager = TransUndoManager(trans: self)
    }
    
    
    init(eventTrans: CBEventTransaction, relatedID: String) {
        self.id = relatedID
        self.uuid = relatedID
        self.relatedTransactionID = eventTrans.id
        self.relatedTransactionType = XrefModel.getItem(from: .relatedTransactionType, byID: 4)
        self.title = eventTrans.title
        self.amountString = eventTrans.amountString
        //self.action = .add
        self.factorInCalculations = true
        self.payMethod = eventTrans.payMethod
        self.category = eventTrans.category
        self.date = eventTrans.date
        self.color = .primary
        self.active = true
        self.enteredDate = Date()
        self.updatedDate = Date()
        self.trackingNumber = ""
        self.orderNumber = ""
        self.url = ""
        self.tags = []
        self.wasAddedFromPopulate = false
                
        self.action = eventTrans.actionForRealTransaction!
    }
    
    init(fitTrans: CBFitTransaction) {
        let uuid = UUID().uuidString
        self.id = uuid
        self.uuid = uuid
        self.fitID = String(fitTrans.fitID)
        self.title = fitTrans.title
        self.amountString = fitTrans.amountString
        //self.action = .add
        self.factorInCalculations = true
        self.payMethod = fitTrans.payMethod
        //self.category = eventTrans.category
        self.date = fitTrans.date
        self.color = .primary
        self.active = true
        self.enteredDate = Date()
        self.updatedDate = Date()
        self.trackingNumber = ""
        self.orderNumber = ""
        self.url = ""
        self.notes = "(Added via F.I.T.)"
        self.tags = []
        self.wasAddedFromPopulate = false
                
        self.action = .add
    }
    
    
    enum CodingKeys: CodingKey { case id, uuid, title, amount, date, payment_method, category, notes, title_hex_code, factor_in_calculations, active, user_id, account_id, entered_by, updated_by, entered_date, updated_date, pictures, tags, device_uuid, notification_offset, notify_on_due_date, related_transaction_id, tracking_number, order_number, url, was_added_from_populate, logs, related_transaction_type_id, fit_id }
    
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(uuid, forKey: .uuid)
        try container.encode(relatedTransactionID, forKey: .related_transaction_id)
        try container.encode(title, forKey: .title)
        try container.encode(amount, forKey: .amount)
        try container.encode(payMethod, forKey: .payment_method)
        try container.encode(category, forKey: .category)
        try container.encode(notes, forKey: .notes)
        try container.encode(date?.string(to: .serverDate), forKey: .date)
        try container.encode(color.toHex(), forKey: .title_hex_code)
        //try container.encode(color.description, forKey: .title_hex_code)
        try container.encode(factorInCalculations ? 1 : 0, forKey: .factor_in_calculations)
        try container.encode(active ? 1 : 0, forKey: .active) // for the Transferable protocol
        try container.encode(AppState.shared.user?.id, forKey: .user_id)
        try container.encode(AppState.shared.user?.accountID, forKey: .account_id)
        try container.encode(AppState.shared.deviceUUID, forKey: .device_uuid)
        try container.encode(enteredBy, forKey: .entered_by) // for the Transferable protocol
        try container.encode(updatedBy, forKey: .updated_by) // for the Transferable protocol
        try container.encode(enteredDate.string(to: .serverDateTime), forKey: .entered_date) // for the Transferable protocol
        try container.encode(updatedDate.string(to: .serverDateTime), forKey: .updated_date) // for the Transferable protocol
        try container.encode(pictures, forKey: .pictures)
        try container.encode(tags, forKey: .tags)
        try container.encode(notificationOffset, forKey: .notification_offset)
        try container.encode(notifyOnDueDate ? 1 : 0, forKey: .notify_on_due_date)
        
        try container.encode(trackingNumber, forKey: .tracking_number)
        try container.encode(orderNumber, forKey: .order_number)
        try container.encode(url, forKey: .url)
        try container.encode(wasAddedFromPopulate ? 1 : 0, forKey: .was_added_from_populate)
        try container.encode(logs, forKey: .logs)
        try container.encode(relatedTransactionType?.id, forKey: .related_transaction_type_id)
        
        try container.encode(fitID, forKey: .fit_id)
    }
    
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        do {
            id = try String(container.decode(Int.self, forKey: .id))
        } catch {
            id = try container.decode(String.self, forKey: .id)
        }
        
        title = try container.decode(String.self, forKey: .title)
        
        let amount = try container.decode(Double.self, forKey: .amount)
        let useWholeNumbers = UserDefaults.standard.bool(forKey: "useWholeNumbers")
        self.amountString = amount.currencyWithDecimals(useWholeNumbers ? 0 : 2)
        
        self.payMethod = try container.decode(CBPaymentMethod?.self, forKey: .payment_method)
        self.category = try container.decode(CBCategory?.self, forKey: .category)
        self.notes = try container.decode(String?.self, forKey: .notes) ?? ""
        
        self.trackingNumber = try container.decode(String?.self, forKey: .tracking_number) ?? ""
        self.orderNumber = try container.decode(String?.self, forKey: .order_number) ?? ""
        self.url = try container.decode(String?.self, forKey: .url) ?? ""
        
        //let colorDescription = try container.decode(String?.self, forKey: .title_hex_code)
        //let color = Color.fromName(colorDescription ?? "white")
        let hexCode = try container.decode(String?.self, forKey: .title_hex_code)
        let color = Color.fromHex(hexCode) ?? .primary
        
        if color == .white || color == .black {
            self.color = .primary
        } else {
            self.color = color
        }
                
        
        let isActive = try container.decode(Int?.self, forKey: .active)
        self.active = isActive == 1
        
        let factorIn = try container.decode(Int?.self, forKey: .factor_in_calculations)
        if factorIn == nil {
            self.factorInCalculations = true
        } else {
            self.factorInCalculations = factorIn == 1
        }
        
        
        self.notificationOffset = try container.decode(Int?.self, forKey: .notification_offset)
        
        let notifyOnDueDate = try container.decode(Int?.self, forKey: .notify_on_due_date)
        self.notifyOnDueDate = notifyOnDueDate == 1
        
        
        enteredBy = try container.decode(CBUser.self, forKey: .entered_by)
        updatedBy = try container.decode(CBUser.self, forKey: .updated_by)
        
        pictures = try container.decode(Array<CBPicture>?.self, forKey: .pictures)
        tags = try container.decode(Array<CBTag>?.self, forKey: .tags) ?? []
        
        let relatedTransactionTypeID = try container.decode(Int?.self, forKey: .related_transaction_type_id)
        if let relatedTransactionTypeID = relatedTransactionTypeID {
            self.relatedTransactionType = XrefModel.getItem(from: .relatedTransactionType, byID: relatedTransactionTypeID)
        }
        

        
        action = .edit
        //factorInCalculations = true
        
        let date = try container.decode(String?.self, forKey: .date)
        if let date {
            self.date = date.toDateObj(from: .serverDate)!
        } else {
            //fatalError("Could not determine transaction date")
        }
        
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
        
        do {
            let relatedTransactionID = try container.decode(Int?.self, forKey: .related_transaction_id)
            if let relatedTransactionID {
                self.relatedTransactionID = String(relatedTransactionID)
            } else {
                self.relatedTransactionID = nil
            }
        } catch {
            relatedTransactionID = try container.decode(String?.self, forKey: .related_transaction_id)
        }
        
        
        let wasAddedFromPopulate = try container.decode(Int?.self, forKey: .was_added_from_populate)
        if wasAddedFromPopulate == nil {
            self.wasAddedFromPopulate = false
        } else {
            self.wasAddedFromPopulate = wasAddedFromPopulate == 1
        }
        
        //self.undoManager = TransUndoManager(trans: self)
    }
    
    
//    static var empty: CBTransaction {
//        CBTransaction()
//    }
//    
    
    func dateChanged() -> Bool {
        if let deepCopy = deepCopy {
            if self.date == deepCopy.date {
                return false
            }
        }
        return true
    }
    
    func getDateChanges() -> (Date?, Date?)? {
        if let deepCopy = deepCopy {
            return (deepCopy.date, self.date)
        }
        return nil
    }
    
    
    func hasChanges() -> Bool {
        if let deepCopy = deepCopy {
            if self.title == deepCopy.title
            && self.amount == deepCopy.amount
            && self.payMethod?.id == deepCopy.payMethod?.id
            && self.category?.id == deepCopy.category?.id
            && self.notes == deepCopy.notes
            && self.factorInCalculations == deepCopy.factorInCalculations
            && self.color == deepCopy.color
            && self.tags == deepCopy.tags
            && self.notificationOffset == deepCopy.notificationOffset
            && self.notifyOnDueDate == deepCopy.notifyOnDueDate
            && self.trackingNumber == deepCopy.trackingNumber
            && self.orderNumber == deepCopy.orderNumber
            && self.url == deepCopy.url
            && self.wasAddedFromPopulate == deepCopy.wasAddedFromPopulate
            && self.pictures == deepCopy.pictures
            && self.date == deepCopy.date {
                return false
            }
            
            log(deepCopy: deepCopy)
        }
        
        return true
    }
    
    
    func log(deepCopy: CBTransaction) {
        print("Beginning Logging Process")
        if self.action == .edit || (self.action == .add && self.tempAction == .edit) {
            if self.title != deepCopy.title {
                self.log(field: .title, old: deepCopy.title, new: self.title)
            }
            if self.amount != deepCopy.amount {
                self.log(field: .amount, old: String(deepCopy.amount), new: String(self.amount))
            }
            if self.payMethod?.id != deepCopy.payMethod?.id {
                self.log(field: .payMethod, old: deepCopy.payMethod?.id, new: self.payMethod?.id)
            }
            if self.category?.id != deepCopy.category?.id {
                self.log(field: .category, old: deepCopy.category?.id, new: self.category?.id)
            }
            if self.notes != deepCopy.notes {
                self.log(field: .notes, old: deepCopy.notes, new: self.notes)
            }
            if self.factorInCalculations != deepCopy.factorInCalculations {
                self.log(field: .factorInCalculations, old: deepCopy.factorInCalculations ? "true" : "false", new: self.factorInCalculations ? "true" : "false")
            }
            if self.color != deepCopy.color {
                self.log(field: .color, old: deepCopy.color.description, new: self.color.description)
            }
            if self.tags != deepCopy.tags {
                self.log(field: .tags, old: deepCopy.tags.map { $0.tag }.joined(separator: ", "), new: self.tags.map { $0.tag }.joined(separator: ", "))
            }
            if self.notificationOffset != deepCopy.notificationOffset {
                self.log(field: .notificationOffset, old: String(deepCopy.notificationOffset ?? 0), new: String(self.notificationOffset ?? 0))
            }
            if self.notifyOnDueDate != deepCopy.notifyOnDueDate {
                self.log(field: .notifyOnDueDate, old: deepCopy.notifyOnDueDate ? "true" : "false", new: self.notifyOnDueDate ? "true" : "false")
            }
            if self.trackingNumber != deepCopy.trackingNumber {
                self.log(field: .trackingNumber, old: deepCopy.trackingNumber, new: self.trackingNumber)
            }
            if self.orderNumber != deepCopy.orderNumber {
                self.log(field: .orderNumber, old: deepCopy.orderNumber, new: self.orderNumber)
            }
            if self.url != deepCopy.url {
                self.log(field: .url, old: deepCopy.url, new: self.url)
            }
            if self.date != deepCopy.date  {
                self.log(field: .date, old: deepCopy.date?.string(to: .monthDayShortYear), new: self.date?.string(to: .monthDayShortYear))
            }
        }
    }
    
    
    func log(field: LogField, old: String?, new: String?) {
        let log = CBLog(itemID: self.id, logType: .transaction, field: field, old: old, new: new)
        self.logs.append(log)
    }
    
    
    
    var deepCopy: CBTransaction?
    func deepCopy(_ mode: ShadowCopyAction) {
        switch mode {
        case .create:
            let copy = CBTransaction(uuid: UUID().uuidString)
            copy.id = self.id
            copy.uuid = self.uuid
            copy.title = self.title
            copy.amountString = self.amountString
            copy.payMethod = self.payMethod
            copy.category = self.category
            copy.date = self.date
            copy.notes = self.notes
            copy.factorInCalculations = self.factorInCalculations
            copy.color = self.color
            copy.tags = self.tags
            copy.enteredDate = self.enteredDate
            copy.updatedDate = self.updatedDate
            copy.enteredBy = self.enteredBy
            copy.updatedBy = self.updatedBy
            copy.notificationOffset = self.notificationOffset
            copy.notifyOnDueDate = self.notifyOnDueDate
            copy.trackingNumber = self.trackingNumber
            copy.orderNumber = self.orderNumber
            copy.url = self.url
            copy.active = self.active
            copy.wasAddedFromPopulate = self.wasAddedFromPopulate
            copy.pictures = self.pictures
            //copy.action = self.action
            self.deepCopy = copy
            
        case .restore:
            if let deepCopy = self.deepCopy {
                self.id = deepCopy.id
                self.uuid = deepCopy.uuid
                self.title = deepCopy.title
                self.amountString = deepCopy.amountString
                self.payMethod = deepCopy.payMethod
                self.category = deepCopy.category
                self.date = deepCopy.date
                self.notes = deepCopy.notes
                self.factorInCalculations = deepCopy.factorInCalculations
                self.color = deepCopy.color
                self.tags = deepCopy.tags
                self.enteredDate = deepCopy.enteredDate
                self.updatedDate = deepCopy.updatedDate
                self.enteredBy = deepCopy.enteredBy
                self.updatedBy = deepCopy.updatedBy
                self.notificationOffset = deepCopy.notificationOffset
                self.notifyOnDueDate = deepCopy.notifyOnDueDate
                self.trackingNumber = deepCopy.trackingNumber
                self.orderNumber = deepCopy.orderNumber
                self.url = deepCopy.url
                self.active = deepCopy.active
                self.wasAddedFromPopulate = deepCopy.wasAddedFromPopulate
                self.pictures = deepCopy.pictures
                //self.action = deepCopy.action
            }
        }
    }
    
    func setFromAnotherInstance(transaction: CBTransaction) {
        self.id = transaction.id
        self.title = transaction.title
        
        let useWholeNumbers = UserDefaults.standard.bool(forKey: "useWholeNumbers")
        self.amountString = transaction.amount.currencyWithDecimals(useWholeNumbers ? 0 : 2)
        
        self.payMethod = transaction.payMethod
        self.category = transaction.category
        self.date = transaction.date
        self.notes = transaction.notes
        self.color = transaction.color
        self.tags = transaction.tags
        self.enteredDate = transaction.enteredDate
        self.updatedDate = transaction.updatedDate
        self.enteredBy = transaction.enteredBy
        self.updatedBy = transaction.updatedBy
        self.pictures = transaction.pictures
        self.factorInCalculations = transaction.factorInCalculations
        self.notificationOffset = transaction.notificationOffset
        self.notifyOnDueDate = transaction.notifyOnDueDate
        self.trackingNumber = transaction.trackingNumber
        self.orderNumber = transaction.orderNumber
        self.url = transaction.url
        self.wasAddedFromPopulate = transaction.wasAddedFromPopulate
    }
    
    
    func setFromEventInstance(eventTrans: CBEventTransaction) {
        //self.id = transaction.id
        self.title = eventTrans.title
        let useWholeNumbers = UserDefaults.standard.bool(forKey: "useWholeNumbers")
        self.amountString = eventTrans.amount.currencyWithDecimals(useWholeNumbers ? 0 : 2)
        self.date = eventTrans.date
        //self.enteredBy = eventTrans.paidBy!
        //self.updatedBy = eventTrans.paidBy!
        self.relatedTransactionID = eventTrans.id
        self.relatedTransactionType = XrefModel.getItem(from: .relatedTransactionType, byEnumID: .eventTransaction)
        self.payMethod = eventTrans.payMethod
        self.category = eventTrans.category
        self.enteredDate = Date()
        self.updatedDate = Date()
    }
    

    func getChanges(new: CBTransaction) -> (Array<String>, Int) {
        var changes: [String] = []
        var count = 0
        
        if self.title != new.title {
            changes.append("title")
            count += 1
        }
        
        if self.amount != new.amount {
            changes.append("amount")
            count += 1
        }
                
        if self.payMethod?.id != new.payMethod?.id {
            changes.append("pay method")
            count += 1
        }
        
        if self.category?.id != new.category?.id {
            changes.append("category")
            count += 1
        }
        
        if self.date != new.date {
            changes.append("date")
            count += 1
        }
        
        return (changes, count)
        
        
//        if lhs.id == rhs.id
//        && lhs.title == rhs.title
//        && lhs.amount == rhs.amount
//        && lhs.payMethod?.id == rhs.payMethod?.id
//        && lhs.category?.id == rhs.category?.id
//        && lhs.notes == rhs.notes
//        && lhs.factorInCalculations == rhs.factorInCalculations
//        && lhs.color == rhs.color
//        && lhs.tags == rhs.tags
//        && lhs.date == rhs.date
//        && lhs.enteredDate == rhs.enteredDate
//        && lhs.updatedDate == rhs.updatedDate
//        && lhs.enteredBy.id == rhs.enteredBy.id
//        && lhs.updatedBy.id == rhs.updatedBy.id
//        && lhs.notificationOffset == rhs.notificationOffset
//        && lhs.notifyOnDueDate == rhs.notifyOnDueDate
//        {
//            return true
//        }
//        return false
    }
    
    
    static func == (lhs: CBTransaction, rhs: CBTransaction) -> Bool {
        if lhs.id == rhs.id
        && lhs.uuid == rhs.uuid
        && lhs.title == rhs.title
        && lhs.amount == rhs.amount
        && lhs.payMethod?.id == rhs.payMethod?.id
        && lhs.category?.id == rhs.category?.id
        && lhs.notes == rhs.notes
        && lhs.factorInCalculations == rhs.factorInCalculations
        && lhs.color == rhs.color
        && lhs.tags == rhs.tags
        && lhs.date == rhs.date
        && lhs.enteredDate == rhs.enteredDate
        && lhs.updatedDate == rhs.updatedDate
        && lhs.enteredBy.id == rhs.enteredBy.id
        && lhs.updatedBy.id == rhs.updatedBy.id
        && lhs.notificationOffset == rhs.notificationOffset
        && lhs.notifyOnDueDate == rhs.notifyOnDueDate
        && lhs.trackingNumber == rhs.trackingNumber
        && lhs.orderNumber == rhs.orderNumber
        && lhs.wasAddedFromPopulate == rhs.wasAddedFromPopulate
        && lhs.url == rhs.url
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
    
            
//    class TransUndoManager {
//
//        var trans: CBTransaction
//        init(trans: CBTransaction) {
//            self.trans = trans
//        }
//        
//        //static let shared = UndodoManager()
//        
//        var undoField: String = ""
//        var redoField: String = ""
//        var showAlert = false
//        var returnMe: UndoableText?
//        //var trans: CBTransaction = CBTransaction()
//        
//        var undoPosition: Int = 0
//        var history: [UndoableText] = []
//        var maxIndex: Int { history.count - 1 }
//
//        private var changeTasks: Array<UndoTask> = []
//        
//        var canUndo: Bool = false
//        var canRedo: Bool = false
//        
//        func getChangeFields() {
//            /// Simulate undo to get field that will be undone if the user takes action.
//            var simUndoPosition = undoPosition - 1
//            print("undo simPos \(simUndoPosition)")
//            
//            if simUndoPosition == -1 {
//                canUndo = false
//                
//            } else if simUndoPosition == 0 {
//                if !shouldIgnore(for: .undo, index: simUndoPosition) {
//                    canUndo = true
//                    undoField = history[simUndoPosition].field.rawValue
//                } else {
//                    canUndo = false
//                }
//                
//            } else if simUndoPosition > 0 {
//                let usedPosition = getPosition(for: .undo, index: simUndoPosition)
//                simUndoPosition = usedPosition
//                print("undo simPos \(simUndoPosition)")
//                
//                if simUndoPosition == -1 {
//                    canUndo = false
//                } else {
//                    canUndo = true
//                    undoField = history[simUndoPosition].field.rawValue
//                }
//            }
//            
//            
//            /// Simulate redo to get field that will be redone if the user takes action.
//            var simRedoPosition = undoPosition + 1
//            print("redo simPos \(simRedoPosition)")
//            
//            if simRedoPosition > maxIndex {
//                canRedo = false
//                
//            } else if simRedoPosition == maxIndex {
//                if !shouldIgnore(for: .redo, index: simRedoPosition) {
//                    canRedo = true
//                    redoField = history[simRedoPosition].field.rawValue
//                } else {
//                    canRedo = false
//                }
//                
//            } else if simRedoPosition < maxIndex {
//                let usedPosition = getPosition(for: .redo, index: simRedoPosition)
//                simRedoPosition = usedPosition
//                print("redo simPos \(simRedoPosition)")
//                
//                if simRedoPosition > maxIndex {
//                    canRedo = false
//                } else {
//                    canRedo = true
//                    redoField = history[simRedoPosition].field.rawValue
//                }
//            }
//            
//            
//        }
//        
//        func processChange(value: String?, field: TransactionUndoField) {
//            if returnMe != nil {
//                returnMe = nil
//            } else {
//                let task = Task {
//                    do {
//                        try await Task.sleep(for: .seconds(1))
//                        await MainActor.run {
//                            self.commitChange(value: value, field: field)
//                        }
//                    }
//                }
//                            
//                if let index = changeTasks.firstIndex(where: { $0.field == field }) {
//                    changeTasks[index].task?.cancel()
//                    changeTasks[index].task = task
//                } else {
//                    changeTasks.append(UndoTask(field: field, task: task))
//                }
//            }
//        }
//        
//        
//        func commitChangeInTask(value: String?, field: TransactionUndoField) {
//            Task {
//                do {
//                    try await Task.sleep(for: .seconds(1))
//                    await MainActor.run {
//                        self.commitChange(value: value, field: field)
//                    }
//                }
//            }
//        }
//        
//        
//        func commitChange(value: String?, field: TransactionUndoField) {
//            /// Make sure you don't duplicate changes.
//            guard (value, field) != (history.last?.value, history.last?.field) else { return }
//
//            
//            let undoText = UndoableText(value: value, field: field)
//            history.append(undoText)
//            undoPosition += 1
//            
//            if maxIndex == -1 {
//                undoPosition = 0
//            } else if undoPosition < maxIndex  {
//                let range = undoPosition..<maxIndex
//                history.removeSubrange(range)
//            } else {
//                undoPosition = maxIndex
//            }
//            
//            print("-- \(#function) -- undoPosition: \(undoPosition)")
//            print(history.map { "\($0.value ?? "") - \($0.field.rawValue)" })
//        }
//
//        
//        func undo(trans: CBTransaction) -> UndoableText? {
//            print("-- \(#function) ❌old position \(undoPosition)")
//            undoPosition -= 1
//            
//            if undoPosition == -1 {
//                undoPosition = 0
//                
//            } else if undoPosition == 0 {
//                // do the check from getPosition(), but only check for matching, don't get new index
//                
//            } else if undoPosition > 0 {
//                let usedPosition = getPosition(for: .undo, index: undoPosition)
//                undoPosition = usedPosition
//            }
//            print("-- \(#function) ✅usedPosition \(undoPosition)")
//            return history[undoPosition]
//        }
//
//        
//        func redo(trans: CBTransaction) -> UndoableText?  {
//            print("-- \(#function) ❌old position \(undoPosition)")
//            undoPosition += 1
//            
//            if undoPosition > maxIndex {
//                undoPosition = maxIndex
//                
//            } else if undoPosition == maxIndex {
//                // do the check from getPosition(), but only check for matching, don't get new index
//                
//            } else if undoPosition < maxIndex {
//                let usedPosition = getPosition(for: .redo, index: undoPosition)
//                undoPosition = usedPosition
//            }
//            
//            print("-- \(#function) ✅usedPosition \(undoPosition)")
//            return history[undoPosition]
//        }
//        
//        
//        func clearHistory() {
//            history.removeAll()
//        }
//        
//        
//        func getPosition(for undoredo: UndoRedo, index: Int) -> Int {
//            print("-- \(#function) -- \(index)")
//            if index < 0 {
//                print("index is less than 0")
//                return 0
//            }
//            
//            let target = history[index]
//            
//            let next = undoredo == .undo ? index - 1 : index + 1
//            
//            switch target.field {
//            case .title:
//                if trans.title == target.value { return getPosition(for: undoredo, index: next) }
//            case .amount:
//                if trans.amountString == target.value { return getPosition(for: undoredo, index: next) }
//            case .payMethod:
//                if trans.payMethod?.id == target.value { return getPosition(for: undoredo, index: next) }
//            case .category:
//                if trans.category?.id == target.value { return getPosition(for: undoredo, index: next) }
//            case .date:
//                if trans.date?.string(to: .serverDate) == target.value { return getPosition(for: undoredo, index: next) }
//            case .trackingNumber:
//                if trans.trackingNumber == target.value { return getPosition(for: undoredo, index: next) }
//            case .orderNumber:
//                if trans.orderNumber == target.value { return getPosition(for: undoredo, index: next) }
//            case .url:
//                if trans.url == target.value { return getPosition(for: undoredo, index: next) }
//            case .notes:
//                if trans.notes == target.value { return getPosition(for: undoredo, index: next) }
//            }
//            return index
//        }
//        
//        
//        func shouldIgnore(for undoredo: UndoRedo, index: Int) -> Bool {
//            let target = history[index]
//                    
//            switch target.field {
//            case .title:
//                if trans.title == target.value { return true }
//            case .amount:
//                if trans.amountString == target.value { return true }
//            case .payMethod:
//                if trans.payMethod?.id == target.value { return true }
//            case .category:
//                if trans.category?.id == target.value { return true }
//            case .date:
//                if trans.date?.string(to: .serverDate) == target.value { return true }
//            case .trackingNumber:
//                if trans.trackingNumber == target.value { return true }
//            case .orderNumber:
//                if trans.orderNumber == target.value { return true }
//            case .url:
//                if trans.url == target.value { return true }
//            case .notes:
//                if trans.notes == target.value { return true }
//            }
//            return false
//        }
//    }
}
