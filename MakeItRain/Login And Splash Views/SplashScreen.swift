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
    //@State private var hang = ""
    let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    @State private var showSlowLoadingButton = false
    
    var body: some View {
        ZStack {
            rainingDollars
            
            makeItRainLogo
                .frame(maxHeight: .infinity, alignment: .center)
        }
        .overlay {
            if showSlowLoadingButton {
                offlineButton
            }
        }        
        .task {
            startLogoAnimation()
        }
        .onReceive(timer) { _ in
            showOfflineButton()
        }
        .onDisappear {
            timer.upstream.connect().cancel()
            showSlowLoadingButton = false
        }
    }
    
    var rainingDollars: some View {
        EmitterView()
            .scaleEffect(1, anchor: .top)
            .ignoresSafeArea()
            #if os(macOS)
            .rotationEffect(Angle(degrees: 180))
            #endif
    }
    
    var makeItRainLogo: some View {
        Text("Make it Rain")
            .scaleEffect(logoScale)
            .font(.largeTitle)
            .foregroundStyle(.primary)
            .textRenderer(TitleTextRenderer(progress: titleProgress))
    }
    
    var offlineButton: some View {
        VStack {
            Spacer()
            Text("Connecting is taking longer than expected…")
            Button("Offline Mode") {
                AuthState.shared.loginTask?.cancel()
                withAnimation {
                    AuthState.shared.isLoggedIn = false
                    AppState.shared.hasBadConnection = true
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
        }
    }
    
    
    func startLogoAnimation() {
        withAnimation(.smooth(duration: 2.5, extraBounce: 0)) {
            titleProgress = 1
        } completion: {
            withAnimation(.easeOut(duration: 1)) {
                AppState.shared.splashTextAnimationIsFinished = true
            }
        }
    }
    
    
    func showOfflineButton() {
        withAnimation {
            if AuthState.shared.isThinking {
                showSlowLoadingButton = true
            }
        }
        
        self.timer.upstream.connect().cancel()
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
            
            var copy = ctx
                        
            //let degree = Angle.degrees(Double(180 * 10))
            
            copy.addFilter(.blur(radius: 5 - (5 * sliceProgress)))
            copy.opacity = sliceProgress
            copy.translateBy(x: 0, y: 5 - (5 * sliceProgress))
                        
            //copy.addFilter(.hueRotation(degree))
            copy.draw(slice, options: .disablesSubpixelQuantization)
        }
    }
}

//
//struct CustomTextRenderer2: TextRenderer {
//    var progress: CGFloat
//    var startColor: Color
//    var endColor: Color
//
//    func draw(layout: Text.Layout, in ctx: inout GraphicsContext) {
//        let slices = layout.flatMap({ $0 }).flatMap({ $0 })
//        
//        for (index, slice) in slices.enumerated() {
//            let sliceProgressIndex = CGFloat(slices.count) * progress
//            let sliceProgress = max(min(sliceProgressIndex / CGFloat(index + 1), 1), 0)
//            
//            var copy = ctx
//                        
//            copy.addFilter(.blur(radius: 5 - (5 * sliceProgress)))
//            copy.opacity = sliceProgress
//            copy.translateBy(x: 0, y: 5 - (5 * sliceProgress))
//            copy.addFilter(.alphaThreshold(min: 0, color: .white))
//            
//            let interpolatedColor = startColor.interpolate(to: endColor, fraction: sliceProgress)
//           
//
//            
//                        copy.fill(slice.path, with: interpolatedColor)
//
//                        // Draw the slice (text)
//                        copy.draw(slice)
//        
//        }
//    }
//}
//extension Color {
//    func interpolate(to end: Color, fraction: CGFloat) -> Color {
//        let startComponents = self.components
//        let endComponents = end.components
//        
//        return Color(
//            red:   startComponents.red   * (1 - fraction) + endComponents.red   * fraction,
//            green: startComponents.green * (1 - fraction) + endComponents.green * fraction,
//            blue:  startComponents.blue  * (1 - fraction) + endComponents.blue  * fraction
//        )
//    }
//    
//    var components: (red: CGFloat, green: CGFloat, blue: CGFloat, opacity: CGFloat) {
//        let uiColor = UIColor(self)
//        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
//        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
//        return (r, g, b, a)
//    }
//}
