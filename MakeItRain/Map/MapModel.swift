//
//  Model.swift
//  SearchableMapDemo
//
//  Created by Cody Burnett on 4/10/25.
//


import Foundation
import MapKit
import SwiftUI

@Observable
@MainActor
class MapModel: NSObject {
    var locationManager = LocationManager.shared
    var position: MapCameraPosition = .userLocation(followsHeading: false, fallback: .userLocation(fallback: .automatic))
    var modes: MapInteractionModes = [.all]
    
    private let completer = MKLocalSearchCompleter()
    var completions: [MKLocalSearchCompletion] = []
    
    var recentQueries: Array<String> = []
    var searchQuery: String = ""
    var searchResults: [CBLocation] = []
    var visibleRegion: MKCoordinateRegion?
    var selection:  MapSelection<CBLocation>?
    var selectedMapItem: CBLocation?
    var didTouchAndHold = false
    
    private var currentSearch: MKLocalSearch?
    var route: MKRoute?
    var isCalculatingRoute = false
    
    var blockCompletion = false
    
    var lastSearchQuery: String = ""
    
    var showSearchSuggestions = false
    var panelContent: MapBottomPanelContent?
    
    private let defaultRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.83657722488077, longitude: 14.306896671048852),
        span: MKCoordinateSpan(latitudeDelta: 0.0125, longitudeDelta: 0.0125)
    )
    
    override init() {
        super.init()        
        completer.delegate = self
        
        let userDefaults = UserDefaultsManager<String>(file: .mapSearches)
        if let recentQueries = userDefaults.loadMany() {
            self.recentQueries = recentQueries
        }
    }
    
    
    func getAutoCompletions(for text: String) {
        if blockCompletion {
            blockCompletion = false
        } else {
            completer.queryFragment = text
            completer.resultTypes = [.address, .pointOfInterest]
            completer.region = visibleRegion ?? defaultRegion
        }
    }
    
    
    func addQueryToRecents() {
        
        if let index = recentQueries.firstIndex(of: searchQuery) {
            recentQueries.remove(at: index)
        }
        
        if recentQueries.count > 5 {
            recentQueries.removeFirst()
        }
        if !searchQuery.isEmpty {
            recentQueries.append(searchQuery)
        }
        
        let userDefaults = UserDefaultsManager<String>(file: .mapSearches)
        userDefaults.saveMany(recentQueries)
    }
    
    
    func search(parentID: String, parentType: XrefEnum, useLastQuery: Bool = false) {
        // If there's another search already// in progress, cancel it.
        currentSearch?.cancel()
        
        if !useLastQuery {
            lastSearchQuery = searchQuery
        }
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = useLastQuery ? lastSearchQuery : searchQuery
        request.resultTypes = [.address, .pointOfInterest]
        request.region = visibleRegion ?? defaultRegion
        
        Task {
            let search = MKLocalSearch(request: request)
            
            currentSearch = search
            defer {
                // After the search completes, the reference is no longer needed.
                currentSearch = nil
            }
            
            let response = try? await search.start()
            searchResults = response?.mapItems.map { CBLocation(relatedID: parentID, locationType: parentType, title: $0.name ?? "N/A", mapItem: $0) } ?? []
            //searchResults = response?.mapItems ?? []
            position = .region(request.region)
        }
    }
    
    
    func getMapItem(from localSearchCompletion: MKLocalSearchCompletion, parentID: String, parentType: XrefEnum) async -> CBLocation? {
        completions.removeAll()
        let request = MKLocalSearch.Request(completion: localSearchCompletion)
        let search = MKLocalSearch(request: request)
                
        let response = try? await search.start()
        let mapItems = response?.mapItems ?? []
        if mapItems.count > 0 {
            #if os(iOS)
                let viewCord = CLLocationCoordinate2D(
                    latitude: mapItems[0].location.coordinate.latitude/* - 0.004*/,
                    longitude: mapItems[0].location.coordinate.longitude
                )
            #else
                let viewCord = CLLocationCoordinate2D(
                    latitude: mapItems[0].placemark.coordinate.latitude/* - 0.004*/,
                    longitude: mapItems[0].placemark.coordinate.longitude
                )
            #endif
            let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            let region = MKCoordinateRegion(center: viewCord, span: span)
            
            let location = CBLocation(relatedID: parentID, locationType: parentType, title: mapItems[0].name ?? "N/A", mapItem: mapItems[0])
            
            
            
            print("Setting map selection")
            selection = MapSelection(location)
            //searchResults = [mapItems[0]]
            //searchResults = [location]
            withAnimation { position = .region(region) }
            return location
        }
        return nil
    }
    
    
    func addLocationViaTouchAndHold(coordinate: CLLocationCoordinate2D, parentID: String, parentType: XrefEnum) async -> CBLocation? {
        print("-- \(#function)")
        searchResults.removeAll()
        
        #if os(iOS)
        do {
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            
            if let request = MKReverseGeocodingRequest(location: location) {
                let mapItems = try await request.mapItems
                let item = mapItems.first!
                let cbLocation = CBLocation(relatedID: parentID, locationType: parentType, title: item.name ?? "N/A", mapItem: item)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation {
                        self.selection = MapSelection(cbLocation)
                        self.panelContent = .details
                    }
                }
                
                return cbLocation
            } else {
                return nil
            }
        } catch {
            print(error.localizedDescription)
            return nil
        }
        #else
        do {
            let geocoder = CLGeocoder()
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if !placemarks.isEmpty {
                let mkPlaceMark = MKPlacemark(placemark: placemarks.first!)
                let item = MKMapItem(placemark: mkPlaceMark)
                let location = CBLocation(relatedID: parentID, locationType: parentType, title: item.name ?? "N/A", mapItem: item)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation {
                        self.selection = MapSelection(location)
                        self.panelContent = .details
                    }
                }
                
                return location
            } else {
                return nil
            }
        } catch {
            print(error.localizedDescription)
            return nil
        }
        #endif
        
                
        
    
    }
    
    
    func createMapItemFrom(coordinates: CLLocationCoordinate2D) async -> MKMapItem? {
        #if os(iOS)
        do {
            let location = CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)
            if let request = MKReverseGeocodingRequest(location: location) {
                let mapItems = try await request.mapItems
                return mapItems.first!
            } else {
                print("Cant make map item")
                return nil
            }
        } catch {
            print("Cant make map item")
            print(error.localizedDescription)
            return nil
        }
        #else
        do {
            let geocoder = CLGeocoder()
            let location = CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if !placemarks.isEmpty {
                let mkPlaceMark = MKPlacemark(placemark: placemarks.first!)
                let item = MKMapItem(placemark: mkPlaceMark)
                return item
                
            } else {
                print("Cant make map item")
                return nil
            }
        } catch {
            print("Cant make map item")
            print(error.localizedDescription)
            return nil
        }
        #endif
    }
    
    
    func createMapItem(for location: CBLocation) async -> MKMapItem? {
        if let savedIdentifier = location.identifier, let identifier = MKMapItem.Identifier(rawValue: savedIdentifier) {
            let request = MKMapItemRequest(mapItemIdentifier: identifier)
            do {
                let mapItem: MKMapItem? = try await request.mapItem
                return mapItem
            } catch {
                print(error.localizedDescription)
            }
        }
        return await createMapItemFrom(coordinates: location.coordinates)
    }
    
    
    func updateWithSelectedFeature(_ selection: MapSelection<CBLocation>?, parentID: String, parentType: XrefEnum) {
        if let mapItem = selection?.value?.mapItem {
            print("Getting SelectedMapItem via value")
            print(mapItem)
            // The person has selected an annotation, such as a search result.
            withAnimation {
                //let location = CBLocation(id: UUID().uuidString, name: mapItem.name ?? "N/A", mapItem: mapItem)
                selectedMapItem = selection?.value
                getDirection()
                panelContent = .details
            }
            
        } else if let feature = selection?.feature {
            #if os(iOS)
            // The person has selected a map feature, such as a point of interest. Because the map feature doesn't contain the
            // details as an `MKMapItem`, request a map item for the feature.
            Task {
                let request = MKMapItemRequest(feature: feature)
                do {
                    let mapItem: MKMapItem? = try await request.mapItem
                    print("Getting SelectedMapItem via feature")
                    //print(mapItem)
                    withAnimation {
                        
                        let location = CBLocation(relatedID: parentID, locationType: parentType, title: mapItem?.name ?? "N/A", mapItem: mapItem)
                        selectedMapItem = location
                        getDirection()
                        panelContent = .details
                    }
                } catch {
                    print(error.localizedDescription)
                }
            }
            #endif
        } else {
            print("Setting SelectedMapItem to nil")
            withAnimation {
                route = nil
                selectedMapItem = nil
                panelContent = nil
            }
        }
    }
    
            
    func saveCurrentLocation(parentID: String, parentType: XrefEnum) async -> CBLocation? {
        #if os(iOS)
        if let coordinate = LocationManager.shared.currentLocation {
            do {
                let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                if let request = MKReverseGeocodingRequest(location: location) {
                    let mapItems = try await request.mapItems
                    let item = mapItems.first!
                    let location = CBLocation(relatedID: parentID, locationType: parentType, title: item.name ?? "N/A", mapItem: item)
                    return location
                } else {
                    return nil
                }
            } catch {
                print(error.localizedDescription)
                return nil
            }
        } else {
            return nil
        }
        #else
        if let coordinate = LocationManager.shared.currentLocation {
            do {
                let geocoder = CLGeocoder()
                let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                let placemarks = try await geocoder.reverseGeocodeLocation(location)
                if !placemarks.isEmpty {
                    let mkPlaceMark = MKPlacemark(placemark: placemarks.first!)
                    let item = MKMapItem(placemark: mkPlaceMark)
                    let location = CBLocation(relatedID: parentID, locationType: parentType, title: item.name ?? "N/A", mapItem: item)
                                    
                    return location
                } else {
                    return nil
                }
            } catch {
                print(error.localizedDescription)
                return nil
            }
        } else {
            return nil
        }
        #endif
    }
    
    
    func focusOnFirst(locations: [CBLocation]) {
        let filteredLocations = locations.filter { $0.active }
        
        if let lat = filteredLocations.first?.lat, let lon = filteredLocations.first?.lon {
            let viewCord = CLLocationCoordinate2D(latitude: CLLocationDegrees(floatLiteral: lat), longitude: CLLocationDegrees(floatLiteral: lon))
            let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            let region = MKCoordinateRegion(center: viewCord, span: span)
            position = .region(region)
        }
    }
    
    
    var travelTime: String? {
        guard let route else { return nil }
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.hour, .minute]
        return formatter.string(from: route.expectedTravelTime)
        
    }
    
    
    func getDirection() {
        print("-- \(#function)")
        isCalculatingRoute = true
        route = nil
        guard let selectedMapItem else {
            print("SELECTION IS NIL")
            return
        }
        let request = MKDirections.Request()
        request.source = .forCurrentLocation()
        request.destination = selectedMapItem.mapItem
        
        Task {
            let directions = MKDirections(request: request)
            let response = try? await directions.calculate()
            route = response?.routes.first
            isCalculatingRoute = false
        }
    }
    
    
    func distance(meters: Double) -> String {
        let userLocale = Locale.current
        let formatter = MeasurementFormatter()
        var options: MeasurementFormatter.UnitOptions = []
        options.insert(.providedUnit)
        options.insert(.naturalScale)
        formatter.unitOptions = options
        let meterValue = Measurement(value: round(meters), unit: UnitLength.meters)
        let yardsValue = Measurement(value: round(meters), unit: UnitLength.yards)
        
        let distance = formatter.string(from: userLocale.measurementSystem == .metric ? meterValue : yardsValue)
        
        return distance
    }
    
    
    
//    func saveToServer(location: CBLocation) {
//        withAnimation {
//            savedResults.append(location)
//            #warning("prompt to rename")
//            //item.name = "Hey"
//            //print("Saving Name: \(item.placemark.name)")
//            print("Saving lat: \(location.mapItem?.placemark.coordinate.latitude)")
//            print("Saving lon: \(location.mapItem?.placemark.coordinate.longitude)")
//        }
//    }
}


extension MapModel: MKLocalSearchCompleterDelegate {
    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        Task { @MainActor in
            completions = completer.results.filter { $0.subtitle.contains("United States") }
        }
        
    }
    
    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Error: \(error.localizedDescription)")
    }
    
}



extension MKLocalSearchCompletion {
    
    /**
     Each `MKLocalSearchCompletion` contains a title and a subtitle, as well as ranges describing what part of the title or
     subtitle match the current query string. Use the ranges to apply helpful highlighting of the text in the completion suggestion
     that matches the current query fragment.
     */
    /// - Tag: HighlightFragment
    private func createHighlightedString(text: String, rangeValues: [NSValue], hilightColor: Color) -> NSAttributedString {
        #if os(iOS)
        //let attributes = [NSAttributedString.Key.foregroundColor: UIColor(named: "suggestionHighlight")!/*.withAlphaComponent(0.5)*/]
        let attributes = [NSAttributedString.Key.foregroundColor:  UIColor(hilightColor)/*.withAlphaComponent(0.5)*/]
        #endif
        let highlightedString = NSMutableAttributedString(string: text)
        
    #if os(iOS)
        // Each `NSValue` wraps an `NSRange` that functions as a style attribute's range with `NSAttributedString`.
        let ranges = rangeValues.map { $0.rangeValue }
                        
        for range in ranges where range.location != NSNotFound {
            if range.location + range.length <= highlightedString.length {
                highlightedString.addAttributes(attributes, range: range)
            } else {
                print("⚠️ Skipping invalid range: \(range) for text: '\(text)' (\(highlightedString.length) chars)")
            }
        }
        #endif

        return highlightedString
    }
    
    var highlightedTitleStringForDisplay: NSAttributedString {
        //@Local(\.colorTheme) var colorTheme
        return createHighlightedString(
            text: title,
            rangeValues: titleHighlightRanges,
            hilightColor: Color.theme
        )
    }
    
    var truncatedHighlightedSubtitleStringForDisplay: NSAttributedString {
        //@Local(\.colorTheme) var colorTheme
        return createHighlightedString(
            text: "\(String(subtitle.prefix(15)))…",
            rangeValues: subtitleHighlightRanges,
            hilightColor: Color.theme
        )
        //return createHighlightedString(text: subtitle, rangeValues: subtitleHighlightRanges)
    }
    
    
    var highlightedSubtitleStringForDisplay: NSAttributedString {
        //@Local(\.colorTheme) var colorTheme
        return createHighlightedString(
            text: String(subtitle),
            rangeValues: subtitleHighlightRanges,
            hilightColor: Color.theme
        )
        //return createHighlightedString(text: subtitle, rangeValues: subtitleHighlightRanges)
    }
}

