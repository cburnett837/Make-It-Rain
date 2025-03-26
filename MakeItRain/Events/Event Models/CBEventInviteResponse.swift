//
//  CBEventInviteResponse.swift
//  MakeItRain
//
//  Created by Cody Burnett on 3/26/25.
//


import Foundation
import SwiftUI

struct CBEventInviteResponse: Encodable {
    var id: String
    var uuid: String?
    var participantID: String
    var eventID: String
    var isAccepted: Bool = false

    init(eventID: String, participantID: String, isAccepted: Bool) {
        let uuid = UUID().uuidString
        self.id = uuid
        self.uuid = uuid
        self.eventID = eventID
        self.participantID = participantID
        self.isAccepted = isAccepted
    }

    enum CodingKeys: CodingKey { case id, uuid, event_id, participant_id, user_id, account_id, device_uuid, is_accepted }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(uuid, forKey: .uuid)
        try container.encode(participantID, forKey: .participant_id)
        try container.encode(eventID, forKey: .event_id)

        try container.encode(AppState.shared.user?.id, forKey: .user_id)
        try container.encode(AppState.shared.user?.accountID, forKey: .account_id)
        try container.encode(AppState.shared.deviceUUID, forKey: .device_uuid)
        try container.encode(isAccepted ? 1 : 0, forKey: .is_accepted)
    }
}