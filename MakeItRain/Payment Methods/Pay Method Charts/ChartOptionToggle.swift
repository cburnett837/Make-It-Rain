//
//  OptionToggle.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/30/25.
//


import SwiftUI
import Charts

struct ChartOptionToggle<Content: View>: View {
    @Local(\.colorTheme) var colorTheme
    @State private var showDescription = false
    
    var description: LocalizedStringKey
    var title: Content
    var color: Color
    @Binding var show: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            Toggle(isOn: $show.animation()) {
                Label {
                    title
                } icon: {
                    Image(systemName: showDescription ? "xmark.circle" : "info.circle")
                    //.foregroundStyle(Color.fromName(colorTheme))
                }
                .onTapGesture { withAnimation { showDescription.toggle() } }
                .contentTransition(.symbolEffect(.replace.magic(fallback: .replace)))
                
            }
            .tint(color)
            
            if showDescription {
                Text(description)
                    .font(.caption2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
