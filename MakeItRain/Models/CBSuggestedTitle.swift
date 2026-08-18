//
//  CBSuggestedTitle.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/31/25.
//

import Foundation
import MapKit

struct CBSuggestedTitle: Decodable, Identifiable {
    var id: UUID
    var title: String
    var transactionCount: Int
    
    enum CodingKeys: CodingKey { case title, transaction_count }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        title = try container.decode(String.self, forKey: .title)
        transactionCount = try container.decode(Int.self, forKey: .transaction_count)
    }
}


struct CBSuggestedLocation: Decodable, Identifiable {
    var id: UUID
    var transTitle: String
    var locationTitle: String
    var identifier: String?
    var lat: Double
    var lon: Double
    var mapItem: MKMapItem?
    var locationCount: Int
    
    var coordinates: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: CLLocationDegrees(floatLiteral: lat), longitude: CLLocationDegrees(floatLiteral: lon))
    }
    
    enum CodingKeys: CodingKey { case trans_title, location_title, identifier, lat, lon, location_count }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        transTitle = try container.decode(String.self, forKey: .trans_title)
        locationTitle = try container.decode(String.self, forKey: .location_title)
        identifier = try container.decode(String?.self, forKey: .identifier)
        lat = try container.decode(Double.self, forKey: .lat)
        lon = try container.decode(Double.self, forKey: .lon)
        locationCount = try container.decode(Int.self, forKey: .location_count)
    }
}
