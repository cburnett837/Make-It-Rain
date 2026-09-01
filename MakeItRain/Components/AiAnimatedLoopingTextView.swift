//
//  AiAnimatedLoopingTextView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 12/18/25.
//

import SwiftUI

struct AiAnimatedLoopingTextView: View {
    @State private var isHilighting = false
    @State private var hideHilight = false
    
    var body: some View {
        smartIndicatorView()
    }
    
    @ViewBuilder private func smartIndicatorView() -> some View {
        
        ZStack {
            let shape = Capsule()
            shape
                .stroke(
                    //Color.theme.gradient,
                    AngularGradient(gradient: Gradient(colors: [.red, .yellow, .green, .blue, .purple, .red]), center: .center),
                    style: .init(lineWidth: 2, lineCap: .round, lineJoin: .round)
                )
                .mask {
                    let clearColors: [Color] = Array(repeating: .clear, count: 4)
                    shape
                        .fill(AngularGradient(
                            colors: clearColors + [.red, .yellow, .green, .blue, .purple, .red] + clearColors,
                            center: .center,
                            angle: .init(degrees: isHilighting ? 360 : 0)
                        ))
                        .opacity(hideHilight ? 0 : 1)
                }
                .padding(-2)
                .blur(radius: 0)
                .onAppear {
                    withAnimation(.linear(duration: 2).repeatCount(1, autoreverses: false)) {
                        isHilighting = true
                    }
                    
                    // fade out starting 1.5s into the final spin (slightly before the end)
                    let totalDuration = 2.0 // 2s per spin * 1 repeats
                    let fadeDuration = 1.0
                    let fadeStart = totalDuration - fadeDuration
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + fadeStart) {
                        withAnimation(.easeOut(duration: fadeDuration)) {
                            hideHilight = true
                        }
                    }
                }
                .onDisappear {
                    isHilighting = false
                    hideHilight = false
                }
        }
    }
}

struct AiAnimatedBorder: View {
    var startDate: Date
    var isAnimating: Bool
    var hideHilight: Bool
    
    private let duration: TimeInterval = 1.5
    private let colors: [Color] = [.red, .yellow, .green, .blue, .purple, .red]
    private let shape = RoundedRectangle(cornerRadius: 4)
    private let clearColors: [Color] = Array(repeating: .clear, count: 4)
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: !isAnimating)) { context in
            let elapsed = context.date.timeIntervalSince(startDate)
            let progress = elapsed.truncatingRemainder(dividingBy: duration) / duration
            let angle = progress * 360
            border(angle: angle)
        }
    }
    
    @ViewBuilder
    private func border(angle: Double) -> some View {
        shape
            .stroke(AngularGradient(colors: colors, center: .center), style: .init(lineWidth: 2, lineCap: .round, lineJoin: .round))
            .mask {
                shape
                    .fill(AngularGradient(colors: clearColors + colors + clearColors, center: .center, angle: .degrees(angle)))
            }
            .padding(-2)
            .opacity(hideHilight ? 0 : 1)
    }
}
