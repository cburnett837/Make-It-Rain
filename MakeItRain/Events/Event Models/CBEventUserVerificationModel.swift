//
//  CBEventUserVerificationModel.swift
//  MakeItRain
//
//  Created by Cody Burnett on 3/26/25.
//


import Foundation
import SwiftUI

struct CBEventUserVerificationModel: Decodable {
    var verificationResult: InvitationVerificationResult
    var user: CBUser?
    var participant: CBEventParticipant?
    
    
    enum CodingKeys: CodingKey { case result, user, participant }
    
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let result = try container.decode(String.self, forKey: .result)
        self.verificationResult = InvitationVerificationResult.fromString(result)
        
        user = try container.decode(CBUser?.self, forKey: .user)
        participant = try container.decode(CBEventParticipant?.self, forKey: .participant)
    }
}
