//
//  CBRepTransactionCreateModel.swift
//  MakeItRain
//
//  Created by Cody Burnett on 4/6/26.
//

import Foundation

struct CBRepTransactionCreateModel: Encodable {
    var id: String
    var uuid: String
    var repID: String
    var payMethodID: String?
    var date: Date
    var isPaymentOrigin: Bool = false
    var isTransferOrigin: Bool = false
    var isPaymentDest: Bool = false
    var isTransferDest: Bool = false
    var relatedID: String?
    
    init(
        uuid: String,
        repID: String,
        payMethodID: String?,
        date: Date,
        isPaymentOrigin: Bool = false,
        isPaymentDest: Bool = false,
        isTransferOrigin: Bool = false,
        isTransferDest: Bool = false,
        relatedID: String? = nil
    ) {
        self.id = uuid
        self.uuid = uuid
        self.repID = repID
        self.payMethodID = payMethodID
        self.date = date
        self.isPaymentOrigin = isPaymentOrigin
        self.isTransferOrigin = isTransferOrigin
        self.isPaymentDest = isPaymentDest
        self.isTransferDest = isTransferDest
        self.relatedID = relatedID
    }
    
    enum CodingKeys: CodingKey { case id, uuid, rep_id, pay_method_id, date, is_payment_origin, is_payment_dest, is_transfer_origin, is_transfer_dest, related_id }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(uuid, forKey: .uuid)
        try container.encode(repID, forKey: .rep_id)
        try container.encode(payMethodID, forKey: .pay_method_id)
        try container.encode(date.string(to: .serverDate), forKey: .date)
        try container.encode(isPaymentOrigin ? 1 : 0, forKey: .is_payment_origin)
        try container.encode(isPaymentDest ? 1 : 0, forKey: .is_payment_dest)
        try container.encode(isTransferOrigin ? 1 : 0, forKey: .is_transfer_origin)
        try container.encode(isTransferDest ? 1 : 0, forKey: .is_transfer_dest)
        try container.encode(relatedID, forKey: .related_id)
    }
}


