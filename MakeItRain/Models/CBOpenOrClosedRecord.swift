//
//  Untitled.swift
//  MakeItRain
//
//  Created by Cody Burnett on 3/26/25.
//
import Foundation

@Observable
class CBOpenOrClosedRecord: Codable {
    var id: String
    var uuid: String?
    var recordID: String
    var recordType: XrefItem
    var openOrClosed: OpenOrClosed
    var user: CBUser = AppState.shared.user!
    var active: Bool = true

    init(recordID: String, recordType: XrefItem, openOrClosed: OpenOrClosed) {
        let uuid = UUID().uuidString
        self.id = uuid
        self.uuid = uuid
        self.recordID = recordID
        self.recordType = recordType
        self.openOrClosed = openOrClosed
    }

    enum CodingKeys: CodingKey { case id, uuid, record_id, record_type_id, user_id, account_id, device_uuid, open_or_closed, user, active }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(uuid, forKey: .uuid)
        try container.encode(recordID, forKey: .record_id)
        try container.encode(recordType.id, forKey: .record_type_id)
        try container.encode(openOrClosed.rawValue, forKey: .open_or_closed)
        try container.encode(AppState.shared.user?.id, forKey: .user_id)
        try container.encode(AppState.shared.user?.accountID, forKey: .account_id)
        try container.encode(AppState.shared.deviceUUID, forKey: .device_uuid)
    }
    
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        do {
            id = try String(container.decode(Int.self, forKey: .id))
        } catch {
            id = try container.decode(String.self, forKey: .id)
        }
        
        do {
            recordID = try String(container.decode(Int.self, forKey: .record_id))
        } catch {
            recordID = try container.decode(String.self, forKey: .record_id)
        }
        
        user = try container.decode(CBUser.self, forKey: .user)
                                
        let recordTypeID = try container.decode(Int.self, forKey: .record_type_id)
        self.recordType = XrefModel.getItem(from: .openRecords, byID: recordTypeID)
        
        let isActive = try container.decode(Int?.self, forKey: .active)
        self.active = isActive == 1 ? true : false
        self.openOrClosed = .open
    }
    
    
    func setFromAnotherInstance(openEvent: CBOpenOrClosedRecord) {
        self.user = openEvent.user
        
        self.openOrClosed = openEvent.openOrClosed
        self.active = openEvent.active
        self.recordID = openEvent.recordID
        self.recordType = openEvent.recordType
    }
    
}


class CBBatchOpenOrClosed: Encodable {
    var openOrClosed: OpenOrClosed
    var records: Array<CBOpenOrClosedRecord>

    init(openOrClosed: OpenOrClosed, records: Array<CBOpenOrClosedRecord>) {
        self.openOrClosed = openOrClosed
        self.records = records
    }

    enum CodingKeys: CodingKey { case user_id, account_id, device_uuid, records, open_or_closed }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(openOrClosed.rawValue, forKey: .open_or_closed)
        try container.encode(records, forKey: .records)
        try container.encode(AppState.shared.user?.id, forKey: .user_id)
        try container.encode(AppState.shared.user?.accountID, forKey: .account_id)
        try container.encode(AppState.shared.deviceUUID, forKey: .device_uuid)
    }
}
