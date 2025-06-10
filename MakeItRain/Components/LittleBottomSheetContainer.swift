//
//  ChartOptionSheetContainer.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/30/25.
//

import SwiftUI

struct LittleBottomSheetContainer<Content: View, Content2: View, Content3: View, Content4: View>: View {
    @Environment(\.colorScheme) var colorScheme
    
    @ViewBuilder var content: Content
    var header: () -> Content2?
    var subHeader: () -> Content3?
    var footer: () -> Content4?
    
    @State private var geoHeight: CGFloat = .zero
        
    init(
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder header: @escaping () -> Content2 = { EmptyView() },
        @ViewBuilder subHeader: @escaping () -> Content3? = { EmptyView() },
        @ViewBuilder footer: @escaping () -> Content4? = { EmptyView() }
    ) {
        self.content = content()
        self.header = header
        self.subHeader = subHeader
        self.footer = footer
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    headerChunk
                            
                    VStack(alignment: .leading, spacing: 6) {
                        content
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 12)
                }
                .scrollDismissesKeyboard(.immediately)
                                                    
                footer()
                    .padding(.top, 10)
            }
            .padding(.bottom, 12)
            .background {
                GeometryReader { geo in
                    Color.clear.onAppear {
                        geoHeight = geo.size.height
                    }
                }
            }                            
        }
        .presentationDetents([.height(geoHeight), .medium, .large])
        .presentationContentInteraction(.scrolls)
        .presentationBackgroundInteraction(.enabled)
        
        #if os(macOS)
        .padding(.bottom, 10)
        #endif
        
    }
    
    var headerChunk: some View {
        Group {
            header()
            subHeader()
                .padding(.horizontal)
                .padding(.bottom, 10)
                        
            Divider()
        }
    }
}
