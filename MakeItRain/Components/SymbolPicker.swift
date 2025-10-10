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
    @Local(\.colorTheme) var colorTheme
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var selected: String?
    var color: Color = .primary
        
    @FocusState private var focusedField: Int?
    @State private var searchText = ""
    
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
        
        SymbolSection(title: "Technology", symbols: [
            "desktopcomputer",
            "laptopcomputer",
            "computermouse.fill",
            "printer.fill",
            "smartphone",
            "headphones",
            "flipphone",
            "candybarphone",
        ]),
    ]
    
    fileprivate var filteredSections: Array<SymbolSection> {
        if searchText.isEmpty {
            return sections
        } else {
            return sections
                .filter { !$0.symbols.filter { $0.localizedStandardContains(searchText) }.isEmpty }
        }
    }
    
    
    var body: some View {
        NavigationStack {
            ScrollView {
                content
            }
            #if os(iOS)
            .searchable(text: $searchText, prompt: "Search")
            .navigationTitle("Symbols")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { closeButton }
            }
            #endif
        }
    }
    
    
    @ViewBuilder
    var content: some View {
        if filteredSections.isEmpty {
            ContentUnavailableView("No symbols found", systemImage: "exclamationmark.magnifyingglass")
        } else {
            VStack(alignment: .leading, spacing: 24) {
                ForEach(filteredSections.sorted { $0.title < $1.title }) { section in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(section.title)
                            .font(.headline)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: columnGrid, alignment: .leading, spacing: 10) {
                            ForEach(getSymbols(for: section), id: \.self) { symbolCell($0) }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
    }
    
    
    fileprivate func getSymbols(for section: SymbolSection) -> Array<String> {
        let filtered = searchText.isEmpty
        ? section.symbols.sorted { $0 < $1 }
        : section.symbols.filter { $0.localizedStandardContains(searchText) }.sorted { $0 < $1 }
        return filtered
    }
    
    
    @ViewBuilder
    private func symbolCell(_ sym: String) -> some View {
        Group {
            if (selected ?? "") == sym {
                RoundedRectangle(cornerRadius: 15)
                    .fill(color == .primary ? Color.fromName(colorTheme) : Color(.systemFill))
                    .overlay(image(sym))
            } else {
                image(sym)
            }
        }
        .onTapGesture {
            selected = sym
            dismiss()
        }
        
    }
    
    
    @ViewBuilder func image(_ sym: String) -> some View {
        Image(systemName: sym)
            .frame(maxWidth: .infinity, alignment: .center)
            .font(.title)
            .foregroundStyle(color)
    }
    
    
    var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "checkmark")
                .foregroundStyle(colorScheme == .dark ? .white : .black)
        }
    }
}
