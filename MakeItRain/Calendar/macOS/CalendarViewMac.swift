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
    @Local(\.colorTheme) var colorTheme
    @AppStorage("alignWeekdayNamesLeft") var alignWeekdayNamesLeft = true
    
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
    
    @State private var selectedDay: CBDay?
    @State private var transEditID: String?
    @State private var editTrans: CBTransaction?
    
    
    let enumID: NavDestination
    var isInWindow: Bool = false

    
    var body: some View {
        calendarView
            .padding(viewMode == .split ? .horizontal : .horizontal, 15)
            .if(viewMode == .split) {
                $0.frame(minWidth: calendarWidth - (extraViewsWidth / 2))
            }
            .padding(.bottom, 15)
            .task {
                //funcModel.prepareStartingAmounts()
                /// Needed when selecting a month from a category analytic.
                let viewingMonth = calModel.months.filter { $0.enumID == enumID }.first!
                funcModel.prepareStartingAmounts(for: viewingMonth)
                calModel.setSelectedMonthFromNavigation(navID: enumID, prepareStartAmount: true)
                
                let targetDay = calModel.sMonth.days.filter { $0.dateComponents?.day == (calModel.sMonth.actualNum == AppState.shared.todayMonth ? AppState.shared.todayDay : 1) }.first
                selectedDay = targetDay
            }
            .onChange(of: calModel.sMonth) {
                let targetDay = calModel.sMonth.days.filter { $0.dateComponents?.day == (calModel.sMonth.actualNum == AppState.shared.todayMonth ? AppState.shared.todayDay : 1) }.first
                selectedDay = targetDay
            }
            .onPreferenceChange(ViewWidthKey.self) { extraViewsWidth = $0 }
            //.onPreferenceChange(MaxSizePreferenceKey.self) { maxHeaderHeight = max(maxHeaderHeight, $0) }
                    
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    CalendarToolbarLeading(transEditID: $transEditID, focusedField: $focusedField, enumID: enumID, isInWindow: isInWindow)
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
    //        .searchable(text: $searchText) {
    //            let relevantTransactionTitles: Array<String> = calModel
    //                .sMonth
    //                .justTransactions
    //                .filter { $0.payMethod?.id == calModel.sPayMethod?.id }
    //                .compactMap { $0.title }
    //                .uniqued()
    //                .filter { $0.lowercased().contains(searchText.lowercased()) }
    //
    //            ForEach(relevantTransactionTitles, id: \.self) { title in
    //                Text(title)
    //                    .searchCompletion(title)
    //            }
    //        }
    //        .searchScopes($searchWhat) {
    //            Text("Transaction Title")
    //                .tag(CalendarSearchWhat.titles)
    //            Text("Tag")
    //                .tag(CalendarSearchWhat.tags)
    //        }
            .tint(Color.fromName(colorTheme))
            .loadingSpinner(id: enumID, text: "Loading \(enumID.displayName)…")
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
                calModel.hilightTrans = nil
                focusedField = nil
            }
            .onChange(of: transEditID) { oldValue, newValue in
                print(".onChange(of: transEditID)")
                /// When `newValue` is false, save to the server. We have to use this because `.popover(isPresented:)` has no onDismiss option.
                if oldValue != nil && newValue == nil {
//                        calModel.saveTransaction(id: oldValue!, day: day, eventModel: eventModel)
//
//                        /// Keep the model clean, and show alert for a photo that may be taking a long time to upload.
//                        calModel.pictureTransactionID = nil
                } else {
                    editTrans = calModel.getTransaction(by: transEditID!, from: .normalList)
                }
            }
                       
            /// This onChange is needed because you can close the popover without actually clicking the close button.
            /// `popover()` has no `onDismiss()` option, so I need somewhere to do cleanup.
            .onChange(of: editTrans) { oldValue, newValue in
                print(".onChange(of: editTrans)")
                if oldValue == nil && newValue != nil {
                    focusedField = nil
                }
                
                if oldValue != nil && newValue == nil {
                    
                    /// Copy the selected day as it was when the transaction was being edited.
                    let transSelectedDay = selectedDay
                    
                    /// Set the selected day back to today so the plus button will target it.
                    let targetDay = calModel.sMonth.days.filter { $0.dateComponents?.day == (calModel.sMonth.actualNum == AppState.shared.todayMonth ? AppState.shared.todayDay : 1) }.first
                    selectedDay = targetDay
                    
                    let id = oldValue!.id
                    calModel.saveTransaction(id: id, day: transSelectedDay!)
//                        calModel.pictureTransactionID = nil
                    PhotoModel.shared.pictureParent = nil
                }
            }
        
    }
    
    
    var calendarView: some View {
        Group {
            @Bindable var calModel = calModel
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
        }
    }
    
    
    var weekdayNames: some View {
        VStack(spacing: 0) {
            if !AppState.shared.isInFullScreen {
                Divider()
                    .padding(.bottom, 5)
            }
                                
            LazyVGrid(columns: sevenColumnGrid, spacing: 0) {
                ForEach(calModel.weekdaysNames, id: \.self) { name in
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
            GeometryReader { geo in
                LazyVGrid(columns: sevenColumnGrid, spacing: 0) {
                    ForEach($calModel.sMonth.days) { $day in
                        DayViewMac(transEditID: $transEditID, editTrans: $editTrans, selectedDay: $selectedDay, day: $day, cellHeight: geo.size.height / divideBy, focusedField: _focusedField)
                            //.border(Color(.gray))
                            .overlay {
                                Rectangle().stroke(Color(.gray), lineWidth: 1)
                            }
                    }
                }
            }
        }
    }
}

#endif
