//
//  StandardMiniMap.swift
//  MakeItRain
//
//  Created by Cody Burnett on 4/11/25.
//

import SwiftUI
import MapKit

struct StandardMiniMapContainerWithStatePosition: View {
    @State private var locationManager = LocationManager.shared
    
    @State private var mapModel = MapModel()
    @State private var position: MapCameraPosition = .userLocation(followsHeading: false, fallback: .userLocation(fallback: .automatic))

    @Binding var locations: [CBLocation]
    var parent: CanHandleLocationsDelegate
    var parentID: String
    var parentType: XrefEnum
    var addCurrentLocation: Bool
    var openBigMapOnTap: Bool = true
    
    var body: some View {
        StandardMiniMap(locations: $locations, parent: parent, parentID: parentID, parentType: parentType, addCurrentLocation: addCurrentLocation, openBigMapOnTap: openBigMapOnTap)
            .onChange(of: mapModel.position) { self.position = $1 }
            .environment(mapModel)
            /// Example:
            ///`EventTransactionOptionView` will own the map model, and control the minimap and full map inside.
            /// Since this minimap can be created in a loop, it has to have it's own model and state. So when the locations change, change the position of this isolated minimap.
            .onChange(of: locations) {
                focusOnFirst(locations: locations)
            }
    }
    
    func focusOnFirst(locations: [CBLocation]) {
        let filteredLocations = locations.filter { $0.active }
        
        if let lat = filteredLocations.first?.lat, let lon = filteredLocations.first?.lon {
            let viewCord = CLLocationCoordinate2D(latitude: CLLocationDegrees(floatLiteral: lat), longitude: CLLocationDegrees(floatLiteral: lon))
            let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            let region = MKCoordinateRegion(center: viewCord, span: span)
            mapModel.position = .region(region)
            mapModel.visibleRegion = region
        }
    }
}

struct StandardMiniMap: View {
    @Environment(MapModel.self) private var mapModel
    @State private var locationManager = LocationManager.shared
        
    @Binding var locations: [CBLocation]
    var parent: CanHandleLocationsDelegate
    var parentID: String
    var parentType: XrefEnum
    var addCurrentLocation: Bool
    var openBigMapOnTap: Bool = true
    
    @State private var showFullMap = false
        
    var body: some View {
        @Bindable var mapModel = mapModel
        Map(position: $mapModel.position, interactionModes: []) {
            UserAnnotation()
            /// Show search results.
            ForEach(locations.filter { $0.active }) { result in
                Marker(result.title, systemImage: "heart", coordinate: result.coordinates)
                    .tag(MapSelection(result))
                    .tint(.orange)
            }
        }
        
        /// Fix for iOS 26 not being able to touch the map directly.
        .overlay { Color.gray.opacity(0.01) }
        
        .task {
            /// Create a map item for each CBLocation.
            for loc in locations {
                if loc.mapItem == nil {
                    loc.mapItem = await mapModel.createMapItem(for: loc)
                    //loc.mapItem = await mapModel.createMapItemFrom(coordinates: loc.coordinates)
                }
            }
            
            /// There is no location set, focus on the user position and create a location from there.
            if locations.isEmpty {
                if let coordinate = LocationManager.shared.currentLocation {
                    let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    let region = MKCoordinateRegion(center: coordinate, span: span)
                    mapModel.visibleRegion = region
                }
                
                mapModel.position = .userLocation(followsHeading: false, fallback: .userLocation(fallback: .automatic))
                
                
                if addCurrentLocation {
                    print("should add current location to parent")
                    if let location = await mapModel.saveCurrentLocation(parentID: parentID, parentType: parentType) {
                        parent.upsert(location)
                        focusOnFirst(locations: parent.locations)
                    }
                }
            } else {
                print("setting camera to current location")
                /// Set the camera to the first location in the list when opening the map.
                focusOnFirst(locations: locations)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 150)
        .if(openBigMapOnTap) {
            $0.onTapGesture {
                showFullMap = true
            }
        }
        
        .onDisappear {
            mapModel.completions.removeAll()
        }
        #if os(iOS)
        .fullScreenCover(isPresented: $showFullMap, onDismiss: {
            /// Set the camera to the first location in the list when opening the map.
            mapModel.focusOnFirst(locations: locations)
        }) {
            StandardMapView(locations: $locations, parent: parent, parentID: parentID, parentType: parentType)
        }
        #endif
//        #else
//        .sheet(isPresented: $showFullMap, onDismiss: {
//            /// Set the camera to the first location in the list when opening the map.
//            mapModel.focusOnFirst(locations: locations)
//        }) {
//            StandardMapView(locations: $locations, parent: parent, parentID: parentID, parentType: parentType)
//        }
//        #endif
    }
    
    func focusOnFirst(locations: [CBLocation]) {
        let filteredLocations = locations.filter { $0.active }
        
        if let lat = filteredLocations.first?.lat, let lon = filteredLocations.first?.lon {
            let viewCord = CLLocationCoordinate2D(latitude: CLLocationDegrees(floatLiteral: lat), longitude: CLLocationDegrees(floatLiteral: lon))
            let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            let region = MKCoordinateRegion(center: viewCord, span: span)
            mapModel.position = .region(region)
            mapModel.visibleRegion = region
        }
    }
}
