//
//  CBEvent.swift
//  MakeItRain
//
//  Created by Cody Burnett on 1/20/25.
//
import Foundation
import SwiftUI



@Observable
class CBEvent: Codable, Identifiable, Equatable, Hashable {
    var id: String
    var uuid: String?
    var title: String
    var amount: Double? {
        Double(amountString?.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "") ?? "0.0") ?? 0.0
    }
    var amountString: String?
    var eventType: String?
    
    var startDate: Date?
    var endDate: Date?
    
    var active: Bool
    var action: EventAction
    
    var enteredBy: CBUser = AppState.shared.user!
    var updatedBy: CBUser = AppState.shared.user!
    
    var enteredDate: Date
    var updatedDate: Date
    
    var activeParticipantUserIds: [Int]
    var participants: [CBEventParticipant]
    var files: Array<CBFile>?
    var items: Array<CBEventItem>
    var transactions: Array<CBEventTransaction>
    var categories: Array<CBEventCategory>
    
    var pendingRealTransactionsToSave: [CBTransaction] = []
    //var invitationsToSend: Array<CBEventInvite> = []
    //var participantsToRemove: Array<CBUser> = []    
    
    init() {
        let uuid = UUID().uuidString
        self.id = uuid
        self.uuid = uuid
        self.title = ""
        self.amountString = ""
        self.active = true
        self.action = .add
        self.participants = []
        self.items = []
        self.transactions = []
        self.categories = []
        self.activeParticipantUserIds = [AppState.shared.user!.id]
        
        self.enteredDate = Date()
        self.updatedDate = Date()
    }
    
    
    init(uuid: String) {
        self.id = uuid
        self.uuid = uuid
        self.title = ""
        self.amountString = ""
        self.active = true
        self.action = .add
        self.participants = []
        self.items = []
        self.transactions = []
        self.categories = []
        self.activeParticipantUserIds = [AppState.shared.user!.id]
        
        self.enteredDate = Date()
        self.updatedDate = Date()
    }
    
    enum CodingKeys: CodingKey { case id, uuid, title, amount, event_type, start_date, end_date, active, entered_by, updated_by, entered_date, updated_date, user_id, account_id, device_uuid, participants, items, transactions, categories, files, active_participant_user_ids }
    
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(uuid, forKey: .uuid)
        try container.encode(title, forKey: .title)
        try container.encode(amount, forKey: .amount)
        try container.encode(eventType, forKey: .event_type)
        
        try container.encode(startDate?.string(to: .serverDate), forKey: .start_date)
        try container.encode(endDate?.string(to: .serverDate), forKey: .end_date)
        
        try container.encode(participants, forKey: .participants)
        try container.encode(items, forKey: .items)
        try container.encode(transactions, forKey: .transactions)
        try container.encode(categories, forKey: .categories)
        try container.encode(files, forKey: .files)
        
        try container.encode(enteredBy, forKey: .entered_by)
        try container.encode(updatedBy, forKey: .updated_by)
        try container.encode(enteredDate.string(to: .serverDateTime), forKey: .entered_date)
        try container.encode(updatedDate.string(to: .serverDateTime), forKey: .updated_date)
        try container.encode(active ? 1 : 0, forKey: .active)
        try container.encode(AppState.shared.user?.id, forKey: .user_id)
        try container.encode(AppState.shared.user?.accountID, forKey: .account_id)
        try container.encode(AppState.shared.deviceUUID, forKey: .device_uuid)
        //try container.encode(invitationsToSend, forKey: .invitations_to_send)
        //try container.encode(participantsToRemove, forKey: .participants_to_remove)
        
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
        let useWholeNumbers = LocalStorage.shared.useWholeNumbers
        self.amountString = amount.currencyWithDecimals(useWholeNumbers ? 0 : 2)
        
        eventType = try container.decode(String?.self, forKey: .event_type)
        
        let startDate = try container.decode(String?.self, forKey: .start_date)
        if let startDate {
            //print(startDate)
            self.startDate = startDate.toDateObj(from: .serverDate)!
        } else {
            //fatalError("Could not determine transaction date")
        }
        
        let endDate = try container.decode(String?.self, forKey: .end_date)
        if let endDate {
            self.endDate = endDate.toDateObj(from: .serverDate)!
        } else {
            //fatalError("Could not determine transaction date")
        }
        
        self.participants = try container.decodeIfPresent(Array<CBEventParticipant>.self, forKey: .participants) ?? []
        self.items = try container.decodeIfPresent(Array<CBEventItem>.self, forKey: .items) ?? []
        self.transactions = try container.decodeIfPresent(Array<CBEventTransaction>.self, forKey: .transactions) ?? []
        self.categories = try container.decodeIfPresent(Array<CBEventCategory>.self, forKey: .categories) ?? []
        self.activeParticipantUserIds = try container.decodeIfPresent(Array<Int>.self, forKey: .active_participant_user_ids) ?? []
        self.files = try container.decode(Array<CBFile>?.self, forKey: .files)
        
        //invitationsToSend = try container.decode(Array<CBEventInvite>.self, forKey: .invitations_to_send)
        //participantsToRemove = try container.decode(Array<CBUser>.self, forKey: .participants_to_remove)
        
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
        
        
        let isActive = try container.decode(Int?.self, forKey: .active)
        self.active = isActive == 1 ? true : false
        
        action = .edit
    }
    
   
    func hasChanges() -> Bool {
        if let deepCopy = deepCopy {
            if self.title == deepCopy.title
            && self.amountString == deepCopy.amountString
            && self.eventType == deepCopy.eventType
            && self.startDate == deepCopy.startDate
            && self.files == deepCopy.files
            && self.endDate == deepCopy.endDate {
                return false
            }
        }
        return true
    }
    
    
    var deepCopy: CBEvent?
    func deepCopy(_ mode: ShadowCopyAction) {
        switch mode {
        case .create:
            let copy = CBEvent()
            copy.id = self.id
            copy.uuid = self.uuid
            copy.title = self.title
            copy.amountString = self.amountString
            copy.eventType = self.eventType
            copy.startDate = self.startDate
            copy.endDate = self.endDate
            copy.activeParticipantUserIds = self.activeParticipantUserIds
            copy.files = self.files
            
            copy.participants = self.participants.map {
                $0.deepCopy(.create)
                return $0.deepCopy!
            }
            
            copy.items = self.items.map {
                $0.deepCopy(.create)
                return $0.deepCopy!
            }
            
            copy.transactions = self.transactions.map {
                $0.deepCopy(.create)
                return $0.deepCopy!
            }
            
            copy.categories = self.categories.map {
                $0.deepCopy(.create)
                return $0.deepCopy!
            }
            
//            copy.invitationsToSend = self.invitationsToSend.map {
//                $0.deepCopy(.create)
//                return $0.deepCopy!
//            }
//            
//            copy.participantsToRemove = self.participantsToRemove.map {
//                $0.deepCopy(.create)
//                return $0.deepCopy!
//            }
            
            copy.active = self.active
            self.deepCopy = copy
            
        case .restore:
            if let deepCopy = self.deepCopy {
                self.id = deepCopy.id
                self.uuid = deepCopy.uuid
                self.title = deepCopy.title
                self.amountString = deepCopy.amountString
                self.eventType = deepCopy.eventType
                self.startDate = deepCopy.startDate
                self.endDate = deepCopy.endDate
                self.participants = deepCopy.participants
                self.items = deepCopy.items
                self.transactions = deepCopy.transactions
                self.categories = deepCopy.categories
                self.active = deepCopy.active
                self.activeParticipantUserIds = deepCopy.activeParticipantUserIds
                self.files = deepCopy.files
            }
        case .clear:
            break
        }
    }
    
    /// This one will only be used when doing a full refresh from the server/
    func setFromAnotherInstance(event: CBEvent) {
        self.id = event.id
        self.uuid = event.uuid
        self.title = event.title
        self.amountString = event.amountString
        self.eventType = event.eventType
        self.startDate = event.startDate
        self.endDate = event.endDate
        self.active = event.active
        self.action = event.action
        self.activeParticipantUserIds = event.activeParticipantUserIds
        self.files = event.files
        
        var activeIds: Array<String> = []
        
        
        // MARK: - Handle Items
        activeIds.removeAll()
        for each in event.items {
            activeIds.append(each.id)
            if let index = self.items.firstIndex(where: { $0.id == each.id }) {
                self.items[index].setFromAnotherInstance(item: each)
            } else {
                self.items.append(each)
            }
        }
        
        /// Delete from model if deleted on the server.
        for each in items {
            if !activeIds.contains(each.id) {
                items.removeAll { $0.id == each.id }
            }
        }
        
        // MARK: - Handle Categories
        activeIds.removeAll()
        for each in event.categories {
            activeIds.append(each.id)
            if let index = self.categories.firstIndex(where: { $0.id == each.id }) {
                self.categories[index].setFromAnotherInstance(category: each)
            } else {
                self.categories.append(each)
            }
        }
        
        /// Delete from model if deleted on the server.
        for each in categories {
            if !activeIds.contains(each.id) {
                categories.removeAll { $0.id == each.id }
            }
        }
        
        // MARK: - Handle Transactions
        activeIds.removeAll()
        for each in event.transactions {
            activeIds.append(each.id)
            if let index = self.transactions.firstIndex(where: { $0.id == each.id }) {
                //if each.changedDate > self.transactions[index].changedDate {
                    self.transactions[index].setFromAnotherInstance(transaction: each)
                //}
            } else {
                self.transactions.append(each)
            }
        }
        
        /// Delete from model if deleted on the server.
        for each in transactions {
            if !activeIds.contains(each.id) {
                transactions.removeAll { $0.id == each.id }
            }
        }
        
        // MARK: - Handle Participants
        activeIds.removeAll()
        for each in event.participants {
            activeIds.append(each.id)
            if let index = self.participants.firstIndex(where: { $0.id == each.id }) {
                self.participants[index].setFromAnotherInstance(part: each)
            } else {
                self.participants.append(each)
            }
        }
        
        /// Delete from model if deleted on the server.
        for each in participants {
            /// Check to see if the participant is active. The long poll would be missing any previously active participants when running this
            if event.activeParticipantUserIds.contains(each.user.id) {
                continue
            } else {
                if !activeIds.contains(each.id) {
                    participants.removeAll { $0.id == each.id }
                }
            }
        }
    }
    
    
    
    func setListOrdersForCategories() -> Array<ListOrderUpdate> {
        var updates: Array<ListOrderUpdate> = []
        var index = 0
        
        for category in categories {
            category.listOrder = index
            updates.append(ListOrderUpdate(id: category.id, listorder: index))
            
            index += 1
        }
        
        return updates
    }
    
    
    func setListOrdersForItems() -> Array<ListOrderUpdate> {
        var updates: Array<ListOrderUpdate> = []
        var index = 0
        
        for item in items {
            item.listOrder = index
            updates.append(ListOrderUpdate(id: item.id, listorder: index))
            
            index += 1
        }
        
        return updates
    }
    
    
    
    /// Only update the event details when updating via the long poll
    func setFromAnotherInstanceForLongPoll(event: CBEvent) {
        self.id = event.id
        self.uuid = event.uuid
        self.title = event.title
        self.amountString = event.amountString
        self.eventType = event.eventType
        self.startDate = event.startDate
        self.endDate = event.endDate
        self.active = event.active
        self.action = event.action
        self.files = event.files
        self.activeParticipantUserIds = event.activeParticipantUserIds
    }
    
    
    static func == (lhs: CBEvent, rhs: CBEvent) -> Bool {
        if lhs.id == rhs.id
        && lhs.uuid == rhs.uuid
        && lhs.title == rhs.title
        && lhs.amountString == rhs.amountString
        && lhs.eventType == rhs.eventType
        && lhs.startDate == rhs.startDate
        && lhs.endDate == rhs.endDate
        && lhs.participants == rhs.participants
        && lhs.activeParticipantUserIds == rhs.activeParticipantUserIds
        && lhs.items == rhs.items
        && lhs.transactions == rhs.transactions
        && lhs.categories == rhs.categories
        && lhs.files == rhs.files
        && lhs.active == rhs.active {
            return true
        }
        return false
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    
    func amIAdmin() -> Bool {
        return AppState.shared.user!.id == self.enteredBy.id
    }
    
    func wasUpdatedByAdmin() -> Bool {
        return self.updatedBy.id == self.enteredBy.id
    }
    
    
    
    // MARK: - Particpiants
    func upsert(_ part: CBEventParticipant) {
        if !doesExist(part) {
            withAnimation {
                participants.append(part)
            }
        }
    }
    
    func getIndex(for part: CBEventParticipant) -> Int? {
        return participants.firstIndex(where: { $0.id == part.id })
    }
    
    func doesExist(_ part: CBEventParticipant) -> Bool {
        return !participants.filter { $0.id == part.id }.isEmpty
    }
    
    func getParticipant(by id: String) -> CBEventParticipant? {
        return participants.filter { $0.id == id }.first
    }
    
    func saveParticipant(id: String) -> Bool {
        //let part = getParticipant(by: id)
//        if part.title.isEmpty {
//            if part.action != .add && part.title.isEmpty {
//                part.title = part.deepCopy?.title ?? ""
//                AppState.shared.showAlert("Removing a title is not allowed. If you want to delete \(part.title), please use the delete button instead.")
//            } else {
//                participants.removeAll { $0.id == id }
//            }
//            return false
//        }
        
        return true
    }
    
    func deleteParticipant(id: String) {
        withAnimation {
            participants.removeAll(where: {$0.id == id})
        }
    }
    
    
    
    // MARK: - Items
    func upsert(_ item: CBEventItem) {
        if !doesExist(item) {
            withAnimation {
                items.append(item)
            }
        }
    }
    
    func getIndex(for item: CBEventItem) -> Int? {
        return items.firstIndex(where: { $0.id == item.id })
    }
    
    func doesExist(_ item: CBEventItem) -> Bool {
        return !items.filter { $0.id == item.id }.isEmpty
    }
    
    func getItem(by id: String) -> CBEventItem {
        return items.filter { $0.id == id }.first ?? CBEventItem(uuid: id, eventID: self.id)
    }
    
    func saveItem(id: String) -> Bool {
        let item = getItem(by: id)
        if item.title.isEmpty {
            if item.action != .add && item.title.isEmpty {
                item.title = item.deepCopy?.title ?? ""
                AppState.shared.showAlert("Removing a title is not allowed. If you want to delete \(item.title), please use the delete button instead.")
            } else {
                items.removeAll { $0.id == id }
            }
            return false
        } else {
            transactions.filter{$0.item?.id == id}.forEach { trans in
                trans.item = item
            }
        }
        
        return true
    }
    
    func deleteItem(id: String) {
        let index = items.firstIndex(where: {$0.id == id})
        if let index {
            items[index].active = false
            items[index].action = .delete
        }
        
        transactions.filter{$0.item?.id == id}.forEach { trans in
            trans.item = nil
        }
    }
    
    
    
    
    // MARK: - Categories
    func upsert(_ category: CBEventCategory) {
        if !doesExist(category) {
            withAnimation {
                categories.append(category)
            }
            
        }
    }
    
    func getIndex(for category: CBEventCategory) -> Int? {
        return categories.firstIndex(where: { $0.id == category.id })
    }
    
    func doesExist(_ category: CBEventCategory) -> Bool {
        return !categories.filter { $0.id == category.id }.isEmpty
    }
    
    func getCategory(by id: String) -> CBEventCategory {
        return categories.filter { $0.id == id }.first ?? CBEventCategory(uuid: id, eventID: self.id)
    }
    
    func saveCategory(id: String) -> Bool {
        let category = getCategory(by: id)
        if category.title.isEmpty {
            if category.action != .add && category.title.isEmpty {
                category.title = category.deepCopy?.title ?? ""
                AppState.shared.showAlert("Removing a title is not allowed. If you want to delete \(category.title), please use the delete button instead.")
            } else {
                categories.removeAll { $0.id == id }
            }
            return false
        } else {
            transactions.filter{$0.category?.id == id}.forEach { trans in
                trans.category = category
            }
        }
        
        return true
    }
    
    func deleteCategory(id: String) {
        let index = categories.firstIndex(where: {$0.id == id})
        if let index {
            categories[index].active = false
            categories[index].action = .delete
        }
        
        transactions.filter{$0.category?.id == id}.forEach { trans in
            trans.category = nil
        }
        
    }
    
    
    
    
    // MARK: - Transactions
    func upsert(_ trans: CBEventTransaction) {
        if !doesExist(trans) {
            withAnimation {
                transactions.append(trans)
            }
        }
    }
    
    func getIndex(for trans: CBEventTransaction) -> Int? {
        return transactions.firstIndex(where: { $0.id == trans.id })
    }
    
    func doesExist(_ item: CBEventTransaction) -> Bool {
        return !transactions.filter { $0.id == item.id }.isEmpty
    }
    
    func getTransaction(by id: String) -> CBEventTransaction {
        return transactions.filter { $0.id == id }.first ?? CBEventTransaction(uuid: id, eventID: self.id)
    }
    
    func saveTransaction(id: String) -> Bool {
        let trans = getTransaction(by: id)
        
        
        if trans.hasChanges() || trans.action == .delete {
            if trans.title.isEmpty {
                if trans.action != .add && trans.title.isEmpty {
                    trans.title = trans.deepCopy?.title ?? ""
                    AppState.shared.showAlert("Removing a title is not allowed. If you want to delete \(trans.title), please use the delete button instead.")
                } else {
                    transactions.removeAll { $0.id == id }
                }
                
                return false
            } else {
                return true
            }
        } else if trans.title.isEmpty {
            transactions.removeAll { $0.id == id }
            print("-- \(#function) -- Titlemissing 2")
            return false
        }
        
        return false
    }
    
    func deleteTransaction(id: String) {
        let index = transactions.firstIndex(where: {$0.id == id})
        if let index {
            transactions[index].active = false
            transactions[index].action = .delete
        } else {
            print("CANT FIND TRANS")
        }
    }
}
