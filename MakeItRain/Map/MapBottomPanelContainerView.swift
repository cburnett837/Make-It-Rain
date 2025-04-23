//
//  MapBottomPanelContainerView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 4/11/25.
//


import SwiftUI
import MapKit

struct MapBottomPanelContainerView<Content: View>: View {
    @Binding var height: CGFloat
    var panelContent: MapBottomPanelContent
    var content: Content
    
    init (_ height: Binding<CGFloat>, panelContent: MapBottomPanelContent, @ViewBuilder content: () -> Content) {
        self._height = height
        self.panelContent = panelContent
        self.content = content()
    }
    
    var body: some View {
        VStack {
            content
        }
        #if os(iOS)
        .background {
            //Color.darkGray.ignoresSafeArea(edges: .bottom)
            Rectangle()
                .fill(.thinMaterial)
                .clipShape(
                    .rect(
                        topLeadingRadius: 15,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 15
                    )
                )
                .ignoresSafeArea(edges: .bottom)
        }
        .frame(height: panelContent == MapBottomPanelContent.search ? height : nil)
        
        
        #endif
        .frame(maxHeight: .infinity, alignment: .bottom)
        //.transition(.move(edge: .bottom))
        //.offset(y: height)
        //.transition(.opacity)
        //.transition(.opacity.combined(with: .move(edge: .bottom)))
        .onDisappear {
            height = 70
        }
        
    }
}
