//
//  TextWithCircleBackground.swift
//  MakeItRain
//
//  Created by Cody Burnett on 4/2/25.
//


import SwiftUI

struct TextWithCircleBackground: View {
    let text: String
    @State private var width: CGFloat = .zero
    @State private var height: CGFloat = .zero

    var body: some View {
        ZStack {
            if (!width.isZero && !height.isZero) {
                Capsule()
                    .fill(Color.secondary.opacity(0.5))
                    //.strokeBorder()
                    .frame(
                        width: height >= width ? height : width,
                        height: height
                    )
            }
            
            Text(text)
                .padding(4)
                .background(
                    GeometryReader { geo in
                        Color.clear.onAppear() {
                            //radius = max(geo.size.width, geo.size.height)
                            width = geo.size.width
                            height = geo.size.height
                        }
                    }.hidden()
                )
            
        }
    }
}