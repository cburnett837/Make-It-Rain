//
//  CalendarGridPhone.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/3/25.
//

import SwiftUI

struct CalendarGridPhone: View {
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
    
    var body: some View {
        @Bindable var calModel = calModel
        @Bindable var calProps = calProps
        
        /// Use geometry reader instead of a preference key to avoid the fakeNavHeader from being pushed up when the dayOverView sheet gets dragged to the top.
        return GeometryReader { geo in
            /// DO NOT USE the new scrollView apis.
            /// The new .scrollPosition($scrollPosition) causes big lagging issues when scrolling. --->I think it's because it has to constantly report its position.
            ScrollViewReader { scrollProxy in
                ScrollView {
                    LazyVGrid(columns: sevenColumnGrid, spacing: 0) {
                        ForEach($calModel.sMonth.days) { $day in
                            DayViewPhone(day: $day)
                                .overlay(dividingLine, alignment: .bottom)
                                .frame(minHeight: geo.size.height / divideBy, alignment: .center)
                                .id(day.id)
                        }
                    }
                }
                //.contentMargins(.bottom, calculatedScrollContentMargins, for: .scrollContent)
                .frame(height: geo.size.height)
                .scrollIndicators(.hidden)
                .onScrollPhaseChange { if $1 == .interacting { withAnimation { calModel.hilightTrans = nil } } }
                /// Scroll to today when the view loads (if applicable)
                .onAppear { scrollToTodayOnAppearOfScrollView(scrollProxy) }
                /// Focus on the overviewDay when selecting, or changing.
                .onChange(of: calProps.overviewDay) { scrollToOverViewDay(scrollProxy, $0, $1) }
                
                .onChange(of: calProps.bottomPanelContent) { oldValue, newValue in
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
            }
        }
    }
    
    
    var dividingLine: some View {
        Rectangle()
            .frame(width: nil, height: 2, alignment: .bottom)
            .foregroundColor(Color(.tertiarySystemFill))
    }
    
    
    func scrollToTodayOnAppearOfScrollView(_ proxy: ScrollViewProxy) {
        if enumID.monthNum == AppState.shared.todayMonth {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    proxy.scrollTo(AppState.shared.todayDay, anchor: .bottom)
                }
            }
        }
    }
    
    
    func scrollToOverViewDay(_ proxy: ScrollViewProxy, _ oldValue: CBDay?, _ newValue: CBDay?) {
        print("-- \(#function)")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if let day = newValue {
                print("\(#function) -- new overView day is set")
                /// Block this from running since .onChange(of: calculatedScrollContentMargins) will also run when opening the day for the first time.
                if oldValue != nil {
                    print("\(#function) -- adjusting day to \(day.id)")
                    withAnimation {
                        proxy.scrollTo(day.id, anchor: .bottom)
                    }
                } else {
                    print("\(#function) -- ignoring because oldValue is nil")
                }
                
            } else if let oldViewDay = oldValue {
                print("\(#function) -- old overView say is set - adjusting day to \(oldViewDay.id)")
                withAnimation { proxy.scrollTo(oldViewDay.id, anchor: .bottom) }
            } else {
                print("\(#function) -- Can't find overview day")
            }
        }
    }
}
