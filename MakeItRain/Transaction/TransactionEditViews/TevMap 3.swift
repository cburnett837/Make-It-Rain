//
//  TevMap.swift
//  MakeItRain
//
//  Created by Cody Burnett on 8/13/26.
//

import SwiftUI
import MapKit

struct TevMap: View {
    @Bindable var trans: CBTransaction
    @Bindable var mapModel: MapModel
    @Binding var suggestedLocations: [CBSuggestedLocation]
    @Binding var showUseCurrentLocationButton: Bool
    @Binding var shouldShowLocationSuggestions: Bool
    var showExpensiveViews: Bool        
    
    var body: some View {
        Section {
            if showExpensiveViews {
                StandardMiniMap(
                    locations: $trans.locations,
                    parent: trans,
                    parentID: trans.id,
                    parentType: .transaction,
                    addCurrentLocation: false
                )
                .listRowInsets(EdgeInsets())
                .overlay {
                    if trans.action == .add && showUseCurrentLocationButton {
                        VStack {
                            Button {
                                mapModel.completions.removeAll()
                                Task {
                                    if let location = await mapModel.saveCurrentLocation(parentID: trans.id, parentType: .transaction) {
                                        trans.upsert(location)
                                    }
                                }
                                showUseCurrentLocationButton = false
                                shouldShowLocationSuggestions = false
                            } label: {
//                                Image(systemName: "heart")
                                ZStack {
                                    Image(systemName: "heart")
                                    Image(systemName: "location.fill")
                                        .scaleEffect(0.5)
                                }
                            }
                            .clipShape(.circle)
                            #if os(iOS)
                            .buttonStyle(.glass)
                            #endif
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .padding(.top, 5)
                        .padding(.trailing, 5)
                        
                    }
                }
            } else {
                ProgressView()
                    .listRowInsets(EdgeInsets())
                    .frame(maxWidth: .infinity)
                    .frame(height: 150)
                    .tint(.none)
            }
        } footer: {
            if shouldShowLocationSuggestions {
                footer
            }
        }
    }
    
    @ViewBuilder
    var footer: some View {
        ScrollView(.horizontal) {
            HStack {
//                AiAnimatedAliveSymbol(symbol: "brain", withGlow: false)
                ForEach(suggestedLocations.sorted(by: { $0.locationCount > $1.locationCount }).prefix(3)) {
                    MapSuggestionButton(
                        trans: trans,
                        mapModel: mapModel,
                        location: $0,
                        showUseCurrentLocationButton: $showUseCurrentLocationButton,
                        shouldShowLocationSuggestions: $shouldShowLocationSuggestions
                    )
                }
            }
        }
        .scrollIndicators(.hidden)
    }
}


fileprivate struct MapSuggestionButton: View {
    @Bindable var trans: CBTransaction
    @Bindable var mapModel: MapModel
    var location: CBSuggestedLocation
    @Binding var showUseCurrentLocationButton: Bool
    @Binding var shouldShowLocationSuggestions: Bool
    
    @State private var mapItem: MKMapItem?
    
    var address: String {
        #if os(iOS)
        if let mapItem, let address = mapItem.address, let shortAddress = address.shortAddress {
            "\(shortAddress.prefix(15))…"
        } else {
            "Address unavailable"
        }
        #else
        return "Address unavailable"
        #endif
    }
    
    
    var highlightedTitleStringForDisplay: AttributedString {
        return Helpers.highlightString(query: trans.title, in: location.locationTitle)
    }
    
    var body: some View {
        Button {
            selectLocation()
        } label: {
            VStack(alignment: .leading) {
                Text("\(highlightedTitleStringForDisplay)?")
                    .font(.subheadline)
                Text(address)
                    .font(.caption2)
            }
            .foregroundStyle(.gray)
        }
        #if os(iOS)
        .padding(8)
        .background(Capsule().foregroundStyle(.thickMaterial))
        #else
        .buttonStyle(.roundMacButton(horizontalPadding: 10))
        #endif
        .task {
            self.mapItem = await mapModel.createMapItemFrom(coordinates: location.coordinates)
        }
    }
    
    func selectLocation() {
        shouldShowLocationSuggestions = false
        showUseCurrentLocationButton = false
        Task {
            if let location = await mapModel.addLocationViaTouchAndHold(
                coordinate: location.coordinates,
                parentID: trans.id,
                parentType: .transaction,
                showDetailsPanel: false
            ) {
                trans.upsert(location)
                mapModel.focusOnFirst(locations: trans.locations)
            }
        }
    }
}
