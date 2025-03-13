//
//  EventItem.swift
//  MakeItRain
//
//  Created by Cody Burnett on 1/20/25.
//

import Foundation

@Observable
class CBEventItem: Codable, Identifiable, Hashable, Equatable {
    var id: String
    var uuid: String?
    var title: String
    var dateTitle: String?
    var dateValue: Date?
    var textTitle: String?
    var textValue: String?
    var pickerTitle: String?
    var pickerValue: [String]?
    var active: Bool
    var enteredBy: CBUser = AppState.shared.user!
    var updatedBy: CBUser = AppState.shared.user!
    
    var enteredDate: Date
    var updatedDate: Date
    
    var action: EventItemAction
        
    enum CodingKeys: CodingKey { case id, uuid, event_id, title, opt_date_title, opt_date_value, opt_text_title, opt_text_value, opt_picker_title, opt_picker_value, active, entered_by, updated_by, entered_date, updated_date, user_id, account_id, device_uuid, action }
    
    init(uuid: String) {
        self.id = uuid
        self.uuid = uuid
        self.title = ""
        self.active = true
        self.enteredDate = Date()
        self.updatedDate = Date()
        self.action = .add
    }
    
    init() {
        let uuid = UUID().uuidString
        self.id = uuid
        self.uuid = uuid
        self.title = ""
        self.active = true
        self.enteredDate = Date()
        self.updatedDate = Date()
        self.action = .add
    }
    
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(uuid, forKey: .uuid)
        try container.encode(title, forKey: .title)
        try container.encode(dateTitle, forKey: .opt_date_title)
        try container.encode(dateValue?.string(to: .serverDate), forKey: .opt_date_value)
        try container.encode(textTitle, forKey: .opt_text_title)
        try container.encode(textValue, forKey: .opt_text_value)
        try container.encode(pickerTitle, forKey: .opt_picker_title)
        try container.encode(pickerValue, forKey: .opt_picker_value)
        try container.encode(enteredBy, forKey: .entered_by) // for the Transferable protocol
        try container.encode(updatedBy, forKey: .updated_by) // for the Transferable protocol
        try container.encode(enteredDate.string(to: .serverDateTime), forKey: .entered_date) // for the Transferable protocol
        try container.encode(updatedDate.string(to: .serverDateTime), forKey: .updated_date) // for the Transferable protocol
        try container.encode(active ? 1 : 0, forKey: .active)
        try container.encode(AppState.shared.user?.id, forKey: .user_id)
        try container.encode(AppState.shared.user?.accountID, forKey: .account_id)
        try container.encode(AppState.shared.deviceUUID, forKey: .device_uuid)
        try container.encode(action.serverKey, forKey: .action)
    }
        
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try String(container.decode(Int.self, forKey: .id))
        
        title = try container.decode(String.self, forKey: .title)
        dateTitle = try container.decode(String?.self, forKey: .opt_date_title)
        
        let dateValue = try container.decode(String?.self, forKey: .opt_date_value)
        if let dateValue {
            self.dateValue = dateValue.toDateObj(from: .serverDate)!
        }
        
        textTitle = try container.decode(String?.self, forKey: .opt_text_title)
        textValue = try container.decode(String?.self, forKey: .opt_text_value)
        pickerTitle = try container.decode(String?.self, forKey: .opt_picker_title)
        pickerValue = try container.decode(Array<String>?.self, forKey: .opt_picker_value)
        
        enteredBy = try container.decode(CBUser.self, forKey: .entered_by)
        updatedBy = try container.decode(CBUser.self, forKey: .updated_by)
        
        let enteredDate = try container.decode(String?.self, forKey: .entered_date)
        if let enteredDate {
            self.enteredDate = enteredDate.toDateObj(from: .serverDateTime)!
        } else {
            fatalError("Could not determine enteredDate date")
        }
        
        let updatedDate = try container.decode(String?.self, forKey: .updated_date)
        if let updatedDate {
            self.updatedDate = updatedDate.toDateObj(from: .serverDateTime)!
        } else {
            fatalError("Could not determine updatedDate date")
        }
        
        
        let isActive = try container.decode(Int?.self, forKey: .active)
        self.active = isActive == 1 ? true : false
        action = .edit
    }
    
    
    var deepCopy: CBEventItem?
    func deepCopy(_ mode: ShadowCopyAction) {
        switch mode {
        case .create:
            let copy = CBEventItem()
            copy.id = self.id
            copy.uuid = self.uuid
            copy.title = self.title
            copy.dateTitle = self.dateTitle
            copy.dateValue = self.dateValue
            copy.textTitle = self.textTitle
            copy.textValue = self.textValue
            copy.pickerTitle = self.pickerTitle
            copy.pickerValue = self.pickerValue
            copy.active = self.active
            copy.enteredBy = self.enteredBy
            copy.updatedBy = self.updatedBy
            copy.enteredDate = self.enteredDate
            copy.updatedDate = self.updatedDate
            copy.active = self.active
            self.deepCopy = copy
        case .restore:
            if let deepCopy = self.deepCopy {
                self.id = deepCopy.id
                self.uuid = deepCopy.uuid
                self.title = deepCopy.title
                self.dateTitle = deepCopy.dateTitle
                self.dateValue = deepCopy.dateValue
                self.textTitle = deepCopy.textTitle
                self.textValue = deepCopy.textValue
                self.pickerTitle = deepCopy.pickerTitle
                self.pickerValue = deepCopy.pickerValue
                self.active = deepCopy.active
                self.enteredBy = deepCopy.enteredBy
                self.updatedBy = deepCopy.updatedBy
                self.enteredDate = deepCopy.enteredDate
                self.updatedDate = deepCopy.updatedDate
                self.active = deepCopy.active
            }
        case .clear:
            break
        }
    }
    
    
    
    
    static func == (lhs: CBEventItem, rhs: CBEventItem) -> Bool {
        if lhs.id == rhs.id
        && lhs.title == rhs.title
        && lhs.dateTitle == rhs.dateTitle
        && lhs.dateValue == rhs.dateValue
        && lhs.textTitle == rhs.textTitle
        && lhs.textValue == rhs.textValue
        && lhs.pickerTitle == rhs.pickerTitle
        && lhs.pickerValue == rhs.pickerValue
        && lhs.active == rhs.active
        && lhs.enteredBy == rhs.enteredBy
        && lhs.updatedBy == rhs.updatedBy
        && lhs.enteredDate == rhs.enteredDate
        && lhs.updatedDate == rhs.updatedDate
        && lhs.active == rhs.active
        {
            return true
        }
        return false
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    
    func setFromAnotherInstance(item: CBEventItem) {
        //print("SETTING ACTIVE TO \(item.active) for \(item.title)")
        self.id = item.id
        self.title = item.title
        self.dateTitle = item.dateTitle
        self.dateValue = item.dateValue
        self.textTitle = item.textTitle
        self.textValue = item.textValue
        self.pickerTitle = item.pickerTitle
        self.pickerValue = item.pickerValue
        self.active = item.active
        self.enteredBy = item.enteredBy
        self.updatedBy = item.updatedBy
        self.enteredDate = item.enteredDate
        self.updatedDate = item.updatedDate
        self.active = item.active
        self.action = item.action
    }
}
