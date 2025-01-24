//
//  CBEventParticipant.swift
//  MakeItRain
//
//  Created by Cody Burnett on 1/20/25.
//

import Foundation

@Observable
class CBEventParticipant: Codable, Identifiable, Hashable, Equatable {
    var id: String
    var uuid: String?
    var user: CBUser
    var amount: Double? {
        Double(amountString?.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "") ?? "0.0") ?? 0.0
    }
    var amountString: String?
    
    var inviteFrom: CBUser?
    var inviteTo: CBUser?
    var email: String?
    var status: XrefItem?
    var eventID: String /// Used for verifying email
    
    
    var active: Bool
    var action: EventParticipantAction
    
    enum CodingKeys: CodingKey { case id, uuid, user, amount, active, invite_from, invite_to, email, status_id, event_id }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(uuid, forKey: .uuid)
        try container.encode(user, forKey: .user)
        try container.encode(amount, forKey: .amount)
        try container.encode(active ? 1 : 0, forKey: .active)
        try container.encode(inviteFrom, forKey: .invite_from)
        try container.encode(inviteTo, forKey: .invite_to)
        try container.encode(email, forKey: .email)
        try container.encode(status?.id, forKey: .status_id)
        try container.encode(eventID, forKey: .event_id)
    }
    
    
    
    init(user: CBUser, eventID: String, email: String?) {
        let uuid = UUID().uuidString
        self.id = uuid
        self.uuid = uuid
        self.user = user
        self.active = true
        self.action = .add
        self.inviteFrom = AppState.shared.user!
        self.inviteTo = AppState.shared.user!
        self.eventID = eventID
        self.email = email
        self.status = XrefModel.getItem(from: .eventInviteStatus, byEnumID: .pending)
    }
    
    
        
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        do {
            id = try String(container.decode(Int.self, forKey: .id))
        } catch {
            id = try container.decode(String.self, forKey: .id)
        }
        user = try container.decode(CBUser.self, forKey: .user)
        
        let amount = try container.decode(Double.self, forKey: .amount)
        let useWholeNumbers = UserDefaults.standard.bool(forKey: "useWholeNumbers")
        self.amountString = amount.currencyWithDecimals(useWholeNumbers ? 0 : 2)
        
        let isActive = try container.decode(Int?.self, forKey: .active)
        self.active = isActive == 1 ? true : false
        
        inviteFrom = try container.decode(CBUser.self, forKey: .invite_from)
        inviteTo = try container.decode(CBUser.self, forKey: .invite_to)
        email = try container.decode(String?.self, forKey: .email)
        let statusID = try container.decode(Int.self, forKey: .status_id)
        self.status = XrefModel.getItem(from: .eventInviteStatus, byID: statusID)
        
        do {
            eventID = try String(container.decode(Int.self, forKey: .event_id))
        } catch {
            eventID = try container.decode(String.self, forKey: .event_id)
        }
        
        action = .edit
    }
    
    
    var deepCopy: CBEventParticipant?
    func deepCopy(_ mode: ShadowCopyAction) {
        switch mode {
        case .create:
            let copy = CBEventParticipant(user: self.user, eventID: self.eventID, email: self.email)
            copy.id = self.id
            copy.uuid = self.uuid
            copy.user = self.user
            copy.amountString = self.amountString
            copy.active = self.active
            copy.inviteFrom = self.inviteFrom
            copy.inviteTo = self.inviteTo
            copy.email = self.email
            copy.status = self.status
            self.deepCopy = copy
        case .restore:
            if let deepCopy = self.deepCopy {
                self.id = deepCopy.id
                self.uuid = deepCopy.uuid
                self.user = deepCopy.user
                self.amountString = deepCopy.amountString
                self.active = deepCopy.active
                self.inviteFrom = deepCopy.inviteFrom
                self.inviteTo = deepCopy.inviteTo
                self.email = deepCopy.email
                self.eventID = deepCopy.eventID
                self.status = deepCopy.status
            }
        }
    }
    
    
    
    
    static func == (lhs: CBEventParticipant, rhs: CBEventParticipant) -> Bool {
        if lhs.id == rhs.id
        && lhs.user == rhs.user
        && lhs.amount == rhs.amount
        && lhs.inviteFrom == rhs.inviteFrom
        && lhs.inviteTo == rhs.inviteTo
        && lhs.email == rhs.email
        && lhs.status == rhs.status
        && lhs.active == rhs.active {
            return true
        }
        return false
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
