//
//  Auditable.swift
//  MakeItRain
//
//  Created by Cody Burnett on 8/31/26.
//

import Foundation

protocol Auditable: AnyObject {
    var audit: AuditInfo { get set }
}

struct AuditInfo: Codable {
    var enteredBy: CBUser
    var updatedBy: CBUser
    var enteredById: Int?
    var updatedById: Int?
    var enteredDate: Date
    var updatedDate: Date
    
    init(user: CBUser = AppState.shared.user!, date: Date = .now) {
        enteredBy = user
        updatedBy = user
        enteredById = user.id
        updatedById = user.id
        enteredDate = date
        updatedDate = date
    }
    
    enum CodingKeys: String, CodingKey {
        case enteredById = "entered_by_id"
        case updatedById = "updated_by_id"
        case enteredDate = "entered_date"
        case updatedDate = "updated_date"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(enteredById, forKey: .enteredById)
        try container.encode(updatedById, forKey: .updatedById)
        try container.encode(enteredDate, forKey: .enteredDate)
        try container.encode(updatedDate, forKey: .updatedDate)
    }
    
//    func encode<Key>(
//        to container: inout KeyedEncodingContainer<Key>,
//        enteredByIdKey: Key,
//        updatedByIdKey: Key,
//        enteredDateKey: Key,
//        updatedDateKey: Key
//    ) throws where Key: CodingKey {
//        try container.encode(enteredById, forKey: enteredByIdKey)
//        try container.encode(updatedById, forKey: updatedByIdKey)
//        try container.encode(enteredDate, forKey: enteredDateKey)
//        try container.encode(updatedDate, forKey: updatedDateKey)
//    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        enteredById = try container.decode(Int?.self, forKey: .enteredById)
        updatedById = try container.decode(Int?.self, forKey: .updatedById)

        enteredDate = try container.decode(Date.self, forKey: .enteredDate)
        updatedDate = try container.decode(Date.self, forKey: .updatedDate)

        enteredBy = enteredById.flatMap { AppState.shared.getUserBy(id: $0) } ?? CBUser()
        updatedBy = updatedById.flatMap { AppState.shared.getUserBy(id: $0) } ?? CBUser()
    }
    
//    init<Key>(
//        from container: KeyedDecodingContainer<Key>,
//        enteredByIdKey: Key,
//        updatedByIdKey: Key,
//        enteredDateKey: Key,
//        updatedDateKey: Key
//    ) throws where Key: CodingKey {
//        enteredById = try container.decode(Int?.self, forKey: enteredByIdKey)
//        updatedById = try container.decode(Int?.self, forKey: updatedByIdKey)
//        enteredDate = try container.decode(Date.self, forKey: enteredDateKey)
//        updatedDate = try container.decode(Date.self, forKey: updatedDateKey)
//        enteredBy = enteredById.flatMap { AppState.shared.getUserBy(id: $0) } ?? CBUser()
//        updatedBy = updatedById.flatMap { AppState.shared.getUserBy(id: $0) } ?? CBUser()
//    }
}


extension Auditable {
    var enteredBy: CBUser {
        get { audit.enteredBy }
        set { audit.enteredBy = newValue }
    }
    
    var updatedBy: CBUser {
        get { audit.updatedBy }
        set { audit.updatedBy = newValue }
    }
    
    var enteredById: Int? {
        get { audit.enteredById }
        set { audit.enteredById = newValue }
    }
    
    var updatedById: Int? {
        get { audit.updatedById }
        set { audit.updatedById = newValue }
    }
    
    var enteredDate: Date {
        get { audit.enteredDate }
        set { audit.enteredDate = newValue }
    }
    
    var updatedDate: Date {
        get { audit.updatedDate }
        set { audit.updatedDate = newValue }
    }
    
    func markUpdated(by user: CBUser = AppState.shared.user!) {
        updatedBy = user
        updatedById = user.id
        updatedDate = .now
    }
        
    func setAuditInfo(from other: some Auditable) {
        enteredBy = other.enteredBy
        enteredById = other.enteredById
        enteredDate = other.enteredDate
        updatedBy = other.updatedBy
        updatedById = other.updatedById
        updatedDate = other.updatedDate
    }
}
