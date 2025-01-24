////
////  CBEventInvite.swift
////  MakeItRain
////
////  Created by Cody Burnett on 1/22/25.
////
//
//import Foundation
//
//@Observable
//class CBEventInvite: Codable, Identifiable, Equatable, Hashable {
//    var id: String
//    var uuid: String?
//    var eventID: String
//    var eventName: String?
//    var inviteFrom: CBUser?
//    var inviteTo: CBUser?
//    var email: String?
//    var status: XrefItem?
//    var active: Bool
//    
//    var enteredBy: CBUser = AppState.shared.user!
//    var updatedBy: CBUser = AppState.shared.user!
//    
//    var enteredDate: Date
//    var updatedDate: Date
//    
//    
//    enum CodingKeys: CodingKey { case id, uuid, event_id, invite_from, invite_to, email, status_id, event_name, active, entered_by, updated_by, entered_date, updated_date }
//    
//    func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(id, forKey: .id)
//        try container.encode(uuid, forKey: .uuid)
//        try container.encode(inviteFrom, forKey: .invite_from)
//        try container.encode(inviteTo, forKey: .invite_to)
//        try container.encode(email, forKey: .email)
//        try container.encode(eventID, forKey: .event_id)
//        try container.encode(enteredBy, forKey: .entered_by)
//        try container.encode(updatedBy, forKey: .updated_by)
//        try container.encode(enteredDate.string(to: .serverDateTime), forKey: .entered_date)
//        try container.encode(updatedDate.string(to: .serverDateTime), forKey: .updated_date)
//        try container.encode(active ? 1 : 0, forKey: .active)
//    }
//    
//    
//    
//    init(user: CBUser, eventID: String, email: String) {
//        let uuid = UUID().uuidString
//        self.id = uuid
//        self.uuid = uuid
//        self.inviteFrom = user
//        self.eventID = eventID
//        self.email = email
//        self.active = true
//        self.enteredDate = Date()
//        self.updatedDate = Date()
//        
//    }
//    
//    init() {
//        let uuid = UUID().uuidString
//        self.id = uuid
//        self.uuid = uuid
//        self.eventID = ""
//        self.active = true
//        self.enteredDate = Date()
//        self.updatedDate = Date()
//    }
//    
//    
//        
//    required init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        id = try String(container.decode(Int.self, forKey: .id))
//        inviteFrom = try container.decode(CBUser.self, forKey: .invite_from)
//        inviteTo = try container.decode(CBUser.self, forKey: .invite_to)
//        eventID = try String(container.decode(Int.self, forKey: .event_id))
//        eventName = try container.decode(String?.self, forKey: .event_name)
//        email = try container.decode(String?.self, forKey: .email)
//        let statusID = try container.decode(Int.self, forKey: .status_id)
//        self.status = XrefModel.getItem(from: .eventInviteStatus, byID: statusID)
//        
//        enteredBy = try container.decode(CBUser.self, forKey: .entered_by)
//        updatedBy = try container.decode(CBUser.self, forKey: .updated_by)
//        
//        let enteredDate = try container.decode(String?.self, forKey: .entered_date)
//        if let enteredDate {
//            self.enteredDate = enteredDate.toDateObj(from: .serverDateTime)!
//        } else {
//            fatalError("Could not determine enteredDate date")
//        }
//        
//        let updatedDate = try container.decode(String?.self, forKey: .updated_date)
//        if let updatedDate {
//            self.updatedDate = updatedDate.toDateObj(from: .serverDateTime)!
//        } else {
//            fatalError("Could not determine updatedDate date")
//        }
//        
//        
//        let isActive = try container.decode(Int?.self, forKey: .active)
//        self.active = isActive == 1 ? true : false
//    }
//    
//    
//    
//    var deepCopy: CBEventInvite?
//    func deepCopy(_ mode: ShadowCopyAction) {
//        switch mode {
//        case .create:
//            let copy = CBEventInvite()
//            copy.id = self.id
//            copy.inviteFrom = self.inviteFrom
//            copy.inviteTo = self.inviteTo
//            copy.eventID = self.eventID
//            copy.eventName = self.eventName
//            copy.status = self.status
//            copy.active = self.active
//            self.deepCopy = copy
//        case .restore:
//            if let deepCopy = self.deepCopy {
//                self.id = deepCopy.id
//                self.inviteFrom = deepCopy.inviteFrom
//                self.inviteTo = deepCopy.inviteTo
//                self.eventID = deepCopy.eventID
//                self.eventName = deepCopy.eventName
//                self.status = deepCopy.status
//                self.active = deepCopy.active
//            }
//        }
//    }
//    
//    
//    static func == (lhs: CBEventInvite, rhs: CBEventInvite) -> Bool {
//        if lhs.id == rhs.id
//        && lhs.inviteFrom == rhs.inviteFrom
//        && lhs.inviteTo == rhs.inviteTo
//        && lhs.eventID == rhs.eventID
//        && lhs.eventName == rhs.eventName
//        && lhs.status == rhs.status {
//            return true
//        }
//        return false
//    }
//    
//    func hash(into hasher: inout Hasher) {
//        hasher.combine(id)
//    }
//}
//
//
//
//
//
//
//
//
//
