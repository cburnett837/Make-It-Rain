//
//  ChartCircleDot.swift
//  MakeItRain
//
//  Created by Cody Burnett on 3/8/25.
//

import SwiftUI
import Charts

struct ChartCircleDot: View {
    
    var budget: Double
    var expenses: Double
    var color: Color
    var size: CGFloat
    
    var body: some View {
        Chart {
            
            
            if abs(expenses) == 0 && abs(budget) == 0 {
                SectorMark(angle: .value("Budget", 1))
                    .foregroundStyle(color)
                    .opacity(0.5)
            } else {
                if abs(expenses) < abs(budget) {
                    SectorMark(angle: .value("Budget", abs(budget - abs(expenses))))
                        .foregroundStyle(color)
                        .opacity(0.5)
                }
                SectorMark(angle: .value("Expenses", abs(expenses)))
                    .foregroundStyle(color)
                    .opacity(1)
            }
            
        }
        .frame(maxWidth: size, maxHeight: size)
    }
}
