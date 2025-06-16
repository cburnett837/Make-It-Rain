//
//  CBEventTransactionOption.swift
//  MakeItRain
//
//  Created by Cody Burnett on 3/30/25.
//

import Foundation

@Observable
class CBEventTransactionOption: Codable, Identifiable, Hashable, Equatable, CanEditTitleWithLocation, CanEditAmount {
    var id: String
    var uuid: String?
    var transactionID: String
    var title: String
    var amount: Double {
        Double(amountString.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")) ?? 0.0
    }
    var amountString: String
    
    var amountTypeLingo: String {
        amountString.contains("-") ? "Expense" : "Income"
    }    
    
    var url: String
    var notes: String = ""
    var address: String?
    var active: Bool
    var enteredBy: CBUser = AppState.shared.user!
    var updatedBy: CBUser = AppState.shared.user!
    
    var enteredDate: Date
    var updatedDate: Date
    
    var costRange: Int?
    var locations: Array<CBLocation>
    var pictures: Array<CBPicture>?
    
    var action: EventTransactionOptionAction
        
    enum CodingKeys: CodingKey { case id, uuid, transaction_id, title, amount, url, notes, address, active, entered_by, updated_by, entered_date, updated_date, user_id, account_id, device_uuid, action, pictures, locations, cost_range }
    
    init(transactionID: String) {
        let uuid = UUID().uuidString
        self.id = uuid
        self.uuid = uuid
        self.transactionID = transactionID
        self.title = ""
        self.amountString = ""
        self.active = true
        self.enteredDate = Date()
        self.updatedDate = Date()
        self.action = .add
        self.url = ""
        self.locations = []
    }
    
    init(uuid: String, transactionID: String) {
        self.id = uuid
        self.uuid = uuid
        self.transactionID = transactionID
        self.title = ""
        self.amountString = ""
        self.active = true
        self.enteredDate = Date()
        self.updatedDate = Date()
        self.action = .add
        self.url = ""
        self.locations = []
    }
    
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(uuid, forKey: .uuid)
        try container.encode(transactionID, forKey: .transaction_id)
        try container.encode(title, forKey: .title)
        try container.encode(amount, forKey: .amount)
        try container.encode(url, forKey: .url)
        try container.encode(notes, forKey: .notes)
        try container.encode(address, forKey: .address)
        try container.encode(enteredBy, forKey: .entered_by) // for the Transferable protocol
        try container.encode(updatedBy, forKey: .updated_by) // for the Transferable protocol
        try container.encode(enteredDate.string(to: .serverDateTime), forKey: .entered_date) // for the Transferable protocol
        try container.encode(updatedDate.string(to: .serverDateTime), forKey: .updated_date) // for the Transferable protocol
        try container.encode(active ? 1 : 0, forKey: .active)
        try container.encode(AppState.shared.user?.id, forKey: .user_id)
        try container.encode(AppState.shared.user?.accountID, forKey: .account_id)
        try container.encode(AppState.shared.deviceUUID, forKey: .device_uuid)
        try container.encode(action.serverKey, forKey: .action)
        
        try container.encode(pictures, forKey: .pictures)
        try container.encode(locations, forKey: .locations)
        try container.encode(costRange, forKey: .cost_range)
    }
        
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        do {
            id = try String(container.decode(Int.self, forKey: .id))
        } catch {
            id = try container.decode(String.self, forKey: .id)
        }
        
        do {
            transactionID = try String(container.decode(Int.self, forKey: .transaction_id))
        } catch {
            transactionID = try container.decode(String.self, forKey: .transaction_id)
        }
        
        
        title = try container.decode(String.self, forKey: .title)
        
        let amount = try container.decode(Double.self, forKey: .amount)
        let useWholeNumbers = LocalStorage.shared.useWholeNumbers
        self.amountString = amount.currencyWithDecimals(useWholeNumbers ? 0 : 2)
        
        url = try container.decode(String.self, forKey: .url)
        notes = try container.decode(String.self, forKey: .notes)
        address = try container.decode(String?.self, forKey: .address)
        self.pictures = try container.decode(Array<CBPicture>?.self, forKey: .pictures)
        self.locations = try container.decode(Array<CBLocation>.self, forKey: .locations)
        self.costRange = try container.decode(Int?.self, forKey: .cost_range)
        
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
    
    
    var deepCopy: CBEventTransactionOption?
    func deepCopy(_ mode: ShadowCopyAction) {
        switch mode {
        case .create:
            print("creating deep copy")
            let copy = CBEventTransactionOption(uuid: UUID().uuidString, transactionID: self.transactionID)
            copy.id = self.id
            copy.uuid = self.uuid
            copy.transactionID = self.transactionID
            copy.title = self.title
            copy.amountString = self.amountString
            copy.url = self.url
            copy.notes = self.notes
            copy.address = self.address
            copy.active = self.active
            copy.enteredBy = self.enteredBy
            copy.updatedBy = self.updatedBy
            copy.enteredDate = self.enteredDate
            copy.updatedDate = self.updatedDate
            copy.pictures = self.pictures
            copy.locations = self.locations.compactMap ({ $0.deepCopy(.create); return $0.deepCopy })
            copy.costRange = self.costRange
            copy.active = self.active
            self.deepCopy = copy
        case .restore:
            if let deepCopy = self.deepCopy {
                self.id = deepCopy.id
                self.uuid = deepCopy.uuid
                self.transactionID = deepCopy.transactionID
                self.title = deepCopy.title
                self.amountString = deepCopy.amountString
                self.url = deepCopy.url
                self.notes = deepCopy.notes
                self.address = deepCopy.address
                self.active = deepCopy.active
                self.enteredBy = deepCopy.enteredBy
                self.updatedBy = deepCopy.updatedBy
                self.enteredDate = deepCopy.enteredDate
                self.updatedDate = deepCopy.updatedDate
                self.pictures = deepCopy.pictures
                self.locations = deepCopy.locations
                self.costRange = deepCopy.costRange
                self.active = deepCopy.active
            }
        case .clear:
            break
        }
    }
    
    
    
    
    static func == (lhs: CBEventTransactionOption, rhs: CBEventTransactionOption) -> Bool {
        if lhs.id == rhs.id
        && lhs.uuid == rhs.uuid
        && lhs.transactionID == rhs.transactionID
        && lhs.title == rhs.title
        && lhs.amount == rhs.amount
        && lhs.url == rhs.url
        && lhs.notes == rhs.notes
        && lhs.address == rhs.address
        && lhs.active == rhs.active
        && lhs.enteredBy == rhs.enteredBy
        && lhs.updatedBy == rhs.updatedBy
        && lhs.enteredDate == rhs.enteredDate
        && lhs.updatedDate == rhs.updatedDate
        && lhs.pictures == rhs.pictures
        && lhs.locations == rhs.locations
        && lhs.costRange == rhs.costRange
        && lhs.active == rhs.active
        {
            return true
        }
        return false
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    
    func setFromAnotherInstance(option: CBEventTransactionOption) {
        //print("SETTING ACTIVE TO \(item.active) for \(item.title)")
        //self.id = item.id
        self.id = option.id
        self.uuid = option.uuid
        self.transactionID = option.transactionID
        self.title = option.title
        
        let useWholeNumbers = LocalStorage.shared.useWholeNumbers
        self.amountString = option.amount.currencyWithDecimals(useWholeNumbers ? 0 : 2)
        
        self.url = option.url
        self.notes = option.notes
        self.address = option.address
        self.active = option.active
        self.enteredBy = option.enteredBy
        self.updatedBy = option.updatedBy
        self.enteredDate = option.enteredDate
        self.updatedDate = option.updatedDate
        self.active = option.active
        self.action = option.action
        
        self.locations = option.locations
        self.pictures = option.pictures
        self.costRange = option.costRange
    }
    
    
    func hasChanges() -> Bool {
        if let deepCopy = deepCopy {
            if self.title == deepCopy.title
            && self.amountString == deepCopy.amountString
            && self.url == deepCopy.url
            && self.notes == deepCopy.notes
            && self.pictures == deepCopy.pictures
            && self.locations == deepCopy.locations
            && self.costRange == deepCopy.costRange
            && self.address == deepCopy.address {
                return false
            } else {
               print("Changes detected:")
               if self.title != deepCopy.title {
                   print("- Title changed: \(deepCopy.title) → \(self.title)")
                }
                if self.amountString != deepCopy.amountString {
                    print("- Amount changed: \(deepCopy.amountString) → \(self.amountString)")
                }
                if self.url != deepCopy.url {
                    print("- URL changed: \(String(describing: deepCopy.url)) → \(String(describing: self.url))")
                }
                if self.notes != deepCopy.notes {
                    print("- Notes changed: \(deepCopy.notes) → \(self.notes)")
                }
                if self.address != deepCopy.address {
                    print("- Address changed: \(String(describing: deepCopy.address)) → \(String(describing: self.address))")
                }
                if self.locations != deepCopy.locations {
                    print("- locations changed: \(deepCopy.locations) → \(self.locations)")
                }
                if self.pictures != deepCopy.pictures {
                    print("- pictures changed: \(String(describing: deepCopy.pictures)) → \(String(describing: self.pictures))")
                }
                if self.costRange != deepCopy.costRange {
                    print("- costRange changed: \(String(describing: deepCopy.costRange)) → \(String(describing: self.costRange))")
                }
           }
        } else {
            print("no deepy copy")
        }
        return true
    }
    
    
    // MARK: - Locations
    func doesExist(_ location: CBLocation) -> Bool {
        return !locations.filter { $0.id == location.id }.isEmpty
    }
    
    func upsert(_ location: CBLocation) {
        if !doesExist(location) {
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
}
