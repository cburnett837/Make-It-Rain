//
//  Picture.swift
//  Christmas List
//
//  Created by Cody Burnett on 11/28/23.
//

import Foundation

@Observable
class CBFile: Codable, Identifiable, Hashable {
    var id: String
    var relatedID: String
    var relatedRecordType: XrefItem
    var uuid: String
    var active: Bool
    var fileType: FileType
    
    var isPlaceholder: Bool = false
    
    enum CodingKeys: CodingKey { case id, related_id, related_type_id, uuid, ext, active, user_id, account_id, device_uuid }
    
    init(relatedID: String, uuid: String, parentType: XrefEnum, fileType: FileType) {
        self.id = UUID().uuidString
        self.relatedID = relatedID
        self.uuid = uuid
        self.active = true
        self.relatedRecordType = XrefModel.getItem(from: .fileTypes, byEnumID: parentType)
        self.fileType = fileType
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(Int(id), forKey: .id) // This weird Int() thing is for the drag and drop
        try container.encode(relatedID, forKey: .related_id)
        try container.encode(fileType.ext, forKey: .ext)
        try container.encode(uuid, forKey: .uuid)
        try container.encode(active ? 1 : 0, forKey: .active)
        try container.encode(AppState.shared.user?.id, forKey: .user_id)
        try container.encode(AppState.shared.user?.accountID, forKey: .account_id)
        try container.encode(AppState.shared.deviceUUID, forKey: .device_uuid)
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
        
        
        uuid = try container.decode(String.self, forKey: .uuid)
        let active = try container.decode(Int.self, forKey: .active)
        self.active = active == 1 ? true : false
        
        let relatedID = try container.decode(Int.self, forKey: .related_type_id)
        self.relatedRecordType = XrefModel.getItem(from: .fileTypes, byID: relatedID)
        
        let ext = try container.decode(String.self, forKey: .ext)
        self.fileType = FileType.getByExtension(ext)
        
        
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: CBFile, rhs: CBFile) -> Bool {
        if lhs.uuid == rhs.uuid
        && lhs.active == rhs.active
        {
            return true
        } else {
            return false
        }
    }
}

