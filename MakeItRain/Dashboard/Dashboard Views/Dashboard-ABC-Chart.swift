//
//  DashboardActivityByCategoryChart.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/16/26.
//


import SwiftUI
import Charts

fileprivate struct HeightMeasurer: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geo in
                    Color.clear
                        .preference(key: DashboardViewHeightKey.self, value: geo.size.height)
                }
            )
    }
}

fileprivate extension View {
    func measureHeight() -> some View {
        self.modifier(HeightMeasurer())
    }
}

fileprivate struct DashboardViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct DashboardActivityByCategoryChart: View {
    enum Tabs: String, CaseIterable {
        case horizontalBar
        case verticalBar
        case pie
        
        var imageName: String {
            switch self {
            case .horizontalBar: "chart.bar.fill"
            case .verticalBar: "chart.bar.fill"
            case .pie: "chart.pie.fill"
            }
        }
    }
    
    @AppStorage("dashboardSelectedChartPageTabThing") var selectedTab: Tabs = .horizontalBar
    @Environment(CalendarModel.self) private var calModel
    @Environment(AppStore.self) private var store
    
    @Bindable var model: DashboardModel
    @Bindable var data: DashboardData
    var isForSelectedMonth: Bool
    @Binding var navPath: [NavDest]
    
    @State private var selectedCategory1: CBCategory?
    @State private var selectedCategory2: CBCategory?
    @State private var selectedCategory3: CBCategory?
    
    //let columnGrid = Array(repeating: GridItem(.flexible(), spacing: 0, alignment: .top), count: 6)
    
    enum ChartRow: String {
        case budget = "Budget"
        case spending = "Spending"
        case income = "Money In"
    }
    
    var amount: Decimal {
        data.categoryAndGroupBudget - (model.shouldUseTotalSpending ? data.allAmounts.totalSpend : data.allAmounts.actualSpend)
    }
    
    var isOver: Bool { amount < 0 }
    var overUnder: String { abs(amount).currencyWithDecimals() }
    
    var message: AttributedString {
        let leftovers = calculateLeftovers()
        let spendingAmount = model.shouldUseTotalSpending ? data.allAmounts.totalSpend : data.allAmounts.actualSpend
        
        return AttributedString.build {
            if isForSelectedMonth {
                "Your cash flow \(leftovers.1 ? "increased by" : "decreased by") "
                
                "\(leftovers.0)"
                    .foreground(leftovers.1 ? .green : .red)
                
                ", and you are currently "
            } else {
                "You are currently "
            }
            
            overUnder
                .foreground(isOver ? .red : .green)

            " \(isOver ? "over" : "under") your categorical budget of "
            "\(data.categoryAndGroupBudget.currencyWithDecimals()), having spent "

            spendingAmount
                .currencyWithDecimals()
                .bold()
            "."
        }
    }
    
    
    func calculateLeftovers() -> (String, Bool) {
        var amount: Decimal = 0.0
        if let start = calModel.sMonth.startingAmounts.filter({ $0.payMethod?.isUnifiedDebit == true }).first {
            let eom = CalcHelper.calculateTotal(for: calModel.sMonth, using: start.payMethod, and: .giveMeLastDayEod, store: store)
            let change = eom - start.amount
            amount = change
                        
            if start.payMethod?.isCreditOrLoan == true || start.payMethod?.isUnifiedCredit == true {
                return (abs(amount).currencyWithDecimals(), change < 0)
            } else {
                return (abs(amount).currencyWithDecimals(), change > 0)
            }
        } else {
            return ((0.0).currencyWithDecimals(), false)
        }
    }
    
    @State private var tabHeight: CGFloat = 100
    
    
    var body: some View {
        VStack(spacing: 24) {
            Card(layer: .two) {
                Text(message)
                    .frame(maxWidth: .infinity, alignment: .leading)
                //.padding(.bottom, 10)
            }
            
            
            VStack(spacing: 0) {
                Text(selectedTab == .verticalBar ? "Spending" : "Spending & Income")
                    .padding(.leading, 12)
                    .foregroundStyle(.secondary)
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                
//                switch selectedTab {
//                case .horizontalBar:
//                    Card(layer: .two) {
//                        DashboardActivityByCategoryHorizontalBarChart(model: model, data: data, selectedCategory: $selectedCategory1)
//                    }
//                case .verticalBar:
//                    Card(layer: .two) {
//                        DashboardActivityByCategoryPieChart(model: model, data: data, selectedCategory: $selectedCategory2)
//                    }
//                case .pie:
//                    Card(layer: .two) {
//                        DashboardActivityByCategoryVerticalBarChart(
//                            model: model,
//                            data: data,
////                                selectedCategory: $selectedCategory3
//                        )
//                    }
//                case .guage:
//                    Card(layer: .two) {
//                        DashboardActivityByCategoryVerticalBarChart(
//                            model: model,
//                            data: data,
////                                selectedCategory: $selectedCategory3
//                        )
//                    }
//                }
                
                TabView(selection: $selectedTab) {
                    Tab(value: Tabs.horizontalBar) {
                        Card(layer: .two) {
                            DashboardActivityByCategoryHorizontalBarChart(model: model, data: data, selectedCategory: $selectedCategory1)
                        }
                        .measureHeight()
                    } label: {
                        Label("Bar Chart", systemImage: "chart.bar.yaxis")
                    }
                    
                    Tab(value: Tabs.verticalBar) {
                        Card(layer: .two) {
                            DashboardActivityByCategoryVerticalBarChart(
                                model: model,
                                data: data,
                                selectedCategory: $selectedCategory3
                            )
                        }
                        .measureHeight()
                    } label: {
                        Label("Bar Chart", systemImage: "chart.bar.xaxis")
                    }
                    
                    Tab(value: Tabs.pie) {
                        Card(layer: .two) {
                            DashboardActivityByCategoryPieChart(model: model, data: data, selectedCategory: $selectedCategory2)
                        }
                        .measureHeight()                        
                    } label: {
                        Label("Pie Chart", systemImage: "chart.pie")
                    }
                }
                .frame(height: tabHeight)
                .onPreferenceChange(DashboardViewHeightKey.self) { measuredHeight in
                    if measuredHeight > 0 {
                        self.tabHeight = measuredHeight
                    }
                }
                //.frame(height: 250)
                #if os(iOS)
                .tabViewStyle(.page(indexDisplayMode: .never))
                #endif
                .overlay(alignment: .top) {
                    if let category = selectedCategory1 ?? selectedCategory2 ?? selectedCategory3 {
                        VStack {
                            Spacer()
                                .frame(height: 20)

                            DashboardActivityByCategoryAnnotation(category: category)
                        }
                    }
                }
                
                /// Have to use a custom tab indicator since the tabview doesn't place nice with automatic sizing.
                HStack {
                    ForEach(Tabs.allCases, id: \.self) { tab in
                        Image(systemName: tab.imageName)
                            .foregroundStyle(selectedTab == tab ? .primary : .secondary)
                            .onTapGesture { selectedTab = tab }
                            .if(tab == .horizontalBar) {
                                $0.rotationEffect(Angle(degrees: 90))
                            }
                    }
                }
                .font(.caption2)
                .padding(.top, 5)
            }
            
            DashboardActivityByCategoryTable(model: model, isForSelectedMonth: isForSelectedMonth, navPath: $navPath)
        }
    }
//    
//    
//    var bodyOG: some View {
//        VStack(spacing: 24) {
//            Card(layer: .two) {
//                Text(message)
//                    .frame(maxWidth: .infinity, alignment: .leading)
//                //.padding(.bottom, 10)
//            }
//            
////            Divider()
////                .padding(.vertical, 10)
//            
////            if !model.categories.filter({ $0.type == .payment }).isEmpty {
////                Text("(Note that the spending amount contains credit payments, which could be classified as a transfer. To see true spending, remove the credit payment category from the filter list.)")
////                    .foregroundStyle(.secondary)
////                    .font(.caption2)
////                    .padding(.vertical, 10)
////                    .bold()
////
////                Divider()
////            }
//            
//
//            Card(layer: .two, title: "Spending & Income") {
//                TabView(selection: $selectedTab) {
//                    Tab(value: Tabs.horizontalBar) {
//                        VStack {
//                            DashboardActivityByCategoryHorizontalBarChart(model: model, data: data, selectedCategory: $selectedCategory)
//                            Spacer()
//                        }
//                    } label: {
//                        Label("Bar Chart", systemImage: "chart.bar.yaxis")
//                        //                    Image(systemName: "chart.bar.yaxis")
//                    }
//                    
//                    Tab(value: Tabs.pie) {
//                        VStack {
//                            DashboardActivityByCategoryPieChart(model: model, data: data, selectedCategory: $selectedCategory)
//                            Spacer()
//                        }
//                    } label: {
//                        Label("Pie Chart", systemImage: "chart.pie")
//                        //                    Image(systemName: "chart.pie")
//                    }
//                }
//                .frame(height: 200)
//                #if os(iOS)
//                .tabViewStyle(.page)
//                #endif
//                .padding(.bottom, -20) /// Remove the padding under the page indicators
//                .overlay(alignment: .top) {
//                    if let category = selectedCategory {
//                        DashboardActivityByCategoryAnnotation(category: category)
//                    }
//                }
//                #if os(iOS)
//                /// Tab indicators don't show in light mode.
//                .onAppear {
//                    UIPageControl.appearance().currentPageIndicatorTintColor = UIColor.label
//                    UIPageControl.appearance().pageIndicatorTintColor = UIColor.secondaryLabel.withAlphaComponent(0.35)
//                }
//                #endif
//            }
//                         
//            DashboardActivityByCategoryTable(model: model, isForSelectedMonth: isForSelectedMonth, navPath: $navPath)
//        }
//    }
}



fileprivate struct DashboardActivityByCategoryTable: View {
    @AppStorage("dashboardIsBreakdownExpanded") var isBreakdownExpanded: Bool = false
    @Environment(CalendarModel.self) private var calModel
    @Environment(AppStore.self) private var store
    
    @Bindable var model: DashboardModel
    var isForSelectedMonth: Bool
    @Binding var navPath: [NavDest]
    
    @State private var isBreakdownExpandedLocal: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            Card(layer: .two, title: "Breakdown") {
                if isBreakdownExpandedLocal {
                    DashboardExpenseByCategoryTable(
                        model: model,
                        navPath: $navPath,
                        isForSelectedMonth: isForSelectedMonth
                    )
                }
            }
            .onAppear { isBreakdownExpandedLocal = isBreakdownExpanded }
            .onChange(of: isBreakdownExpandedLocal) { isBreakdownExpanded = $1 }
            
            Button {
                withAnimation { isBreakdownExpandedLocal.toggle() }
            } label: {
                Card(layer: .two) {
                    Text(isBreakdownExpandedLocal ? "Hide Breakdown" : "View")
                        .foregroundStyle(Color.theme)
                }
                .contentShape(.rect)
            }
            #if os(iOS)
            /// Use this to prevent the text from chaning position seperately from the button itself.
            /// https://stackoverflow.com/questions/75446318/animate-a-buttons-text-and-position-at-the-same-time-in-swiftui
            .drawingGroup()
            #endif
            .buttonStyle(.plain)
        }
    }
}
