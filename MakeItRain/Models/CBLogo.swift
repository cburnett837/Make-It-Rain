//
//  CBLogo.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/27/25.
//

import Foundation

class LogoMaybeShouldUpdateModel: Codable {
    var logos: [CBLogo]?
    
    init(logos: [CBLogo]) {
        self.logos = logos
    }
    
    enum CodingKeys: CodingKey { case user_id, account_id, device_uuid, logos }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(logos, forKey: .logos)
        try container.encode(Cody.shared.id, forKey: .user_id)
        try container.encode(Cody.shared.accountID, forKey: .account_id)
        try container.encode(Cody.shared.deviceUUID, forKey: .device_uuid)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        logos = try container.decode(Array<CBLogo>?.self, forKey: .logos)
    }
}



@Observable
class CBLogo: Codable, Identifiable, Hashable {
    var id: String
    var relatedID: String
    var relatedRecordType: XrefLogoParentType
    var baseString: String?
    var active: Bool
    var enteredBy: CBUser = AppState.shared.user!
    var updatedBy: CBUser = AppState.shared.user!
    var enteredById: Int?
    var updatedById: Int?
    var enteredDate: Date
    var updatedDate: Date
    
    enum CodingKeys: CodingKey { case id, related_id, related_type_id, base_string, active, user_id, account_id, device_uuid, entered_by, updated_by, entered_date, updated_date, entered_by_id, updated_by_id }
    
    init(relatedID: String, baseString: String, fileType: XrefLogoParentType) {
        self.id = UUID().uuidString
        self.relatedID = relatedID
        self.baseString = baseString
        self.active = true
        self.relatedRecordType = fileType // XrefModel.getItem(from: .fileTypes, byEnumID: fileType)
        self.enteredBy = AppState.shared.user!
        self.updatedBy = AppState.shared.user!
        self.enteredDate = Date()
        self.updatedDate = Date()
    }
    
    /// Only used to check if new logos are required to download from the server.
    init(entity: PersistentLogo) {
        //print("init logo with entity id \(entity.id)")
        //print("init logo with entity relatedID \(entity.relatedID)")
        //print("init logo with entity relatedTypeID \(entity.relatedTypeID)")        
        self.id = entity.id!
        self.updatedDate = entity.localUpdatedDate ?? Date()
        
        /// Don't care about any of these, they're just here to satisfy the initializer.
        self.relatedID = entity.relatedID!
        self.relatedRecordType = XrefLogoParentType(id: Int(entity.relatedTypeID)) //XrefModel.getItem(from: .logoTypes, byID: Int(entity.relatedTypeID))
        self.active = true
        self.enteredDate = Date()
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        //try container.encode(Int(id), forKey: .id) // This weird Int() thing is for the drag and drop
        try container.encode(relatedID, forKey: .related_id)
        try container.encode(baseString, forKey: .base_string)
        try container.encode(active ? 1 : 0, forKey: .active)
        try container.encode(updatedDate.string(to: .serverDateTime), forKey: .updated_date)
        try container.encode(Cody.shared.id, forKey: .user_id)
        try container.encode(Cody.shared.accountID, forKey: .account_id)
        try container.encode(Cody.shared.deviceUUID, forKey: .device_uuid)
        try container.encode(relatedRecordType.id, forKey: .related_type_id)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        do {
            id = try String(container.decode(Int.self, forKey: .id))
        } catch {
            id = try container.decode(String.self, forKey: .id)
        }
        
        do {
            relatedID = try String(container.decode(Int.self, forKey: .related_id))
        } catch {
            relatedID = try container.decode(String.self, forKey: .related_id)
        }
                
        baseString = try container.decode(String?.self, forKey: .base_string)
        let active = try container.decode(Int.self, forKey: .active)
        self.active = active == 1 ? true : false
        
        let relatedTypeID = try container.decode(Int.self, forKey: .related_type_id)
        self.relatedRecordType = XrefLogoParentType(id: relatedTypeID) //XrefModel.getItem(from: .logoTypes, byID: relatedTypeID)
        
        if let enteredById = try container.decode(Int?.self, forKey: .entered_by_id) {
            self.enteredBy = AppState.shared.getUserBy(id: enteredById) ?? CBUser()
        }
        
        if let updatedById = try container.decode(Int?.self, forKey: .updated_by_id) {
            self.updatedBy = AppState.shared.getUserBy(id: updatedById) ?? CBUser()
        }
        
        enteredDate = try container.decode(Date.self, forKey: .entered_date)
        updatedDate = try container.decode(Date.self, forKey: .updated_date)
        
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
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: CBLogo, rhs: CBLogo) -> Bool {
        if lhs.baseString == rhs.baseString
        && lhs.active == rhs.active
        {
            return true
        } else {
            return false
        }
    }
}

