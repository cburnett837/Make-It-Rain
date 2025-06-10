//
//  ChartOptionMenu.swift
//  MakeItRain
//
//  Created by Cody Burnett on 6/2/25.
//

import SwiftUI

struct ChartOptionMenu<Content: View>: View {
    @Local(\.colorTheme) var colorTheme
    @State private var showDescription = false
    
    var description: LocalizedStringKey
    var title: String
    var menu: Content
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Label {
                    Text(title)
                } icon: {
                    Image(systemName: showDescription ? "xmark.circle" : "info.circle")
                    //.foregroundStyle(Color.fromName(colorTheme))
                }
                .onTapGesture { withAnimation { showDescription.toggle() } }
                .contentTransition(.symbolEffect(.replace.magic(fallback: .replace)))
                
                Spacer()
                
                menu
            }
            
            if showDescription {
                Text(description)
                    .font(.caption2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
