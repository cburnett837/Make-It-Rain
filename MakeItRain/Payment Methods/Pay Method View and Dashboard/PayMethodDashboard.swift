//
//  MultiAnalyticChart.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/9/25.
//

import SwiftUI
import Charts


struct PayMethodDashboard: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @Environment(PayMethodModel.self) private var payModel

    @Local(\.incomeColor) var incomeColor
    @Local(\.useWholeNumbers) var useWholeNumbers
    //@Local(\.colorTheme) var colorTheme
    @Local(\.threshold) var threshold
    
    @AppStorage(LocalKeys.Charts.Options.showOverviewDataPerMethodOnUnified) var showOverviewDataPerMethodOnUnifiedChart = false
    @AppStorage("showAllCategoryChartData") private var showAllChartData = false
        
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
                .filter { searchText.isEmpty ? true : $0.date.string(to: .monthNameYear).localizedCaseInsensitiveContains(searchText) }
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
    
    
    @State private var showMenuDemo: Bool = false
    
    let iPadChartGrid = Array(repeating: GridItem(.flexible(), spacing: 30, alignment: .top), count: 2)
    
    // MARK: - Views
    var body: some View {
        VStack {
            ChartDateRangeHeader(vm: vm, payMethod: payMethod)
                .scenePadding(.horizontal)
            
            Group {
                if AppState.shared.isIpad {
                    ScrollView {
                        LazyVGrid(columns: iPadChartGrid, spacing: 30) {
                            GroupBox {
                                IncomeExpenseChartWidget(vm: vm, payMethod: payMethod)
                            } label: {
                                Text("Transactions")
                            }
                            .cornerRadius(25)
                                    
                            if !payMethod.isCredit {
                                GroupBox {
                                    ProfitLossChartWidget(vm: vm, payMethod: payMethod)
                                } label: {
                                    Text("Net Worth")
                                }
                                .cornerRadius(25)
                            }
                            
                            GroupBox {
                                MinMaxEodChartWidget(vm: vm, payMethod: payMethod)
                            } label: {
                                Text("Min/Max EOD Amounts")
                            }
                            .cornerRadius(25)
                            
                            /// NOTE: This is slightly different because it has it's own view model.
                            if payMethod.isUnified {
                                MetricByPaymentMethodChartWidget(vm: vm, payMethod: payMethod)
                            }
                        }
                    }
                    .scenePadding(.horizontal)
                    
                } else {
                    StandardContainerWithToolbar(.list) {
                        Section {
                            IncomeExpenseChartWidget(vm: vm, payMethod: payMethod)
                        } header: {
                            Text("Transactions")
                        }
                                
                        if !payMethod.isCredit {
                            Section {
                                ProfitLossChartWidget(vm: vm, payMethod: payMethod)
                            } header: {
                                Text("Net Worth")
                            }
                        }
                        
                        Section {
                            MinMaxEodChartWidget(vm: vm, payMethod: payMethod)
                        } header: {
                            Text("Min/Max EOD Amounts")
                        }
                        
                        /// NOTE: This is slightly different because it has it's own view model.
                        if payMethod.isUnified {
                            MetricByPaymentMethodChartWidget(vm: vm, payMethod: payMethod)
                        }
                    }
                }
            }
        }
        
        
        
        
        
        
//        VStack(spacing: 0) {
//            ZStack(alignment: .top) {
//                if showNonScrollingHeader {
//                    VStack {
//                        chartHeaderContainer
//                        Spacer()
//                    }
//                    .zIndex(1)
//                }
//                
//                ScrollView {
//                    VStack(spacing: 0) {
//                        chartHeaderContainer
//                            .opacity(showNonScrollingHeader ? 0 : 1)
//                        
//                        //ChartStack(vm: vm, payMethod: payMethod)
//                        
//                        chartStack
//                        
//                        
////                        Button("Show it parent") {
////                            showMenuDemo = true
////                        }
//                    }
//                }
//                .scrollIndicators(.hidden)
//                .onScrollGeometryChange(for: CGFloat.self) {
//                    $0.contentOffset.y + $0.contentInsets.top
//                } action: {
//                    if $1 > 0 {
//                        flipZindex = true
//                        showNonScrollingHeader = true
//                    } else if $1 == 0 {
//                        flipZindex = false
//                        showNonScrollingHeader = false
//                    }
//                }
//                .zIndex(flipZindex ? 0 : 1)
//            }
//        }
        .sheet(item: $selectedBreakdowns) { breakdowns in
            BreakdownView(payMethod: payMethod, breakdowns: breakdowns)
        }
//        .sheet(isPresented: $showMenuDemo) {
//            Menu("Heyyyy") {
//                Button {  } label: {
//                    Text("Also hey")
//                }
//            }
//        }
    }
    
    
//    var chartHeaderContainer: some View {
//        VStack(spacing: 5) {
//            chartVisibleYearPicker
//            chartHeader
//        }
//        
////        VStack(spacing: 0) {
//////            SheetHeader(
//////                title: payMethod.title,
//////                close: { editID = nil; dismiss() },
//////                view1: { refreshButton },
//////                view2: { styleMenu }
//////            )
////            
//////            if colorScheme == .dark {
//////                Divider()
//////                    //.padding(.horizontal)
//////            }
////            
////            VStack(spacing: 5) {
////                chartVisibleYearPicker
////                chartHeader
////            }
////            //.padding(.horizontal, 12)
////            .padding(.top, 12)
////                        
////        }        
//////        #if os(iOS)
//////        //.background(Color(.secondarySystemGroupedBackground))
//////        .background(.background)
//////        #else
//////        .background(.background)
//////        #endif
//////        .background {
//////            GeometryReader { geo in
//////                Color.clear.preference(key: MaxHeaderHeightPreferenceKey.self, value: geo.size.height)
//////            }
//////        }
//////        .onPreferenceChange(MaxHeaderHeightPreferenceKey.self) { headerHeight = max(headerHeight, $0) }
////        
//    }
    
    
//    var chartHeader: some View {
//        HStack {
//            VStack(alignment: .leading) {
//                HStack {
//                    Text("Insights By \(vm.viewByQuarter ? "Quarter" : "Month")")
//                        .font(.title3)
//                        .bold()
//                    
//                    Spacer()
//                    
//                    if payMethod.isCredit {
//                        Text("Payments: \(vm.visiblePayments.currencyWithDecimals(useWholeNumbers ? 0 : 2))")
//                            .foregroundStyle(.gray)
//                            .font(.subheadline)
//                    } else {
//                        Text("Income: \(vm.visibleIncome.currencyWithDecimals(useWholeNumbers ? 0 : 2))")
//                            .foregroundStyle(.gray)
//                            .font(.subheadline)
//                    }
//                }
//                
//                HStack {
//                    displayYearAndArrows
//                                        
//                    Spacer()
//                    
//                    Text("Expenses: \(vm.visibleExpenses.currencyWithDecimals(useWholeNumbers ? 0 : 2))")
//                }
//                .foregroundStyle(.gray)
//                .font(.subheadline)
//                //.padding(.bottom, 5)
//                                                
//            }
//        }
//    }
//    
    
//    var styleMenu: some View {
//        Menu {
//            Section("This Year Style") {
//                Picker(selection: $vm.chartCropingStyle) {
//                    Text("Whole year")
//                        .tag(ChartCropingStyle.showFullCurrentYear)
//                    Text("Through current month")
//                        .tag(ChartCropingStyle.endAtCurrentMonth)
//                } label: {
//                    Text(vm.chartCropingStyle.prettyValue)
//                }
//                .pickerStyle(.menu)
//            }
//            
//            Section("Overview Style") {
//                Picker(selection: $showOverviewDataPerMethodOnUnifiedChart) {
//                    Text("View as summary only")
//                        .tag(false)
//                    Text("View by payment method")
//                        .tag(true)
//                } label: {
//                    Text(showOverviewDataPerMethodOnUnifiedChart ? "By payment method" : "As summary only")
//                }
//                .pickerStyle(.menu)
//                
//            }
//        } label: {
//            Image(systemName: "checklist")
//        }
//    }
    
    
//    @ViewBuilder
//    var displayYearAndArrows: some View {
//        Button {
//            vm.moveYears(forward: false)
//        } label: {
//            Image(systemName: "chevron.left")
//        }
//        .contentShape(Rectangle())
//        
//        displayYears
//        
//        Button {
//            vm.moveYears(forward: true)
//        } label: {
//            Image(systemName: "chevron.right")
//        }
//        .contentShape(Rectangle())
//    }
//    
//    
//    var displayYears: some View {
//        HStack(spacing: 5) {
//            let lower = vm.visibleDateRangeForHeader.lowerBound.year
//            let upper = vm.visibleDateRangeForHeader.upperBound.year
//            
//            var ytdText: String {
//                if vm.chartCropingStyle == .endAtCurrentMonth {
//                    if upper == lower && lower == AppState.shared.todayYear
//                    || upper != lower && upper == AppState.shared.todayYear {
//                        return " (YTD)"
//                    }
//                }
//                return ""
//            }
//            
//            if upper != lower {
//                Text(String(lower))
//                Text("-")
//            }
//                                                
//            Text("\(String(upper))\(ytdText)")
//        }
//    }
    
    
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
        
    
//    var chartVisibleYearPicker: some View {
//        Picker("", selection: $vm.visibleYearCount) {
//            Text("1Y").tag(PayMethodChartRange.year1)
//            Text("2Y").tag(PayMethodChartRange.year2)
//            Text("3Y").tag(PayMethodChartRange.year3)
//            Text("4Y").tag(PayMethodChartRange.year4)
//            Text("5Y").tag(PayMethodChartRange.year5)
//            Text("10Y").tag(PayMethodChartRange.year10)
//        }
//        .pickerStyle(.segmented)
//        .labelsHidden()
//        .onChange(of: vm.visibleYearCount) { vm.setChartScrolledToDate($1) }
//    }
            
    
    @ViewBuilder
    var chartStack: some View {
        IncomeExpenseChartWidget(vm: vm, payMethod: payMethod)
                
        if !payMethod.isCredit {
            ProfitLossChartWidget(vm: vm, payMethod: payMethod)
        }
        
        MinMaxEodChartWidget(vm: vm, payMethod: payMethod)
        
        if payMethod.isUnified {
            MetricByPaymentMethodChartWidget(vm: vm, payMethod: payMethod)
        }
        
        //rawDataList
        
        
//        VStack(alignment: .leading, spacing: 6) {
//            IncomeExpenseChartWidget(vm: vm, payMethod: payMethod)
//            
//            if !payMethod.isCredit {
//                ProfitLossChartWidget(vm: vm, payMethod: payMethod)
//            }
//            
//            MinMaxEodChartWidget(vm: vm, payMethod: payMethod)
//            
//            if payMethod.isUnified {
//                MetricByPaymentMethodChartWidget(vm: vm, payMethod: payMethod)
//            }
//            
//            Divider()
//            
//            rawDataList
//            
//            Button("Show it") {
//                showMenuDemo = true
//            }
//        }
//        .padding(.horizontal, 12)
//        .padding(.top, 12)
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
}





struct PayMethodDashboardOG: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @Environment(PayMethodModel.self) private var payModel

    @Local(\.incomeColor) var incomeColor
    @Local(\.useWholeNumbers) var useWholeNumbers
    //@Local(\.colorTheme) var colorTheme
    @Local(\.threshold) var threshold
    
    @AppStorage(LocalKeys.Charts.Options.showOverviewDataPerMethodOnUnified) var showOverviewDataPerMethodOnUnifiedChart = false
    @AppStorage("showAllCategoryChartData") private var showAllChartData = false
        
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
                .filter { searchText.isEmpty ? true : $0.date.string(to: .monthNameYear).localizedCaseInsensitiveContains(searchText) }
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
    
    
    @State private var showMenuDemo: Bool = false
    
    // MARK: - Views
    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                if showNonScrollingHeader {
                    VStack {
                        chartHeaderContainer
                        Spacer()
                    }
                    .zIndex(1)
                }
                
                ScrollView {
                    VStack(spacing: 0) {
                        chartHeaderContainer
                            .opacity(showNonScrollingHeader ? 0 : 1)
                        
                        //ChartStack(vm: vm, payMethod: payMethod)
                        
                        chartStack
                        
                        
//                        Button("Show it parent") {
//                            showMenuDemo = true
//                        }
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
                }
                .zIndex(flipZindex ? 0 : 1)
            }
        }
        .sheet(item: $selectedBreakdowns) { breakdowns in
            BreakdownView(payMethod: payMethod, breakdowns: breakdowns)
        }
//        .sheet(isPresented: $showMenuDemo) {
//            Menu("Heyyyy") {
//                Button {  } label: {
//                    Text("Also hey")
//                }
//            }
//        }
    }
    
    
    var chartHeaderContainer: some View {
        VStack(spacing: 0) {
//            SheetHeader(
//                title: payMethod.title,
//                close: { editID = nil; dismiss() },
//                view1: { refreshButton },
//                view2: { styleMenu }
//            )
            
//            if colorScheme == .dark {
//                Divider()
//                    //.padding(.horizontal)
//            }
            
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
        #if os(iOS)
        //.background(Color(.secondarySystemGroupedBackground))
        .background(.background)
        #else
        .background(.background)
        #endif
        .background {
            GeometryReader { geo in
                Color.clear.preference(key: MaxHeaderHeightPreferenceKey.self, value: geo.size.height)
            }
        }
        .onPreferenceChange(MaxHeaderHeightPreferenceKey.self) { headerHeight = max(headerHeight, $0) }
        
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
    
    
//    var styleMenu: some View {
//        Menu {
//            Section("This Year Style") {
//                Picker(selection: $vm.chartCropingStyle) {
//                    Text("Whole year")
//                        .tag(ChartCropingStyle.showFullCurrentYear)
//                    Text("Through current month")
//                        .tag(ChartCropingStyle.endAtCurrentMonth)
//                } label: {
//                    Text(vm.chartCropingStyle.prettyValue)
//                }
//                .pickerStyle(.menu)
//            }
//
//            Section("Overview Style") {
//                Picker(selection: $showOverviewDataPerMethodOnUnifiedChart) {
//                    Text("View as summary only")
//                        .tag(false)
//                    Text("View by payment method")
//                        .tag(true)
//                } label: {
//                    Text(showOverviewDataPerMethodOnUnifiedChart ? "By payment method" : "As summary only")
//                }
//                .pickerStyle(.menu)
//
//            }
//        } label: {
//            Image(systemName: "checklist")
//        }
//    }
    
    
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
            
    
    var chartStack: some View {
        VStack(alignment: .leading, spacing: 6) {
            IncomeExpenseChartWidget(vm: vm, payMethod: payMethod)
            
            if !payMethod.isCredit {
                ProfitLossChartWidget(vm: vm, payMethod: payMethod)
            }
            
            MinMaxEodChartWidget(vm: vm, payMethod: payMethod)
            
            if payMethod.isUnified {
                MetricByPaymentMethodChartWidget(vm: vm, payMethod: payMethod)
            }
            
            Divider()
            
            rawDataList
            
//            Button("Show it") {
//                showMenuDemo = true
//            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 12)
//        .sheet(isPresented: $showMenuDemo) {
//            Menu("Heyyyy") {
//                Button {  } label: {
//                    Text("Also hey")
//                }
//            }
//        }
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
}






//struct ChartStack: View {
//    @State private var showMenuDemo: Bool = false
//
//    
//    @Bindable var vm: PayMethodViewModel
//    var payMethod: CBPaymentMethod
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 6) {
//            IncomeExpenseChartWidget(vm: vm, payMethod: payMethod)
//            
//            if !payMethod.isCredit {
//                ProfitLossChartWidget(vm: vm, payMethod: payMethod)
//            }
//            
//            MinMaxEodChartWidget(vm: vm, payMethod: payMethod)
//            
//            if payMethod.isUnified {
//                MetricByPaymentMethodChartWidget(vm: vm, payMethod: payMethod)
//            }
//            
//            Divider()
//            
//            //rawDataList
//            
//            Button("Show it") {
//                showMenuDemo = true
//            }
//        }
//        .padding(.horizontal, 12)
//        .padding(.top, 12)
//        .sheet(isPresented: $showMenuDemo) {
//            Menu("Heyyyy") {
//                Button {  } label: {
//                    Text("Also hey")
//                }
//            }
//        }
//    }
//    
//    
//    
//}


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


enum DetailStyle {
    case overlay, inline
}


