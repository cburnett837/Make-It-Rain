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
    var groupAmount: Double? {
        Double(groupAmountString?.replacing("$", with: "").replacing(",", with: "") ?? "0.0") ?? 0.0
    }
    var groupAmountString: String?
    
    var personalAmount: Double? {
        Double(personalAmountString?.replacing("$", with: "").replacing(",", with: "") ?? "0.0") ?? 0.0
    }
    var personalAmountString: String?
    
    var inviteFrom: CBUser?
    var inviteTo: CBUser?
    var email: String?
    var status: XrefItem?
    var eventID: String /// Used for verifying email
    var eventName: String?
    
    
    var active: Bool
    var action: EventParticipantAction
    
    enum CodingKeys: CodingKey { case id, uuid, user, group_amount, personal_amount, active, invite_from, invite_to, email, status_id, event_id, event_name, user_id, account_id, device_uuid }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(uuid, forKey: .uuid)
        try container.encode(user, forKey: .user)
        try container.encode(groupAmount, forKey: .group_amount)
        try container.encode(personalAmount, forKey: .personal_amount)
        try container.encode(active ? 1 : 0, forKey: .active)
        try container.encode(inviteFrom, forKey: .invite_from)
        try container.encode(inviteTo, forKey: .invite_to)
        try container.encode(email, forKey: .email)
        try container.encode(status?.id, forKey: .status_id)
        try container.encode(eventID, forKey: .event_id)
        try container.encode(AppState.shared.user?.id, forKey: .user_id)
        try container.encode(AppState.shared.user?.accountID, forKey: .account_id)
        try container.encode(AppState.shared.deviceUUID, forKey: .device_uuid)
    }
    
    
    
    init(user: CBUser, eventID: String, email: String?) {
        let uuid = UUID().uuidString
        self.id = uuid
        self.uuid = uuid
        self.user = user
        self.active = true
        self.action = .add
        self.inviteFrom = AppState.shared.user!
        //self.inviteTo = AppState.shared.user!
        self.eventID = eventID
        self.email = email
        self.status = XrefModel.getItem(from: .eventInviteStatus, byEnumID: .pending)
    }
    
    init(user: CBUser, eventID: String) {
        let uuid = UUID().uuidString
        self.id = uuid
        self.uuid = uuid
        self.user = user
        self.active = true
        self.action = .add
        self.inviteFrom = AppState.shared.user!
        //self.inviteTo = AppState.shared.user!
        self.eventID = eventID
        self.email = user.email
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
        
        
        let useWholeNumbers = LocalStorage.shared.useWholeNumbers
        let groupAmount = try container.decode(Double.self, forKey: .group_amount)
        self.groupAmountString = groupAmount.currencyWithDecimals(useWholeNumbers ? 0 : 2)
        let personalAmount = try container.decode(Double.self, forKey: .personal_amount)
        self.personalAmountString = personalAmount.currencyWithDecimals(useWholeNumbers ? 0 : 2)
        
        
        
        let isActive = try container.decode(Int?.self, forKey: .active)
        self.active = isActive == 1 ? true : false
        
        inviteFrom = try container.decode(CBUser.self, forKey: .invite_from)
        inviteTo = try container.decode(CBUser.self, forKey: .invite_to)
        email = try container.decode(String?.self, forKey: .email)
        
        eventName = try container.decodeIfPresent(String.self, forKey: .event_name)
        
        let statusID = try container.decode(Int.self, forKey: .status_id)
        self.status = XrefModel.getItem(from: .eventInviteStatus, byID: statusID)
        
        do {
            eventID = try String(container.decode(Int.self, forKey: .event_id))
        } catch {
            eventID = try container.decode(String.self, forKey: .event_id)
        }
        
        action = .edit
    }
    
    
    
    func setFromAnotherInstance(part: CBEventParticipant) {
        self.id = part.id
        self.uuid = part.uuid
        self.eventID = part.eventID
        self.user = part.user
        self.groupAmountString = part.groupAmountString
        self.personalAmountString = part.personalAmountString
        self.active = part.active
        self.inviteFrom = part.inviteFrom
        self.inviteTo = part.inviteTo
        self.email = part.email
        self.eventName = part.eventName
        self.status = part.status
        
    }
    
    func updateFromLongPoll(part: CBEventParticipant) {
        if AppState.shared.user(is: part.user) {
            self.user = part.user
            self.groupAmountString = part.groupAmountString
            self.personalAmountString = part.personalAmountString
            self.active = part.active
            self.inviteFrom = part.inviteFrom
            self.inviteTo = part.inviteTo
            self.email = part.email
            self.eventID = part.eventID
            self.eventName = part.eventName
            self.status = part.status
        }
    }
    
    
    var deepCopy: CBEventParticipant?
    func deepCopy(_ mode: ShadowCopyAction) {
        switch mode {
        case .create:
            let copy = CBEventParticipant(user: self.user, eventID: self.eventID, email: self.email)
            copy.id = self.id
            copy.uuid = self.uuid
            copy.user = self.user
            copy.groupAmountString = self.groupAmountString
            copy.personalAmountString = self.personalAmountString
            copy.active = self.active
            copy.inviteFrom = self.inviteFrom
            copy.inviteTo = self.inviteTo
            copy.email = self.email
            copy.status = self.status
            copy.eventID = self.eventID
            copy.eventName = self.eventName
            self.deepCopy = copy
        case .restore:
            if let deepCopy = self.deepCopy {
                self.id = deepCopy.id
                self.uuid = deepCopy.uuid
                self.user = deepCopy.user
                self.groupAmountString = deepCopy.groupAmountString
                self.personalAmountString = deepCopy.personalAmountString
                self.active = deepCopy.active
                self.inviteFrom = deepCopy.inviteFrom
                self.inviteTo = deepCopy.inviteTo
                self.email = deepCopy.email
                self.eventID = deepCopy.eventID
                self.eventName = deepCopy.eventName
                self.status = deepCopy.status
            }
        case .clear:
            break
        }
    }
    
    func hasChanges() -> Bool {
        if let deepCopy = deepCopy {
            if self.groupAmount == deepCopy.groupAmount
            && self.personalAmount == deepCopy.personalAmount
            && self.active == deepCopy.active
            {
                return false
            }
        }
        
        return true
    }
    
    
    
    
    static func == (lhs: CBEventParticipant, rhs: CBEventParticipant) -> Bool {
        if lhs.id == rhs.id
        && lhs.user == rhs.user
        && lhs.groupAmount == rhs.groupAmount
        && lhs.personalAmount == rhs.personalAmount
        && lhs.inviteFrom == rhs.inviteFrom
        && lhs.inviteTo == rhs.inviteTo
        && lhs.email == rhs.email
        && lhs.status == rhs.status
        && lhs.eventID == rhs.eventID
        && lhs.eventName == rhs.eventName
        && lhs.active == rhs.active {
            return true
        }
        return false
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
