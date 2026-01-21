//
//  LoadingPlaceholder.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/26/25.
//


import SwiftUI
import WebKit
import PDFKit

struct LoadingPlaceholder: View {
    let text: String
    var displayStyle: FileSectionDisplayStyle
    var useDefaultFrame: Bool = true
    
    var body: some View {
        Group {
            switch displayStyle {
            case .standard:
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.gray.opacity(0.1))
                    .if(useDefaultFrame) {
                        $0
                        .frame(width: 125, height: 250)
                    }
                
            case .grid:
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.gray.opacity(0.1))
                    .aspectRatio(1, contentMode: .fit)
            }
        }
        .overlay {
            ProgressView() {
                Text(text)
            }
            .tint(.none)
        }
    }
}
