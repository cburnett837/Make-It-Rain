//
//  DayOverview.swift
//  MakeItRain
//
//  Created by Cody Burnett on 2/21/25.
//

import Foundation
import SwiftUI

struct DayOverviewView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(CalendarModel.self) private var calModel
    @Environment(CalendarViewModel.self) private var calViewModel
    @Environment(EventModel.self) private var eventModel
    
    @Binding var day: CBDay?
    /// The transaction Sheet and the transfer sheet use the selected day - so keep it up to date with the day being displayed in the bottom panel
    @Binding var selectedDay: CBDay?
    @Binding var transEditID: String?
    @Binding var showTransferSheet: Bool
    @Binding var showCamera: Bool
    @Binding var showPhotosPicker: Bool
    
    @State private var showDropActions = false
    @State private var showDailyActions = false
    
    var body: some View {
        if let day {
            var filteredTrans: Array<CBTransaction> {
                calModel.filteredTrans(day: day)
            }
            VStack {
                #if os(iOS)
                if !AppState.shared.isLandscape { header }
                #else
                header
                #endif
                ScrollView {
                    VStack(spacing: 0) {
                        #if os(iOS)
                        if AppState.shared.isLandscape { header }
                        #endif
                        Divider()
                        
                        if filteredTrans.isEmpty {
                            ContentUnavailableView("No Transactions", systemImage: "bag.fill.badge.questionmark")
                            Button("Add") {
                                transEditID = UUID().uuidString
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
            }
            #if os(iOS)
            .background {
                //Color.darkGray.ignoresSafeArea(edges: .bottom)
                Color(.secondarySystemBackground)
                    .clipShape(
                        .rect(
                            topLeadingRadius: 15,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: 15
                        )
                    )
                    .ignoresSafeArea(edges: .bottom)
            }
            #endif
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
                DayContextMenu(
                    day: day,
                    selectedDay: $day,
                    transEditID: $transEditID,
                    showTransferSheet: $showTransferSheet,
                    showCamera: $showCamera,
                    showPhotosPicker: $showPhotosPicker
                )
            } message: {
                Text("\(day.weekday), the \((day.dateComponents?.day ?? 0).withOrdinal())")
            }
        }
    }
    
    
    var header: some View {
        SheetHeader(
            title: day!.displayDate,
            close: {
                /// When closing, set the selected day back to today or the first of the month if not viewing the current month (which would be the default)
                withAnimation { self.day = nil }
                let targetDay = calModel.sMonth.days.filter { $0.dateComponents?.day == (calModel.sMonth.num == AppState.shared.todayMonth ? AppState.shared.todayDay : 1) }.first
                selectedDay = targetDay
            },
            view1: { moreButton }
        )
        .padding()
    }
    
    
    var moreButton: some View {
//            Button {
//                showDailyActions = true
//            } label: {
//                Image(systemName: "ellipsis")
//            }
                    
        Menu {
            DayContextMenu(
                day: day!,
                selectedDay: $day,
                transEditID: $transEditID,
                showTransferSheet: $showTransferSheet,
                showCamera: $showCamera,
                showPhotosPicker: $showPhotosPicker
            )
        } label: {
            Image(systemName: "ellipsis")
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
                    calModel.saveTransaction(id: trans.id, eventModel: eventModel)
                }
            }
        }
    }
    
    var copyAndPasteButton: some View {
        Button {
            withAnimation {
                if let trans = calModel.getCopyOfTransaction() {
                    trans.date = day?.date!
                                                    
                    if !calModel.isUnifiedPayMethod {
                        trans.payMethod = calModel.sPayMethod!
                    }
                    
                    day?.upsert(trans)
                    calModel.dragTarget = nil
                    calModel.saveTransaction(id: trans.id, day: day)
                }
            }
        } label: {
            Text("Copy & Paste")
        }
    }
        
}
