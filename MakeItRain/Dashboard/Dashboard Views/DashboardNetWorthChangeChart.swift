//
//  DashboardNetWorthChangeChart.swift
//  MakeItRain
//
//  Created by Cody Burnett on 8/13/26.
//

import SwiftUI
import Charts

struct DashboardNetWorthChangeChart: View {
    @Environment(CalendarModel.self) private var calModel
    @Bindable var model: DashboardModel
    @Bindable var data: DashboardData
    
    @State private var annotationHeight: CGFloat = 0
    @State private var chartScroll: Date?
    @State private var rawSelectedDate: Date?
    
    enum SelectedBreakdown {
        case month(DashboardDataByMonth)
        case quarter(DashboardDataByQuarter)
    }
    
    var selectedQuarter: DashboardDataByQuarter? {
        guard let rawSelectedDate else { return nil }

        return data.quarterlyBreakdowns.first { quarter in
            rawSelectedDate >= quarter.date &&
            rawSelectedDate < quarter.endDate
        }
    }

    var selectedMonth: DashboardDataByMonth? {
        guard let rawSelectedDate else { return nil }

        return data.monthlyBreakdowns.first {
            Calendar.current.isDate(
                rawSelectedDate,
                equalTo: $0.date,
                toGranularity: .month
            )
        }
    }

    var selectedSummary: (any DashboardBreakdownSummary)? {
        switch data.breakdownType {
        case .monthly:      selectedMonth
        case .quarterly:    selectedQuarter
        }
    }
    
    var selectedID: String? {
        switch data.breakdownType {
        case .monthly:      selectedMonth?.id
        case .quarterly:    selectedQuarter?.id
        }
    }
    
    
    var annotationColor: AnyShapeStyle {
        AnyShapeStyle(
            LinearGradient(
                stops: [
                    .init(color: .orange, location: 0),
                    .init(color: .green, location: 1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
    
    func circleColor(for point: DashboardBreakdownSummary) -> Color {
        (point.startingAmount ?? 0) > 0 ? .green : .red
    }
        
    var lineStyle: some ShapeStyle {
        let amounts = switch data.breakdownType {
        case .monthly:
            data.monthlyBreakdowns.map { ($0.startingAmount ?? 0) }
        case .quarterly:
            data.quarterlyBreakdowns.map { ($0.startingAmount ?? 0) }
        }
                        
        if amounts.allSatisfy({ $0 > 0 }) { return AnyShapeStyle(Color.green) }
        if amounts.allSatisfy({ $0 < 0 }) { return AnyShapeStyle(Color.red) }
                
        let epsilon = 0.0001
        
        let gradientPos = switch data.breakdownType {
        case .monthly:
            Helpers.getChartGradientPosition(from: data.monthlyBreakdowns, budget: 0, value: \.startingAmount)
            
        case .quarterly:
            Helpers.getChartGradientPosition(from: data.quarterlyBreakdowns, budget: 0, value: \.startingAmount)
        }
        
        let transition = CGFloat(
            NSDecimalNumber(decimal: min(max(gradientPos ?? 0.5, 0.001), 0.999)).doubleValue
        )

        return AnyShapeStyle(
            LinearGradient(
                stops: [
                    .init(color: .red, location: max(0, transition - epsilon)),
                    .init(color: .green, location: min(1, transition + epsilon))
                ],
                startPoint: .bottom,
                endPoint: .top
            )
        )
    }

    
    var body: some View {
        Card {
            HStack(spacing: 0) {
                Menu {
                    ForEach(DashboardMontlyOrQuarterlyBreakdowns.allCases, id: \.self) { opt in
                        Button {
                            withAnimation {
                                data.breakdownType = opt
                            }
                        } label: {
                            Text(opt.rawValue)
                        }
                    }
                } label: {
                    Text(data.breakdownType.rawValue)
                        .bold()
                }
                .padding(.leading, 12)
                
                Text(" Net Worth Change")
                    .foregroundStyle(.secondary)
                    .font(.headline)
                    .layoutPriority(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        } footer: {
            Text("Note: This chart is not influenced by categorical filters.")
                .foregroundStyle(.secondary)
                .font(.caption)
        } content: {
            compareChart
                .overlay(alignment: .top) {
                    if let _ = selectedMonth {
                        selectedDataView
                    }
                }
        }
    }
    
    var compareChart: some View {
        Chart {
            if let selectedSummary = selectedSummary {
                let date = switch data.breakdownType {
                case .monthly:
                    selectedSummary.date
                case .quarterly:
                    selectedSummary.date.startDateOfQuarter
                }
                RuleMark(x: .value("Start Date", date, unit: .day))
                    .foregroundStyle(Color.secondary.opacity(0.5))
            }
            
            switch data.breakdownType {
            case .monthly:
                ForEach(data.monthlyBreakdowns) { month in
                    LineMark(
                        x: .value("Date", month.date, unit: .day),
                        y: .value("Amount", (month.startingAmount ?? 0)),
                        series: .value("Type", "Starting")
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(lineStyle)
                    .symbol {
                        Circle()
                            .fill(circleColor(for: month))
                            .frame(width: 5, height: 5)
                    }
                }
            case .quarterly:
                ForEach(data.quarterlyBreakdowns) { quarter in
                    LineMark(
                        x: .value("Start Date", quarter.date.startDateOfQuarter, unit: .day),
                        y: .value("Amount", (quarter.startingAmount ?? 0)),
                        series: .value("Type", "Balance")
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(lineStyle)
                    .symbol {
                        Circle()
                            .fill(circleColor(for: quarter))
                            .frame(width: 5, height: 5)
                    }
                }
            }
        }
        .frame(height: 150)
        .sensoryFeedback(.selection, trigger: selectedID)
        .chartXSelection(value: $rawSelectedDate)
        .chartYAxis { yAxis() }
        //.chartLegend(position: .top, alignment: .leading, spacing: 8)
//        .chartForegroundStyleScale(
//            domain: ["Balance", "Payment"],
//            range: [.orange, .green]
//        )
    }
    
    
    
    
    
    @AxisContentBuilder
    func yAxis() -> some AxisContent {
        AxisMarks { axisValue in
            AxisGridLine()
            AxisTick()
            AxisValueLabel {
                if let value = axisValue.as(Double.self) {
                    Text("$\(value.kVersion)")
                }
            }
        }
    }
    
    @ViewBuilder
    var selectedDataView: some View {
        if let item = selectedSummary {
            VStack {
                VStack(alignment: .leading) {
                    HStack {
                        Text(item.title)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .lineLimit(1)

                        Spacer()
                    }
                    .font(.headline)

                    Divider()

                    Grid(alignment: .leading) {
                        GridRow {
                            Text("Beginning Balance").bold()
                            Text(((item.startingAmount ?? 0)).currencyWithDecimals())
                        }
                    }
                    .font(.subheadline)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(circleColor(for: item))
                )
                .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal)
            .background {
                GeometryReader { geo in
                    Color.clear
                        .onAppear { annotationHeight = geo.size.height }
                        .onChange(of: geo.size.height) { annotationHeight = $1 }
                }
            }
            .offset(y: -annotationHeight - 8)
            .zIndex(10)
        }
    }
}
