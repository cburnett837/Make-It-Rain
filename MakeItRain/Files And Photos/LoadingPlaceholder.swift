//
//  LoadingPlaceholder.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/26/25.
//


import SwiftUI
import WebKit
import PDFKit

fileprivate let fileWidth: CGFloat = 125
fileprivate let fileHeight: CGFloat = 250
fileprivate let symbolWidth: CGFloat = 26

struct LoadingPlaceholder: View {
    let text: String
    var displayStyle: FileSectionDisplayStyle
    
    var body: some View {
        Group {
            switch displayStyle {
            case .standard:
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: fileWidth, height: fileHeight)
            case .grid:
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.gray.opacity(0.1))
                    .aspectRatio(1, contentMode: .fit)
            }
        }
        .overlay {
            VStack {
                ProgressView()
                    .tint(.none)
                Text(text)
            }
        }
    }
}
