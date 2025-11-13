//
//  AiLabel.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/8/25.
//

import SwiftUI

//struct AiLabelOG: View {
//    var text: String
//    
//    var body: some View {
//        let colors: [Color] = [.orange, .pink, .purple]
//        let label = Label(text, systemImage: "brain")
//        label
//            /// Add padding so the symbol doesn't get cut off.
//            .padding(.vertical, 4)
//            .foregroundStyle(.blue)
//            .overlay {
//                /// Use a geo reader to match sizes so the text doesn't get truncated.
//                GeometryReader { proxy in
//                    let geoWidth = proxy.size.width
//                    let geoHeight = proxy.size.height
//                    LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing)
//                        .frame(width: geoWidth, height: geoHeight)
//                        .mask(
//                            label
//                                .frame(width: geoWidth, height: geoHeight, alignment: .leading)
//                                /// Add padding since the mask cuts off the front of the symbol.
//                                .padding(.leading, 3)
//                                .compositingGroup()
//                        )
//                        /// Compensate the leading padding.
//                        .offset(x: -1.5)
//                }
//            }
//            /// Compensate the earlier vertical padding.
//            .padding(.vertical, -4)
//    }
//}
//
//
//
//
//struct AiLabel2: View {
//    var text: String
//    @State private var speed: CGFloat = 20   // points/sec
//
//    var body: some View {
//        let label = Label(text, systemImage: "brain")
//
//        label
//            .padding(.vertical, 4)
//            .foregroundStyle(.blue)
//            .overlay {
//                MovingLoopGradient(colors: [.orange, .pink, .purple], speed: speed)
//                    .mask {
//                        GeometryReader { proxy in
//                            label
//                                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .leading)
//                                .padding(.leading, 3)       // keep your symbol adjustment
//                                .compositingGroup()
//                        }
//                    }
//                    .offset(x: -3)
//            }
//            .padding(.vertical, -4)
//    }
//}
//
///// A horizontally looping gradient that's clipped to its own bounds.
///// Uses TimelineView so multiple labels stay smooth & independent.
//private struct MovingLoopGradient: View {
//    let colors: [Color]
//    let speed: CGFloat   // points per second
//
//    private var grad: LinearGradient {
//        // Repeat first color to avoid seams
//        LinearGradient(colors: colors + [colors.first!], startPoint: .leading, endPoint: .trailing)
//    }
//
//    var body: some View {
//        TimelineView(.animation) { context in
//            GeometryReader { geo in
//                let w = max(1, geo.size.width)
//                let h = geo.size.height
//                let t = context.date.timeIntervalSinceReferenceDate
//                // phase in [0, w)
//                let phase = CGFloat(t).truncatingRemainder(dividingBy: w / max(1, speed)) * speed
//                let x = phase.truncatingRemainder(dividingBy: w)
//                //let x = -phase.truncatingRemainder(dividingBy: w)
//
//                ZStack(alignment: .leading) {
//                    grad.frame(width: w, height: h).offset(x: x)
//                    grad.frame(width: w, height: h).offset(x: x - w) // tile #2 for wraparound
//                }
//                //.clipped() // keep strictly inside the label's rect (no wiping neighbors)
//            }
//        }
//    }
//}
//
//
//
//struct AiLabel: View {
//    var text: String
//    @State private var phase: CGFloat = -1 // start off-screen
//    
//    var body: some View {
//        let label = Label(text, systemImage: "brain")
//        
//        label
//            .padding(.vertical, 5)
//            .padding(.trailing, 2)
//            // Base static gradient text
//            .overlay {
//                LinearGradient(colors: [.orange, .pink, .purple], startPoint: .leading, endPoint: .trailing)
//                    .mask(label)
//                    //.padding(.leading, 5)
//                    .offset(x: -1)
//            }
//            // The shimmer overlay
//            .overlay {
//                ShimmerMask()
//                    .mask(label)
//                    //.padding(.leading, 3)
//                    .offset(x: -1)
//            }
//            //.padding(.vertical, -4)
//    }
//}
//
//private struct ShimmerMask: View {
//    @State private var t: CGFloat = -1
//    
//    var body: some View {
//        GeometryReader { geo in
//            let w = geo.size.width
//            
//            // White shine band fading to transparent on both sides
//            LinearGradient(
//                gradient: Gradient(colors: [
//                    Color.white.opacity(0.0),
//                    Color.white.opacity(0.8),
//                    Color.white.opacity(0.0),
//                ]),
//                startPoint: .leading,
//                endPoint: .trailing
//            )
//            .frame(width: w * 0.4)        // width of shine band
//            .offset(x: w * t)             // move across
//            .animation(
//                .linear(duration: 2.5).repeatForever(autoreverses: false),
//                value: t
//            )
//            .onAppear { t = 1.5 }         // sweep fully past
//        }
//    }
//}
//
//
//
//

fileprivate let animationDelay: Double = 1
fileprivate let animationDuration: Double = 5
fileprivate let colors: Array<Color> = [.orange, .pink, .purple]
fileprivate var baseGradient = Gradient(colors: colors)
fileprivate let gradient = LinearGradient(
    gradient: baseGradient,
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)

fileprivate func animate(withGlow: Bool, hueShift: Binding<Double>, glowPulse: Binding<CGFloat>) {
    /// Let the label appear naturally for a second before beginning the animation.
    DispatchQueue.main.asyncAfter(deadline: .now() + animationDelay) {
        withAnimation(.linear(duration: animationDuration).repeatForever(autoreverses: false)) {
            hueShift.wrappedValue = 360
        }
        if withGlow {
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                glowPulse.wrappedValue = 1
            }
        }
    }
}

extension AiAnimatedAliveLabel where Content == Label<Text, Image> {
    init(_ text: String, systemImage: String, withGlow: Bool) {
        self.content = Label(text, systemImage: systemImage)
        self.withGlow = withGlow
    }
}

struct AiAnimatedAliveLabel<Content: View>: View {
    let content: Content
    var withGlow: Bool
    
    @State private var hueShift: Double = 0
    @State private var glowPulse: CGFloat = 0

    var body: some View {
        Group {
            if withGlow {
                ZStack {
                    labelLayer(isBlur: true)
                    labelLayer(isBlur: false)
                }
            } else {
                labelLayer(isBlur: false)
            }
        }
        /// Compensate the vertical padding from the labelLayer().
        .offset(x: -4)
        .onAppear {
            animate(withGlow: withGlow, hueShift: $hueShift, glowPulse: $glowPulse)
        }
    }
    
    @ViewBuilder func labelLayer(isBlur: Bool) -> some View {
        let label = content
            //.bold()
            /// Add padding so the symbol doesn't get cut off.
            .padding(4)
        
        label
            .foregroundStyle(.clear)
            /// Have to use overlay and mask since labels will apply the animation to the text and symbol seperatly.
            /// Using overlay & mask, along with composite group treats them as one.
            .overlay {
                gradient
                    .hueRotation(.degrees(hueShift))
                    .mask(label.compositingGroup())
                    /// There seems to be a very subtle alignment issue with the stacked labels.
                    .offset(x: 0.1)
                    .if(isBlur) {
                        $0
                        .blur(radius: 8 + glowPulse * 8)
                        .opacity(0.6 + glowPulse * 0.3)
                    }
            }
    }
}


struct AiAnimatedAliveSymbol: View {
    @State private var hueShift: Double = 0
    @State private var glowPulse: CGFloat = 0
    
    var symbol: String
    var withGlow: Bool = false
    
    var body: some View {
        Group {
            if withGlow {
                ZStack {
                    image
                        .blur(radius: 8 + glowPulse * 8)
                        .opacity(0.6 + glowPulse * 0.3)
                        /// Needed to make the blur rotate colors.
                        .compositingGroup()
                    image
                }
            } else {
                image
            }
        }
        .onAppear {
            animate(withGlow: withGlow, hueShift: $hueShift, glowPulse: $glowPulse)
        }
    }
    
    var image: some View {
        Image(systemName: symbol)
            .foregroundStyle(gradient)
            .hueRotation(.degrees(hueShift))
    }
}
