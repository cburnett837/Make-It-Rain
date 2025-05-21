//
//  MultiAnalyticChart.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/9/25.
//

import SwiftUI
import Charts


struct PayMethodChart: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss

    @Local(\.incomeColor) var incomeColor
    @Local(\.useWholeNumbers) var useWholeNumbers
    @Local(\.colorTheme) var colorTheme
    @Local(\.threshold) var threshold
    
    //@AppStorage("monthlyAnalyticChartVisibleYearCount") private var chartVisibleYearCount: PayMethodChartRange = .year1
    @AppStorage("profitLossStyle") private var profitLossStyle: String = "amount"
    @AppStorage("showIncomeOnAnalyticChart") private var showIncome: Bool = true
    @AppStorage("showIncomeAndPositiveAmountsOnAnalyticChart") private var showIncomeAndPositiveAmountsOnAnalyticChart: Bool = true
    @AppStorage("showPositiveAmountsOnAnalyticChart") private var showPositiveAmountsOnAnalyticChart: Bool = true
    @AppStorage("showExpensesOnAnalyticChart") private var showExpenses: Bool = true
    @AppStorage("showPaymentsOnAnalyticChart") private var showPayments: Bool = true
    @AppStorage("showStartingAmountsOnAnalyticChart") private var showStartingAmounts: Bool = true
    @AppStorage("showProfitLossOnAnalyticChart") private var showProfitLoss: Bool = true
    
    @AppStorage("showMonthEndOnAnalyticChart") private var showMonthEnd: Bool = true
    @AppStorage("showMinEodOnAnalyticChart") private var showMinEod: Bool = true
    @AppStorage("showMaxEodOnAnalyticChart") private var showMaxEod: Bool = true
    
    //@AppStorage("profitLossMetrics") private var profitLossMetrics: String = "all"
    @ChartOption(\.profitLossMetrics) var profitLossMetrics
    @ChartOption(\.showOverviewDataPerMethodOnUnifiedChart) var showOverviewDataPerMethodOnUnifiedChart
    //@ChartOption(\.chartCropingStyle) var chartCropingStyle
    

    
    @AppStorage("showAllCategoryChartData") private var showAllChartData = false
    
    @Environment(PayMethodModel.self) private var payModel
    
    let threeColumnGrid = Array(repeating: GridItem(.flexible(), spacing: 0, alignment: .topLeading), count: 3)
    
    @Bindable var vm: PayMethodViewModel
    @Binding var editID: String?
    var payMethod: CBPaymentMethod
    
    @State private var flipZindex: Bool = false
    @State private var showNonScrollingHeader: Bool = false
    @State private var headerHeight: CGFloat = 0
    
    @FocusState private var focusedField: Int?
    @State private var showSearchBar = false
    @State private var searchText = ""
    @State private var selectedBreakdowns: Breakdown?
    @State private var rawSelectedDate: Date?
                
    var filteredBreakdowns: [PayMethodMonthlyBreakdown] {
        if let first = vm.payMethods.first {
            return first
                .breakdowns
                //.filter { chartVisibleYearCount == .yearToDate ? $0.year == AppState.shared.todayYear : true }
                .filter { searchText.isEmpty ? true : $0.date.string(to: .monthNameYear).localizedStandardContains(searchText) }
                .sorted(by: { $0.date > $1.date })
        } else {
            return []
        }
    }
    
    struct MaxHeaderHeightPreferenceKey: PreferenceKey {
        static var defaultValue: CGFloat = .zero

        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = max(value, nextValue())
        }
    }
    
    
    // MARK: - Views
    var body: some View {
        chartPage3
            //.onChange(of: vm.payMethods) { vm.prepareData() }
            //.task { vm.prepareData() }
            //.onChange(of: chartVisibleYearCount) { vm.chartVisibleYearCount = $1 }
            //.onChange(of: incomeType) { vm.incomeType = $1 }
    }
    

    var chartPage3: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                if showNonScrollingHeader {
                    VStack {
                        chartHeaderContainer
                            .background {
                                GeometryReader { geo in
                                    Color.clear.preference(key: MaxHeaderHeightPreferenceKey.self, value: geo.size.height)
                                }
                            }
                            .onPreferenceChange(MaxHeaderHeightPreferenceKey.self) { headerHeight = max(headerHeight, $0) }
                        
                        Spacer()
                    }
                    .zIndex(1)
                }
                
                ScrollView {
                    VStack(spacing: 0) {
                        chartHeaderContainer
                            .opacity(showNonScrollingHeader ? 0 : 1)
                            .background {
                                GeometryReader { geo in
                                    Color.clear.preference(key: MaxHeaderHeightPreferenceKey.self, value: geo.size.height)
                                }
                            }
                            .onPreferenceChange(MaxHeaderHeightPreferenceKey.self) { headerHeight = max(headerHeight, $0) }
                        
                        
                        VStack(alignment: .leading, spacing: 6) {
                            incomeExpenseChartWidget
                            profitLossChartWidget
                            
                            minMaxEodChartWidget
                                                                                    
                            if payMethod.isUnified {
                                metricsByMethodChartWidget
                            }
                            
                            Divider()
                            
                            rawDataList
                        }
                        .padding(.horizontal, 12)
                        .padding(.top, 12)
                    }
                }
                .scrollIndicators(.hidden)
                .onScrollGeometryChange(for: CGFloat.self) {
                    $0.contentOffset.y + $0.contentInsets.top
                } action: {
                    if $1 > 0 {
                        flipZindex = true
                        showNonScrollingHeader = true
                    } else if $1 == 0 {
                        flipZindex = false
                        showNonScrollingHeader = false
                    }
                    
//                    if $1 > topChartHeaderHeight {
//                        flipZindex = true
//                    } else {
//                        flipZindex = false
//                    }
                }
                .zIndex(flipZindex ? 0 : 1)
            }
        }
        .sheet(item: $selectedBreakdowns) { breakdowns in
            BreakdownView(payMethod: payMethod, breakdowns: breakdowns)
        }
    }
    
    
    var chartHeaderContainer: some View {
        VStack(spacing: 0) {
            SheetHeader(
                title: payMethod.title,
                close: { editID = nil; dismiss() },
                view1: { refreshButton },
                view2: {
                    Menu {
                        Section("This Year Style") {
                            Picker(selection: $vm.chartCropingStyle) {
                                Text("Whole year")
                                    .tag(ChartCropingStyle.showFullCurrentYear)
                                Text("Through current month")
                                    .tag(ChartCropingStyle.endAtCurrentMonth)
                            } label: {
                                Text(vm.chartCropingStyle.prettyValue)
                            }
                            .pickerStyle(.menu)
                        }
                        
                        Section("Overview Style") {
                            Picker(selection: $showOverviewDataPerMethodOnUnifiedChart) {
                                Text("View as summary only")
                                    .tag(false)
                                Text("View by payment method")
                                    .tag(true)
                            } label: {
                                Text(showOverviewDataPerMethodOnUnifiedChart ? "By payment method" : "As summary only")
                            }
                            .pickerStyle(.menu)
                            
                        }
                        
                    } label: {
                        Image(systemName: "checklist")
                    }
                }
            )
            
            if colorScheme == .dark {
                Divider()
                    //.padding(.horizontal)
            }
            
            VStack(spacing: 5) {
                chartVisibleYearPicker
                chartHeader
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)
            
            Divider()
                .padding(.horizontal, 12)
                .padding(.top, 12)
        }
        .background(Color(.systemBackground))
    }
    
    
    var chartHeader: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack {
                    Text("Insights By \(vm.viewByQuarter ? "Quarter" : "Month")")
                        .font(.title3)
                        .bold()
                    
                    Spacer()
                    
                    if payMethod.isCredit {
                        Text("Payments: \(vm.visiblePayments.currencyWithDecimals(useWholeNumbers ? 0 : 2))")
                            .foregroundStyle(.gray)
                            .font(.subheadline)
                    } else {
                        Text("Income: \(vm.visibleIncome.currencyWithDecimals(useWholeNumbers ? 0 : 2))")
                            .foregroundStyle(.gray)
                            .font(.subheadline)
                    }
                }
                
                HStack {
                    displayYearAndArrows
                                        
                    Spacer()
                    
                    Text("Expenses: \(vm.visibleExpenses.currencyWithDecimals(useWholeNumbers ? 0 : 2))")
                }
                .foregroundStyle(.gray)
                .font(.subheadline)
                //.padding(.bottom, 5)
                
                
                
            }
            Spacer()
        }
    }
    
    
    @ViewBuilder
    var displayYearAndArrows: some View {
        Button {
            vm.moveYears(forward: false)
        } label: {
            Image(systemName: "chevron.left")
        }
        .contentShape(Rectangle())
        
        displayYears
        
        Button {
            vm.moveYears(forward: true)
        } label: {
            Image(systemName: "chevron.right")
        }
        .contentShape(Rectangle())
    }
    
    
    var displayYears: some View {
        HStack(spacing: 5) {
            let lower = vm.visibleDateRangeForHeader.lowerBound.year
            let upper = vm.visibleDateRangeForHeader.upperBound.year
            
            var ytdText: String {
                if vm.chartCropingStyle == .endAtCurrentMonth {
                    if upper == lower && lower == AppState.shared.todayYear
                    || upper != lower && upper == AppState.shared.todayYear {
                        return " (YTD)"
                    }
                }
                return ""
            }
            
            if upper != lower {
                Text(String(lower))
                Text("-")
            }
                                                
            Text("\(String(upper))\(ytdText)")
        }
    }
    
    
    var refreshButton: some View {
        Button {
            payMethod.breakdowns.removeAll()
            payMethod.breakdownsRegardlessOfPaymentMethod.removeAll()
            Task {
                vm.fetchYearStart = AppState.shared.todayYear - 10
                vm.fetchYearEnd = AppState.shared.todayYear
                vm.payMethods.removeAll()
                vm.isLoadingHistory = true
                await vm.fetchHistory(for: payMethod, payModel: payModel, setChartAsNew: true)
            }
        } label: {
            Image(systemName: "arrow.triangle.2.circlepath")
        }
    }
        
    
    var chartVisibleYearPicker: some View {
        Picker("", selection: $vm.visibleYearCount) {
            Text("1Y").tag(PayMethodChartRange.year1)
            Text("2Y").tag(PayMethodChartRange.year2)
            Text("3Y").tag(PayMethodChartRange.year3)
            Text("4Y").tag(PayMethodChartRange.year4)
            Text("5Y").tag(PayMethodChartRange.year5)
            Text("10Y").tag(PayMethodChartRange.year10)
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .onChange(of: vm.visibleYearCount) { vm.setChartScrolledToDate($1) }
    }
            

    var rawDataList: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Data (\(String(vm.fetchYearStart)) - \(String(AppState.shared.todayYear)))")
                    .foregroundStyle(.gray)
                    .font(.subheadline)
                    //.padding(.leading, 6)
                
                Spacer()
                                                
                Button {
                    withAnimation {
                        showAllChartData.toggle()
                    }
                } label: {
                    Text(showAllChartData ? "Hide" : "Show")
                }
            }
                        
            
            Divider()
            
            if showAllChartData {
                VStack(spacing: 0) {
                    SearchTextField(title: "Dates", searchText: $searchText, focusedField: $focusedField, focusState: _focusedField)
                        .padding(.horizontal, -20)
                        .padding(.bottom, 5)
                                                                            
                    breakdownGrid
                }
                .padding(.bottom, 10)
            }
            
        }
    }
    
    
    var breakdownGrid: some View {
        LazyVGrid(columns: threeColumnGrid) {
            Text("Date").bold()
            Text("Income").bold()
            Text("Expenses").bold()
            Divider()
            Divider()
            Divider()
            
            ForEach(filteredBreakdowns) { breakdown in
                RawDataLineItem(breakdown: breakdown)
                    .onTapGesture {
                        let breakdowns = payMethod.breakdownsRegardlessOfPaymentMethod.filter { $0.month == breakdown.month && $0.year == breakdown.year }
                        let selectedBreakdowns = Breakdown(date: breakdown.date, breakdowns: breakdowns)
                        self.selectedBreakdowns = selectedBreakdowns
                    }
                
                Divider()
                Divider()
                Divider()
            }
            if vm.visibleYearCount != .yearToDate {
                Section {
                } header: {
                    loadMoreHistoryButton
                }
            }
        }
    }
        
    
    var loadMoreHistoryButton: some View {
        Button {
            vm.fetchMoreHistory(for: payMethod, payModel: payModel)
        } label: {
            Text("Fetch \(String(vm.fetchYearStart-10))-\(String(vm.fetchYearEnd-11))")
                .opacity(vm.isLoadingMoreHistory ? 0 : 1)
        }
        .disabled(vm.isLoadingMoreHistory)
        .buttonStyle(.borderedProminent)
        .overlay {
            ProgressView()
                .tint(.none)
                .opacity(vm.isLoadingMoreHistory ? 1 : 0)
        }
    }
    
    
    
    var incomeExpenseChartWidget: some View {
        VStack(alignment: .leading) {
            let description: LocalizedStringKey = "**Only income:**\nThe sum of amounts where transactions have an ***income*** category.\n\n**Money in only (no income):**\nThe sum of positive dollar amounts ***excluding*** transactions that have an income category.\n(Deposits, Refunds, Etc.)\n\n**All money in:**\nThe sum of ***all*** positive dollar amounts.\n(Income, Deposits, Refunds, Etc.)\n\n**Starting amount & all money in:**\nThat sum of all positive dollar amounts + the amount you started the month with."
                        
            WidgetLabelMenu(title: "All Expenses/Income", sections: [
                WidgetLabelOptionSection(title: "Income Type", options: [
                    WidgetLabelOption(content: AnyView(IncomeOptionToggle(vm: vm, description: description, show: $showIncome)))
                ])
            ])
                    
            IncomeExpenseChart(vm: vm, payMethod: payMethod, detailStyle: .overlay)
                .padding()
                .widgetShape()
        }
        .padding(.bottom, 30)
    }
    
    
    var profitLossChartWidget: some View {
        VStack(alignment: .leading) {
            WidgetLabelMenu(title: "Profit/Loss", sections: [
                WidgetLabelOptionSection(title: "Chart Style", options: [
                    WidgetLabelOption(content: AnyView(profitLossStyleMenu))
                ]),
                WidgetLabelOptionSection(title: "Metric Style", options: [
                    WidgetLabelOption(content: AnyView(profitLossMetricsMenu))
                ])
            ])
            
            ProfitLossChart(vm: vm, payMethod: payMethod)
                .padding()
                .widgetShape()
        }
        .padding(.bottom, 30)
    }
        
    
    var minMaxEodChartWidget: some View {
        VStack(alignment: .leading) {
            WidgetLabel(title: "Min/Max EOD Amounts")
            MinMaxEodChart(vm: vm, payMethod: payMethod)
                .padding()
                .widgetShape()
        }
        .padding(.bottom, 30)
    }
    
    
    var metricsByMethodChartWidget: some View {
        VStack(alignment: .leading) {
            WidgetLabel(title: "Expenses By Payment Method")
            ExpensesByPaymentMethodChart(vm: vm, payMethod: payMethod)
                .padding()
                .widgetShape()
        }
        .padding(.bottom, 30)
    }
    

    var profitLossStyleMenu: some View {
        Menu {
            Button("As amount") {
                profitLossStyle = "amount"
            }
            Button("As percentage") {
                profitLossStyle = "percentage"
            }
        } label: {
            Text(profitLossStyle.capitalized)
        }
    }
    
    
    
    var profitLossMetricsMenu: some View {
        Menu {
            Button("By Payment Method") {
                profitLossMetrics = "split"
            }
            Button("Summary") {
                profitLossMetrics = "summary"
            }
        } label: {
            Text(profitLossMetrics.capitalized)
        }
    }
}


fileprivate struct RawDataLineItem: View {
    @Local(\.incomeColor) var incomeColor
    @Local(\.useWholeNumbers) var useWholeNumbers
    var breakdown: PayMethodMonthlyBreakdown
    
    var body: some View {
        Group {
            Text(breakdown.date.string(to: .monthNameYear))
            
            Text(breakdown.income.currencyWithDecimals(useWholeNumbers ? 0 : 2))
                .foregroundStyle(.secondary)
                //.foregroundStyle(Color.fromName(incomeColor))
            
            Text(breakdown.expenses.currencyWithDecimals(useWholeNumbers ? 0 : 2))
                .foregroundStyle(.secondary)
                //.foregroundStyle(.red)
        }
        .font(.subheadline)
        .contentShape(Rectangle())
        
    }
}



fileprivate struct IncomeOptionToggle: View {
    @Local(\.colorTheme) var colorTheme
    @State private var showDescription = false
    
    @Bindable var vm: PayMethodViewModel
    var description: LocalizedStringKey
    @Binding var show: Bool
    
    /// Need this to prevent the button from animating.
    @State private var incomeText = ""
    
    var body: some View {
        VStack(alignment: .trailing) {
            HStack {
                Menu {
                    Button { change(to: .income) } label: {
                        menuOptionLabel(title: "Income only", isChecked: vm.incomeType == .income)
                    }
                    Button { change(to: .positiveAmounts) } label: {
                        menuOptionLabel(title: "Money in only (no income)", isChecked: vm.incomeType == .positiveAmounts)
                    }
                    Button { change(to: .incomeAndPositiveAmounts) } label: {
                        menuOptionLabel(title: "All money in", isChecked: vm.incomeType == .incomeAndPositiveAmounts)
                    }
                    Button { change(to: .startingAmountsAndPositiveAmounts) } label: {
                        menuOptionLabel(title: "Starting amount & all money in", isChecked: vm.incomeType == .startingAmountsAndPositiveAmounts)
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(incomeText)
                            .lineLimit(1)
//                        Image(systemName: "chevron.up.chevron.down")
//                            .font(.footnote)
                    }
                    .transaction {
                        $0.disablesAnimations = true
                        $0.animation = nil
                    }
                }
            }
            
            
//            if showDescription {
//                Text(description)
//                    .font(.caption2)
//                    .frame(maxWidth: .infinity, alignment: .trailing)
//                    .foregroundStyle(.secondary)
//            }
        }
        .onAppear {
            setText(incomeType: vm.incomeType)
        }
    }
    
    @ViewBuilder func menuOptionLabel(title: String, isChecked: Bool) -> some View {
        HStack {
            Text(title)
            if isChecked {
                Image(systemName: "checkmark")
            }
        }
    }
    
    func change(to option: IncomeType) {
        setText(incomeType: option)
        withAnimation {
            vm.incomeType = option
        }
    }
    
    func setText(incomeType: IncomeType) {
        switch incomeType {
        case .income:
            self.incomeText = IncomeType.income.prettyValue
            
        case .incomeAndPositiveAmounts:
            self.incomeText = IncomeType.incomeAndPositiveAmounts.prettyValue
            
        case .positiveAmounts:
            self.incomeText = IncomeType.positiveAmounts.prettyValue
            
        case .startingAmountsAndPositiveAmounts:
            self.incomeText = IncomeType.startingAmountsAndPositiveAmounts.prettyValue
        }
    }
}



fileprivate struct OptionToggle: View {
    @Local(\.colorTheme) var colorTheme
    @State private var showDescription = false
    
    var description: String
    var config: (title: String, enabled: Bool, color: Color)
    @Binding var show: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            Toggle(isOn: $show.animation()) {
                Label {
                    Text(config.title)
                } icon: {
                    Image(systemName: showDescription ? "xmark.circle" : "info.circle")
                    //.foregroundStyle(Color.fromName(colorTheme))
                }
                .onTapGesture { withAnimation { showDescription.toggle() } }
                .contentTransition(.symbolEffect(.replace.magic(fallback: .replace)))
                
            }
            .tint(config.color)
            
            if showDescription {
                Text(description)
                    .font(.caption2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

    

fileprivate struct ShowHideOptionButton: View {
    @Local(\.colorTheme) var colorTheme
    @State private var showDescription = false
    
    var text: String
    var description: String
    @Binding var show: Bool
    
    var body: some View {
        VStack(alignment: .trailing) {
            HStack {
                Image(systemName: showDescription ? "xmark.circle" : "info.circle")
                    .contentTransition(.symbolEffect(.replace.magic(fallback: .replace)))
                    .onTapGesture { withAnimation { showDescription.toggle() } }
                
                Text(text)
                Spacer()
                
                Button {
                    show.toggle()
                } label: {
                   Text(show ? "Hide" : "Show")
                }
            }
                        
            if showDescription {
                Text(description)
                    .font(.caption2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

    

fileprivate struct MenuOptionLabel: View {
    var title: String
    var isChecked: Bool
    var body: some View {
        HStack {
            Text(title)
            if isChecked {
                Image(systemName: "checkmark")
            }
        }
    }
}



fileprivate struct BreakdownView: View {
    @Local(\.incomeColor) var incomeColor
    @Local(\.useWholeNumbers) var useWholeNumbers
    @Environment(PayMethodModel.self) private var payModel
    var payMethod: CBPaymentMethod
    var breakdowns: Breakdown
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(breakdowns.breakdowns) { down in
                    Section {
                        lineItem(title: "Expenses", value: down.expenses, color: .red)
                        lineItem(title: "Starting Balance", value: down.startingAmounts, color: .orange)
                        lineItem(title: "Free Cash Flow", value: down.profitLoss, color: .green)
                        lineItem(title: "Income", value: down.income, color: Color.fromName(incomeColor))
                        if payMethod.accountType == .unifiedCredit {
                            lineItem(title: "Payments", value: down.payments, color: .green)
                        }
                        lineItem(title: "Month End", value: down.monthEnd, color: .mint)
                        lineItem(title: "Min EOD", value: down.minEod, color: .indigo)
                        lineItem(title: "Max EOD", value: down.maxEod, color: .cyan)
                        
                    } header: {
                        HStack {
                            if let meth = payModel.paymentMethods.filter({ $0.id == down.payMethodID }).first {
                                Circle()
                                    .fill(meth.color)
                                    .frame(width: 12, height: 12)
                                    .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
                                
                                Text(meth.title)
                            } else {
                                Text("N/A")
                            }
                            
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Details \(breakdowns.date.string(to: .monthNameYear))")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .listSectionSpacing(10)
            #endif
        }
    }
    
    @ViewBuilder func lineItem(title: String, value: Double, color: Color) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text(title)
            Spacer()
            Text(value.currencyWithDecimals(useWholeNumbers ? 0 : 2))
        }
    }
}



fileprivate struct LegendView: View {
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

enum DetailStyle {
    case overlay, inline
}

// MARK: - Charts
fileprivate struct IncomeExpenseChart: View {
    @Environment(\.dismiss) var dismiss
    @Local(\.incomeColor) var incomeColor
    @Local(\.useWholeNumbers) var useWholeNumbers
    @ChartOption(\.showOverviewDataPerMethodOnUnifiedChart) var showOverviewDataPerMethodOnUnifiedChart

    @AppStorage("showIncomeOnAnalyticChart") private var showIncome: Bool = true
    @AppStorage("showIncomeAndPositiveAmountsOnAnalyticChart") private var showIncomeAndPositiveAmountsOnAnalyticChart: Bool = true
    @AppStorage("showPositiveAmountsOnAnalyticChart") private var showPositiveAmountsOnAnalyticChart: Bool = true
    @AppStorage("showExpensesOnAnalyticChart") private var showExpenses: Bool = true
    @AppStorage("showPaymentsOnAnalyticChart") private var showPayments: Bool = true
    @AppStorage("showStartingAmountsOnAnalyticChart") private var showStartingAmounts: Bool = true
    @AppStorage("showMonthEndOnAnalyticChart") private var showMonthEnd: Bool = true
    
    @Bindable var vm: PayMethodViewModel
    @Bindable var payMethod: CBPaymentMethod
    var detailStyle: DetailStyle
    @State private var chartWidth: CGFloat = 0
    
    @State private var legendItems = [
        (id: UUID(), title: "Income", color: Color.blue),
        (id: UUID(), title: "Expenses", color: Color.red),
        (id: UUID(), title: "Month Begin", color: Color.orange),
    ]
    
    @State private var showDetailsSheet = false
    
    @State private var rawSelectedDate: Date?
    var selectedDate: Date? {
        if let raw = rawSelectedDate {
            let breakdowns = vm.payMethods.first?.breakdowns
            if vm.viewByQuarter {
                return breakdowns?.first { $0.date.year == raw.year && $0.date.startOfQuarter == raw.startOfQuarter }?.date
            } else {
                return breakdowns?.first { raw.matchesMonth(of: $0.date) }?.date
            }
        } else {
            return nil
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if detailStyle == .inline {
                selectedDataView
            }
            
            LegendView(items: legendItems)
                .task {
                    if payMethod.isCredit {
                        legendItems.append((id: UUID(), title: "Payments", color: Color.green))
                    }
                }
            
            Chart {
                if let selectedDate {
                    if detailStyle == .overlay {
                        vm.selectionRectangle(for: selectedDate, content: selectedDataView)
                    } else {
                        vm.selectionRectangle(for: selectedDate, content: EmptyView())
                    }
                }
                
                ForEach(vm.relevantBreakdowns()) {
                    incomeLine($0)
                    expensesLine($0)
                    startingAmountLine($0)
                                                            
                    if payMethod.isCredit {
                        paymentLine($0)
                    }
                }
            }
            .frame(minHeight: 150)
            .chartYAxis { vm.yAxis() }
            .chartXAxis { vm.xAxis() }
            //.chartXVisibleDomain(length: vm.visibleChartAreaDomain)
            .chartXScale(domain: vm.chartXScale)
            .chartXSelection(value: $rawSelectedDate)
            .maxChartWidthObserver()
            .onPreferenceChange(MaxChartSizePreferenceKey.self) { chartWidth = max(chartWidth, $0) }
        }
//        .onTapGesture {
//            showDetailsSheet = true
//        }
//        .sheet(isPresented: $showDetailsSheet) {
//            StandardContainer {
//                IncomeExpenseChart(vm: vm, payMethod: payMethod, detailStyle: .inline)
//            } header: {
//                SheetHeader(title: "Income & Expenses") {
//                    dismiss()
//                }
//            }
//        }
        
        //.gesture(vm.moveYearGesture)
    }
            
    @ChartContentBuilder
    func incomeLine(_ breakdown: PayMethodMonthlyBreakdown) -> some ChartContent {
        LineMark(
            x: .value("Date", breakdown.date, unit: .month),
            y: .value("Amount1", vm.getIncomeText(for: breakdown)),
            series: .value("", "Amount1\(payMethod.id)")
        )
        .foregroundStyle(.blue.gradient)
        .interpolationMethod(.catmullRom)
    }
        
    @ChartContentBuilder
    func expensesLine(_ breakdown: PayMethodMonthlyBreakdown) -> some ChartContent {
        LineMark(
            x: .value("Date", breakdown.date, unit: .month),
            y: .value("Amount2", breakdown.expenses),
            series: .value("", "Amount2\(payMethod.id)")
        )
        .foregroundStyle(.red.gradient)
        .interpolationMethod(.catmullRom)
    }
    
    @ChartContentBuilder
    func startingAmountLine(_ breakdown: PayMethodMonthlyBreakdown) -> some ChartContent {
        LineMark(
            x: .value("Date", breakdown.date, unit: .month),
            y: .value("Amount4", breakdown.startingAmounts),
            series: .value("", "Amount4\(payMethod.id)")
        )
        .foregroundStyle(.orange.gradient)
        .interpolationMethod(.catmullRom)
        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 3]))
    }
    
    @ChartContentBuilder
    func paymentLine(_ breakdown: PayMethodMonthlyBreakdown) -> some ChartContent {
        LineMark(
            x: .value("Date", breakdown.date, unit: .month),
            y: .value("Amount3", breakdown.payments),
            series: .value("", "Amount3\(payMethod.id)")
        )
        .foregroundStyle(.green.gradient)
        .interpolationMethod(.catmullRom)
        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 3]))
    }
            
    @ViewBuilder
    var selectedDataView: some View {
        if let selectedDate = selectedDate {
            
            SelectedDataContainer(vm: vm, payMethod: payMethod, selectedDate: selectedDate, chartWidth: chartWidth, showOverviewDataPerMethodOnUnifiedChart: showOverviewDataPerMethodOnUnifiedChart) {
                if showOverviewDataPerMethodOnUnifiedChart { Text("Method") }
                Text("Income").foregroundStyle(.blue.gradient)
                Text("Expenses").foregroundStyle(.red.gradient)
                Text("Starting").foregroundStyle(.orange.gradient)
                if payMethod.isCredit {
                    Text("Payments").foregroundStyle(.green.gradient)
                }
            } rows: {
                if showOverviewDataPerMethodOnUnifiedChart {
                    ForEach(vm.breakdownPerMethod(on: selectedDate)) { breakdown in
                        GridRow(alignment: .top) {
                            HStack(spacing: 0) {
                                CircleDot(color: breakdown.color)
                                Text(breakdown.title)
                            }
                            
                            Text(vm.getIncomeText(for: breakdown).currencyWithDecimals(useWholeNumbers ? 0 : 2))
                            Text(breakdown.expenses.currencyWithDecimals(useWholeNumbers ? 0 : 2))
                            Text(breakdown.startingAmounts.currencyWithDecimals(useWholeNumbers ? 0 : 2))
                            
                            if payMethod.isCredit {
                                Text(breakdown.payments.currencyWithDecimals(useWholeNumbers ? 0 : 2))
                            }
                        }
                    }
                } else {
                    EmptyView()
                }
                
            } summary: {
                let breakdown = vm.breakdownForMethod(method: vm.mainPayMethod, on: selectedDate)
                Text(vm.getIncomeText(for: breakdown).currencyWithDecimals(useWholeNumbers ? 0 : 2))
                Text(breakdown.expenses.currencyWithDecimals(useWholeNumbers ? 0 : 2))
                Text(breakdown.startingAmounts.currencyWithDecimals(useWholeNumbers ? 0 : 2))
                                            
                if payMethod.isCredit {
                    Text(breakdown.payments.currencyWithDecimals(useWholeNumbers ? 0 : 2))
                }
            }
        }
    }
    
//    
//    
//    
//    
//    
//            
//    
//    @ViewBuilder var optionToggles: some View {
//        VStack {
//            if let incomeConfig = config.incomeConfig, incomeConfig.enabled {
//                
//                let description: LocalizedStringKey = "**Only income:**\nThe sum of amounts where transactions have an ***income*** category.\n\n**Money in only (no income):**\nThe sum of positive dollar amounts ***excluding*** transactions that have an income category.\n(Deposits, Refunds, Etc.)\n\n**All money in:**\nThe sum of ***all*** positive dollar amounts.\n(Income, Deposits, Refunds, Etc.)\n\n**Starting amount & all money in:**\nThat sum of all positive dollar amounts + the amount you started the month with."
//                
//                
//                IncomeOptionToggle(description: description, config: incomeConfig, show: $showIncome)
//            }
//                                                                        
//            if let paymentsConfig = config.paymentsConfig, paymentsConfig.enabled {
//                ShowHideOptionButton(
//                    text: "Payments",
//                    description: "Payments made for the credit card.",
//                    show: $showPayments
//                )
//            }
//        }
//    }
}



fileprivate struct ProfitLossChart: View {
    @Local(\.colorTheme) var colorTheme
    //@AppStorage("threshold") var threshold: Double = 500.00
    @AppStorage("profitLossStyle") private var profitLossStyle: String = "amount"
    @Local(\.useWholeNumbers) var useWholeNumbers
    //@AppStorage("profitLossMetrics") private var profitLossMetrics: String = "all"
    @Local(\.threshold) var threshold
    @ChartOption(\.profitLossMetrics) var profitLossMetrics
    @ChartOption(\.showOverviewDataPerMethodOnUnifiedChart) var showOverviewDataPerMethodOnUnifiedChart

    @Bindable var vm: PayMethodViewModel
    @Bindable var payMethod: CBPaymentMethod
    @State private var chartWidth: CGFloat = 0
    
    @State private var showDetailsSheet = false
    
    @State private var rawSelectedDate: Date?
    var selectedDate: Date? {
        if let raw = rawSelectedDate {
            let breakdowns = vm.payMethods.first?.breakdowns
            if vm.viewByQuarter {
                return breakdowns?.first {
                    $0.date.year == raw.year && $0.date.startOfQuarter == raw.startOfQuarter
                }?.date
            } else {
                return breakdowns?.first { raw.matchesMonth(of: $0.date) }?.date
            }
        } else {
            return nil
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if profitLossMetrics == "summary" {
                LegendView(items: [
                    (id: UUID(), title: "Profit", color: Color.green),
                    (id: UUID(), title: "Loss", color: Color.red),
                ])
            } else {
                LegendView(items: vm.payMethods.map { (id: UUID(), title: $0.title, color: $0.color) })
            }
                                                    
            Chart {
                /// WARNING! This cannot be a computed property.
                let positionForNewColor: Double? = vm.getGradientPosition(for: profitLossStyle == "amount" ? .amount : .percentage, flipAt: 0)
                
                if let selectedDate {
                    vm.selectionRectangle(for: selectedDate, content: selectedDataView)
                }
                     
                if profitLossMetrics == "summary" {
                    ForEach(vm.relevantBreakdowns()) {
                        profitLossLine(meth: payMethod, breakdown: $0, positionForNewColor: positionForNewColor)
                    }
                } else {
                    ForEach(vm.payMethods) { meth in
                        ForEach(vm.relevantBreakdowns(for: meth)) {
                            profitLossLine(meth: meth, breakdown: $0, positionForNewColor: positionForNewColor)
                        }
                    }
                }
            }
            .frame(minHeight: 150)
            .chartYAxis { vm.yAxis(symbol: profitLossStyle == "amount" ? "$" : "%") }
            .chartXAxis { vm.xAxis() }
            //.chartXVisibleDomain(length: vm.visibleChartAreaDomain)
            .chartXScale(domain: vm.chartXScale)
            .chartXSelection(value: $rawSelectedDate)
            .maxChartWidthObserver()
            .onPreferenceChange(MaxChartSizePreferenceKey.self) { chartWidth = max(chartWidth, $0) }
        }
        //.gesture(vm.moveYearGesture)
    }
    
    @ChartContentBuilder
    func profitLossLine(meth: CBPaymentMethod, breakdown: PayMethodMonthlyBreakdown, positionForNewColor: Double?) -> some ChartContent {
        if profitLossMetrics == "summary" {
            LineMark(
                x: .value("Date", breakdown.date, unit: .month),
                y: .value("Amount5", profitLossStyle == "amount" ? breakdown.profitLoss : breakdown.profitLossPercentage),
                series: .value("", "Amount5\(meth.id)")
            )
            .foregroundStyle(
                .linearGradient(
                    Gradient(
                        stops: [
                            //.init(color: .red, location: 0),
                            //.init(color: .red, location: positionForNewColor - 0.00001),
                            //.init(color: .green, location: positionForNewColor + 0.00001),
                            //.init(color: .green, location: 1)
                            
                            
                            .init(color: .red, location: 0),
                            .init(color: .red, location: positionForNewColor ?? 0.5 - 0.00001),
                            .init(color: .green, location: positionForNewColor ?? 0.5 + 0.00001),
                            .init(color: .green, location: 1)
                        ]
                    ),
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .interpolationMethod(.catmullRom)
        } else {
            LineMark(
                x: .value("Date", breakdown.date, unit: .month),
                y: .value("Amount5", profitLossStyle == "amount" ? breakdown.profitLoss : breakdown.profitLossPercentage),
                series: .value("", "Amount5\(meth.id)")
            )
            .foregroundStyle(meth.color)
            .interpolationMethod(.catmullRom)
        }
    }
    
    @ViewBuilder
    var selectedDataView: some View {
        if let selectedDate = selectedDate {
            SelectedDataContainer(vm: vm, payMethod: payMethod, selectedDate: selectedDate, chartWidth: chartWidth, showOverviewDataPerMethodOnUnifiedChart: showOverviewDataPerMethodOnUnifiedChart) {
                if showOverviewDataPerMethodOnUnifiedChart { Text("Method") }
                Text("PL $")
                Text("PL %")
            } rows: {
                if showOverviewDataPerMethodOnUnifiedChart {
                    ForEach(vm.breakdownPerMethod(on: selectedDate)) { breakdown in
                        GridRow(alignment: .top) {
                            HStack(spacing: 0) {
                                CircleDot(color: breakdown.color)
                                Text(breakdown.title)
                            }
                            
                            Text(breakdown.profitLoss.currencyWithDecimals(useWholeNumbers ? 0 : 2))
                                .foregroundStyle(breakdown.profitLoss < 0 ? . red : .green)
                            
                            Text("\(breakdown.profitLossPercentage.decimals(1))%")
                                .foregroundStyle(breakdown.profitLossPercentage < 0 ? . red : .green)
                            
                        }
                    }
                } else {
                    EmptyView()
                }
            } summary: {
                let breakdown = vm.breakdownForMethod(method: vm.mainPayMethod, on: selectedDate)
                Text(breakdown.profitLoss.currencyWithDecimals(useWholeNumbers ? 0 : 2))
                    .foregroundStyle(breakdown.profitLoss < 0 ? . red : .green)
                
                Text("\(breakdown.profitLossPercentage.decimals(1))%")
                    .foregroundStyle(breakdown.profitLossPercentage < 0 ? . red : .green)
            }
        }
    }
}



fileprivate struct MinMaxEodChart: View {
    @Local(\.colorTheme) var colorTheme
    @Local(\.threshold) var threshold
    @Local(\.useWholeNumbers) var useWholeNumbers
    @ChartOption(\.showOverviewDataPerMethodOnUnifiedChart) var showOverviewDataPerMethodOnUnifiedChart

    @Bindable var vm: PayMethodViewModel
    @Bindable var payMethod: CBPaymentMethod
    
    @State private var chartWidth: CGFloat = 0
    
    @State private var showDetailsSheet = false
    
    @State private var rawSelectedDate: Date?
    var selectedDate: Date? {
        if let raw = rawSelectedDate {
            let breakdowns = vm.payMethods.first?.breakdowns
            if vm.viewByQuarter {
                return breakdowns?.first {
                    $0.date.year == raw.year && $0.date.startOfQuarter == raw.startOfQuarter
                }?.date
            } else {
                return breakdowns?.first { raw.matchesMonth(of: $0.date) }?.date
            }
        } else {
            return nil
        }
    }
        
    var body: some View {
        VStack(spacing: 0) {
            LegendView(items: [
                (id: UUID(), title: "Above Threshold", color: Color.green),
                (id: UUID(), title: "Under Threshold", color: Color.orange),
            ])
            
            Chart {
                if let selectedDate {
                    vm.selectionRectangle(for: selectedDate, color: .clear, content: selectedDataView)
                }
                
                ForEach(vm.relevantBreakdowns()) {
                    minMaxLine($0)
                }
            }
            .frame(minHeight: 150)
            .chartYAxis { vm.yAxis() }
            .chartXAxis { vm.xAxis() }
            //.chartXVisibleDomain(length: vm.visibleChartAreaDomain)
            .chartXScale(domain: vm.chartXScale)
            .chartXSelection(value: $rawSelectedDate)
            .maxChartWidthObserver()
            .onPreferenceChange(MaxChartSizePreferenceKey.self) { chartWidth = max(chartWidth, $0) }
        }
        //.gesture(vm.moveYearGesture)
    }
    
    @ChartContentBuilder
    func minMaxLine(_ breakdown: PayMethodMonthlyBreakdown) -> some ChartContent {
        let startColor: Color = breakdown.minEod < threshold ? .orange : .green
        let min = breakdown.minEod
        let max = breakdown.maxEod
        let positionForNewColor: Double? = vm.getGradientPosition(for: .minMaxEod, flipAt: threshold, min: min, max: max)
        let gradient = Gradient(
            stops: [
                .init(color: startColor, location: 0),
                .init(color: startColor, location: positionForNewColor ?? 0.5 - 0.00001),
                .init(color: .green, location: positionForNewColor ?? 0.5 + 0.00001),
                .init(color: .green, location: 1)
            ]
        )
        
        var opacity: Double {
            if let selectedDate {
                breakdown.date == selectedDate ? 1 : 0.3
            } else {
                1
            }
        }
        
        if vm.viewByQuarter {
            RectangleMark(
                xStart: .value("Start Date", breakdown.date.startOfQuarter, unit: .day),
                xEnd: .value("End Date", breakdown.date.endOfQuarter.addingTimeInterval(-60 * 60 * 24 * 14), unit: .day),
                yStart: .value("Min Eod", breakdown.minEod),
                yEnd: .value("Max Eod", breakdown.maxEod),
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .foregroundStyle(.linearGradient(gradient, startPoint: .bottom, endPoint: .top))
            .opacity(opacity)
        } else {
            RectangleMark(
                x: .value("Start Date", breakdown.date, unit: .month),
                yStart: .value("Min Eod", breakdown.minEod),
                yEnd: .value("Max Eod", breakdown.maxEod),
                width: .ratio(0.6)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .foregroundStyle(.linearGradient(gradient, startPoint: .bottom, endPoint: .top))
            .opacity(opacity)
        }
    }
    
    @ViewBuilder
    var selectedDataView: some View {
        if let selectedDate = selectedDate {
            SelectedDataContainer(vm: vm, payMethod: payMethod, selectedDate: selectedDate, chartWidth: chartWidth, showOverviewDataPerMethodOnUnifiedChart: showOverviewDataPerMethodOnUnifiedChart) {
                if showOverviewDataPerMethodOnUnifiedChart { Text("Method") }
                Text("Min EOD")
                Text("Max EOD")
            } rows: {
                if showOverviewDataPerMethodOnUnifiedChart {
                    ForEach(vm.breakdownPerMethod(on: selectedDate)) { info in
                        GridRow(alignment: .top) {
                            HStack(spacing: 0) {
                                CircleDot(color: info.color)
                                Text(info.title)
                            }
                            
                            Text(info.minEod.currencyWithDecimals(useWholeNumbers ? 0 : 2))
                                .foregroundStyle(info.minEod < threshold ? .orange : .secondary)
                            
                            Text(info.maxEod.currencyWithDecimals(useWholeNumbers ? 0 : 2))
                                .foregroundStyle(info.maxEod < threshold ? .orange : .secondary)
                            
                        }
                    }
                } else {
                    EmptyView()
                }
            } summary: {
                let breakdown = vm.breakdownForMethod(method: vm.mainPayMethod, on: selectedDate)
                Text(breakdown.minEod.currencyWithDecimals(useWholeNumbers ? 0 : 2))
                    .foregroundStyle(breakdown.minEod < threshold ? .orange : .secondary)
                
                Text(breakdown.maxEod.currencyWithDecimals(useWholeNumbers ? 0 : 2))
                    .foregroundStyle(breakdown.maxEod < threshold ? .orange : .secondary)
            }
        }
    }
}



fileprivate struct ExpensesByPaymentMethodChart: View {
    @Local(\.useWholeNumbers) var useWholeNumbers
    @ChartOption(\.showOverviewDataPerMethodOnUnifiedChart) var showOverviewDataPerMethodOnUnifiedChart

    @Bindable var vm: PayMethodViewModel
    @Bindable var payMethod: CBPaymentMethod

    @State private var chartWidth: CGFloat = 0
    
    @State private var showDetailsSheet = false
    
    @State private var rawSelectedDate: Date?
    var selectedDate: Date? {
        if let raw = rawSelectedDate {
            let breakdowns = vm.payMethods.first?.breakdowns
            if vm.viewByQuarter {
                return breakdowns?.first {
                    $0.date.year == raw.year && $0.date.startOfQuarter == raw.startOfQuarter
                }?.date
            } else {
                return breakdowns?.first { raw.matchesMonth(of: $0.date) }?.date
            }
        } else {
            return nil
        }
    }
    
    
    var body: some View {
        VStack(spacing: 0) {
            LegendView(items: vm.payMethods.map { (id: UUID(), title: $0.title, color: $0.color) })
            
            Chart {
                if let selectedDate {
                    vm.selectionRectangle(for: selectedDate, content: selectedDataView)
                }
                
                ForEach(vm.payMethods) { meth in
                    ForEach(vm.relevantBreakdowns(for: meth)) {
                        expenseLine(meth: meth, breakdown: $0)
                    }
                }
            }
            .frame(minHeight: 150)
            .chartYAxis { vm.yAxis() }
            .chartXAxis { vm.xAxis() }
            //.chartXVisibleDomain(length: vm.visibleChartAreaDomain)
            .chartXScale(domain: vm.chartXScale)
            .chartXSelection(value: $rawSelectedDate)
            .maxChartWidthObserver()
            .onPreferenceChange(MaxChartSizePreferenceKey.self) { chartWidth = max(chartWidth, $0) }
        }
        //.gesture(vm.moveYearGesture)
    }
    
    @ChartContentBuilder
    func expenseLine(meth: CBPaymentMethod, breakdown: PayMethodMonthlyBreakdown) -> some ChartContent {
        LineMark(
            x: .value("Date", breakdown.date, unit: .month),
            y: .value("Amount2", breakdown.expenses),
            series: .value("", "Amount2\(meth.id)")
        )
        .foregroundStyle(meth.color)
        .interpolationMethod(.catmullRom)
    }
    
    @ViewBuilder
    var selectedDataView: some View {
        if let selectedDate = selectedDate {
            SelectedDataContainer(vm: vm, payMethod: payMethod, selectedDate: selectedDate, chartWidth: chartWidth, showOverviewDataPerMethodOnUnifiedChart: true) {
                Text("Method")
                Text("Expenses").foregroundStyle(.red)
            } rows: {
                ForEach(vm.breakdownPerMethod(on: selectedDate)) { info in
                    GridRow(alignment: .top) {
                        HStack(spacing: 0) {
                            CircleDot(color: info.color)
                            Text(info.title)
                        }
                        Text(info.expenses.currencyWithDecimals(useWholeNumbers ? 0 : 2))

                    }
                    .minimumScaleFactor(0.5)
                    .foregroundStyle(.secondary)
                }
                
            } summary: {
                let breakdown = vm.breakdownForMethod(method: vm.mainPayMethod, on: selectedDate)
                Text(breakdown.expenses.currencyWithDecimals(useWholeNumbers ? 0 : 2))
            }
        }

    }
}



struct SelectedDataContainer<Headers: View, Rows: View, Summary: View>: View {
    @Bindable var vm: PayMethodViewModel
    @Bindable var payMethod: CBPaymentMethod
    var selectedDate: Date
    var chartWidth: CGFloat
    var showOverviewDataPerMethodOnUnifiedChart: Bool
    
    @ViewBuilder var headers: Headers
    @ViewBuilder var rows: Rows
    @ViewBuilder var summary: Summary
            
    var body: some View {
        VStack(spacing: 0) {
            Text(vm.overViewTitle(for: selectedDate))
                .bold()
            
            Divider()
            
            Grid {
                GridRow(alignment: .top) {
                    headers
                }
                .foregroundStyle(.secondary)
                .bold()
                
                Divider()
                
                
                if showOverviewDataPerMethodOnUnifiedChart {
                    rows
                    Divider()
                }
                
                
                GridRow(alignment: .top) {
                    if showOverviewDataPerMethodOnUnifiedChart {
                        HStack(spacing: 0) {
                            CircleDotGradient()
                            Text("Summary")
                        }
                    }
                    
                    summary
                }
            }
            .minimumScaleFactor(0.5)
            .foregroundStyle(.secondary)
            .frame(maxHeight: .infinity)
        }
        .frame(maxWidth: chartWidth, maxHeight: .infinity)
        .foregroundStyle(.primary)
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 10)
                //#if os(iOS)
                .fill(Color(.tertiarySystemBackground))
                .shadow(radius: 5)
            
                //#endif
        )
    }
}
