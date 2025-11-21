//
//  CalendarGridPhone.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/3/25.
//

import SwiftUI
#if os(iOS)
struct CalendarGridPhone: View {
    @Local(\.tightenUpEodTotals) var tightenUpEodTotals
    @Local(\.lineItemIndicator) var lineItemIndicator
    @Local(\.phoneLineItemDisplayItem) var phoneLineItemDisplayItem
    @Local(\.incomeColor) var incomeColor
    @Local(\.useWholeNumbers) var useWholeNumbers
    
    @Environment(CalendarModel.self) private var calModel
    @Environment(CalendarProps.self) private var calProps
    
    let enumID: NavDestination
    
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
    
    @State private var initialGeoHeight: CGFloat = 0
    
    #warning("REGARDING HITCH: All I did here was change binding to day to a regular bindable")
    var body: some View {
        let _ = Self._printChanges()
        @Bindable var calModel = calModel
        @Bindable var calProps = calProps
        
        /// Use geometry reader instead of a preference key to avoid the fakeNavHeader from being pushed up when the dayOverView sheet gets dragged to the top.
        GeometryReader { geo in
            /// DO NOT USE the new scrollView apis.
            /// The new .scrollPosition($scrollPosition) causes big lagging issues when scrolling. ---> I think it's because it has to constantly report its position.
            ScrollViewReader { scrollProxy in
                ScrollView {
                    LazyVGrid(columns: sevenColumnGrid, spacing: 0) {
                        #warning("day as $binding (not bindable) causes hitches with sheets.")
                        ForEach(calModel.sMonth.days) { day in
                            DayViewPhone(
                                day: day,
                                tightenUpEodTotals: tightenUpEodTotals,
                                lineItemIndicator: lineItemIndicator,
                                phoneLineItemDisplayItem: phoneLineItemDisplayItem,
                                incomeColor: incomeColor,
                                useWholeNumbers: useWholeNumbers
                            )
                            .overlay(dividingLine, alignment: .bottom)
                            /// Use the initial geo height so the day view doesn't shrink too much when opening the bottom panel.
                            .frame(minHeight: initialGeoHeight / divideBy, alignment: .center)
                            .id(day.id)
                        }
                    }
                }
                //.contentMargins(.bottom, calculatedScrollContentMargins, for: .scrollContent)
                .frame(height: geo.size.height)
                .scrollIndicators(.hidden)
                //.onScrollPhaseChange { if $1 == .interacting { withAnimation { calModel.hilightTrans = nil } } }
                /// Scroll to today when the view loads (if applicable)
                .onAppear { scrollToTodayOnAppearOfScrollView(scrollProxy) }
                /// Focus on the overviewDay when selecting, or changing.
                .onChange(of: calProps.overviewDay) { scrollToOverViewDay(scrollProxy, $0, $1) }
                .onChange(of: calProps.bottomPanelContent) { handleBottomPanelContentChange($0, $1) }
            }
            /// Set the initial geo height so the day views don't shrink too much when opening the bottom panel. (Since the geometry reader will get small and cause the minHeight of the day view to become less)
            .task { initialGeoHeight = geo.size.height }
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
            let targetDay = calModel.sMonth.days.filter { $0.dateComponents?.day == (calModel.sMonth.num == AppState.shared.todayMonth ? AppState.shared.todayDay : 1) }.first
            calProps.selectedDay = targetDay
        }
        
        if newValue == nil {
            if calModel.isInMultiSelectMode {
                calProps.bottomPanelContent = .multiSelectOptions
            }
        }
    }
    
    
    func scrollToTodayOnAppearOfScrollView(_ proxy: ScrollViewProxy) {
        if enumID.monthNum == AppState.shared.todayMonth {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                withAnimation {
//                    proxy.scrollTo(AppState.shared.todayDay, anchor: .top)
//                }
                
                if let today = calModel.sMonth.days.first(where: { $0.id == AppState.shared.todayDay }) {
                    withAnimation {
                        proxy.scrollTo(today.id, anchor: .top)
                    }
                } else {
                    print("⚠️ todayDay not found in current scrollable days.")
                }
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
