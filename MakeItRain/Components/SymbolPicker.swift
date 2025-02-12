//
//  SymbolPicker.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/22/24.
//

import SwiftUI

fileprivate struct SymbolSection: Identifiable {
    var id: UUID = UUID()
    var title: String
    var symbols: Array<String>
}

struct SymbolPicker: View {
    @AppStorage("appColorTheme") var appColorTheme: String = Color.green.description
    @Environment(\.dismiss) var dismiss
    @Binding var selected: String?
    
    let columnGrid = Array(repeating: GridItem(.flexible(), spacing: 0), count: 6)
    
    
    fileprivate let sections: Array<SymbolSection> = [
        SymbolSection(title: "Child Care", symbols: [
            "backpack.fill",
            "puzzlepiece.fill",
            "stroller.fill",
            "teddybear.fill",
        ]),
        
        SymbolSection(title: "Home", symbols: [
            "house.fill",
            "tree.fill",
            "leaf.fill",
            "scissors",
            "camera.macro",
            "screwdriver.fill",
            "door.garage.double.bay.closed",
            "pipe.and.drop.fill",
            "sofa.fill",
            "chair.lounge.fill"
        ]),
        
        
        SymbolSection(title: "Fitness", symbols: [
            "dumbbell.fill",
            "sportscourt.fill",
            "baseball.fill",
            "basketball.fill",
            "football.fill",
            "tennis.racket",
            "volleyball.fill",
            "hockey.puck.fill",
            "figure.run",
            "figure.pool.swim"
        ]),
        
        SymbolSection(title: "Health", symbols: [
            "pills.fill",
            "bandage.fill",
            "staroflife.fill",
            "stethoscope",
            "medical.thermometer.fill",
            "cross.case.fill",
            "ivfluid.bag",
            "waveform.path.ecg.rectangle.fill",
            "brain.head.profile.fill",
            "heart.fill",
            "syringe.fill"
        ]),
        
        SymbolSection(title: "Food", symbols: [
            "fork.knife",
            "cup.and.saucer.fill",
            "carrot.fill",
            "wineglass.fill",
            "takeoutbag.and.cup.and.straw.fill",
            "frying.pan.fill"
        ]),
        
        SymbolSection(title: "Entertainment", symbols: [
            "pianokeys.inverse",
            "popcorn.fill",
            "gamecontroller.fill",
            "paintpalette.fill",
            "camera.fill",
            "play.tv.fill",
            "theatermasks.fill",
            "guitars.fill",
            "beach.umbrella.fill",
            "surfboard.fill",
            "av.remote.fill"
        ]),
        
        SymbolSection(title: "Utilities", symbols: [
            "spigot.fill",
            "shower.handheld.fill",
            "washer.fill",
            "dryer.fill",
            "refrigerator.fill",
            "sink.fill",
            "toilet.fill",
            "powerplug.fill",
            "bolt.fill",
            "lightbulb.fill",
            "shower.fill"
        ]),
        
        SymbolSection(title: "Pets", symbols: [
            "dog.fill",
            "cat.fill",
            "tortoise.fill",
            "bird.fill",
            "fish.fill",
            "pawprint.fill",
        ]),
        
        SymbolSection(title: "Travel / Transportation", symbols: [
            "fuelpump.fill",
            "car.fill",
            "bus.fill",
            "train.side.front.car",
            "airplane",
            "tram.fill",
            "tent.fill",
            "bicycle",
            "scooter"
        ]),
        
        SymbolSection(title: "Shopping", symbols: [
            "dollarsign.circle.fill",
            "creditcard.fill",
            "gym.bag.fill",
            "tag.fill",
            "bag.fill",
            "shoe.fill",
            "tshirt.fill",
            "basket.fill",
            "cart.fill",
            "hanger"
        ]),
                
        SymbolSection(title: "Misc", symbols: [
            "gift.fill",
            "balloon.2.fill",
            "birthday.cake.fill",
            "party.popper.fill"
        ]),
    ]
        
    @FocusState private var focusedField: Int?
    @State private var searchText = ""
    
    fileprivate var filteredSections: Array<SymbolSection> {
        if searchText.isEmpty {
            return sections
        } else {
            return sections
                .filter {
                    !$0.symbols.filter { $0.localizedStandardContains(searchText) }.isEmpty
                }
        }
    }
    
    var body: some View {
        VStack {
            SheetHeader(title: "Symbols", close: { dismiss() })
                .padding(.bottom, 12)
                .padding(.horizontal, 20)
                .padding(.top)
            
            SearchTextField(title: "Symbols", searchText: $searchText, focusedField: $focusedField, focusState: _focusedField)                        
            
            List {
                ForEach(filteredSections.sorted { $0.title < $1.title }) { section in
                    Section(section.title) {
                        LazyVGrid(columns: columnGrid, alignment: .leading, spacing: 10) {
                            ForEach(searchText.isEmpty
                                    ? section.symbols.sorted { $0 < $1 }
                                    : section.symbols.filter { $0.localizedStandardContains(searchText) }.sorted { $0 < $1 },
                                    id: \.self)
                            { sym in
                                Image(systemName: sym)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .font(.title)
                                    .onTapGesture {
                                        selected = sym
                                        dismiss()
                                    }
                                    .padding(5)
                                    .background {
                                        Circle()
                                            .fill((selected ?? "") == sym ? Color.fromName(appColorTheme) : Color.clear)
                                    }
                            }
                        }
                    }
                }
            }
            #if os(iOS)
            .listSectionSpacing(2)
            #endif
        }
    }
}
