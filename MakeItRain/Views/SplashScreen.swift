//
//  SplashScreen.swift
//  MakeItRain
//
//  Created by Cody Burnett on 12/20/24.
//

import SwiftUI
import SpriteKit

@MainActor
struct SplashScreen: View {
    @State private var logoScale: Double = 1
    @State private var titleProgress: CGFloat = 0
    
    
    var body: some View {
        ZStack {
            
//            SpriteView(scene: DollarScene.scene, options: [.allowsTransparency])
//                .ignoresSafeArea()
//                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            
            EmitterView()
                .scaleEffect(1, anchor: .top)
                .ignoresSafeArea()
                #if os(macOS)
                .rotationEffect(Angle(degrees: 180))
                #endif
                //.blur(radius: 1)
//            
            VStack {
                Spacer()
                
                Text("Make it Rain")
                    .scaleEffect(logoScale)
                    .transition(.asymmetric(insertion: .scale, removal: .opacity)) // top
                    .font(.title)
                    .foregroundStyle(.primary)
                    .textRenderer(TitleTextRenderer(progress: titleProgress))
                    
                Spacer()
            }
//            .task {
//                withAnimation(.easeIn(duration: 2)) {
//                    logoScale = 1
//                }
//            }
        }
        #if os(iOS)
        .standardBackground()
        #endif
        .task {
            withAnimation(.smooth(duration: 2.5, extraBounce: 0)) {
                titleProgress = 1
            }
        }
    }
}


struct TitleTextRenderer: TextRenderer, Animatable {
    var progress: CGFloat
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }
    
    func draw(layout: Text.Layout, in ctx: inout GraphicsContext) {
        let slices = layout.flatMap({ $0 }).flatMap({ $0 })
        
        for (index, slice) in slices.enumerated() {
            let sliceProgressIndex = CGFloat(slices.count) * progress
            let sliceProgress = max(min(sliceProgressIndex / CGFloat(index + 1), 1), 0)
            
            ctx.addFilter(.blur(radius: 5 - (5 * sliceProgress)))
            ctx.opacity = sliceProgress
            ctx.translateBy(x: 0, y: 5 - (5 * sliceProgress))
            ctx.draw(slice, options: .disablesSubpixelQuantization)
        }
    }
}
