//
//  StandardTitleTextField.swift
//  MakeItRain
//
//  Created by Cody Burnett on 4/15/25.
//

import SwiftUI

struct StandardTitleTextField<T: CanEditTitleWithLocation & Observation.Observable>: View {
    @Environment(MapModel.self) private var mapModel
    var symbolWidth: CGFloat
    var focusedField: FocusState<Int?>
    var focusID: Int
    var showSymbol: Bool = true
    var parentType: XrefEnum
    
    var obj: T
    
    var body: some View {
        @Bindable var obj = obj
        HStack(alignment: .circleAndTitle) {
            Image(systemName: "bag.fill")
                .foregroundColor(.gray)
                .frame(width: symbolWidth)
                .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
            
            VStack {
                Group {
                    #if os(iOS)
                    StandardUITextField("Title",
                                        text: $obj.title,
                                        onSubmit: { focusedField.wrappedValue = focusID + 1 },
                                        onClear: { mapModel.completions.removeAll() },
                                        toolbar: { KeyboardToolbarView(focusedField: focusedField.projectedValue) }
                    )
                    .cbClearButtonMode(.whileEditing)
                    .cbFocused(focusedField, equals: focusID)
                    .cbSubmitLabel(.next)
                    #else
                    StandardTextField("Title", text: $obj.title, focusedField: focusedField.projectedValue, focusValue: focusID)
                        .onSubmit { focusedField.wrappedValue = focusID + 1 }
                    #endif
                }
                .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
                /// For transactions
                .overlay {
                    if !obj.factorInCalculations {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(.red, lineWidth: 4)
                    }
                }
                
                if !mapModel.completions.isEmpty {
                    VStack(alignment: .leading) {
                        ForEach(mapModel.completions.prefix(3), id: \.self) { completion in
                            VStack(alignment: .leading) {
                                Text(AttributedString(completion.highlightedTitleStringForDisplay))
                                    .font(.caption2)
                                
                                Text(AttributedString(completion.highlightedSubtitleStringForDisplay))
                                    .font(.caption2)
                                    .foregroundStyle(.gray)
                            }
                            .onTapGesture {
                                mapModel.blockCompletion = true
                                obj.title = completion.title
                                Task {
                                    if let location = await mapModel.getMapItem(from: completion, parentID: obj.id, parentType: parentType) {
                                        obj.upsert(location)
                                        mapModel.focusOnFirst(locations: obj.locations)
                                    }
                                }
                            }
                            
                            Divider()
                        }
                        
                        HStack {
                            Button("Use Current Location") {
                                mapModel.completions.removeAll()
                                Task {
                                    if let location = await mapModel.saveCurrentLocation(parentID: obj.id, parentType: parentType) {
                                        obj.upsert(location)
                                    }
                                }
                            }
                            .bold(true)
                            .font(.caption)
                            
                            Button("Hide") {
                                mapModel.completions.removeAll()
                            }
                            .bold(true)
                            .font(.caption)
                        }
                        
                        Divider()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        /// Handle search suggestions
        .onChange(of: obj.title) { oldTerm, newTerm in
            mapModel.getAutoCompletions(for: newTerm)
        }
        .onChange(of: focusedField.wrappedValue) { oldValue, newValue in
            if oldValue == focusID && newValue != focusID {
                withAnimation {
                    mapModel.completions.removeAll()
                }
            }
        }
    }
}
