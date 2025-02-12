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
        
    var participants: [CBEventParticipant]
    var items: [CBEventItem]
    var transactions: Array<CBEventTransaction>
    
    var pendingRealTransactionsToSave: [CBTransaction] = []
    //var invitationsToSend: Array<CBEventInvite> = []
    //var participantsToRemove: Array<CBUser> = []
    
    
    /// For deep copies
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
        
        self.enteredDate = Date()
        self.updatedDate = Date()
    }
    
    /// For new
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
        
        self.enteredDate = Date()
        self.updatedDate = Date()
    }
    
    enum CodingKeys: CodingKey { case id, uuid, title, amount, event_type, start_date, end_date, active, entered_by, updated_by, entered_date, updated_date, user_id, account_id, device_uuid, participants, items, transactions }
    
    
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
        let useWholeNumbers = UserDefaults.standard.bool(forKey: "useWholeNumbers")
        self.amountString = amount.currencyWithDecimals(useWholeNumbers ? 0 : 2)
        
        eventType = try container.decode(String?.self, forKey: .event_type)
        
        let startDate = try container.decode(String?.self, forKey: .start_date)
        if let startDate {
            print(startDate)
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
        
        participants = try container.decode(Array<CBEventParticipant>.self, forKey: .participants)
        items = try container.decode(Array<CBEventItem>.self, forKey: .items)
        self.transactions = try container.decode(Array<CBEventTransaction>.self, forKey: .transactions)
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
            && self.endDate == deepCopy.endDate
            && self.participants == deepCopy.participants
            && self.transactions == deepCopy.transactions
            //&& self.invitationsToSend == deepCopy.invitationsToSend
            //&& self.participantsToRemove == deepCopy.participantsToRemove
            && self.items == deepCopy.items {
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
                self.active = deepCopy.active
            }
        }
    }
    
    
    func setFromAnotherInstance(event: CBEvent) {
        self.title = event.title
        self.amountString = event.amountString
        self.eventType = event.eventType
        self.startDate = event.startDate
        self.endDate = event.endDate
        //self.participants = event.participants
        //self.invitationsToSend = event.invitationsToSend
        //self.participantsToRemove = event.participantsToRemove
        //self.items = event.items
        self.active = event.active
        self.action = event.action
        
        
        self.participants = event.participants.map { part in
            if let index = self.participants.firstIndex(where: {$0.id == part.id}) {
                self.participants[index].setFromAnotherInstance(part: part)
                return self.participants[index]
            }
            return part
        }
        
        self.items = event.items.map { item in
            if let index = self.items.firstIndex(where: {$0.id == item.id}) {
                self.items[index].setFromAnotherInstance(item: item)
                return self.items[index]
            }
            return item
        }
        
        self.transactions = event.transactions.map { trans in
            if let index = self.transactions.firstIndex(where: {$0.id == trans.id}) {
                self.transactions[index].setFromAnotherInstance(transaction: trans)
                return self.transactions[index]
            }
            return trans
        }
    }
    
    
    func updateFromLongPoll(event: CBEvent) {
        print("SELF PARTS")
        print("userNames: \(self.participants.map {$0.user.name})")
        print("actives: \(self.participants.map {$0.active})")
        print("statuses: \(self.participants.map {$0.status?.description})")
        print("ids: \(self.participants.map {$0.id})")
        
        if event.wasUpdatedByAdmin() {
            print("Event was updated by admin")
            /// If the event was updated by the admin, update the event details.
            self.title = event.title
            self.amountString = event.amountString
            self.eventType = event.eventType
            self.startDate = event.startDate
            self.endDate = event.endDate
            
            /// If the event was updated by the admin, update the event items
            self.items = event.items.map { item in
                if let index = self.items.firstIndex(where: { $0.id == item.id }) {
                    self.items[index].setFromAnotherInstance(item: item)
                    return self.items[index]
                }
                return item
            }
                        
            for each in event.participants {
                print("Processing Participant ID \(each.id)")
                /// Determine if the admin removed participants, or If someone rejected an invitation.
                if !each.active || each.status?.enumID == .rejected {
                    print("PArt is either deactive ir rejected \(each.active) - \(String(describing: each.status?.description))")
                    /// Clean the incoming event.
                    event.participants.removeAll(where: { $0.id == each.id })
                    /// Remove the participants from the event object being updated.
                    withAnimation {
                        self.participants.removeAll(where: { $0.id == each.id })
                    }
                } else {
                    /// Determine if the admin added new participants.
                    if !self.participants.contains(where: { $0.id == each.id }) {
                        print("✅Appending Object \(each.id) ")
                        withAnimation {
                            self.participants.append(each)
                        }
                    } else {
                        print("⚠️Object is already there \(each.id) ")
                        let object = self.participants.filter {$0.id == each.id}.first
                        if let object {
                            print("Objkect has a staus of \(String(describing: object.status?.description)) and an active of \(object.active)")
                        }
                        
                    }
                }
            }
        } else {
            print("was not updated by admin \(event.updatedBy.id) - \(event.enteredBy.id)")
            
            
            /// If the user that updated the event is the same as the logged in user, change their own things. Otherwise change other things.
            for each in event.participants {
                if let index = self.participants.firstIndex(where: { $0.id == each.id && $0.status?.enumID == .pending }) {
                    self.participants[index].setFromAnotherInstance(part: each)
                }
            }
        }
        
        /// If the user that updated the event is the same as the logged in user, change their own things. Otherwise change other things.
        for each in event.transactions.filter({ (AppState.shared.user(is: event.updatedBy) ? AppState.shared.user(is: $0.paidBy) : !AppState.shared.user(is: $0.paidBy)) || $0.paidBy == nil }) {
            if let index = self.transactions.firstIndex(where: { $0.id == each.id }) {
                self.transactions[index].setFromAnotherInstance(transaction: each)
            } else {
                self.transactions.append(each)
            }
        }
        
        
        /// If the user that updated the event is the same as the logged in user, change their own things. Otherwise change other things.
        for each in event.participants.filter({ AppState.shared.user(is: event.updatedBy) ? AppState.shared.user(is: $0.user) : !AppState.shared.user(is: $0.user) }) {
            if let index = self.participants.firstIndex(where: { $0.id == each.id }) {
                self.participants[index].setFromAnotherInstance(part: each)
            }
        }
                                            
        self.active = event.active
        self.action = event.action
        
        
        
        self.participants.removeAll(where: { $0.status?.enumID == .rejected })
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
        && lhs.items == rhs.items
        && lhs.transactions == rhs.transactions
        //&& lhs.invitationsToSend == rhs.invitationsToSend
        //&& lhs.participantsToRemove == rhs.participantsToRemove
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
    
    
    func upsert(_ item: CBEventItem) {
        if !doesExist(item) {
            items.append(item)
        }
    }
    
    func doesExist(_ item: CBEventItem) -> Bool {
        return !items.filter { $0.id == item.id }.isEmpty
    }
    
    func getItem(by id: String) -> CBEventItem {
        return items.filter { $0.id == id }.first ?? CBEventItem(uuid: id)
    }
    
    func saveItem(id: String) {
        let item = getItem(by: id)
        if item.title.isEmpty {
            if item.action != .add && item.title.isEmpty {
                item.title = item.deepCopy?.title ?? ""
                AppState.shared.showAlert("Removing a title is not allowed. If you want to delete \(item.title), please use the delete button instead.")
            } else {
                items.removeAll { $0.id == id }
            }
        }
    }
    
    func deleteItem(id: String) {
        let index = items.firstIndex(where: {$0.id == id})
        if let index {
            items[index].active = false
            items[index].action = .delete
            
        }
    }
    
    
    func upsert(_ trans: CBEventTransaction) {
        if !doesExist(trans) {
            transactions.append(trans)
        }
    }
    
    func doesExist(_ item: CBEventTransaction) -> Bool {
        return !transactions.filter { $0.id == item.id }.isEmpty
    }
    
    func getTransaction(by id: String) -> CBEventTransaction {
        return transactions.filter { $0.id == id }.first ?? CBEventTransaction(uuid: id)
    }
    
    func saveTransaction(id: String) {
        let trans = getTransaction(by: id)
        if trans.title.isEmpty {
            if trans.action != .add && trans.title.isEmpty {
                trans.title = trans.deepCopy?.title ?? ""
                AppState.shared.showAlert("Removing a title is not allowed. If you want to delete \(trans.title), please use the delete button instead.")
            } else {
                transactions.removeAll { $0.id == id }
            }
        }
    }
    
    func deleteTransaction(id: String) {
        let index = transactions.firstIndex(where: {$0.id == id})
        if let index {
            transactions[index].active = false
            transactions[index].action = .delete
        }
    }
}
