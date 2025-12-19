////
////  CBPaymentMethodHolder.swift
////  MakeItRain
////
////  Created by Cody Burnett on 11/25/25.
////
//
//
//import Foundation
//import SwiftUI
//
//@Observable
//class CBPaymentMethodHolder: Codable, Identifiable, Hashable, Equatable {
//    var id: String
//    var uuid: String?
//    var user: CBUser?
//    var payMethod: CBPaymentMethod
//    var holderType: XrefItem?
//    var active: Bool
//    var enteredBy: CBUser = AppState.shared.user ?? CBUser()
//    var updatedBy: CBUser = AppState.shared.user ?? CBUser()
//    var enteredDate: Date
//    var updatedDate: Date
//            
//    enum CodingKeys: CodingKey { case id, uuid, holder_user_id, holder_type_id, payment_method, user_id, account_id, device_uuid, active, entered_by, updated_by, entered_date, updated_date }
//    
//    
//    init() {
//        let uuid = UUID().uuidString
//        self.id = uuid
//        self.uuid = uuid
//        self.payMethod = CBPaymentMethod()
//        self.active = true
//        self.enteredDate = Date()
//        self.updatedDate = Date()
//    }
//    
//    init(payMethod: CBPaymentMethod) {
//        let uuid = UUID().uuidString
//        self.id = uuid
//        self.uuid = uuid
//        self.payMethod = payMethod
//        self.user = AppState.shared.user!
//        self.holderType = XrefModel.getItem(from: .paymentMethodHolderTypes, byEnumID: .primary)
//        self.active = true
//        self.enteredDate = Date()
//        self.updatedDate = Date()
//    }
//    
//    func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(id, forKey: .id)
//        try container.encode(uuid, forKey: .uuid)
//        try container.encode(user, forKey: .holder_user_id)
//        try container.encode(payMethod, forKey: .payment_method)
//        try container.encode(holderType?.id, forKey: .holder_type_id)
//        try container.encode(enteredBy, forKey: .entered_by)
//        try container.encode(updatedBy, forKey: .updated_by)
//        try container.encode(enteredDate.string(to: .serverDateTime), forKey: .entered_date)
//        try container.encode(updatedDate.string(to: .serverDateTime), forKey: .updated_date)
//        try container.encode(AppState.shared.user?.id, forKey: .user_id)
//        try container.encode(AppState.shared.user?.accountID, forKey: .account_id)
//        try container.encode(AppState.shared.deviceUUID, forKey: .device_uuid)
//    }
//    
//    
//    required init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        do {
//            id = try String(container.decode(Int.self, forKey: .id))
//        } catch {
//            id = try container.decode(String.self, forKey: .id)
//        }
//        self.payMethod = try container.decode(CBPaymentMethod.self, forKey: .payment_method)
//        let isActive = try container.decode(Int?.self, forKey: .active)
//        self.active = isActive == 1 ? true : false
//        
//        self.enteredBy = try container.decode(CBUser.self, forKey: .entered_by)
//        self.updatedBy = try container.decode(CBUser.self, forKey: .updated_by)
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
//    }
//    
//    
//    
//    func hasChanges() -> Bool {
//        if let deepCopy = deepCopy {
//            if self.payMethod == deepCopy.payMethod
//                && self.active == deepCopy.active
//                && self.holderType == deepCopy.holderType
//            {
//                return false
//            }
//        }
//        return true
//    }
//    
//    
//    var deepCopy: CBPaymentMethodHolder?
//    func deepCopy(_ mode: ShadowCopyAction) {
//        switch mode {
//        case .create:
//            let copy = CBPaymentMethodHolder()
//            copy.id = self.id
//            copy.payMethod = self.payMethod
//            copy.active = self.active
//            copy.holderType = self.holderType
//            self.deepCopy = copy
//        case .restore:
//            if let deepCopy = self.deepCopy {
//                self.payMethod = deepCopy.payMethod
//                self.holderType = deepCopy.holderType
//                self.active = deepCopy.active
//            }
//        case .clear:
//            break
//        }
//    }
//    
//    
//    
//    
//    static func == (lhs: CBPaymentMethodHolder, rhs: CBPaymentMethodHolder) -> Bool {
//        if lhs.id == rhs.id
//            && lhs.payMethod == rhs.payMethod
//            && lhs.holderType == rhs.holderType
//            && lhs.active == rhs.active
//        {
//            return true
//        }
//        return false
//    }
//    
//    
//    func setFromAnotherInstance(startingAmount: CBPaymentMethodHolder) {
//        self.payMethod = startingAmount.payMethod
//    }
//    
//    
//    
//    func hash(into hasher: inout Hasher) {
//        hasher.combine(id)
//    }
//}
