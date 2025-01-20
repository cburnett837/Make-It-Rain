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
    @AppStorage("appColorTheme") var appColorTheme: String = Color.green.description
    @AppStorage("updatedByOtherUserDisplayMode") var updatedByOtherUserDisplayMode = UpdatedByOtherUserDisplayMode.full
    @AppStorage("useWholeNumbers") var useWholeNumbers = false
    @AppStorage("tightenUpEodTotals") var tightenUpEodTotals = true
    @AppStorage("threshold") var threshold = "500.0"
    @AppStorage("lineItemIndicator") var lineItemIndicator: LineItemIndicator = .emoji
    @AppStorage("phoneLineItemDisplayItem") var phoneLineItemDisplayItem: PhoneLineItemDisplayItem = .both
    @AppStorage("preferDarkMode") var preferDarkMode: Bool = true
    
    
    @Environment(CalendarModel.self) private var calModel
    @Environment(PayMethodModel.self) private var payModel
    @Environment(CategoryModel.self) private var catModel
    @Environment(KeywordModel.self) private var keyModel
    
    private var eodColor: Color {
        if day.eodTotal > Double(threshold) ?? 500 {
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
    @Binding var putBackToBottomPanelViewOnRotate: Bool
    @Binding var showPhotosPicker: Bool
    @Binding var showCamera: Bool
    @Binding var overviewDay: CBDay?
    @Binding var transHeight: CGFloat
    
    @State private var showDropActions = false
    @State private var showDailyActions = false
    
    
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
                        }
                    }
                }
                .onLongPressGesture(minimumDuration: 1) {
                    showDailyActions = true
                }
                .sensoryFeedback(.success, trigger: showDailyActions) { oldValue, newValue in
                    !oldValue && newValue
                }
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        /// Use this to only hilight the overview day.
                        .fill(overviewDay == day || calModel.dragTarget == day ? Color(.tertiarySystemFill) : Color.clear)
                        /// Offset the overlay divider line in `CalendarViewPhone` that separates the weeks.
                        .padding(.bottom, 2)
                )
                .padding(.vertical, 2)
                .dropDestination(for: CBTransaction.self) { droppedTrans, location in
                    let trans = droppedTrans.first
                    if let trans {
                        if trans.date == day.date {
                            calModel.dragTarget = nil
                            AppState.shared.showToast(header: "Operation Cancelled", title: "Can't copy or move to the original day", message: "Please try again", symbol: "hand.raised.fill", symbolColor: .orange)
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
                        selectedDay: $selectedDay,
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
                    
                    trans.log(field: .date, old: trans.date?.string(to: .monthDayShortYear), new: day.date?.string(to: .monthDayShortYear))
                    
                    trans.date = day.date!
                    calModel.sMonth.days.forEach { $0.transactions.removeAll(where: { $0.id == trans.id }) }
                                                    
                    day.transactions.append(trans)
                    calModel.dragTarget = nil
                    calModel.saveTransaction(id: trans.id)
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
                }
            }
        } label: {
            Text("Copy & Paste")
        }
    }
        
    var dayNumber: some View {
        Text("\(day.dateComponents?.day ?? 0)")
            .frame(maxWidth: .infinity)
            //.foregroundStyle(.primary)
            .contentShape(Rectangle())
            .if(isToday) {
                $0
                .bold()
                .background {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.fromName(appColorTheme).opacity(preferDarkMode ? 1 : 0.7))
                        .frame(maxWidth: .infinity)
                }
                .if(!preferDarkMode) {
                    $0.foregroundStyle(.white)
                }
            }
    }
    
    var dailyTransactionList: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(filteredTrans) { trans in
                LineItemMiniView(
                    transEditID: $transEditID,
                    trans: trans,
                    day: day,
                    putBackToBottomPanelViewOnRotate: $putBackToBottomPanelViewOnRotate,
                    transHeight: $transHeight
                )
                //.padding(.vertical, 0)
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
        .font(.caption2)
        .foregroundColor(eodColor)
        .frame(maxWidth: .infinity, alignment: .center) /// This causes each day to be the same size
        .minimumScaleFactor(0.5)
        .lineLimit(1)
    }
            
}


#endif
