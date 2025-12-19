//
//  CBPlaidBank.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/22/25.
//

import Foundation
import SwiftUI


@Observable
class CBPlaidBank: Codable, Identifiable, Equatable, Hashable, CanHandleLogo {
    var id: String
    var title: String
    var active: Bool
    var action: PlaidBankAction
    
    var accounts: Array<CBPlaidAccount>
    
    var enteredBy: CBUser = AppState.shared.user!
    var updatedBy: CBUser = AppState.shared.user!
    var enteredDate: Date
    var updatedDate: Date
    var lastUpdateByPlaidDate: Date?
    var lastTimePlaidSyncedWithInstitutionDate: Date?
    var lastTimeICheckedPlaidSyncedDate: Date?
    var plaidID: String?
    var requiresUpdate: Bool = false
    var logo: Data?
    var logoParentType: XrefItem = XrefModel.getItem(from: .logoTypes, byEnumID: .plaidBank)
    var color: Color = .primary
    
    var numberOfAccounts: Int {
        accounts.count
    }
    
    var hasIssues: Bool {
        !accountsWithIssues.isEmpty || requiresUpdate
    }
    
    var accountsWithIssues: Array<CBPlaidAccount> {
        accounts.filter { $0.paymentMethodID == nil }
    }
    
    /// For deep copies
    init() {
        let uuid = UUID().uuidString
        self.id = uuid
        self.title = ""
        self.active = true
        self.action = .edit /// Different than normal since a `PlaidBank` will never be be created directly by the user.
        self.enteredBy = AppState.shared.user!
        self.updatedBy = AppState.shared.user!
        self.enteredDate = Date()
        self.updatedDate = Date()
        self.accounts = []
    }
    
        
    enum CodingKeys: CodingKey { case id, title, active, user_id, account_id, device_uuid, entered_by, updated_by, entered_date, updated_date, accounts, plaid_id, requires_update, last_updated_by_plaid_date, last_time_plaid_synced_with_institution_date, last_time_i_checked_plaid_synced_date, logo }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(accounts, forKey: .accounts)
        try container.encode(plaidID, forKey: .plaid_id)
        try container.encode(AppState.shared.user?.id, forKey: .user_id)
        try container.encode(AppState.shared.user?.accountID, forKey: .account_id)
        try container.encode(AppState.shared.deviceUUID, forKey: .device_uuid)
        try container.encode(enteredBy, forKey: .entered_by) // for the Transferable protocol
        try container.encode(updatedBy, forKey: .updated_by) // for the Transferable protocol
        try container.encode(enteredDate.string(to: .serverDateTime), forKey: .entered_date) // for the Transferable protocol
        try container.encode(updatedDate.string(to: .serverDateTime), forKey: .updated_date) // for the Transferable protocol
        try container.encode(logo, forKey: .logo)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        do {
            id = try String(container.decode(Int.self, forKey: .id))
        } catch {
            id = try container.decode(String.self, forKey: .id)
        }
        
        title = try container.decode(String.self, forKey: .title)
        plaidID = try container.decode(String?.self, forKey: .plaid_id)
        
        self.accounts = try container.decodeIfPresent(Array<CBPlaidAccount>.self, forKey: .accounts) ?? []
        
        let isActive = try container.decode(Int?.self, forKey: .active)
        self.active = isActive == 1 ? true : false
        
        let requiresUpdate = try container.decode(Int?.self, forKey: .requires_update)
        self.requiresUpdate = requiresUpdate == 1 ? true : false
                
        
        action = .edit
        
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
        
        let lastUpdateByPlaidDate = try container.decode(String?.self, forKey: .last_updated_by_plaid_date)
        if let lastUpdateByPlaidDate {
            self.lastUpdateByPlaidDate = lastUpdateByPlaidDate.toDateObj(from: .serverDateTime)!
        }
        
        let lastTimePlaidSyncedWithInstitutionDate = try container.decode(String?.self, forKey: .last_time_plaid_synced_with_institution_date)
        if let lastTimePlaidSyncedWithInstitutionDate {
            self.lastTimePlaidSyncedWithInstitutionDate = lastTimePlaidSyncedWithInstitutionDate.toDateObj(from: .serverDateTime)!
        }
        
        let lastTimeICheckedPlaidSyncedDate = try container.decode(String?.self, forKey: .last_time_i_checked_plaid_synced_date)
        if let lastTimeICheckedPlaidSyncedDate {
            self.lastTimeICheckedPlaidSyncedDate = lastTimeICheckedPlaidSyncedDate.toDateObj(from: .serverDateTime)!
        }
        
        //logo = try container.decode(String?.self, forKey: .logo)
        
        let pred1 = NSPredicate(format: "relatedID == %@", self.id)
        let pred2 = NSPredicate(format: "relatedTypeID == %@", NSNumber(value: XrefModel.getItem(from: .logoTypes, byEnumID: .plaidBank).id))
        let comp = NSCompoundPredicate(andPredicateWithSubpredicates: [pred1, pred2])
        
        /// Fetch the logo out of core data since the encoded strings can be heavy and I don't want to use Async Image for every logo.
        let context = DataManager.shared.createContext()
        if let logo = DataManager.shared.getOne(
           context: context,
           type: PersistentLogo.self,
           predicate: .compound(comp),
           createIfNotFound: false
        ) {
            self.logo = logo.photoData
        }
    }
        
    
    func hasChanges() -> Bool {
        if let deepCopy = deepCopy {
            if self.title == deepCopy.title
            && self.logo == deepCopy.logo {
                return false
            }
        }
        return true
    }
    
    
    var deepCopy: CBPlaidBank?
    func deepCopy(_ mode: ShadowCopyAction) {
        switch mode {
        case .create:
            let copy = CBPlaidBank()
            copy.id = self.id
            copy.title = self.title
            copy.plaidID = self.plaidID
            copy.requiresUpdate = self.requiresUpdate
            copy.active = self.active
            copy.logo = self.logo
            //copy.action = self.action
            
            copy.accounts = self.accounts.map {
                $0.deepCopy(.create)
                return $0.deepCopy!
            }
            
            self.deepCopy = copy
        case .restore:
            if let deepCopy = self.deepCopy {
                self.id = deepCopy.id
                self.title = deepCopy.title
                self.plaidID = deepCopy.plaidID
                self.requiresUpdate = deepCopy.requiresUpdate
                self.accounts = deepCopy.accounts
                self.active = deepCopy.active
                self.logo = deepCopy.logo
                //self.action = deepCopy.action
            }
        case .clear:
            break
        }
    }
    
    
    func setFromAnotherInstance(bank: CBPlaidBank) {
        self.title = bank.title
        self.plaidID = bank.plaidID
        self.requiresUpdate = bank.requiresUpdate
        self.active = bank.active
        self.lastUpdateByPlaidDate = bank.lastUpdateByPlaidDate
        self.lastTimePlaidSyncedWithInstitutionDate = bank.lastTimePlaidSyncedWithInstitutionDate
        self.lastTimeICheckedPlaidSyncedDate = bank.lastTimeICheckedPlaidSyncedDate
        self.logo = bank.logo
        
        var activeIds: Array<String> = []
        
        activeIds.removeAll()
        for each in bank.accounts {
            activeIds.append(each.id)
            if let index = self.accounts.firstIndex(where: { $0.id == each.id }) {
                self.accounts[index].setFromAnotherInstance(account: each)
            } else {
                self.accounts.append(each)
            }
        }
        
        /// Delete from model if deleted on the server.
        for each in accounts {
            if !activeIds.contains(each.id) {
                accounts.removeAll { $0.id == each.id }
            }
        }
    }
    
    
    static func == (lhs: CBPlaidBank, rhs: CBPlaidBank) -> Bool {
        if lhs.id == rhs.id
        && lhs.plaidID == rhs.plaidID
        && lhs.requiresUpdate == rhs.requiresUpdate
        && lhs.title == rhs.title
        && lhs.accounts == rhs.accounts
        && lhs.logo == rhs.logo
        && lhs.active == rhs.active {
            return true
        }
        return false
    }
    
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
     
    
    func upsert(_ account: CBPlaidAccount) {
        if !doesExist(account) {
            withAnimation {
                accounts.append(account)
            }
        }
    }
    
    func getIndex(for account: CBPlaidAccount) -> Int? {
        return accounts.firstIndex(where: { $0.id == account.id })
    }
    
    func doesExist(_ account: CBPlaidAccount) -> Bool {
        return !accounts.filter { $0.id == account.id }.isEmpty
    }
    
    func getAccount(by id: String) -> CBPlaidAccount? {
        return accounts.filter { $0.id == id }.first
    }
    
    func saveAccount(id: String) -> Bool {
        if let account = getAccount(by: id) {
            if account.title.isEmpty {
                if account.action == .edit && account.title.isEmpty {
                    account.title = account.deepCopy?.title ?? ""
                    AppState.shared.showAlert("Removing a title is not allowed. If you want to delete \(account.title), please use the delete button instead.")
                } else {
                    accounts.removeAll { $0.id == id }
                }
                return false
            }
            
            return true
        } else {
            return false
        }
    }
    
    func deleteAccount(id: String) {
        let index = accounts.firstIndex(where: {$0.id == id})
        if let index {
            accounts[index].active = false
            accounts[index].action = .delete
        }
    }
}
