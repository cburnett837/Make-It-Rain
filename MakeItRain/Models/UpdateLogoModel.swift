//
//  UpdateLogoModel.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/27/25.
//

import Foundation

class UpdateLogoModel: Encodable {
    var parentID: String?
    var parentType: XrefEnum?
    var logoString: String?
    //var hasPaymentMethodsExisiting: Bool = false
    
    enum CodingKeys: CodingKey { case parent_id, parent_type, logo_string, user_id, account_id, device_uuid }
    
    init(parentID: String?, parentType: XrefEnum, logoString: String) {
        self.parentID = parentID
        self.parentType = parentType
        self.logoString = logoString
    }
        
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(parentID, forKey: .parent_id)
        try container.encode(parentType?.rawValue, forKey: .parent_type)
        try container.encode(logoString, forKey: .logo_string)
        try container.encode(AppState.shared.user?.id, forKey: .user_id)
        try container.encode(AppState.shared.user?.accountID, forKey: .account_id)
        try container.encode(AppState.shared.deviceUUID, forKey: .device_uuid)

    }
}
