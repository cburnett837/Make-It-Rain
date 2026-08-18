//
//  StandardMiniMap.swift
//  MakeItRain
//
//  Created by Cody Burnett on 4/11/25.
//

import SwiftUI
import MapKit
import WeatherKit

import CoreLocation

extension CLLocationCoordinate2D: @retroactive Equatable {
    public static func == (
        lhs: CLLocationCoordinate2D,
        rhs: CLLocationCoordinate2D
    ) -> Bool {
        lhs.latitude == rhs.latitude &&
        lhs.longitude == rhs.longitude
    }
}

struct StandardMiniMapContainerWithStatePosition: View {
    @State private var locationManager = LocationManager.shared
    
    @State private var mapModel = MapModel()
    @State private var position: MapCameraPosition = .userLocation(followsHeading: false, fallback: .userLocation(fallback: .automatic))

    @Binding var locations: [CBLocation]
    var parent: CanHandleLocationsDelegate
    var parentID: String
    var parentType: XrefLocationType
    var addCurrentLocation: Bool
    var openBigMapOnTap: Bool = true
    
    var body: some View {
        StandardMiniMap(
            locations: $locations,
            parent: parent,
            parentID: parentID,
            parentType: parentType,
            addCurrentLocation: addCurrentLocation,
            openBigMapOnTap: openBigMapOnTap
        )
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
    var parentType: XrefLocationType
    var addCurrentLocation: Bool
    var openBigMapOnTap: Bool = true
    
    @State private var showFullMap = false
    @State private var currentWeather: CurrentWeather?
        
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
        .overlay(weatherBlurbView)
        /// Fix for iOS 26 not being able to touch the map directly.
        .overlay(Color.gray.opacity(0.01))
        .task {
            await prepareMap()
        }
        .frame(maxWidth: .infinity)
        .frame(height: 150)
        .if(openBigMapOnTap) {
            $0.onTapGesture {
                showFullMap = true
            }
        }
        .onChange(of: locationManager.currentLocation) {
            Task {
                await getWeatherForLocation()
            }
        }
        .onChange(of: locations.map({ $0.mapItem?.identifier })) {
            Task {
                await getWeatherForLocation()
            }
        }
        .onDisappear {
            mapModel.completions.removeAll()
        }
        #if os(iOS)
        .fullScreenCover(isPresented: $showFullMap, onDismiss: {
            /// Set the camera to the first location in the list when closing the map.
            mapModel.focusOnFirst(locations: locations)
        }) {
            StandardMapView(locations: $locations, parent: parent, parentID: parentID, parentType: parentType)
        }
        #endif
    }
    
    var weatherBlurbView: some View {
        Group {
            if let current = currentWeather {
                HStack {
                    Image(systemName: current.symbolName)
                    Text(current.temperature.formatted(
                        .measurement(
                            width: .abbreviated,
                            usage: .weather,
                            numberFormatStyle: .number.precision(.fractionLength(0))
                        )
                    ))
                }
            } else {
                Text("Fetching weather…")
            }
        }
        .padding(5)
        .glassEffect()
        //.background(.thickMaterial, in: .capsule)
        .font(.caption2)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        .padding(5)
        .padding(.trailing, 6)
    }
    
    
    func prepareMap() async {
        /// Create a map item for each CBLocation.
        for loc in locations {
            if loc.mapItem == nil {
                loc.mapItem = await mapModel.createMapItem(for: loc)
                //loc.mapItem = await mapModel.createMapItemFrom(coordinates: loc.coordinates)
            }
        }
        
        /// There is no location set, focus on the user position and create a location from there.
        if locations.isEmpty {
            if let coordinate = locationManager.currentLocation {
                let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                let region = MKCoordinateRegion(center: coordinate, span: span)
                mapModel.visibleRegion = region
            }
            
            mapModel.position = .userLocation(followsHeading: false, fallback: .userLocation(fallback: .automatic))
        
            if addCurrentLocation {
                //print("should add current location to parent")
                if let location = await mapModel.saveCurrentLocation(parentID: parentID, parentType: parentType) {
                    parent.upsert(location)
                    focusOnFirst(locations: parent.locations)
                }
            }
            
            await getWeatherForCurrentLocation()
        } else {
            /// Set the camera to the first location in the list when opening the map.
            focusOnFirst(locations: locations)
            await getWeatherForLocation()
        }
    }
    
    func focusOnFirst(locations: [CBLocation]) {
        //print("setting camera to first location in array")
        let filteredLocations = locations.filter { $0.active }
        
        if let lat = filteredLocations.first?.lat,
           let lon = filteredLocations.first?.lon {
            let viewCord = CLLocationCoordinate2D(latitude: CLLocationDegrees(floatLiteral: lat), longitude: CLLocationDegrees(floatLiteral: lon))
            let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            let region = MKCoordinateRegion(center: viewCord, span: span)
            mapModel.position = .region(region)
            mapModel.visibleRegion = region
        }
    }
    
    func getWeatherForLocation() async {
        if let location = locations.filter({ $0.active }).first?.mapItem?.location {
            do {
                self.currentWeather = try await getWeather(for: location)
            } catch {
                print(error.localizedDescription)
            }
        } else {
            print("Could not determine map item")
        }
    }
    
    func getWeatherForCurrentLocation() async {
        if let lat = locationManager.currentLocation?.latitude,
           let lon = locationManager.currentLocation?.longitude {
            let location = CLLocation(latitude: lat, longitude: lon)
            
            do {
                self.currentWeather = try await getWeather(for: location)
            } catch {
                print(error.localizedDescription)
            }
        } else {
            print("Location data not available")
        }
    }
    
    func getWeather(for location: CLLocation) async throws -> CurrentWeather {
        let weather = try await WeatherService.shared.weather(for: location, including: .current)
        return weather
    }
}

