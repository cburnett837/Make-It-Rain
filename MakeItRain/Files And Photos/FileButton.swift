//
//  FileButton.swift
//  MakeItRain
//
//  Created by Cody Burnett on 8/19/26.
//


import SwiftUI
import WebKit

fileprivate let fileWidth: CGFloat = 125
fileprivate let fileHeight: CGFloat = 250
fileprivate let symbolWidth: CGFloat = 26

struct FileButton: View {
    var button: SelectFileButtonType
    var files: [CBFile]?
    
    @State private var hoverColor: Color = Color(.tertiarySystemFill)
    @State private var symbolHeight: CGFloat = 20.0
    
    var body: some View {
        let thereAreFiles = files?.filter({ $0.active }).count ?? 0 > 0
        
        let tallRectangle = RoundedRectangle(cornerRadius: 14)
            .fill(hoverColor)
            .frame(width: fileWidth/*, height: (fileHeight / 3) - 3*/) /// -4 to account for the padding
        
        let shortRectangle = RoundedRectangle(cornerRadius: 14)
            .fill(hoverColor)
            .frame(maxWidth: .infinity)
            .frame(height: (fileHeight / 3))
        
        Button(action: button.action, label: {
            VStack {
                if thereAreFiles {
                    tallRectangle
                } else {
                    shortRectangle
                }
            }
            .overlay {
                VStack {
                    Image(systemName: button.symbol)
                        .font(.title)
                        /// Monitor the background size so all symbols are the same height.
                        .background { GeometryReader {
                            Color.clear.preference(key: MaxSymbolHeightPreferenceKey.self, value: $0.size.height) }
                        }
                        .frame(height: symbolHeight, alignment: .center)
                    Text(button.title)
                }
                .foregroundStyle(.gray)
            }
        })
        .buttonStyle(.plain)
        .onHover { isHovered in hoverColor = isHovered ? Color(.systemFill) : Color(.tertiarySystemFill) }
        .focusEffectDisabled(true)
    }
}
