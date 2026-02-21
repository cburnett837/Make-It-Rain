//
//  CalendarView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/18/24.
//

import SwiftUI
import Algorithms

#if os(macOS)
struct CalendarViewMac: View {
    @AppStorage("calendarSplitViewPercentage") var calendarSplitViewPercentage = 0.0
    @AppStorage("viewMode") var viewMode = CalendarViewMode.scrollable
    //@Local(\.colorTheme) var colorTheme
    @Local(\.alignWeekdayNamesLeft) var alignWeekdayNamesLeft
    @Environment(CalendarProps.self) private var calProps
    @Environment(CalendarModel.self) private var calModel
    @Environment(FuncModel.self) private var funcModel
        
    var divideBy: CGFloat {
        let cellCount = calModel.sMonth.firstWeekdayOfMonth - 1 + calModel.sMonth.dayCount
        if cellCount > 35 {
            return 6
        } else if cellCount <= 35 && cellCount > 28 {
            return 5
        } else {
            return 4
        }
    }
    
    let sevenColumnGrid = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    
    //@State private var searchText = ""
    //@State private var searchWhat = CalendarSearchWhat.titles
    
    @State private var calendarWidth: CGFloat = 500
    @State private var chartWidth: CGFloat = 500
    @State private var fullWidth: CGFloat = 500
    @State private var extraViewsWidth: CGFloat = 0
    @State private var maxHeaderHeight: CGFloat = 0.0
    
    @FocusState private var focusedField: Int?
    @State private var isHoveringOnSlider: Bool = false
    
    //@State private var selectedDay: CBDay?
    @State private var transEditID: String?
    @State private var editTrans: CBTransaction?
    
    @State private var pulse = false
    
    let enumID: NavDestination
    var isInWindow: Bool = false

    
    var body: some View {
        @Bindable var calProps = calProps
        
        calendarView
            .padding(viewMode == .split ? .horizontal : .horizontal, 15)
            .if(viewMode == .split) {
                $0.frame(minWidth: calendarWidth - (extraViewsWidth / 2))
            }
            .padding(.bottom, 15)
            .if(calModel.isPlayground) {
                $0
                    .border(Color(.orange).opacity(pulse ? 0.6 : 1), width: 3)
                    //.onAppear { withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) { pulse.toggle() } }
            }
            .task {
                //funcModel.prepareStartingAmounts()
                /// Needed when selecting a month from a category analytic.
                let viewingMonth = calModel.months.filter { $0.enumID == enumID }.first!
                funcModel.prepareStartingAmounts(for: viewingMonth)
                calModel.setSelectedMonthFromNavigation(navID: enumID, calculateStartingAndEod: true)
                
                let targetDay = calModel.sMonth.days.filter { $0.dateComponents?.day == (calModel.sMonth.actualNum == AppState.shared.todayMonth ? AppState.shared.todayDay : 1) }.first
                calProps.selectedDay = targetDay
            }
            .onChange(of: calModel.sMonth) {
                let targetDay = calModel.sMonth.days.filter { $0.dateComponents?.day == (calModel.sMonth.actualNum == AppState.shared.todayMonth ? AppState.shared.todayDay : 1) }.first
                calProps.selectedDay = targetDay
            }
            .onPreferenceChange(ViewWidthKey.self) { extraViewsWidth = $0 }
            //.onPreferenceChange(MaxSizePreferenceKey.self) { maxHeaderHeight = max(maxHeaderHeight, $0) }
                    
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    CalendarToolbarLeading(focusedField: $focusedField, enumID: enumID, isInWindow: isInWindow)
                        //.opacity(LoadingManager.shared.showInitiallyLoadingSpinner ? 0 : 1)
                        .focusSection()
                }
                ToolbarItem(placement: .principal) {
                    ToolbarCenterView(enumID: enumID)
                }
                ToolbarItem {
                    Spacer()
                }
                ToolbarItem(placement: .primaryAction) {
                    CalendarToolbarTrailing(focusedField: $focusedField, isInWindow: isInWindow)
                        //.opacity(LoadingManager.shared.showInitiallyLoadingSpinner ? 0 : 1)
                        .focusSection()
                }
            }
            .onReceive(AppState.shared.currentDateTimer) { input in
                let _ = AppState.shared.setNow()
            }
            .tint(Color.theme)
            .calendarLoadingSpinner(id: enumID, text: "Loading \(enumID.displayName)…")
            /// This is here in case you want to cancel the dragging transaction - this will unhilight the last hilighted day.
            .dropDestination(for: CBTransaction.self) { droppedTrans, location in
                calModel.dragTarget = nil
                return true
            } isTargeted: {
                if $0 { withAnimation { calModel.dragTarget = nil } }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                /// Used for hilighting
                //calModel.hilightTrans = nil
                focusedField = nil
            }
            .sheet(isPresented: $calProps.showTransferSheet) {
                TransferSheet(defaultDate: calProps.selectedDay?.date ?? Date())
            }
            .transactionEditSheetAndLogic(
                transEditID: $calProps.transEditID,
                selectedDay: $calProps.selectedDay,
                overviewDay: $calProps.overviewDay,
                findTransactionWhere: $calProps.findTransactionWhere,
                presentTip: true,
                resetSelectedDayOnClose: true,
            )
        
    }
    
    
    @ViewBuilder
    var calendarView: some View {
        @Bindable var calModel = calModel
        @Bindable var calProps = calProps
        VStack {
            weekdayNames
            dayGrid
        }
        .opacity(calModel.sMonth.enumID == enumID ? 1 : 0)
        .overlay(
            ProgressView()
                .transition(.opacity)
                .tint(.none)
                .opacity(calModel.sMonth.enumID == enumID ? 0 : 1)
        )
        .inspector(isPresented: $calProps.showInspector) {
            if let content = calProps.inspectorContent {
                inspectorContent(content)
            } else {
                /// Have a fallback view with options in case the inspector gets left open.
                /// Inspector state is retained by the SwiftUI framework.
                noInspectorContentView
            }
        }
    }
    
    
    var weekdayNames: some View {
        VStack(spacing: 0) {
            if !AppState.shared.isInFullScreen {
                Divider()
                    .padding(.bottom, 5)
            }
                                
            let weekdaysNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
            LazyVGrid(columns: sevenColumnGrid, spacing: 0) {
                ForEach(weekdaysNames, id: \.self) { name in
                    HStack {
                        if !alignWeekdayNamesLeft {
                            Spacer()
                        }
                        Text(name)
                            .font(.title2)
                            .lineLimit(1)
                        if alignWeekdayNamesLeft {
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 8)
                }
            }
            .padding(.bottom, 5)
            .padding(.top, AppState.shared.isInFullScreen ? 10 : 0)
            //.maxViewHeightObserver()
            
            Divider()
                //.padding(.bottom, 5)
        }
        /// Since the biggest view will always be the weekday names, use this to report its height. The headers of the budget chart and budget table will use the `maxHeaderHeight` to calculate their heights.
        .background {
            GeometryReader { geo in
                Rectangle()
                    .fill(Color.clear)
                    //.fill(Color.red.opacity(0.5))
                    .onChange(of: geo.size.height, initial: true) { oldValue, newValue in
                        maxHeaderHeight = newValue
                    }
            }
        }
    }
    
    
    var dayGrid: some View {
        Group {
            @Bindable var calModel = calModel
            @Bindable var calProps = calProps
            GeometryReader { geo in
                LazyVGrid(columns: sevenColumnGrid, spacing: 0) {
                    ForEach($calModel.sMonth.days) { $day in
                        DayViewMac(transEditID: $transEditID, editTrans: $editTrans, selectedDay: $calProps.selectedDay, day: $day, cellHeight: geo.size.height / divideBy, focusedField: _focusedField)
                            //.border(Color(.gray))
                            .overlay {
                                Rectangle().stroke(Color(.gray), lineWidth: 1)
                            }
                    }
                }
            }
        }
    }
    
    
    @ViewBuilder func inspectorContent(_ content: CalendarInspectorContent) -> some View {
        @Bindable var calProps = calProps
        @Bindable var calModel = calModel
        Group {
            switch content {
            case .dashboard:
                CalendarDashboard()
                
            case .analysisSheet:
                Text("not available")
                //CategoryInsightsViewWrapperIpad(showAnalysisSheet: $calProps.showInspector, model: categoryAnalysisModel)
                    //.onDisappear { calModel.isInMultiSelectMode = false }
                
            case .transactionList:
                TransactionListView(showTransactionListSheet: $calProps.showInspector)
                
            case .plaidTransactions:
                PlaidTransactionOverlay(showInspector: $calProps.showInspector, navPath: .constant(.init()))
                
            case .multiSelectOptions:
                MultiSelectTransactionOptionsSheet(showInspector: $calProps.showInspector)
                
            case .smartTransactionsWithIssues:
                SmartTransactionsWithIssuesOverlay(showInspector: $calProps.showInspector)
                
            case .budgets:
                BudgetTable()
                
            case .overviewDay:
                Text("not available")
                //DayOverviewView(day: $calProps.overviewDay, showInspector: $calProps.showInspector)
                
            case .paymentMethods:
                PayMethodSheet(payMethod: $calModel.sPayMethod, whichPaymentMethods: .all, showStartingAmountOption: true, showNoneOption: true)
            }
        }
        //.toolbarRole(.navigationStack)
        .inspectorColumnWidth(min: 300, ideal: 450, max: 600)
        .presentationBackground(.thinMaterial)
    }
    
    
    var noInspectorContentView: some View {
        NavigationStack {
            StandardContainerWithToolbar(.list) {
                Button { calProps.inspectorContent = .dashboard } label: { Label("Dashboard", systemImage: "rectangle.grid.1x3.fill") }
                Button { calProps.inspectorContent = .analysisSheet } label: { Label("Insights", systemImage: "chart.bar.doc.horizontal") }
                Button { calProps.inspectorContent = .budgets } label: { Label("Budgets", systemImage: "chart.pie") }
                Button { calProps.inspectorContent = .transactionList } label: { Label("All Transactions", systemImage: "list.bullet") }
                                
                Section {
                    Button {
                        calModel.isInMultiSelectMode = true
                        calProps.inspectorContent = .multiSelectOptions
                    } label: {
                        Label("Multi-Select", systemImage: "rectangle.and.hand.point.up.left.filled")
                    }
                }
            }
            .navigationTitle("Inspector")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        calProps.showInspector = false
                    } label: {
                        Image(systemName: "checkmark")
                            .schemeBasedForegroundStyle()
                    }
                }
            }
            #endif
        }
        .inspectorColumnWidth(min: 200, ideal: 250, max: 300)
    }
}

#endif
