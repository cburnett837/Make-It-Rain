//
//  DashboardChartLegend.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/16/26.
//


import SwiftUI
import Charts

struct DashboardChartLegend: View {
    @Environment(CalendarModel.self) private var calModel
    @Bindable var data: DashboardData
    
    var categories: [CBCategory] {
        return (data.categories + data.categoryGroups.flatMap { $0.categories })
            .sorted(by: Helpers.categorySorter())
            .uniqued(on: { $0.id })
    }
    
    var body: some View {
        ScrollView(.horizontal) {
            ZStack {
                Spacer()
                    .containerRelativeFrame([.horizontal])
                    .frame(height: 1)
                                            
                HStack(spacing: 0) {
                    ForEach(categories) { cat in
                        HStack(alignment: .circleAndTitle, spacing: 5) {
                            //Text("\(item.category.active)")
                            Circle()
                                .fill(cat.color)
                                .frame(maxWidth: 8, maxHeight: 8) // 8 seems to be the default from charts
                                .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(cat.title)
                                    .foregroundStyle(Color.secondary)
                                    .font(.caption2)
                                    .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
                            }
                        }
                        .padding(.horizontal, 4)
                        .contentShape(Rectangle())
                    }
                    Spacer()
                }
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        .contentMargins(.vertical, 10, for: .scrollContent)
    }
    
//    var body: some View {
//        ScrollView {
//            ZStack {
////                Spacer()
////                    .containerRelativeFrame([.horizontal])
////                    .frame(height: 1)
//                                            
//                VStack(alignment: .leading, spacing: 5) {
//                    ForEach(categories) { cat in
//                        HStack(alignment: .circleAndTitle, spacing: 5) {
//                            //Text("\(item.category.active)")
//                            Circle()
//                                .fill(cat.color)
//                                .frame(maxWidth: 8, maxHeight: 8) // 8 seems to be the default from charts
//                                .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
//                            
//                            VStack(alignment: .leading, spacing: 2) {
//                                Text(cat.title)
//                                    .foregroundStyle(Color.secondary)
//                                    .font(.caption2)
//                                    .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
//                            }
//                        }
//                        .padding(.horizontal, 4)
//                        .contentShape(Rectangle())
//                    }
//                    Spacer()
//                }
//            }
//        }
//        .scrollBounceBehavior(.basedOnSize)
//        //.contentMargins(.vertical, 10, for: .scrollContent)
//        .frame(height: 150)
//    }
}
