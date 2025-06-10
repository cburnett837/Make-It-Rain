//
//  DayViewPhone.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/16/24.
//

import SwiftUI

#if os(iOS)
struct DayViewPhone: View {
    @Environment(\.colorScheme) var colorScheme
    @Local(\.colorTheme) var colorTheme
    @AppStorage("updatedByOtherUserDisplayMode") var updatedByOtherUserDisplayMode = UpdatedByOtherUserDisplayMode.full
    @Local(\.useWholeNumbers) var useWholeNumbers
    @AppStorage("tightenUpEodTotals") var tightenUpEodTotals = true
    @Local(\.threshold) var threshold
    @AppStorage("lineItemIndicator") var lineItemIndicator: LineItemIndicator = .emoji
    @AppStorage("phoneLineItemDisplayItem") var phoneLineItemDisplayItem: PhoneLineItemDisplayItem = .both
    
    
    @Environment(CalendarModel.self) private var calModel
    
    @Environment(PayMethodModel.self) private var payModel
    @Environment(CategoryModel.self) private var catModel
    @Environment(KeywordModel.self) private var keyModel
    
    private var eodColor: Color {
        if day.eodTotal > threshold {
            return .gray
        } else if day.eodTotal < 0 {
            return .red
        } else {
            return .orange
        }
    }
    private var isToday: Bool {
        AppState.shared.todayDay == (day.dateComponents?.day ?? 0) && AppState.shared.todayMonth == calModel.sMonth.actualNum && AppState.shared.todayYear == calModel.sMonth.year
    }
    
    @Binding var transEditID: String?
    @Binding var day: CBDay
    @Binding var selectedDay: CBDay?
    @Binding var showTransferSheet: Bool
    //@Binding var putBackToBottomPanelViewOnRotate: Bool
    @Binding var showPhotosPicker: Bool
    @Binding var showCamera: Bool
    @Binding var overviewDay: CBDay?
    @Binding var bottomPanelContent: BottomPanelContent?
    
    @State private var showDropActions = false
    @State private var showDailyActions = false
    @State private var showMoreTrans = false
    
    
    var filteredTrans: [CBTransaction] {
        calModel.filteredTrans(day: day)
    }
    
    let columnGrid = Array(repeating: GridItem(.flexible(), spacing: 3), count: 2)
    
   
    var body: some View {
        //let _ = Self._printChanges()
        @Bindable var calModel = calModel
        Group {
            if day.date == nil {
                VStack {
                    Text("")
                    Spacer()
                        .frame(maxWidth: .infinity)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation { calModel.hilightTrans = nil }
                }
                .dropDestination(for: CBTransaction.self) { droppedTrans, location in
                    calModel.dragTarget = nil
                    return true
                }
            } else {
                VStack(spacing: 5) {
                    dayNumber
                    dailyTransactionList
                    eodText
                }
                .frame(maxWidth: .infinity, alignment: .center) /// This causes each day to be the same width.
                .contentShape(Rectangle())
                .onTapGesture {
                    if phoneLineItemDisplayItem != .both {
                        withAnimation {
                            overviewDay = day
                            /// Set `selectedDay` to the same day as the overview day that way any transactions or transfers initiated via the bottom panel will have the date of the bottom panel.
                            /// (Since `TransactionEditView` and `TransferSheet` use `selectedDate` as their default date.)
                            selectedDay = day
                            
                            bottomPanelContent = .overviewDay
                            
                        }
                    }
                }
                .onLongPressGesture(minimumDuration: 1) {
                    showDailyActions = true
                }
                .sensoryFeedback(.warning, trigger: showDailyActions) { !$0 && $1 }                
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        /// Use this to only hilight the overview day.
                        .fill((overviewDay == day && bottomPanelContent == .overviewDay) || calModel.dragTarget == day ? Color(.tertiarySystemFill) : Color.clear)
                        /// Offset the overlay divider line in `CalendarViewPhone` that separates the weeks.
                        .padding(.bottom, 2)
                )
                .padding(.vertical, 2)
                .dropDestination(for: CBTransaction.self) { droppedTrans, location in
                    let trans = droppedTrans.first
                    if let trans {
                        if trans.date == day.date {
                            calModel.dragTarget = nil
                            AppState.shared.showToast(title: "Operation Cancelled", subtitle: "Can't copy or move to the original day", body: "Please try again", symbol: "hand.raised.fill", symbolColor: .orange)
                            calModel.transactionToCopy = nil
                            return true
                        }
                                                
                        calModel.transactionToCopy = trans
                        showDropActions = true
                    }
                    
                    return true
                    
                } isTargeted: {
                    if $0 {
                        withAnimation { calModel.dragTarget = day }
                    } else {
                        withAnimation { calModel.dragTarget = nil }
                    }
                }
                
                .confirmationDialog("\(day.weekday), the \((day.dateComponents?.day ?? 0).withOrdinal())\n\(calModel.transactionToCopy?.title ?? "N/A")", isPresented: $showDropActions) {
                    moveButton
                    copyAndPasteButton
                    Button("Cancel", role: .cancel) {
                        calModel.dragTarget = nil
                        calModel.transactionToCopy = nil
                    }
                } message: {
                    Text("\(calModel.transactionToCopy?.title ?? "N/A")\nDropped on \(day.weekday), the \((day.dateComponents?.day ?? 0).withOrdinal())")
                }
                
                .confirmationDialog("\(day.weekday), the \((day.dateComponents?.day ?? 0).withOrdinal())", isPresented: $showDailyActions) {
                    DayContextMenu(
                        day: day,
                        selectedDay: $selectedDay,
                        transEditID: $transEditID,
                        showTransferSheet: $showTransferSheet,
                        showCamera: $showCamera,
                        showPhotosPicker: $showPhotosPicker,
                        overviewDay: $overviewDay,
                        bottomPanelContent: $bottomPanelContent
                    )
                } message: {
                    Text("\(day.weekday), the \((day.dateComponents?.day ?? 0).withOrdinal())")
                }
            }
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
                    
                    trans.log(field: .date, old: trans.date?.string(to: .monthDayShortYear), new: day.date?.string(to: .monthDayShortYear), groupID: UUID().uuidString)
                    
                    trans.date = day.date!
                    calModel.sMonth.days.forEach { $0.transactions.removeAll(where: { $0.id == trans.id }) }
                                                    
                    day.transactions.append(trans)
                    calModel.dragTarget = nil
                    calModel.saveTransaction(id: trans.id)
                    
                    calModel.transactionToCopy = nil
                }
            }
        }
    }
    
    var copyAndPasteButton: some View {
        Button {
            withAnimation {
                if let trans = calModel.getCopyOfTransaction() {
                    trans.date = day.date!
                                                    
                    if !calModel.isUnifiedPayMethod {
                        trans.payMethod = calModel.sPayMethod!
                    }
                    
                    day.upsert(trans)
                    calModel.dragTarget = nil
                    calModel.saveTransaction(id: trans.id, day: day)
                    
                    calModel.transactionToCopy = nil
                }
            }
        } label: {
            Text("Copy & Paste")
        }
    }
        
    
    var dayNumber: some View {
        Text("\(day.dateComponents?.day ?? 0)")
            .contentShape(Rectangle())
            .if(isToday) {
                $0
                .bold()
                .padding(4)
                .background {
                    Circle()
                    //RoundedRectangle(cornerRadius: 5)
                        .fill(Color.fromName(colorTheme))
                        //.frame(maxWidth: .infinity)
                }
                .foregroundStyle(.white)
                .padding(-4)
            }
            .padding(.leading, AppState.shared.isIpad ? 6 : 0)
            .frame(maxWidth: .infinity, alignment: AppState.shared.isIpad ? .leading : .center)
    }
    
    
    var dailyTransactionList: some View {
        VStack(alignment: .leading, spacing: 2) {
            
            if calModel.sMonth.transactionCount > (calModel.sMonth.dayCount * 5)
                && filteredTrans.count > 5
                && phoneLineItemDisplayItem == .both
            {
                ForEach(filteredTrans.prefix(5)) { trans in
                    LineItemMiniView(transEditID: $transEditID, trans: trans, day: day)
                }
                HStack(spacing: 2) {
                    Canvas { context, size in
                        let capsuleRect = CGRect(origin: .zero, size: size)
                        let capsulePath = Path(roundedRect: capsuleRect, cornerRadius: size.height / 2) // Full capsule effect
                        context.fill(capsulePath, with: .color(.gray))
                    }
                    .frame(width: 3)
                    .padding(.vertical, 2)
                    
                    Button {
                        withAnimation {
                            showMoreTrans.toggle()
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: 0) {
                            Text(showMoreTrans ? "Hide…" : "More…")
                                .font(.caption2)
                                .foregroundStyle(.gray)
                                .lineLimit(1)
                            Text("(\(filteredTrans.count - 5))")
                                .font(.system(size: 10))
                                .foregroundStyle(.gray)
                                .lineLimit(1)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 2)
                .fixedSize(horizontal: false, vertical: true)
                
                
                if showMoreTrans {
                    ForEach(filteredTrans.suffix(filteredTrans.count - 5)) { trans in
                        LineItemMiniView(transEditID: $transEditID, trans: trans, day: day)
                    }
                }
            } else {
                ForEach(filteredTrans) { trans in
                    LineItemMiniView(transEditID: $transEditID, trans: trans, day: day)
                }
            }
            
            Spacer()
        }
    }
    
//    var transactionDotRow: some View {
//        HStack(spacing: 1) {
//            if filteredTrans.count == 0 {
//                Circle()
//                    .fill(.clear)
//                    .frame(width: 6, height: 6)
//                    .padding(.vertical, 3.5)
//
//            } else if filteredTrans.count > 6 {
//                Circle()
//                    .fill(day.transactions[0].category?.color ?? .primary)
//                    .frame(width: 6, height: 6)
//                Circle()
//                    .fill(day.transactions[1].category?.color ?? .primary)
//                    .frame(width: 6, height: 6)
//
//                Text("+\(filteredTrans.count - 2)")
//                    .foregroundStyle(.primary)
//                    .font(.caption2)
//
//            } else {
//                ForEach(filteredTrans) { trans in
//                    Circle()
//                        .fill(trans.category?.color ?? .primary)
//                        .frame(width: 6, height: 6)
//                        .padding(.vertical, 3.5)
//                }
//            }
//        }
//    }
//
    var eodText: some View {
        Group {
            if useWholeNumbers && tightenUpEodTotals {
                Text("\(String(format: "%.00f", day.eodTotal).replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: ""))")
                
            } else if useWholeNumbers {
                Text(day.eodTotal.currencyWithDecimals(0))
                
            } else if !useWholeNumbers && tightenUpEodTotals {
                Text(day.eodTotal.currencyWithDecimals(2).replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: ""))
                
            } else {
                Text(day.eodTotal.currencyWithDecimals(2))
            }
        }
        .padding(.leading, AppState.shared.isIpad ? 8 : 0)
        .font(.caption2)
        .foregroundColor(eodColor)
        .frame(maxWidth: .infinity, alignment: AppState.shared.isIpad ? .leading : .center) /// This causes each day to be the same size
        .minimumScaleFactor(0.5)
        .lineLimit(1)
    }
            
}



#endif
