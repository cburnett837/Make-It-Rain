//
//  CBEventTransaction.swift
//  MakeItRain
//
//  Created by Cody Burnett on 1/21/25.
//

import Foundation
import UniformTypeIdentifiers
import SwiftUI

@Observable
class CBEventTransaction: Codable, Identifiable, Hashable, Equatable, Transferable {
    var id: String
    var uuid: String?
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
        if let date = self.date {
            return Calendar.current.dateComponents(in: .current, from: date)
        }
        return nil
    }
    var payMethod: CBPaymentMethod?
    var category: CBCategory?
    var item: CBEventItem?
    var notes: String = ""
    var active: Bool
    //var color: Color
    var action: EventTransactionAction
    var actionBeforeSave: EventTransactionAction = .add
    var factorInCalculations: Bool
    
    var enteredBy: CBUser = AppState.shared.user!
    var updatedBy: CBUser = AppState.shared.user!
    
    var paidBy: CBUser?
    
    var enteredDate: Date
    var updatedDate: Date
    
    var pictures: Array<CBPicture>?
    
    var trackingNumber: String
    var orderNumber: String
    var url: String
    var status: XrefItem
    var isBeingClaimed = false
    var isBeingUnClaimed = false
    
    
    var actionForRealTransaction: TransactionAction?
    
    //var realTransaction = CBTransaction(uuid: UUID().uuidString)
    
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
       // self.color = .primary
        self.active = true
        self.enteredDate = Date()
        self.updatedDate = Date()
        self.trackingNumber = ""
        self.orderNumber = ""
        self.url = ""
        self.status = XrefModel.getItem(from: .eventTransactionStatuses, byID: 1)
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
        //self.color = .primary
        self.active = true
        self.enteredDate = Date()
        self.updatedDate = Date()
        self.trackingNumber = ""
        self.orderNumber = ""
        self.url = ""
        self.status = XrefModel.getItem(from: .eventTransactionStatuses, byID: 1)
    }
    
    
    
    
    enum CodingKeys: CodingKey { case id, uuid, title, amount, date, payment_method, category, notes, title_hex_code, factor_in_calculations, active, user_id, account_id, entered_by, updated_by, paid_by, entered_date, updated_date, pictures, tags, device_uuid, notification_offset, notify_on_due_date, related_transaction_id, tracking_number, order_number, url, was_added_from_populate, logs, action, status_id, item }
    
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(uuid, forKey: .uuid)
        try container.encode(relatedTransactionID, forKey: .related_transaction_id)
        try container.encode(title, forKey: .title)
        try container.encode(amount, forKey: .amount)
        try container.encode(payMethod, forKey: .payment_method)
        try container.encode(category, forKey: .category)
        try container.encode(item, forKey: .item)
        try container.encode(notes, forKey: .notes)
        try container.encode(date?.string(to: .serverDate), forKey: .date)
        //try container.encode(color.toHex(), forKey: .title_hex_code)
        //try container.encode(color.description, forKey: .title_hex_code)
        try container.encode(factorInCalculations ? 1 : 0, forKey: .factor_in_calculations)
        try container.encode(active ? 1 : 0, forKey: .active)
        try container.encode(AppState.shared.user?.id, forKey: .user_id)
        try container.encode(AppState.shared.user?.accountID, forKey: .account_id)
        try container.encode(AppState.shared.deviceUUID, forKey: .device_uuid)
        try container.encode(enteredBy, forKey: .entered_by)
        try container.encode(updatedBy, forKey: .updated_by)
        try container.encode(paidBy, forKey: .paid_by)
        try container.encode(enteredDate.string(to: .serverDateTime), forKey: .entered_date)
        try container.encode(updatedDate.string(to: .serverDateTime), forKey: .updated_date)
        try container.encode(pictures, forKey: .pictures)
        try container.encode(action.serverKey, forKey: .action)
        
        
        try container.encode(trackingNumber, forKey: .tracking_number)
        try container.encode(orderNumber, forKey: .order_number)
        try container.encode(url, forKey: .url)
        try container.encode(status.id, forKey: .status_id)
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
        self.item = try container.decode(CBEventItem?.self, forKey: .item)
        self.notes = try container.decode(String?.self, forKey: .notes) ?? ""
        
        self.trackingNumber = try container.decode(String?.self, forKey: .tracking_number) ?? ""
        self.orderNumber = try container.decode(String?.self, forKey: .order_number) ?? ""
        self.url = try container.decode(String?.self, forKey: .url) ?? ""
        let statusID = try container.decode(Int.self, forKey: .status_id)
        self.status = XrefModel.getItem(from: .eventTransactionStatuses, byID: statusID)
        
        //let colorDescription = try container.decode(String?.self, forKey: .title_hex_code)
        //let color = Color.fromName(colorDescription ?? "white")
//        let hexCode = try container.decode(String?.self, forKey: .title_hex_code)
//        let color = Color.fromHex(hexCode) ?? .primary
//
//        if color == .white || color == .black {
//            self.color = .primary
//        } else {
//            self.color = color
//        }
        
        let isActive = try container.decode(Int?.self, forKey: .active)
        self.active = isActive == 1
        
        let factorIn = try container.decode(Int?.self, forKey: .factor_in_calculations)
        if factorIn == nil {
            self.factorInCalculations = true
        } else {
            self.factorInCalculations = factorIn == 1
        }
                                        
        enteredBy = try container.decode(CBUser.self, forKey: .entered_by)
        updatedBy = try container.decode(CBUser.self, forKey: .updated_by)
        paidBy = try container.decode(CBUser?.self, forKey: .paid_by)
        
        //pictures = try container.decode(Array<CBPicture>?.self, forKey: .pictures)
        

        
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
                //self.realTransaction.id = String(relatedTransactionID)
            } else {
                self.relatedTransactionID = nil
            }
        } catch {
            relatedTransactionID = try container.decode(String?.self, forKey: .related_transaction_id)
//            if let relatedID = self.relatedTransactionID {
//                self.realTransaction.id = relatedID
//            }
        }
    }
        
    
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
            && self.item?.id == deepCopy.item?.id
            && self.notes == deepCopy.notes
            && self.factorInCalculations == deepCopy.factorInCalculations
            //&& self.color == deepCopy.color
            && self.trackingNumber == deepCopy.trackingNumber
            && self.orderNumber == deepCopy.orderNumber
            && self.url == deepCopy.url
            && self.date == deepCopy.date
            && self.paidBy == deepCopy.paidBy
            && self.status == deepCopy.status
            {
                return false
            }
        }
        
        return true
    }
    
    
    
    var deepCopy: CBEventTransaction?
    func deepCopy(_ mode: ShadowCopyAction) {
        switch mode {
        case .create:
            let copy = CBEventTransaction(uuid: UUID().uuidString)
            copy.id = self.id
            copy.uuid = self.uuid
            copy.title = self.title
            copy.amountString = self.amountString
            copy.payMethod = self.payMethod
            copy.category = self.category
            copy.item = self.item
            copy.date = self.date
            copy.notes = self.notes
            copy.factorInCalculations = self.factorInCalculations
            //copy.color = self.color
            copy.enteredDate = self.enteredDate
            copy.updatedDate = self.updatedDate
            copy.enteredBy = self.enteredBy
            copy.updatedBy = self.updatedBy
            copy.paidBy = self.paidBy
            copy.trackingNumber = self.trackingNumber
            copy.orderNumber = self.orderNumber
            copy.url = self.url
            copy.active = self.active
            copy.status = self.status
            self.deepCopy = copy
            
        case .restore:
            if let deepCopy = self.deepCopy {
                self.id = deepCopy.id
                self.uuid = deepCopy.uuid
                self.title = deepCopy.title
                self.amountString = deepCopy.amountString
                self.payMethod = deepCopy.payMethod
                self.category = deepCopy.category
                self.item = deepCopy.item
                self.date = deepCopy.date
                self.notes = deepCopy.notes
                self.factorInCalculations = deepCopy.factorInCalculations
                //self.color = deepCopy.color
                self.enteredDate = deepCopy.enteredDate
                self.updatedDate = deepCopy.updatedDate
                self.enteredBy = deepCopy.enteredBy
                self.updatedBy = deepCopy.updatedBy
                self.paidBy = deepCopy.paidBy
                self.trackingNumber = deepCopy.trackingNumber
                self.orderNumber = deepCopy.orderNumber
                self.url = deepCopy.url
                self.active = deepCopy.active
                self.status = deepCopy.status
            }
        }
    }
    
    func setFromAnotherInstance(transaction: CBEventTransaction) {
        self.id = transaction.id
        self.title = transaction.title
        
        let useWholeNumbers = UserDefaults.standard.bool(forKey: "useWholeNumbers")
        self.amountString = transaction.amount.currencyWithDecimals(useWholeNumbers ? 0 : 2)
        
        self.payMethod = transaction.payMethod
        self.category = transaction.category
        self.item = transaction.item
        self.date = transaction.date
        self.notes = transaction.notes
        //self.color = transaction.color
        self.enteredDate = transaction.enteredDate
        self.updatedDate = transaction.updatedDate
        self.enteredBy = transaction.enteredBy
        self.updatedBy = transaction.updatedBy
        self.paidBy = transaction.paidBy
        self.pictures = transaction.pictures
        self.factorInCalculations = transaction.factorInCalculations
        self.trackingNumber = transaction.trackingNumber
        self.orderNumber = transaction.orderNumber
        self.url = transaction.url
        self.status = transaction.status
        self.action = transaction.action
        self.active = transaction.active
    }
    

    func setFromTransactionInstance(transaction: CBTransaction) {
        //self.id = transaction.id
        self.title = transaction.title
        let useWholeNumbers = UserDefaults.standard.bool(forKey: "useWholeNumbers")
        self.amountString = transaction.amount.currencyWithDecimals(useWholeNumbers ? 0 : 2)
        self.date = transaction.date
        //self.enteredBy = transaction.paidBy!
        self.updatedBy = transaction.updatedBy
        self.relatedTransactionID = transaction.id
        //self.relatedTransactionType = XrefModel.getItem(from: .relatedTransactionType, byEnumID: .eventTransaction)
        self.payMethod = transaction.payMethod
        self.category = transaction.category
        self.enteredDate = Date()
        self.updatedDate = Date()
    }
    
    
    static func == (lhs: CBEventTransaction, rhs: CBEventTransaction) -> Bool {
        if lhs.id == rhs.id
        && lhs.uuid == rhs.uuid
        && lhs.title == rhs.title
        && lhs.amount == rhs.amount
        && lhs.payMethod?.id == rhs.payMethod?.id
        && lhs.category?.id == rhs.category?.id
        && lhs.item?.id == rhs.item?.id
        && lhs.notes == rhs.notes
        && lhs.factorInCalculations == rhs.factorInCalculations
        //&& lhs.color == rhs.color
        && lhs.date == rhs.date
        && lhs.enteredDate == rhs.enteredDate
        && lhs.updatedDate == rhs.updatedDate
        && lhs.enteredBy.id == rhs.enteredBy.id
        && lhs.updatedBy.id == rhs.updatedBy.id
        && lhs.paidBy?.id == rhs.paidBy?.id
        && lhs.trackingNumber == rhs.trackingNumber
        && lhs.orderNumber == rhs.orderNumber
        && lhs.url == rhs.url
        && lhs.status == rhs.status
        && lhs.active == rhs.active
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
