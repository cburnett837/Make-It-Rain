//
//  AnimatedBrain.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/8/25.
//


import SwiftUI

struct AiAnimatedSwishSymbol: View {
    @State private var progress: CGFloat = 0
    
    var symbol: String
    var baseColor: Color = .gray
    @Binding var hasAnimated: Bool
    
    //let colors: [Color] = [.purple, .red, .orange, .green, .blue]
    //let colors: [Color] = [.purple, .pink, .orange]
    let colors: [Color] = [.orange, .orange, .pink, .purple]
    
    var body: some View {
        ZStack {
            image
                .foregroundStyle(baseColor)
            image
                .foregroundStyle(colorGradient)
                .mask(
                    GeometryReader { geo in
                        swishGradient
                            .clipShape(.circle)
                            .offset(x: calcPosition(-geo.size.width, geo.size.width, progress))
                    }
                )
                .onAppear(perform: animate)
        }
    }
    
    var image: some View {
        Image(systemName: symbol)
    }
    
    var colorGradient: some ShapeStyle {
        LinearGradient(
            colors: colors,
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    var swishGradient: some View {
        LinearGradient(
            stops: [
                .init(color: .clear, location: 0),
                .init(color: .white, location: 0.4),
                .init(color: .white, location: 1)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    func animate() {
       // if !hasAnimated {
            hasAnimated = true
            withAnimation(.easeOut(duration: 2)) {
                progress = 1.2
            }
        //}
    }
    
    private func calcPosition(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat { a + (b - a) * t }
}
