//
//  LocationModel.swift
//  SearchableMapDemo
//
//  Created by Cody Burnett on 4/10/25.
//

import Foundation
import MapKit
import CoreData
import WidgetKit

@Observable
class CBLocation: Codable, Identifiable, Equatable, Hashable {
    var id: String
    var uuid: String?
    var relatedID: String
    var relatedRecordType: XrefItem
    var title: String
    var lat: Double
    var lon: Double
    var mapItem: MKMapItem?
    var enteredBy: CBUser = AppState.shared.user!
    var updatedBy: CBUser = AppState.shared.user!
    var enteredDate: Date
    var updatedDate: Date
    var identifier: String?
    
    var active: Bool
    var action: LocationAction
    
    var coordinates: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: CLLocationDegrees(floatLiteral: lat), longitude: CLLocationDegrees(floatLiteral: lon))
    }
    
    
    enum CodingKeys: CodingKey { case id, uuid, related_id, related_type_id, title, lat, lon, active, user_id, account_id, device_uuid, entered_by, updated_by, entered_date, updated_date, action, identifier }

                
    init(relatedID: String, locationType: XrefEnum, title: String, mapItem: MKMapItem?) {
        let uuid = UUID().uuidString
        self.id = uuid
        self.uuid = uuid
        self.relatedID = relatedID
        self.relatedRecordType = XrefModel.getItem(from: .locationTypes, byEnumID: locationType)
        self.title = title
        self.mapItem = mapItem
        
        //print(mapItem?.identifier?.rawValue)
        
        self.identifier = mapItem?.identifier?.rawValue
        self.lat = mapItem?.location.coordinate.latitude ?? 0
        self.lon = mapItem?.location.coordinate.longitude ?? 0
        self.active = true
        self.action = .add
        self.enteredBy = AppState.shared.user!
        self.updatedBy = AppState.shared.user!
        self.enteredDate = Date()
        self.updatedDate = Date()
    }
            
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(Int(id), forKey: .id) // This weird Int() thing is for the drag and drop
        try container.encode(relatedID, forKey: .related_id)
        try container.encode(uuid, forKey: .uuid)
        try container.encode(active ? 1 : 0, forKey: .active)
        try container.encode(title, forKey: .title)
        try container.encode(identifier, forKey: .identifier)
        try container.encode(action.serverKey, forKey: .action)
        try container.encode(lat, forKey: .lat)
        try container.encode(lon, forKey: .lon)
        try container.encode(AppState.shared.user?.id, forKey: .user_id)
        try container.encode(AppState.shared.user?.accountID, forKey: .account_id)
        try container.encode(AppState.shared.deviceUUID, forKey: .device_uuid)
        try container.encode(relatedRecordType.id, forKey: .related_type_id)
        try container.encode(enteredBy, forKey: .entered_by) // for the Transferable protocol
        try container.encode(updatedBy, forKey: .updated_by) // for the Transferable protocol
        try container.encode(enteredDate.string(to: .serverDateTime), forKey: .entered_date) // for the Transferable protocol
        try container.encode(updatedDate.string(to: .serverDateTime), forKey: .updated_date) // for the Transferable protocol
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
        
        identifier = try container.decode(String?.self, forKey: .identifier)
        title = try container.decode(String.self, forKey: .title)
        lat = try container.decode(Double.self, forKey: .lat)
        lon = try container.decode(Double.self, forKey: .lon)
        
        //uuid = try container.decode(String.self, forKey: .uuid)
        let active = try container.decode(Int.self, forKey: .active)
        self.active = active == 1 ? true : false
        
        let relatedID = try container.decode(Int.self, forKey: .related_type_id)
        self.relatedRecordType = XrefModel.getItem(from: .locationTypes, byID: relatedID)
        
        action = .edit
        
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
    }
    
    
    
    
    func hasChanges() -> Bool {
        if let deepCopy = deepCopy {
            if self.title == deepCopy.title
            && self.lat == deepCopy.lat
            && self.lon == deepCopy.lon
            && self.identifier == deepCopy.identifier {
                return false
            }
        }
        return true
    }
    
    
    var deepCopy: CBLocation?
    func deepCopy(_ mode: ShadowCopyAction) {
        switch mode {
        case .create:
            let copy = CBLocation(relatedID: self.relatedID, locationType: self.relatedRecordType.enumID, title: self.title, mapItem: self.mapItem)
            copy.id = self.id
            copy.uuid = self.uuid
            copy.title = self.title
            copy.active = self.active
            copy.action = self.action
            copy.identifier = self.identifier
            copy.lat = self.lat
            copy.lon = self.lon
            self.deepCopy = copy
        case .restore:
            if let deepCopy = self.deepCopy {
                self.id = deepCopy.id
                self.uuid = deepCopy.uuid
                self.title = deepCopy.title
                self.mapItem = deepCopy.mapItem
                self.lat = deepCopy.lat
                self.lon = deepCopy.lon
                self.active = deepCopy.active
                self.action = deepCopy.action
                self.identifier = deepCopy.identifier
            }
        case .clear:
            break
        }
    }
    
    
    func setFromAnotherInstance(location: CBLocation) {
        self.id = location.id
        self.uuid = location.uuid
        self.relatedID = location.relatedID
        self.relatedRecordType = location.relatedRecordType
        self.title = location.title
        self.lat = location.lat
        self.lon = location.lon
        self.mapItem = location.mapItem
        self.enteredBy = location.enteredBy
        self.updatedBy = location.updatedBy
        self.enteredDate = location.enteredDate
        self.updatedDate = location.updatedDate
        self.active = location.active
        self.action = location.action
        self.identifier = location.identifier
    }
    
    
    
    
    
    
    
    static func == (lhs: CBLocation, rhs: CBLocation) -> Bool {
        if lhs.id == rhs.id
            && lhs.uuid == rhs.uuid
            && lhs.title == rhs.title
            && lhs.lon == rhs.lon
            && lhs.lat == rhs.lat
            && lhs.active == rhs.active
            && lhs.identifier == rhs.identifier
        {
            return true
        }
        return false
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
