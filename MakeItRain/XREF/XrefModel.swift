//
//  XrefModel.swift
//  MakeItRain
//
//  Created by Cody Burnett on 1/22/25.
//

import Foundation

enum RefType {
    case eventTransactionStatuses, relatedTransactionType, photoTypes, eventInviteStatus
}

enum XrefEnum {
    case pending, claimed, transaction, eventTransaction, accepted, rejected
}

struct XrefItem: Identifiable, Equatable {
    let id: Int
    let refType: String
    let description: String
    let enumID: XrefEnum
    
    static func == (lhs: XrefItem, rhs: XrefItem) -> Bool {
        if lhs.id == rhs.id
        && lhs.refType == rhs.refType
        && lhs.description == rhs.description
        && lhs.enumID == rhs.enumID {
            return true
        }
        return false
    }
}

struct XrefModel {
    static let eventTransactionStatuses: Array<XrefItem> = [
        XrefItem(id: 1, refType: "event_transaction_status", description: "Pending", enumID: .pending),
        XrefItem(id: 2, refType: "event_transaction_status", description: "Claimed", enumID: .claimed)
    ]
    
    
    static let relatedTransactionType: Array<XrefItem> = [
        XrefItem(id: 3, refType: "related_transaction_type", description: "Transaction", enumID: .transaction),
        XrefItem(id: 4, refType: "related_transaction_type", description: "Event Transaction", enumID: .eventTransaction)
    ]
    
    static let photoTypes: Array<XrefItem> = [
        XrefItem(id: 5, refType: "photo_type", description: "Transaction", enumID: .transaction),
        XrefItem(id: 6, refType: "photo_type", description: "Event Transaction", enumID: .eventTransaction)
    ]
    
    static let eventInviteStatue: Array<XrefItem> = [
        XrefItem(id: 7, refType: "event_invite_status", description: "Pending", enumID: .pending),
        XrefItem(id: 8, refType: "event_invite_status", description: "Accepted", enumID: .accepted),
        XrefItem(id: 9, refType: "event_invite_status", description: "Rejected", enumID: .rejected)
    ]
    
    static func getItems(forRefType refType: RefType) -> Array<XrefItem> {
        switch refType {
        case .eventTransactionStatuses:
            return eventTransactionStatuses
        case .relatedTransactionType:
            return relatedTransactionType
        case .photoTypes:
            return photoTypes
        case .eventInviteStatus:
            return eventInviteStatue
        }
    }
    
    
    static func getItem(from refType: RefType, byID id: Int) -> XrefItem {
        let items = self.getItems(forRefType: refType)
        return items.filter { $0.id == id }.first!
    }
    
    static func getItem(from refType: RefType, byEnumID enumID: XrefEnum) -> XrefItem {
        let items = self.getItems(forRefType: refType)
        return items.filter { $0.enumID == enumID }.first!
    }
}
