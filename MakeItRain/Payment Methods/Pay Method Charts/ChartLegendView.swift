//
//  LegendView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/30/25.
//


import SwiftUI
import Charts

struct ChartLegendView: View {
    var items: [(id: UUID, title: String, color: Color)]
    
    var body: some View {
        ScrollView(.horizontal) {
            ZStack {
                Spacer()
                    .containerRelativeFrame([.horizontal])
                    .frame(height: 1)
                                            
                HStack(spacing: 0) {
                    ForEach(items, id: \.id) { item in
                        HStack(alignment: .circleAndTitle, spacing: 5) {
                            Circle()
                                .fill(item.color)
                                .frame(maxWidth: 8, maxHeight: 8) // 8 seems to be the default from charts
                                .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title)
                                    .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
                            }
                            .foregroundStyle(Color.secondary)
                            .font(.caption2)
                        }
                        .padding(.trailing, 8)
                        .contentShape(Rectangle())
                    }
                    Spacer()
                }
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        .contentMargins(.bottom, 10, for: .scrollContent)
    }
}
