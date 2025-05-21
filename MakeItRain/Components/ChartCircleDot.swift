//
//  ChartCircleDot.swift
//  MakeItRain
//
//  Created by Cody Burnett on 3/8/25.
//

import SwiftUI
import Charts
//
//struct ChartCircleDot: View {
//    
//    var budget: Double
//    var expenses: Double
//    var color: Color
//    var size: CGFloat
//    
//    var body: some View {
//        VStack {
//            Text(color.toHex() ?? "")
//            Chart {
//                if abs(expenses) == 0 && abs(budget) == 0 {
//                    SectorMark(angle: .value("Budget", 1))
//                        .foregroundStyle(color)
//                        .opacity(0.5)
//                } else {
//                    if abs(expenses) < abs(budget) {
//                        SectorMark(angle: .value("Budget", abs(budget - abs(expenses))))
//                            .foregroundStyle(color)
//                            .opacity(0.5)
//                    }
//                    SectorMark(angle: .value("Expenses", abs(expenses)))
//                        .foregroundStyle(color)
//                        .opacity(1)
//                }
//                
//            }
//            .frame(maxWidth: size, maxHeight: size)
//        }
//        
//    }
//}
//
//



struct ChartCircleDot: View {
    var budget: Double
    var expenses: Double
    var color: Color
    var size: CGFloat
    
    /// If the budget is 0, change it to 1 so the chart can calculate
    var adjustedBudget: Double { budget == 0 ? 1 : budget }
    
    /// If the budget is 0, change these to 100 so that the chart gradient get's applied (since any expenses greater than 0 would be considered over-budget)
    var adjustmentAmount: Double { budget == 0 ? 100 : 1 }
    var adjustmentAmount2: Double { budget == 0 ? 100 : 0 }
    
    var isOverBudget: Bool { abs(expenses) > abs(adjustedBudget) }
    var percentage: Double { (abs(expenses) + adjustmentAmount2) / abs(adjustedBudget * adjustmentAmount) }

    var colors: [Color] {
        isOverBudget ? [color.darker(by: 15.0), color.lighter(by: 15.0)] : [color]
    }
    
    /// Make the gradient calculate like it's only 1 loop.
    /// For example, if you have a budget of 100, and expenses of 1000, the gradient would fade away the large the expense number got. This prevents that.
    var endAngle: Double {
        (270 + (360 * percentage).truncatingRemainder(dividingBy: 360))
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.5))
                .frame(width: size, height: size)

            if expenses != 0 {
                PieSlice(percentage: percentage)
                    .fill(AngularGradient(
                        gradient: Gradient(colors: colors),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(endAngle)
                    ))
                    .frame(width: size, height: size)
            }
        }
        .frame(width: size, height: size)
    }
    
    
    struct PieSlice: Shape {
        var percentage: Double

        func path(in rect: CGRect) -> Path {
            var path = Path()

            let center = CGPoint(x: rect.midX, y: rect.midY)
            let radius = min(rect.width, rect.height) / 2
            let endAngle = Angle(degrees: 360 * percentage)

            path.move(to: center)
            path.addArc(
                center: center,
                radius: radius,
                startAngle: .degrees(-90), // top start
                endAngle: .degrees(-90) + endAngle,
                clockwise: false
            )
            path.closeSubpath()

            return path
        }
    }
}
