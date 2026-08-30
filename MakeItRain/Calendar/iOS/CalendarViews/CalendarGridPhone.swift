//
//  CalendarGridPhone.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/3/25.
//

import SwiftUI

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

#if os(iOS)
struct CalendarGridPhone: View {
    @Local(\.lineItemIndicator) var lineItemIndicator
    @Local(\.phoneLineItemDisplayItem) var phoneLineItemDisplayItem
    
    @Environment(CalendarModel.self) private var calModel
    @Environment(CalendarProps.self) private var calProps
    
    let enumID: NavDest
    
    @State private var initialGeoHeight: CGFloat = 0
    @State private var resetTransactionHighlightTask: Task<Void, Never>?
    
    private let sevenColumnGrid = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    
    private var divideBy: CGFloat {
        let cellCount = calModel.sMonth.firstWeekdayOfMonth - 1 + calModel.sMonth.dayCount
        if cellCount > 35 {
            return 6
        } else if cellCount <= 35 && cellCount > 28 {
            return 5
        } else {
            return 4
        }
    }
    
    private struct DayRenderData {
        let filteredTransactionsByDayID: [CBDay.ID: [CBTransaction]]
        let shouldLimitRows: Bool
    }

    private var dayRenderData: DayRenderData {
        let filteredTransactionsByDayID = Dictionary(
            uniqueKeysWithValues: calModel.sMonth.days.map { day in
                (day.id, calModel.filteredTrans(day: day))
            }
        )

        return DayRenderData(
            filteredTransactionsByDayID: filteredTransactionsByDayID,
            shouldLimitRows:
                calModel.transCountForCurrentPayMethod > calModel.sMonth.dayCount * 5
                && phoneLineItemDisplayItem == .both
        )
    }
        
    
    #warning("REGARDING HITCH: All I did here was change binding to day to a regular bindable")
    var body: some View {
        //let _ = Self._printChanges()
        @Bindable var calModel = calModel
        @Bindable var calProps = calProps
        
        let renderData = dayRenderData
        let weeks = calModel.sMonth.days.chunked(into: 7)
        
        /// Use geometry reader instead of a preference key to avoid the fakeNavHeader from being pushed up when the dayOverView sheet gets dragged to the top.
        GeometryReader { geo in
            /// DO NOT USE the new scrollView apis.
            /// The new .scrollPosition($scrollPosition) causes big lagging issues when scrolling. ---> I think it's because it has to constantly report its position.
            ScrollViewReader { scrollProxy in
                ScrollView {
                    /// NOTE: Tried and failed to use LazyVGrid, because when dismissing the bottom panel, the scroll view would not resize with the dismissing transition. It would just snap when the transition has finished. This is because the LazyVGrid would recalc its size.
                    Grid(alignment: .top, horizontalSpacing: 0, verticalSpacing: 0) {
                        ForEach(weeks.indices, id: \.self) { i in
                            let week = weeks[i]
                            GridRow {
                                ForEach(week) { day in
                                    VStack(spacing: 0) {
//                                        SimpDayView(id: day.id)
                                        DayViewPhone(
                                            day: day,
                                            isToday: calModel.sMonth.isNow && day.id == AppState.shared.todayDay,
                                            filteredTrans: renderData.filteredTransactionsByDayID[day.id, default: []],
                                            shouldLimitRows: renderData.shouldLimitRows,
                                            lineItemIndicator: lineItemIndicator,
                                            phoneLineItemDisplayItem: phoneLineItemDisplayItem,
                                        )
                                        
                                        if week != weeks.last {
                                            dividingLine
                                        }
                                    }
                                    /// Use the initial geo height so the day view doesn't shrink too much when opening the bottom panel.
                                    .frame(minHeight: initialGeoHeight / divideBy, alignment: .center)
                                    .id(day.id)
                                }
                            }
                        }
                    }
                }
                //.contentMargins(.bottom, calculatedScrollContentMargins, for: .scrollContent)
                .frame(height: geo.size.height)
                .scrollIndicators(.hidden)
                //.onScrollPhaseChange { if $1 == .interacting { withAnimation { calModel.hilightTrans = nil } } }
                /// Scroll to today when the view loads (if applicable)
                .onAppear {
                    scrollToDayOnAppearOfScrollView(scrollProxy)
                }
                /// Focus on the overviewDay when selecting, or changing.
                .onChange(of: calProps.overviewDay) { scrollToOverViewDay(scrollProxy, $0, $1) }
                .onChange(of: calProps.bottomPanelContent) { handleBottomPanelContentChange($0, $1) }
                
                /// - From the plaid sheet, if applicable, you can select one of the lines to show the potentially related transaction.
                /// - When this happens, look up the transaction, and take us to the month of the transaction.
                /// - Then scroll to and highlight the transaction.
                .onChange(of: calProps.showPotentiallyExistingTransFromPlaidID) { oldId, newId in
                    if let newId,
                       let trans = calModel.getTransaction(by: newId),
                       let date = trans.date {
                        
                        /// Navigate to the appropriate month if it's not currently on screen.
                        if calModel.sMonth.actualNum != date.month || calModel.sMonth.year != date.year {
                            if let month = calModel.months.get(by: (date.month, date.year)) {
                                NavigationManager.shared.selectedMonth = month.enumID
                            }
                        } else {
                            /// If we're already viewing the appropriate month, scroll to the transaction and highlight it.
                            withAnimation {
                                scrollProxy.scrollTo(date.day, anchor: .top)
                                calProps.tempHighlightTransId = trans.id
                            }
                        }
                    }
                }
                /// - When the applicable potentially related transaction from plaid is highlighted, clear the ID of it from `calProps`, and start a task to clear the highlight.
                /// - In the code above, `calProps.tempHighlightTransId = trans.id`
                ///     will cause `onChange(of: calProps.tempHighlightTransId)` to run
                ///     inside ``LineItemMiniView``,  which will cause all transactions to change to the appropriate highlight state.
                /// - The `resetTransactionHighlightTask` task below will reset all the transactions
                ///     back to normal via `LineItemMiniView.onChange(of: calProps.tempHighlightTransId)`.
                .onChange(of: calProps.tempHighlightTransId) { oldValue, newValue in
                    calProps.showPotentiallyExistingTransFromPlaidID = nil
                    guard newValue != nil else { return }

                    resetTransactionHighlightTask?.cancel()

                    resetTransactionHighlightTask = Task {
                        do {
                            try await Task.sleep(for: .seconds(1.5))

                            guard !Task.isCancelled else { return }

                            calProps.tempHighlightTransId = nil
                            resetTransactionHighlightTask = nil
                        } catch {
                            // Task was cancelled.
                        }
                    }
                }
            }
            /// Set the initial geo height so the day views don't shrink too much when opening the bottom panel. (Since the geometry reader will get small and cause the minHeight of the day view to become less)
            .task {
                /// When navigating forward via the bottom panel, when you come back to the calendar, this would be recalculated based on the size of the calendar view with the bottom panel open. This would cause the day views to be too small. So only set `initialGeoHeight` if it's 0 (default).
                if initialGeoHeight.isZero {
                    initialGeoHeight = geo.size.height
                }
            }
        }
    }
    
    
    var dividingLine: some View {
        Rectangle()
            .frame(width: nil, height: 2, alignment: .bottom)
            .foregroundColor(Color(.tertiarySystemFill))
    }
    
    
    func handleBottomPanelContentChange(_ oldValue: BottomPanelContent?, _ newValue: BottomPanelContent?) {
        if oldValue == .overviewDay && newValue != nil {
            calProps.overviewDay = nil
            
            let dayValue = (calModel.sMonth.num == AppState.shared.todayMonth ? AppState.shared.todayDay : 1)
            let targetDay = calModel.sMonth.getDay(by: dayValue)
            calProps.selectedDay = targetDay
        }
        
        #warning("Wtf was this for, it causes the bottom panel to infinitely open... 8/28/26")
//        if newValue == nil {
//            if calModel.isInMultiSelectMode {
//                calProps.bottomPanelContent = .multiSelectOptions
//            }
//        }
    }
    
    
    func scrollToDayOnAppearOfScrollView(_ proxy: ScrollViewProxy) {
        if enumID.monthActualNum == AppState.shared.todayMonth && calModel.sMonth.year == AppState.shared.todayYear {
            /// Give a little delay since the view can take a while to render.
            /// Without the delay, you can kind of see it flicker when it loads.
            DispatchQueue.main.asyncAfter(deadline: .now() + (calModel.isFirstCalendarLoad ? 0.5 : 0.1)) {
                
                /// If we are opening now month, scroll to today.
                if calProps.showPotentiallyExistingTransFromPlaidID == nil {
                    if let today = calModel.sMonth.days.first(where: { $0.id == AppState.shared.todayDay }) {
                        withAnimation {
                            proxy.scrollTo(today.id, anchor: .top)
                        }
                    }
                } else {
                    /// If we are coming to this month via the plaid sheet, find the appropriate transaction and scroll to it.
                    if let newId = calProps.showPotentiallyExistingTransFromPlaidID,
                       let trans = calModel.getTransaction(by: newId),
                       let date = trans.date {
                        if let targetDay = calModel.sMonth.getDay(by: date) {
                            withAnimation {
                                proxy.scrollTo(targetDay.id, anchor: .top)
                            } completion: {
                                /// Allow a little buffer for the scroll to complete before highlighing the transaction.
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    calProps.tempHighlightTransId = trans.id
                                }
                            }
                        }
                    }
                }
                
                /// There is an animation lag when the calendar first shows. So adjust the "scroll to today" time accordingly.
                calModel.isFirstCalendarLoad = false
            }
        } else {
            /// There is an animation lag when the calendar first shows. So adjust the "scroll to today" time accordingly.
            if calModel.isFirstCalendarLoad {
                calModel.isFirstCalendarLoad = false
            }
        }
    }
    
    
//    func scrollToOverViewDayOLD(_ proxy: ScrollViewProxy, _ oldValue: CBDay?, _ newValue: CBDay?) {
//        print("-- \(#function)")
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
//            if let day = newValue {
//                print("\(#function) -- new overView day is set")
//                /// Block this from running since .onChange(of: calculatedScrollContentMargins) will also run when opening the day for the first time.
//                if oldValue != nil {
//                    print("\(#function) -- adjusting day to \(day.id)")
//                    withAnimation { proxy.scrollTo(day.id, anchor: .bottom) }
//                } else {
//                    print("\(#function) -- ignoring because oldValue is nil")
//                }
//                
//            } else if let oldViewDay = oldValue {
//                print("\(#function) -- old overView say is set - adjusting day to \(oldViewDay.id)")
//                withAnimation { proxy.scrollTo(oldViewDay.id, anchor: .bottom) }
//            } else {
//                print("\(#function) -- Can't find overview day")
//            }
//        }
//    }
    
    
    func scrollToOverViewDay(_ proxy: ScrollViewProxy, _ oldValue: CBDay?, _ newValue: CBDay?) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            if let day = newValue {
                withAnimation(.bouncy) {
                    proxy.scrollTo(day.id, anchor: .bottom)
                }
            }
        }
    }
}
#endif



#if os(iOS)
struct SimpCalendarGridPhone: View {
    @Local(\.lineItemIndicator) var lineItemIndicator
    @Local(\.phoneLineItemDisplayItem) var phoneLineItemDisplayItem
    
    @Environment(CalendarModel.self) private var calModel
    @Environment(CalendarProps.self) private var calProps
    
    let enumID: NavDest
    
    @State private var initialGeoHeight: CGFloat = 0
    
    let sevenColumnGrid = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    
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
        
    
    #warning("REGARDING HITCH: All I did here was change binding to day to a regular bindable")
    @ViewBuilder
    var body: some View {
        //let _ = Self._printChanges()
        @Bindable var calModel = calModel
        @Bindable var calProps = calProps
        
        let weeks = calModel.sMonth.days.chunked(into: 7)
        
        /// Use geometry reader instead of a preference key to avoid the fakeNavHeader from being pushed up when the dayOverView sheet gets dragged to the top.
        GeometryReader { geo in
            /// DO NOT USE the new scrollView apis.
            /// The new .scrollPosition($scrollPosition) causes big lagging issues when scrolling. ---> I think it's because it has to constantly report its position.
            ScrollViewReader { scrollProxy in
                ScrollView {
                    /// NOTE: Tried and failed to use LazyVGrid, because when dismissing the bottom panel, the scroll view would not resize with the dismissing transition. It would just snap when the transition has finished. This is because the LazyVGrid would recalc its size.
                    Grid(alignment: .top, horizontalSpacing: 0, verticalSpacing: 0) {
                        ForEach(weeks, id: \.self) { week in
                            GridRow {
                                ForEach(week) { day in
                                    VStack(spacing: 0) {
                                        SimpDayView(id: day.id)
                                    }
                                    /// Use the initial geo height so the day view doesn't shrink too much when opening the bottom panel.
                                    .frame(minHeight: initialGeoHeight / divideBy, alignment: .center)
                                    .id(day.id)
                                }
                            }
                        }
                    }
                }
                .frame(height: geo.size.height)
                .scrollIndicators(.hidden)
                /// Scroll to today when the view loads (if applicable)
                .onAppear { scrollToTodayOnAppearOfScrollView(scrollProxy) }
                /// Focus on the overviewDay when selecting, or changing.
            }
            .task {
                if initialGeoHeight.isZero {
                    initialGeoHeight = geo.size.height
                }
            }
        }
    }
    
    func scrollToTodayOnAppearOfScrollView(_ proxy: ScrollViewProxy) {
        if enumID.monthActualNum == AppState.shared.todayMonth && calModel.sMonth.year == AppState.shared.todayYear {
            /// Give a little delay since the view can take a while to render.
            /// Without the delay, you can kind of see it flicker when it loads.
            DispatchQueue.main.asyncAfter(deadline: .now() + (calModel.isFirstCalendarLoad ? 0.5 : 0.1)) {
                if let today = calModel.sMonth.days.first(where: { $0.id == AppState.shared.todayDay }) {
                    withAnimation {
                        proxy.scrollTo(today.id, anchor: .top)
                    }
                } else {
                    print("⚠️ todayDay not found in current scrollable days.")
                }
                
                /// There is an animation lag when the calendar first shows. So adjust the "scroll to today" time accordingly.
                calModel.isFirstCalendarLoad = false
            }
        } else {
            /// There is an animation lag when the calendar first shows. So adjust the "scroll to today" time accordingly.
            if calModel.isFirstCalendarLoad {
                calModel.isFirstCalendarLoad = false
            }
        }
    }
}
#endif
