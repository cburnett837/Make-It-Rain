//
//  CircleDot.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/28/24.
//

import SwiftUI

struct CircleDot: View {
    let color: Color?
    var width: CGFloat = 20
    var body: some View {
        ZStack {
            Text("") /// Used just for positioning.
            Circle()
                .fill(color ?? .primary)
                .frame(width: 5, height: 5)
        }
        .frame(width: width)
    }
}


struct CircleDotGradient: View {
    var width: CGFloat = 20
    var body: some View {
        ZStack {
            Text("") /// Used just for positioning.
            Circle()
                .fill(AngularGradient(gradient: Gradient(colors: [.red, .yellow, .green, .blue, .purple, .red]), center: .center))
                .frame(width: 5, height: 5)
        }
        .frame(width: width)
    }
}
