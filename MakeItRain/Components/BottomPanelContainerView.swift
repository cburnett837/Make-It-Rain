//
//  BottomPanelContainerView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 3/24/25.
//

import SwiftUI

struct BottomPanelContainerView<Content: View>: View {
    //@Binding var height: CGFloat
    var content: Content
    
//    init (_ height: Binding<CGFloat>, @ViewBuilder content: () -> Content) {
//        self._height = height
//        self.content = content()
//    }
    
    init (@ViewBuilder content: () -> Content) {
        //self._height = height
        self.content = content()
    }
    
    var body: some View {
        VStack {
            content
        }
        #if os(iOS)
        .if(AppState.shared.isIphone) {
            $0.background {
                //Color.darkGray.ignoresSafeArea(edges: .bottom)
//                ConcentricRectangle()
//                    .fill(Color(.secondarySystemBackground))
//                    .padding(8)
//                    .ignoresSafeArea(edges: .bottom)
                
                Color(.secondarySystemBackground)
                    .clipShape(
                        .rect(
                            topLeadingRadius: 30,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: 30
                        )
                    )
                    .ignoresSafeArea(edges: .bottom)
            }
        }
        //.frame(height: AppState.shared.isLandscape ? AppState.shared.isIpad ? 300 : 150 : AppState.shared.isIpad ? 500 : height)
        
        //.frame(height: 300)
        #endif
        .frame(maxHeight: .infinity, alignment: .bottom)
        //.padding(.horizontal, 5)
        //.transition(.move(edge: .bottom))
        //.offset(y: height)
        //.transition(.opacity)
        //.transition(.opacity.combined(with: .move(edge: .bottom)))
//        .onDisappear {
//            height = 300
//        }
        
    }
}


//
//struct BottomPanelSheetContainerView<Content: View>: View {
//    @Binding var scrollContentMargins: CGFloat
//    var content: Content
//    
//    init (_ scrollContentMargins: Binding<CGFloat>, @ViewBuilder content: () -> Content) {
//        self._scrollContentMargins = scrollContentMargins
//        self.content = content()
//    }
//    
//    var body: some View {
//        content
//            .presentationDetents([.height(300), .medium, .large])
//            .presentationDragIndicator(.visible)
//            .presentationContentInteraction(.scrolls)
//            .presentationBackgroundInteraction(.enabled(upThrough: .medium))
//            .maxViewHeightObserver()
//            .onPreferenceChange(MaxSizePreferenceKey.self) { newHeight in
//                print(newHeight)
//                scrollContentMargins = newHeight
//            }
//            .onDisappear {
//                withAnimation {
//                    scrollContentMargins = 0
//                }
//                
//            }
//        
//        
//    }
//}
