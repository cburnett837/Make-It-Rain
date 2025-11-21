//
//  DayOverview.swift
//  MakeItRain
//
//  Created by Cody Burnett on 2/21/25.
//

import Foundation
import SwiftUI
#if os(iOS)
struct DayOverviewView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(CalendarModel.self) private var calModel
    @Environment(CalendarProps.self) private var calProps    
    @Environment(EventModel.self) private var eventModel
    
    @Binding var day: CBDay?
    @Binding var showInspector: Bool

    /// The transaction Sheet and the transfer sheet use the selected day - so keep it up to date with the day being displayed in the bottom panel
//    @Binding var selectedDay: CBDay?
//    @Binding var transEditID: String?
//    @Binding var showTransferSheet: Bool
//    @Binding var showCamera: Bool
//    @Binding var showPhotosPicker: Bool
//    @Binding var bottomPanelHeight: CGFloat
//    @Binding var scrollContentMargins: CGFloat
//    @Binding var bottomPanelContent: BottomPanelContent?
    
    @State private var showDropActions = false
    @State private var showDailyActions = false
    
    var body: some View {
        @Bindable var calProps = calProps
        if day != nil {
            
            if AppState.shared.isIphone {
                StandardContainer(.bottomPanel) {
                    content
                } header: {
                    sheetHeader
                }
            } else {
                NavigationStack {
                    StandardContainerWithToolbar(.list) {
                        content
                    }
                    .navigationTitle("\(day!.displayDate)")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) { moreButton }
                        ToolbarItem(placement: .topBarTrailing) { closeButton }
                    }
                }
            }
        } else {
            Text("")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    
    @ViewBuilder var content: some View {
        @Bindable var calProps = calProps
        Group {
            if let day {
                Group {
                    var filteredTrans: Array<CBTransaction> {
                        calModel.filteredTrans(day: day)
                    }
                    
                    if filteredTrans.isEmpty {
                        ContentUnavailableView("No Transactions", systemImage: "bag.fill.badge.questionmark")
                        Button("Add") {
                            calProps.transEditID = UUID().uuidString
                        }
                        .buttonStyle(.glassProminent)
                        .frame(maxWidth: .infinity)
                        
                    } else {
                        if AppState.shared.isIpad {
                            ForEach(filteredTrans) { trans in
                                LineItemView(trans: trans, day: day)
                            }
                        } else {
                            VStack(spacing: 0) {
                                ForEach(filteredTrans) { trans in
                                    VStack(spacing: 0) {
                                        LineItemView(trans: trans, day: day)
                                        Divider()
                                    }
                                    .listRowInsets(EdgeInsets())
                                }
                            }
                        }
                    }
                }
                .dropDestination(for: CBTransaction.self) { droppedTrans, location in
                    let trans = droppedTrans.first
                    if let trans {
                        if trans.date == day.date {
                            calModel.dragTarget = nil
                            AppState.shared.showToast(title: "Operation Cancelled", subtitle: "Can't copy or move to the original day", body: "Please try again", symbol: "hand.raised.fill", symbolColor: .orange)
                            return true
                        }
                        
                        calModel.transactionToCopy = trans
                        showDropActions = true
                    }
                    
                    return true
                    
                } isTargeted: {
                    if $0 { withAnimation { calModel.dragTarget = day } }
                }
                
                .confirmationDialog("\(day.weekday), the \((day.dateComponents?.day ?? 0).withOrdinal())\n\(calModel.transactionToCopy?.title ?? "N/A")", isPresented: $showDropActions) {
                    moveButton
                    copyAndPasteButton
                    Button("Cancel", role: .cancel) {
                        calModel.dragTarget = nil
                    }
                } message: {
                    Text("\(calModel.transactionToCopy?.title ?? "N/A")\nDropped on \(day.weekday), the \((day.dateComponents?.day ?? 0).withOrdinal())")
                }
                
                .confirmationDialog("\(day.weekday), the \((day.dateComponents?.day ?? 0).withOrdinal())", isPresented: $showDailyActions) {
                    DayContextMenu(day: day, selectedDay: $day)
                } message: {
                    Text("\(day.weekday), the \((day.dateComponents?.day ?? 0).withOrdinal())")
                }
            }
        }
    }
    
    
    
    @ViewBuilder var sheetHeader: some View {
        @Bindable var calProps = calProps
        SheetHeader(
            title: day!.displayDate,
            close: {
                /// When closing, set the selected day back to today or the first of the month if not viewing the current month (which would be the default)
                withAnimation {
                    calProps.bottomPanelContent = nil
                    self.day = nil
                }
                let targetDay = calModel.sMonth.days.filter { $0.dateComponents?.day == (calModel.sMonth.num == AppState.shared.todayMonth ? AppState.shared.todayDay : 1) }.first
                calProps.selectedDay = targetDay
            },
            view1: { moreButton }
        )
//        #if os(iOS)
//        .bottomPanelAndScrollViewHeightAdjuster(bottomPanelHeight: $calProps.bottomPanelHeight, scrollContentMargins: $calProps.scrollContentMargins)
//        #endif
    }
    
    
    var closeButton: some View {
        Button {
            /// When closing, set the selected day back to today or the first of the month if not viewing the current month (which would be the default)
            
            self.day = nil
            
            if AppState.shared.isIphone {
                calProps.bottomPanelContent = nil
            } else {
                showInspector = false
            }

            let targetDay = calModel.sMonth.days.filter { $0.dateComponents?.day == (calModel.sMonth.num == AppState.shared.todayMonth ? AppState.shared.todayDay : 1) }.first
            calProps.selectedDay = targetDay
            
        } label: {
            Image(systemName: "xmark")
                .schemeBasedForegroundStyle()
        }
    }
    
    
    
    @ViewBuilder var moreButton: some View {
        @Bindable var calProps = calProps
        Menu {
            DayContextMenu(day: day!, selectedDay: $day)
        } label: {
            Image(systemName: AppState.shared.isIpad ? "ellipsis.circle" : "ellipsis")
                .schemeBasedForegroundStyle()
                .contentShape(Rectangle())
        }
    }
    
    
    var moveButton: some View {
        Button("Move") {
            withAnimation {
                if let trans = calModel.transactionToCopy {
                    let originalMonth = trans.dateComponents?.month!
                    let monthObj = calModel.months.filter { $0.num == originalMonth }.first
                    if let monthObj {
                        monthObj.days.forEach { $0.transactions.removeAll(where: { $0.id == trans.id }) }
                    }
                    
                    trans.log(field: .date, old: trans.date?.string(to: .monthDayShortYear), new: day?.date?.string(to: .monthDayShortYear), groupID: UUID().uuidString)
                    
                    trans.date = day?.date!
                    calModel.sMonth.days.forEach { $0.transactions.removeAll(where: { $0.id == trans.id }) }
                                                    
                    day?.transactions.append(trans)
                    calModel.dragTarget = nil
                    Task {
                        await calModel.saveTransaction(id: trans.id, eventModel: eventModel)
                    }
                }
            }
        }
    }
    
    
    var copyAndPasteButton: some View {
        Button {
            if let day = day {
                calModel.pasteTransaction(to: day)
            }
            
//            withAnimation {
//                if let trans = calModel.getCopyOfTransaction() {
//                    trans.date = day?.date!
//                                                    
//                    if !calModel.isUnifiedPayMethod {
//                        trans.payMethod = calModel.sPayMethod!
//                    }
//                    
//                    day?.upsert(trans)
//                    calModel.dragTarget = nil
//                    calModel.saveTransaction(id: trans.id, day: day)
//                }
//            }
        } label: {
            Text("Copy & Paste")
        }
    }
        
}
#endif
