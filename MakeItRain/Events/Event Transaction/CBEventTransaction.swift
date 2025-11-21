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
class CBEventTransaction: Codable, Identifiable, Hashable, Equatable, Transferable, CanEditTitleWithLocation, CanEditAmount {
    var id: String
    var uuid: String?
    var eventID: String
    var relatedTransactionID: String?
    
    /// To rollback from a selected option.
    var originalTitle: String = ""

    
    var title: String
    var amount: Double {
        Double(amountString.replacing("$", with: "").replacing(",", with: "")) ?? 0.0
    }
    var amountString: String
    
    var amountTypeLingo: String {
        amountString.contains("-") ? "Expense" : "Income"
    }
    
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
    var category: CBEventCategory?
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
    var changedDate: Date
    
    var locations: Array<CBLocation>
    var files: Array<CBFile>?
    var options: Array<CBEventTransactionOption>?
    
    var trackingNumber: String
    var orderNumber: String
    var url: String
    var status: XrefItem
    var isBeingClaimed = false
    var isBeingUnClaimed = false
    
    var isIdea: Bool
    var isPrivate: Bool
    var optionID: String?
    
    var isNotIdea: Bool { !isIdea }
    var isNotPrivate: Bool { !isPrivate }
    
    var isPrivateAndBelongsToUser: Bool {
        isPrivate && self.enteredBy.isLoggedIn
    }
    
    
    var actionForRealTransaction: TransactionAction?
    
    //var realTransaction = CBTransaction(uuid: UUID().uuidString)
    
    init(eventID: String) {
        let uuid = UUID().uuidString
        self.id = uuid
        self.uuid = uuid
        self.eventID = eventID
        self.title = ""
        self.amountString = ""
        self.date = nil
        self.action = .add
        self.factorInCalculations = true
        self.payMethod = nil
       // self.color = .primary
        self.locations = []
        self.active = true
        self.enteredDate = Date()
        self.updatedDate = Date()
        self.changedDate = Date()
        self.trackingNumber = ""
        self.orderNumber = ""
        self.url = ""
        self.status = XrefModel.getItem(from: .eventTransactionStatuses, byID: 1)
        self.isIdea = true
        self.isPrivate = false
    }
    
    init(uuid: String, eventID: String) {
        self.id = uuid
        self.uuid = uuid
        self.eventID = eventID
        self.title = ""
        self.amountString = ""
        self.date = nil
        self.action = .add
        self.factorInCalculations = true
        self.payMethod = nil
        //self.color = .primary
        self.locations = []
        self.active = true
        self.enteredDate = Date()
        self.updatedDate = Date()
        self.changedDate = Date()
        self.trackingNumber = ""
        self.orderNumber = ""
        self.url = ""
        self.status = XrefModel.getItem(from: .eventTransactionStatuses, byID: 1)
        self.isIdea = true
        self.isPrivate = false
    }
    
    
    
    
    enum CodingKeys: CodingKey { case id, uuid, title, amount, date, payment_method, category, notes, title_hex_code, factor_in_calculations, active, user_id, account_id, entered_by, updated_by, paid_by, entered_date, updated_date, files, tags, device_uuid, notification_offset, notify_on_due_date, related_transaction_id, tracking_number, order_number, url, was_added_from_populate, logs, action, status_id, item, changed_date, event_id, options, locations, is_idea, option_id, is_private }
    
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(uuid, forKey: .uuid)
        try container.encode(eventID, forKey: .event_id)
        try container.encode(relatedTransactionID, forKey: .related_transaction_id)
        try container.encode(title, forKey: .title)
        try container.encode(amount, forKey: .amount)
        try container.encode(payMethod, forKey: .payment_method)
        try container.encode(category, forKey: .category)
        try container.encode(item, forKey: .item)
        try container.encode(options, forKey: .options)
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
        try container.encode(changedDate.string(to: .serverDateTime), forKey: .changed_date)
        try container.encode(files, forKey: .files)
        try container.encode(locations, forKey: .locations)
        try container.encode(action.serverKey, forKey: .action)
                
        try container.encode(trackingNumber, forKey: .tracking_number)
        try container.encode(orderNumber, forKey: .order_number)
        try container.encode(url, forKey: .url)
        try container.encode(status.id, forKey: .status_id)
        try container.encode(isIdea ? 1 : 0, forKey: .is_idea)
        try container.encode(optionID, forKey: .option_id)
        try container.encode(isPrivate ? 1 : 0, forKey: .is_private)
    }
    
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        do {
            id = try String(container.decode(Int.self, forKey: .id))
        } catch {
            id = try container.decode(String.self, forKey: .id)
        }
        
        do {
            eventID = try String(container.decode(Int.self, forKey: .event_id))
        } catch {
            eventID = try container.decode(String.self, forKey: .event_id)
        }
        
        title = try container.decode(String.self, forKey: .title)
        
        let amount = try container.decode(Double.self, forKey: .amount)
        let useWholeNumbers = LocalStorage.shared.useWholeNumbers
        self.amountString = amount.currencyWithDecimals(useWholeNumbers ? 0 : 2)
        
        self.payMethod = try container.decode(CBPaymentMethod?.self, forKey: .payment_method)
        self.category = try container.decode(CBEventCategory?.self, forKey: .category)
        self.item = try container.decode(CBEventItem?.self, forKey: .item)
        self.options = try container.decode(Array<CBEventTransactionOption>?.self, forKey: .options)
        self.notes = try container.decode(String?.self, forKey: .notes) ?? ""
        
        self.files = try container.decode(Array<CBFile>?.self, forKey: .files)
        self.locations = try container.decode(Array<CBLocation>.self, forKey: .locations)
        
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
        
        //files = try container.decode(Array<CBPicture>?.self, forKey: .files)
        

        
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
        
        let changedDate = try container.decode(String?.self, forKey: .changed_date)
        if let changedDate {
            self.changedDate = changedDate.toDateObj(from: .serverDateTime)!
        } else {
            fatalError("Could not determine changedDate date")
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
        
        if let isIdea = try container.decode(Int?.self, forKey: .is_idea) {
            self.isIdea = isIdea == 1
        } else {
            self.isIdea = true
        }
        
        if let isPrivate = try container.decode(Int?.self, forKey: .is_private) {
            self.isPrivate = isPrivate == 1
        } else {
            self.isPrivate = true
        }
        
        
        do {
            if let id = try container.decode(Int?.self, forKey: .option_id) {
                optionID = String(id)
            }
        } catch {
            optionID = try container.decode(String?.self, forKey: .option_id)
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
            && self.options == deepCopy.options
            && self.notes == deepCopy.notes
            && self.factorInCalculations == deepCopy.factorInCalculations
            && self.files == deepCopy.files
            && self.locations == deepCopy.locations
            //&& self.color == deepCopy.color
            && self.trackingNumber == deepCopy.trackingNumber
            && self.orderNumber == deepCopy.orderNumber
            && self.url == deepCopy.url
            && self.date == deepCopy.date
            && self.paidBy?.id == deepCopy.paidBy?.id
            && self.status == deepCopy.status
            && self.active == deepCopy.active
            && self.isIdea == deepCopy.isIdea
            && self.isPrivate == deepCopy.isPrivate
            && self.optionID == deepCopy.optionID
            {
                return false
            }
        }
        
        
        if self.title != deepCopy?.title {print("title caused change")}
        if self.amount != deepCopy?.amount {print("amount caused change")}
        if self.payMethod?.id != deepCopy?.payMethod?.id {print("payMethod caused change")}
        if self.category?.id != deepCopy?.category?.id {print("category caused change")}
        if self.item?.id != deepCopy?.item?.id {print("item caused change")}
        if self.notes != deepCopy?.notes {print("notes caused change")}
        if self.factorInCalculations != deepCopy?.factorInCalculations {print("factorInCalculations caused change")}
        if self.trackingNumber != deepCopy?.trackingNumber {print("trackingNumber caused change")}
        if self.orderNumber != deepCopy?.orderNumber {print("orderNumber caused change")}
        if self.url != deepCopy?.url {print("url caused change")}
        if self.date != deepCopy?.date {print("date caused change")}
        if self.paidBy?.id != deepCopy?.paidBy?.id {print("paidBy caused change")}
        if self.status != deepCopy?.status {print("status caused change")}
        if self.active != deepCopy?.active {print("active caused change")}
        
        
        return true
    }
    
    
    
    var deepCopy: CBEventTransaction?
    func deepCopy(_ mode: ShadowCopyAction) {
        switch mode {
        case .create:
            let copy = CBEventTransaction(uuid: UUID().uuidString, eventID: self.eventID)
            copy.id = self.id
            copy.uuid = self.uuid
            copy.eventID = self.eventID
            copy.title = self.title
            copy.amountString = self.amountString
            copy.payMethod = self.payMethod
            copy.category = self.category
            copy.item = self.item
            copy.options = self.options
            copy.locations = self.locations.compactMap ({ $0.deepCopy(.create); return $0.deepCopy })
            //copy.locations = self.locations
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
            copy.files = self.files
            copy.isIdea = self.isIdea
            copy.isPrivate = self.isPrivate
            copy.optionID = self.optionID
            self.deepCopy = copy
            
        case .restore:
            if let deepCopy = self.deepCopy {
                self.id = deepCopy.id
                self.uuid = deepCopy.uuid
                self.eventID = deepCopy.eventID
                self.title = deepCopy.title
                self.amountString = deepCopy.amountString
                self.payMethod = deepCopy.payMethod
                self.category = deepCopy.category
                self.item = deepCopy.item
                self.options = deepCopy.options
                self.locations = deepCopy.locations
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
                self.files = deepCopy.files
                self.isIdea = deepCopy.isIdea
                self.isPrivate = deepCopy.isPrivate
                self.optionID = deepCopy.optionID
            }
        case .clear:
            break
        }
    }
    
    func setFromAnotherInstance(transaction: CBEventTransaction) {
        self.id = transaction.id
        self.uuid = transaction.uuid
        self.eventID = transaction.eventID
        self.title = transaction.title
        
        let useWholeNumbers = LocalStorage.shared.useWholeNumbers
        self.amountString = transaction.amount.currencyWithDecimals(useWholeNumbers ? 0 : 2)
        
        self.payMethod = transaction.payMethod
        self.category = transaction.category
        self.item = transaction.item
        self.options = transaction.options
        self.locations = transaction.locations
        
        
//        if let payMethod = transaction.payMethod {
//            self.payMethod?.setFromAnotherInstance(payMethod: payMethod)
//        } else {
//            self.payMethod = nil
//        }
//        
//        if let category = transaction.category {
//            self.category?.setFromAnotherInstance(category: category)
//        } else {
//            self.category = nil
//        }
//        
//        if let item = transaction.item {
//            self.item?.setFromAnotherInstance(item: item)
//        } else {
//            self.item = nil
//        }
        
        
        //print("SETTING PAID BY ID TO \(transaction.paidBy?.id)")
        
        self.date = transaction.date
        self.notes = transaction.notes
        //self.color = transaction.color
        self.enteredDate = transaction.enteredDate
        self.updatedDate = transaction.updatedDate
        self.enteredBy = transaction.enteredBy
        self.updatedBy = transaction.updatedBy
        self.paidBy = transaction.paidBy
        self.files = transaction.files
        self.factorInCalculations = transaction.factorInCalculations
        self.trackingNumber = transaction.trackingNumber
        self.orderNumber = transaction.orderNumber
        self.url = transaction.url
        self.status = transaction.status
        self.action = transaction.action
        self.active = transaction.active
        self.isIdea = transaction.isIdea
        self.isPrivate = transaction.isPrivate
        self.optionID = transaction.optionID
    }
    
    
    func setFromOptionInstance(option: CBEventTransactionOption) {
        self.originalTitle = self.title
        self.title = option.title
        let useWholeNumbers = LocalStorage.shared.useWholeNumbers
        self.amountString = option.amount.currencyWithDecimals(useWholeNumbers ? 0 : 2)
        self.locations = option.locations
        self.updatedDate = option.updatedDate
        self.updatedBy = option.updatedBy
        self.files = option.files
        self.url = option.url
        self.optionID = option.id
    }
    
    
    
    
    

    func setFromTransactionInstance(transaction: CBTransaction) {
        //self.id = transaction.id
        self.title = transaction.title
        let useWholeNumbers = LocalStorage.shared.useWholeNumbers
        self.amountString = transaction.amount.currencyWithDecimals(useWholeNumbers ? 0 : 2)
        self.date = transaction.date
        //self.enteredBy = transaction.paidBy!
        self.updatedBy = transaction.updatedBy
        self.relatedTransactionID = transaction.id
        //self.relatedTransactionType = XrefModel.getItem(from: .relatedTransactionType, byEnumID: .eventTransaction)
        self.payMethod = transaction.payMethod
        //self.category = transaction.category
        self.enteredDate = Date()
        self.updatedDate = Date()
    }
    
    
    static func == (lhs: CBEventTransaction, rhs: CBEventTransaction) -> Bool {
        if lhs.id == rhs.id
        && lhs.uuid == rhs.uuid
        && lhs.eventID == rhs.eventID
        && lhs.title == rhs.title
        && lhs.amount == rhs.amount
        && lhs.payMethod?.id == rhs.payMethod?.id
        && lhs.category?.id == rhs.category?.id
        && lhs.item?.id == rhs.item?.id
        && lhs.options == rhs.options
        && lhs.locations == rhs.locations
        && lhs.notes == rhs.notes
        && lhs.factorInCalculations == rhs.factorInCalculations
        //&& lhs.color == rhs.color
        && lhs.files == rhs.files
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
        && lhs.isIdea == rhs.isIdea
        && lhs.isPrivate == rhs.isPrivate
        && lhs.optionID == rhs.optionID
        {
            return true
        }
        return false
    }
    
    
    // MARK: - Options
    func upsert(_ item: CBEventTransactionOption) {
        if !doesExist(item) {
            if options == nil {
                options = []
            }
            
            options?.append(item)
        }
    }
    
    func getIndex(for option: CBEventTransactionOption) -> Int? {
        return options?.firstIndex(where: { $0.id == option.id })
    }
    
    func doesExist(_ option: CBEventTransactionOption) -> Bool {
        if let options = self.options {
            return !options.filter { $0.id == option.id }.isEmpty
        } else {
            return false
        }
    }
    
    func getOption(by id: String) -> CBEventTransactionOption {
        return options?.filter { $0.id == id }.first ?? CBEventTransactionOption(uuid: id, transactionID: self.id)
    }
    
    func saveOption(id: String) -> Bool {
        let option = getOption(by: id)
        
        print("Attempting to save Option with \(option.id)")
        
        if option.hasChanges() || option.action == .delete {
            print("Option has changes")
            if option.title.isEmpty {
                print("title is blank")
                if option.action != .add && option.title.isEmpty {
                    option.title = option.deepCopy?.title ?? ""
                    AppState.shared.showAlert("Removing a title is not allowed. If you want to delete \(option.title), please use the delete button instead.")
                } else {
                    options?.removeAll { $0.id == id }
                }
                
                return false
            } else {
               return true
           }
        } else if option.title.isEmpty {
            print("title is blank")
            options?.removeAll { $0.id == id }
            print("-- \(#function) -- Titlemissing 2")
            return false
        }
        
        return false
    }
    
    func deleteOption(id: String) {
        let index = options?.firstIndex(where: {$0.id == id})
        if let index {
            options?[index].active = false
            options?[index].action = .delete
        } else {
            print("CANT FIND ITEM")
        }
    }
    
    // MARK: - Locations
    func doesExist(_ location: CBLocation) -> Bool {
        return !locations.filter { $0.id == location.id }.isEmpty
    }
    
    func upsert(_ location: CBLocation) {
        if !doesExist(location) {
            if options == nil {
                options = []
            }
            
            /// Enforce only allowing 1 item
            for each in locations {
                if each.action == .add {
                    locations.removeAll(where: {$0.id == each.id})
                } else {
                    each.action = .delete
                    each.active = false
                }
            }
                        
            locations.append(location)
        }
    }
    
    func deleteLocation(id: String) {
        let index = locations.firstIndex(where: {$0.id == id})
        if let index {
            locations[index].active = false
            locations[index].action = .delete
        } else {
            print("CANT FIND LOCATION")
        }
    }
    
    func setTitle(_ text: String) {
        self.title = text
    }
    
    
    
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .transaction)
    }
}
