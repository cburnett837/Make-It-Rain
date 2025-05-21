//
//  StandardMap.swift
//  MakeItRain
//
//  Created by Cody Burnett on 4/11/25.
//

import Foundation
import SwiftUI
import MapKit

enum MapBottomPanelContent {
    case details, search, clear
}

//struct MapContainer: View {
//    @Environment(Model.self) private var model
//
//    var body: some View {
//        @Bindable var model = model
//        MapView()
//            .searchable(text: $model.searchQuery, prompt: "Search Locations")
//            .searchSuggestions { SearchSuggestions() }
//            .onSubmit(of: .search) {
//                print("Search submit")
//                model.search()
//            }
//    }
//}


#if os(iOS)
struct SearchSuggestions: View {
    @Environment(MapModel.self) private var mapModel
    //@Environment(\.dismissSearch) var dismissSearch
    var focusedField: FocusState<Int?>.Binding
    var parentID: String
    var parentType: XrefEnum
    
    var body: some View {
        List {
            if !mapModel.searchQuery.isEmpty {
                Button("Search Nearby") {
                    withAnimation {
                        mapModel.search(parentID: parentID, parentType: parentType)
                        withAnimation {
                            focusedField.wrappedValue = nil
                            mapModel.panelContent = .clear
                        }
                    }
                }
                .listRowBackground(Color.clear)
            }
                        
            ForEach(mapModel.completions, id: \.self) { completion in
                VStack(alignment: .leading) {
                    Text(AttributedString(completion.highlightedTitleStringForDisplay))
                        .font(.headline)
                    
                    Text(AttributedString(completion.highlightedSubtitleStringForDisplay))
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                }
                .onTapGesture {
                    Task {
                        let location = await mapModel.getMapItem(from: completion, parentID: parentID, parentType: parentType)
                        withAnimation {
                            if let location = location {
                                mapModel.searchResults = [location]
                            }
                            
                            //mapModel.searchResults.removeAll()
                            mapModel.searchQuery = ""
                            focusedField.wrappedValue = nil
                            mapModel.panelContent = .details
                        }
                    }
                    
                }
            }
            .listRowBackground(Color.clear)
        }
        .listStyle(.plain)
    }
}


struct StandardMapView: View {
    @Local(\.colorTheme) var colorTheme

    @Environment(\.dismiss) var dismiss
    @Environment(MapModel.self) private var mapModel
        
    @State private var locationManager = LocationManager.shared
    @State private var bottomPanelHeight: CGFloat = 70
    @State private var mapControlsOpacity: CGFloat = 1
    @State private var showSteps = false
    @FocusState private var focusedField: Int?
    @State private var mapStyle: MapViewStyle = .standard
    
    private let mapStyleOptions = [
        MapViewStyle(name: "Explore", option: .standard(pointsOfInterest: .all), symbol: "map.fill"),
        MapViewStyle(name: "Traffic", option: .standard(showsTraffic: true), symbol: "car.fill"),
        MapViewStyle(name: "Satellite", option: .imagery, symbol: "tree.fill"),
        MapViewStyle(name: "Hybrid", option: .hybrid, symbol: "map.fill")
    ]
    
    @Binding var locations: [CBLocation]
    var parent: CanHandleLocationsDelegate
    var parentID: String
    var parentType: XrefEnum
    
    //@Namespace var mapScope
    
    #if os(iOS)
    struct MapLongPressGesture: UIGestureRecognizerRepresentable {
        private let longPressAt: (_ position: CGPoint) -> Void
        
        init(longPressAt: @escaping (_ position: CGPoint) -> Void) {
            self.longPressAt = longPressAt
        }
        
        func makeUIGestureRecognizer(context: Context) -> UILongPressGestureRecognizer {
            UILongPressGestureRecognizer()
        }
        
        func handleUIGestureRecognizerAction(_ gesture: UILongPressGestureRecognizer, context: Context) {
            guard gesture.state == .began else { return }
            longPressAt(gesture.location(in: gesture.view))
        }
    }
    #endif
    
    var body: some View {
        @Bindable var mapModel = mapModel
        MapReader { proxy in
            Map(position: $mapModel.position, interactionModes: mapModel.modes, selection: $mapModel.selection) {
                UserAnnotation()
                searchResults
                favoriteLocations
                
                if let route = mapModel.route {
                    MapPolyline(route)
                        .stroke(.blue, lineWidth: 5)
                }
            }
            /// Toggle between map, traffic, satellite.
            .mapStyle(mapStyle.option)
            /// Only allow points of interest to be selected (for example exclude country names).
            .mapFeatureSelectionDisabled { feature in
                feature.kind != MapFeature.FeatureKind.pointOfInterest
            }
            #if os(iOS)
            .gesture(MapLongPressGesture { position in
                Helpers.buzzPhone(.success)
                if let coordinate = proxy.convert(position, from: .local) {
                    Task {
                        if let location = await mapModel.addLocationViaTouchAndHold(coordinate: coordinate, parentID: parentID, parentType: parentType) {
                            parent.upsert(location)
                        }
                    }
                }
            })
            #endif
            .mapControls {
                MapCompass().mapControlVisibility(.hidden)
            }
        }
        
        /// Show direction steps
        .sheet(isPresented: $showSteps, content: {
            if let route = mapModel.route {
                List(route.steps, id: \.self) { step in
                    VStack(alignment: .leading) {
                        Text(step.instructions)
                        Text("\(mapModel.distance(meters: step.distance))")
                            .foregroundStyle(.gray)
                            .font(.caption)
                    }
                }
            }
        })
        .toolbar(.hidden)
        
        /// Clean up results when leaving the map.
        .onDisappear(perform: clearSearch)
        /// Set the camera to the first location in the list when opening the map.
        /// Create a MKMapItem for each CBLocation (if applicable).
        .task {
            mapModel.focusOnFirst(locations: locations)
                        
            /// Create a map item for each CBLocation
            for loc in locations {
                if loc.mapItem == nil {
                    loc.mapItem = await mapModel.createMapItem(for: loc)
                }
            }
        }
        
        /// Update visible region on camera change.
        .onMapCameraChange(frequency: .onEnd) { context in
            mapModel.visibleRegion = context.region
        }
        
        /// Add map controls on top of the map
        .overlay(alignment: .topTrailing) { mapControls }
        .overlay(alignment: .topLeading) { closeMapButton }
        /// Make it so the map controls are positions relative to the top of the screen, not the safe area.
        /// This has to go after the overlays.
        .ignoresSafeArea(.all)
           
        /// Bottom Panels
        .overlay {
            MapBottomPanelContainerView($bottomPanelHeight, panelContent: mapModel.panelContent) {
                if mapModel.panelContent == .details || mapModel.panelContent == .clear {
                    bottomBar
                } else {
                    VStack {
                        StandardTextField(
                            "Search Maps",
                            text: $mapModel.searchQuery,
                            isSearchField: true,
                            alwaysShowCancelButton: false,
                            focusedField: $focusedField,
                            focusValue: 0,
                            onSubmit: {
//                                if mapModel.completions.isEmpty {
//                                    withAnimation {
//                                        mapControlsOpacity = 1
//                                    }
//                                }
                            },
                            onCancel: { withAnimation {
                                clearSearch()
                            } }
                        )
                        .padding([.top, .horizontal])
                        
                        SearchSuggestions(focusedField: $focusedField, parentID: parentID, parentType: parentType)
                            .frame(maxHeight: .infinity)
                    }
                    
                    .opacity(mapModel.panelContent == MapBottomPanelContent.search ? 1 : 0)
                }
            }
        }
        
        /// Handle search suggestions
        .onChange(of: mapModel.searchQuery) { oldTerm, newTerm in
            mapModel.getAutoCompletions(for: newTerm)
        }
        /// When focusing on the search bar, adjust the height of the bottom panel.
        /// When unfocusing the search bar, reset the height back to 70.
        .onChange(of: focusedField) { oldValue, newValue in
            if newValue != nil {
                #if os(iOS)
                let maxAllowedHeight = ((UIScreen.main.bounds.height - (UIApplication.shared.keyWindow?.safeAreaInsets.top ?? 0))) - 60
                #else
                let maxAllowedHeight = 200
                #endif
                withAnimation {
                    bottomPanelHeight = maxAllowedHeight
                    mapControlsOpacity = 0
                }
            } else {
                /// Only condense the bottom panel if there is no search suggestions.
                /// For example, when clicking the enter key on the keyboard. This is nesseccary because the suggestion results are behind the keyboard.
                if mapModel.completions.isEmpty {
                    withAnimation {
                        bottomPanelHeight = 70
                    }
                }
                
            }
        }
        /// When tapping a suggesting search term, or initiating a search, show the map controls.
        .onChange(of: mapModel.panelContent) {
            print(".onChange(of: mapModel.panelContent) \($1)")
            if $1 != .search {
                withAnimation {
                    mapControlsOpacity = 1
                }
            }
        }
        /// When tapping a point of interest on the map, summon the MKMapItem from the mapModel. This will set an object in the mapModel.
        .onChange(of: mapModel.selection) { _, newSelection in
            mapModel.updateWithSelectedFeature(newSelection, parentID: parentID, parentType: parentType)
        }
        /// When `mapModel.selectedMapItem` gets set via `updateModelWithSelectedFeature()`, which happens on map selection, this will change the bottom panels accordingly.
        .onChange(of: mapModel.selectedMapItem) { _, newValue in
            if newValue == nil {
                mapModel.selection = nil
            }
            
            /// If an item is selected, and we tap on the map to unselect it, show the search bar (aka reset the map).
            if mapModel.searchQuery.isEmpty && newValue == nil && (mapModel.panelContent == .details) {
                withAnimation {
                    
                    if mapModel.searchResults.count == 1 {
                        mapModel.searchResults.removeAll()
                    }
                    
                    bottomPanelHeight = 70
                    mapModel.panelContent = .search
                }
                
            /// If an item is not  selected, and we tap on an item to select it, show the details panel.
            } else if newValue != nil && mapModel.panelContent == .search {
                withAnimation {
                    mapModel.panelContent = .details
                }
            }
        }
        /// Allow the search panel to properly resize and ignore the keyboard.
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
    
    
    var searchResults: some MapContent {
        ForEach(mapModel.searchResults) { result in
            Marker(result.title, systemImage: "mappin", coordinate: result.coordinates)
                .tag(MapSelection(result))
                .tint(.red)
        }
    }
    
    
    var favoriteLocations: some MapContent {
        ForEach(locations.filter { $0.active }) { result in
            Marker(result.title, systemImage: "heart", coordinate: result.coordinates)
                .tag(MapSelection(result))
                .tint(.orange)
        }
    }
    
    
    var bottomBar: some View {
        VStack {
            if mapModel.selectedMapItem != nil {
                itemOptionsPanel
            } else if !mapModel.searchResults.isEmpty {
                clearSearchResultsPanel
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 4)
        .padding(.top, 8)
        .frame(minHeight: 70)
        //.transition(.asymmetric(insertion: .move(edge: .bottom), removal: .opacity))
        .transition(.opacity)
        .ignoresSafeArea(.all)
    }
    
    
    var calculatingTravelTimeView: some View {
        Text(mapModel.isCalculatingRoute ? "Calculating Travel Time…" : mapModel.travelTime ?? "N/A")
            .foregroundStyle(.gray)
            .font(.caption)
    }
    
    
    var itemOptionsPanel: some View {
        Group {
            if let selection = mapModel.selectedMapItem {
                
                VStack {
                    VStack(spacing: 6) {
                        HStack(spacing: 0) {
                            
                            HStack {
                                #if os(iOS)
                                directionsMenu
                                #endif
                                Button {
                                    selection.mapItem?.openInMaps(launchOptions: [:])
                                } label: {
                                    Image(systemName: "map")
                                }
                            }
                            
                            
                            Text(selection.title)
                                .frame(maxWidth: .infinity)
                                .font(.body)
                                .bold()
                                .lineLimit(1)
                            
                            HStack {
                                saveOrDeleteButton
                                
                                Button {
                                    mapModel.selection = nil
                                } label: {
                                    Image(systemName: "xmark")
                                }
                                .keyboardShortcut(.return, modifiers: [.command]) /// Just because I am used to it from the original app.
                            }
                        }
                        .buttonStyle(.sheetHeader)
                        .focusable(false)
                        .padding(.horizontal)
                        
                        Text(selection.mapItem?.placemark.title ?? "N/A")
                            .foregroundStyle(.gray)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                        
                        calculatingTravelTimeView
                        
                    }
                                                        
                    ShowItemDetailsButton()
                }
                .buttonStyle(.borderedProminent)
            } else {
                Text("No Selection")
            }
        }
    }
    
    
    var saveOrDeleteButton: some View {
        let selection = mapModel.selectedMapItem!
        let isSaved = !locations.filter {$0.id == selection.id}.isEmpty
        return Button {
            withAnimation {
                if isSaved {
                    parent.deleteLocation(id: mapModel.selectedMapItem!.id)
                    mapModel.panelContent = .search
                    mapModel.route = nil
                } else {
                    mapModel.searchResults.removeAll { $0.mapItem?.identifier == selection.mapItem?.identifier }
                    parent.upsert(selection)
                    withAnimation {
                        mapModel.selection = MapSelection(selection)
                    }
                    
                    //mapModel.selectedMapItem = selection
                }
            }
        } label: {
            Image(systemName: isSaved ? "trash" : "heart")
            //Text(isSaved ? "Delete" : "Save")
        }
        .tint(isSaved ? .red : .orange)
    }
    
    #if os(iOS)
    var directionsMenu: some View {
        Menu {
            Section {
                directionsCarButton
                directionsWalkingButton
                directionsTransitButton
            }
            Section {
                directionsByStepButton
            }
        } label: {
            Image(systemName: "car.fill")
        }
    }
    
    
    var directionsCarButton: some View {
        Button {
            Task {
                let _ = await mapModel.selectedMapItem!.mapItem?.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving], from: UIApplication.shared.connectedScenes.first)
            }
        } label: {
            Label {
                Text("Driving")
            } icon: {
                Image(systemName: "car.fill")
            }
        }
    }
    
    
    var directionsWalkingButton: some View {
        Button {
            Task {
                let _ = await mapModel.selectedMapItem!.mapItem?.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeWalking], from: UIApplication.shared.connectedScenes.first)
            }
        } label: {
            Label {
                Text("Walking")
            } icon: {
                Image(systemName: "figure.walk")
            }
        }
    }
    
    
    var directionsTransitButton: some View {
        Button {
            Task {
                let _ = await mapModel.selectedMapItem!.mapItem?.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeTransit], from: UIApplication.shared.connectedScenes.first)
            }
        } label: {
            Label {
                Text("Transit")
            } icon: {
                Image(systemName: "tram.fill")
            }
        }
    }
    
    
    var directionsByStepButton: some View {
        Button {
            showSteps = true
        } label: {
            Label {
                Text("Steps")
            } icon: {
                Image(systemName: "list.bullet")
            }
        }
    }
    
    #endif
    
    var clearSearchResultsPanel: some View {
        HStack {
            Button {
                withAnimation { mapModel.search(parentID: parentID, parentType: parentType) }
            } label: {
                Text("Search Here")
            }
            
            Button {
                mapModel.panelContent = .search
                withAnimation {
                    focusedField = 0
                }
            } label: {
                Text("Alter Search")
            }
            
            Button {
                withAnimation {
                    mapModel.searchResults.removeAll()
                    mapModel.completions.removeAll()
                    mapModel.searchQuery = ""
                    mapModel.panelContent = .search
                    bottomPanelHeight = 70
                }
            } label: {
                Text("Clear Results")
            }
        }
        .buttonStyle(.borderedProminent)
    
    }
    
        
    struct ShowItemDetailsButton: View {
        @Environment(MapModel.self) private var mapModel
        @State private var showDetails = false
        
        var body: some View {
            @Bindable var mapModel = mapModel
            Button("Details") {
                showDetails = true
            }
            .mapItemDetailSheet(isPresented: $showDetails, item: mapModel.selectedMapItem?.mapItem, displaysMap: true)
        }
    }
    
    
    var mapControls: some View {
        VStack(spacing: 0.0) {
            ButtonGroup(topPadding: 50, horizontalPosition: .trailing) {
                VStack(spacing: 0.0) {
                    mapStyleButton
                    buttonSeparator
                    currentLocationButton
                }
            }
            
            if !mapModel.searchQuery.isEmpty {
                ButtonGroup(topPadding: 10, horizontalPosition: .trailing) {
                    VStack(spacing: 0.0) {
                        adjustSearchbutton
                        buttonSeparator
                        clearSearchbutton
                    }
                }
            }
        }
        .opacity(mapControlsOpacity)
    }
    
    
    var closeMapButton: some View {
        ButtonGroup(topPadding: 50, horizontalPosition: .leading) {
            Button {
                withAnimation {
                    clearSearch()
                    dismiss()
                }
            } label: {
                Image(systemName: "xmark")
                    .contentShape(Rectangle())
                    .frame(width: 40, height: 40)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.gray)
            }
        }
        .opacity(mapControlsOpacity)
    }
        
    
    var currentLocationButton: some View {
        Button {
            withAnimation { mapModel.position = .userLocation(fallback: .automatic) }
        } label: {
            Image(systemName: mapModel.position.positionedByUser ? "location" : "location.fill")
                .contentShape(Rectangle())
                .frame(width: 40, height: 40)
                .contentTransition(.symbolEffect(.replace))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.primary)
        }
    }
    
    
    var mapStyleButton: some View {
        Menu {
            ForEach(mapStyleOptions) { opt in
                Button {
                    mapStyle = opt
                } label: {
                    Label {
                        Text(opt.name)
                    } icon: {
                        Image(systemName: mapStyle == opt ? "checkmark" : opt.symbol)
                    }
                }
            }
        } label: {
            Image(systemName: "map.fill")
                .contentShape(Rectangle())
                .frame(width: 40, height: 40)
        }
        .foregroundStyle(.gray)
    }
       
    
    var adjustSearchbutton: some View {
        Button {
            withAnimation {
                mapModel.search(parentID: parentID, parentType: parentType)
            }
        } label: {
            Image(systemName: "location.magnifyingglass")
                .contentShape(Rectangle())
                .frame(width: 40, height: 40)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.gray)
        }
    }
    
    
    var clearSearchbutton: some View {
        Button {
            withAnimation {
                mapModel.searchResults.removeAll()
                mapModel.completions.removeAll()
                mapModel.searchQuery = ""
                mapModel.panelContent = .search
                bottomPanelHeight = 70
            }
        } label: {
            Image(systemName: "x.circle")
                .contentShape(Rectangle())
                .frame(width: 40, height: 40)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.gray)
        }
    }
    
    
    var buttonSeparator: some View {
        Color.gray.frame(height: 0.5)
    }
    
    
    
    
    
    struct ButtonGroup<Content: View>: View {
        let topPadding: Double
        let horizontalPosition: Edge.Set
        @ViewBuilder let content: Content
        
        var body: some View {
            content
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.thinMaterial)
                    //.ignoresSafeArea()
            }
        
            .padding(.top, topPadding)
            .padding(horizontalPosition, 10)
            .frame(width: 40)
            
        }
    }
       
    
    /// This is required because SwiftUI MapStyle is not able to conform to Equatable.
    /// We need Equatable to show the check mark on the mapStyle menu.
    struct MapViewStyle: Identifiable, Equatable {
        public static var standard: MapViewStyle {
            return MapViewStyle(name: "Explore", option: .standard, symbol: "map.fill")
        }
        
        let id = UUID()
        let name: String
        let option: MapStyle
        let symbol: String
        
        static func == (lhs: MapViewStyle, rhs: MapViewStyle) -> Bool {
            if lhs.name == rhs.name { return true } else { return false }
        }
    }
    
    
    
    func clearSearch() {
        mapModel.panelContent = .search
        mapControlsOpacity = 1
        mapModel.selection = nil
        mapModel.searchQuery = ""
        mapModel.searchResults.removeAll()
        mapModel.completions.removeAll()
    }
}
#endif
