//
//  GradientCircleDot.swift
//  MakeItRain
//
//  Created by Cody Burnett on 4/17/26.
//

import SwiftUI

struct GradientCircleDot: View {
    var size: Double = 20
    var colors: [Color]
    var body: some View {
        Circle()
            .fill(AngularGradient(gradient: Gradient(stops: getReversedColors(colors)), center: .center))
            .frame(width: size, height: size)
    }
    
    
    func getReversedColors(_ colors: Array<Color>) -> Array<Gradient.Stop> {
        let count = colors.count
        let step = 1.0 / Double(count)
        let epsilon = 0.00001

        // For sharp edges, we give each color two stops: start and end.
        let stops: [Gradient.Stop] = colors.enumerated().flatMap { index, color in
            let start = Double(index) * step
            let end = start + step - epsilon // Slightly before the next color's start
            return [
                Gradient.Stop(color: color, location: start),
                Gradient.Stop(color: color, location: end)
            ]
        }
        
        return stops
    }
}
