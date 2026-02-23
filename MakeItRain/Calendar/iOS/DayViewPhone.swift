//
//  DayViewPhone.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/16/24.
//

import SwiftUI

#if os(iOS)
struct DayViewPhone: View {
    @Local(\.updatedByOtherUserDisplayMode) var updatedByOtherUserDisplayMode
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(CalendarProps.self) private var calProps
    @Environment(CalendarModel.self) private var calModel
    @Environment(PayMethodModel.self) private var payModel
    @Environment(CategoryModel.self) private var catModel
    @Environment(KeywordModel.self) private var keyModel
    
    private var eodColor: Color {
        if let meth = calModel.sPayMethod {
            if meth.isCreditOrLoan {
                let limit = meth.limit ?? 0
                let thresh = limit - AppSettings.shared.lowBalanceThreshold
                
                if day.eodTotal < thresh {
                    return .gray
                } else if day.eodTotal > limit {
                    return .red
                } else {
                    return .orange
                }
                
            } else {
                if day.eodTotal > AppSettings.shared.lowBalanceThreshold {
                    return .gray
                } else if day.eodTotal < 0 {
                    return .red
                } else {
                    return .orange
                }
            }
        } else {
            if day.eodTotal > 0 {
                return AppSettings.shared.incomeColor
            } else {
                return .gray
            }
        }
    }
    
    private var isToday: Bool {
        AppState.shared.todayDay == (day.dateComponents?.day ?? 0) && AppState.shared.todayMonth == calModel.sMonth.actualNum && AppState.shared.todayYear == calModel.sMonth.year
    }
    
    //@Binding var transEditID: String?
    @Bindable var day: CBDay
    //@Binding var selectedDay: CBDay?
    //@Binding var showTransferSheet: Bool
    ////@Binding var putBackToBottomPanelViewOnRotate: Bool
    //@Binding var showPhotosPicker: Bool
    //@Binding var showCamera: Bool
    //@Binding var overviewDay: CBDay?
    //@Binding var bottomPanelContent: BottomPanelContent?
    
    var lineItemIndicator: LineItemIndicator
    var phoneLineItemDisplayItem: PhoneLineItemDisplayItem
    
    @State private var showDropActions = false
    @State private var showDailyActions = false
    @State private var showMoreTrans = false
    
    
    var filteredTrans: [CBTransaction] {
        calModel.filteredTrans(day: day)
    }
    
    let columnGrid = Array(repeating: GridItem(.flexible(), spacing: 3), count: 2)
        
    var droppedTitle: String {
        "\(day.weekday), the \((day.dateComponents?.day ?? 0).withOrdinal())\n\(calModel.transactionToCopy?.title ?? "N/A")"
    }
    
    var droppedMessage: String {
        "\(calModel.transactionToCopy?.title ?? "N/A")\nDropped on \(day.weekday), the \((day.dateComponents?.day ?? 0).withOrdinal())"
    }
    
    var dateText: String {
        "\(day.weekday), the \((day.dateComponents?.day ?? 0).withOrdinal())"
    }
    
    var shouldLimitTo5: Bool {
        let transCountForCurrentPayMethod = calModel.sMonth.justTransactions.filter({ $0.payMethod?.id == calModel.sPayMethod?.id }).count
        //if calModel.sMonth.transactionCount > (calModel.sMonth.dayCount * 5)
        return transCountForCurrentPayMethod > (calModel.sMonth.dayCount * 5) && filteredTrans.count > 5 && phoneLineItemDisplayItem == .both
    }
    
   
    var body: some View {
        //let _ = Self._printChanges()
        if day.date == nil {
            placeholderDayView
        } else {
            realDayView
        }
    }
    
    var placeholderDayView: some View {
        VStack {
            Text("")
            Spacer()
                .frame(maxWidth: .infinity)
        }
        .contentShape(Rectangle())
//        .onTapGesture {
//            withAnimation { calModel.hilightTrans = nil }
//        }
        .dropDestination(for: CBTransaction.self) { droppedTrans, location in
            calModel.dragTarget = nil
            return true
        }
    }
    
    
    @ViewBuilder
    var realDayView: some View {
        @Bindable var calProps = calProps
        VStack(spacing: 5) {
            dayNumber
            dailyTransactionList
            eodText
        }
        .frame(maxWidth: .infinity, alignment: .center) /// This causes each day to be the same width.
        .contentShape(Rectangle())
        .onTapGesture { handleDayWasTapped() }
        .onLongPressGesture(minimumDuration: 1) { showDailyActions = true }
        .sensoryFeedback(.warning, trigger: showDailyActions) { !$0 && $1 }
        .sensoryFeedback(.selection, trigger: calModel.dragTarget) { $1 == day }
        .padding(.vertical, 2)
        .background(dayBackground)
        .padding(.vertical, 2)
        .dropDestination(for: CBTransaction.self) { droppedTrans, location in
            handleTransactionDrop(droppedTrans)
        } isTargeted: {
            handleDayIsDragTargeted($0)
        }
        
        .confirmationDialog(droppedTitle, isPresented: $showDropActions) {
            moveButton
            copyAndPasteButton
            Button("Cancel", role: .close) {
                calModel.dragTarget = nil
                calModel.transactionIdToCopy = nil
                calModel.transactionToCopy = nil
            }
        } message: {
            Text(droppedMessage)
        }
        
        .confirmationDialog(dateText, isPresented: $showDailyActions) {
            DayContextMenu(day: day, selectedDay: $calProps.selectedDay)
        } message: {
            Text(dateText)
        }
    }
    
    
    var moveButton: some View {
        Button("Move") {
//            withAnimation {
//                if let trans = calModel.transactionToCopy {
//                    let originalMonth = trans.dateComponents?.month!
//                    let monthObj = calModel.months.filter { $0.num == originalMonth }.first
//                    if let monthObj {
//                        monthObj.days.forEach { $0.transactions.removeAll(where: { $0.id == trans.id }) }
//                    }
//                    
//                    trans.log(field: .date, old: trans.date?.string(to: .monthDayShortYear), new: day.date?.string(to: .monthDayShortYear), groupID: UUID().uuidString)
//                    
//                    trans.date = day.date!
//                    calModel.sMonth.days.forEach { $0.transactions.removeAll(where: { $0.id == trans.id }) }
//                                                    
//                    day.transactions.append(trans)
//                    calModel.dragTarget = nil
//                    calModel.saveTransaction(id: trans.id)
//                    
//                    calModel.transactionToCopy = nil
//                }
//            }
            
            /// New logic to attempt to handle the "$0" issue. 10-16-25.
            withAnimation {
                if let transId = calModel.transactionIdToCopy {
                    #warning("serverID Change")
                    if let trans = calModel.justTransactions.filter({ $0.id == transId }).first {
                        let oMonth = trans.dateComponents?.month!
                        let oDay = trans.dateComponents?.day!
                        let oYear = trans.dateComponents?.year!
                        
                        if let monthObj = calModel.months.filter({ $0.actualNum == oMonth && $0.year == oYear }).first {
                            if let dayObject = monthObj.days.filter({ $0.date?.day == oDay }).first {
                                dayObject.transactions.removeAll(where: { $0.id == trans.id })
                            }
                        }
                        
                        trans.log(
                            field: .date,
                            old: trans.date?.string(to: .monthDayShortYear),
                            new: day.date?.string(to: .monthDayShortYear),
                            groupID: UUID().uuidString
                        )
                        
                        trans.date = day.date!
                                                        
                        day.upsert(trans)
                        calModel.dragTarget = nil
                        calModel.transactionIdToCopy = nil
                        
                        //DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            trans.status = .editing
                        //}
                        
                        Task {
                            await calModel.saveTransaction(id: transId)
                        }
                    } else {
                        print("Could not find the transaction ID \(transId)")
                    }
                }
            }
        }
    }
    
    
    var copyAndPasteButton: some View {
        Button {
            calModel.pasteTransaction(to: day)
        } label: {
            Text("Copy & Paste")
        }
    }
        
    
    var dayBackground: some View {
        RoundedRectangle(cornerRadius: 6)
            /// Use this to only hilight the overview day.
            .fill(
                (calProps.overviewDay == day && calProps.bottomPanelContent == .overviewDay)
                || (calProps.overviewDay == day && calProps.inspectorContent == .overviewDay)
                || calModel.dragTarget == day ? Color(.tertiarySystemFill) : Color.clear)
            /// Offset the overlay divider line in `CalendarViewPhone` that separates the weeks.
            .padding(.bottom, 2)
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
                        .fill(Color.theme)
                        //.frame(maxWidth: .infinity)
                }
                .foregroundStyle(.white)
                .padding(-4)
            }
            .padding(.leading, AppState.shared.isIpad ? 6 : 0)
            .frame(maxWidth: .infinity, alignment: AppState.shared.isIpad ? .leading : .center)
    }
    
    
#warning("REGARDING HITCH: All I did here was pull the appstorage properties from the line item to this view, and reworked the shouldLimitTo5")
    @ViewBuilder
    var dailyTransactionList: some View {
        @Bindable var calProps = calProps
        VStack(alignment: .leading, spacing: 2) {
            #warning("shouldLimitTo5 causes hitches with sheets")
            if shouldLimitTo5 {
                ForEach(filteredTrans.prefix(5)) { trans in
                    lineItem(trans)
                }
                
                showMoreTransButton
                                
                if showMoreTrans {
                    ForEach(filteredTrans.suffix(filteredTrans.count - 5)) { trans in
                        lineItem(trans)
                    }
                }
            } else {
                ForEach(filteredTrans) { trans in
                    lineItem(trans)
                    
                }
            }
  
//            ForEach(filteredTrans) { trans in
//                LineItemMiniView(
//                    trans: trans,
//                    day: day,
//                    lineItemIndicator: lineItemIndicator,
//                    phoneLineItemDisplayItem: phoneLineItemDisplayItem
//                )
//                //LineItemMiniViewTest()
//            }
            
            Spacer()
        }
    }
    
    
    @ViewBuilder
    func lineItem(_ trans: CBTransaction) -> some View {
        LineItemMiniView(
            trans: trans,
            day: day,
            lineItemIndicator: lineItemIndicator,
            phoneLineItemDisplayItem: phoneLineItemDisplayItem,
        )
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
    
    
    var showMoreTransButton: some View {
        HStack(spacing: 2) {
            moreButtonGrayCapsule
            moreButtonButton
        }
        .padding(.horizontal, 2)
        .fixedSize(horizontal: false, vertical: true)
    }
    
    
    var moreButtonGrayCapsule: some View {
        Canvas { context, size in
            let capsuleRect = CGRect(origin: .zero, size: size)
            let capsulePath = Path(roundedRect: capsuleRect, cornerRadius: size.height / 2) // Full capsule effect
            context.fill(capsulePath, with: .color(.gray))
        }
        .frame(width: 3)
        .padding(.vertical, 2)
    }
    
    
    var moreButtonButton: some View {
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
    
    
    var eodText: some View {
        Group {
            if AppSettings.shared.useWholeNumbers && AppSettings.shared.tightenUpEodTotals {
                Text("\(String(format: "%.00f", day.eodTotal).replacing("$", with: "").replacing(",", with: ""))")
                
            } else if AppSettings.shared.useWholeNumbers {
                Text(day.eodTotal.currencyWithDecimals(0))
                
            } else if !AppSettings.shared.useWholeNumbers && AppSettings.shared.tightenUpEodTotals {
                Text(day.eodTotal.currencyWithDecimals(2).replacing("$", with: "").replacing(",", with: ""))
                
            } else {
                Text(day.eodTotal.currencyWithDecimals(2))
            }
        }
        .contentTransition(.numericText())
        .padding(.leading, AppState.shared.isIpad ? 8 : 0)
        .font(.caption2)
        .foregroundColor(eodColor)
        .frame(maxWidth: .infinity, alignment: AppState.shared.isIpad ? .leading : .center) /// This causes each day to be the same size
        .minimumScaleFactor(0.5)
        .lineLimit(1)
    }
            
    
    
    // MARK: - Functions
    func handleTransactionDrop(_ droppedTrans: Array<CBTransaction>) -> Bool {
        let trans = droppedTrans.first
        if let trans {
            if trans.date == day.date {
                calModel.dragTarget = nil
                AppState.shared.showToast(
                    title: "Operation Cancelled",
                    subtitle: "Can't copy or move to the original day",
                    body: "Please try again",
                    symbol: "hand.raised.fill",
                    symbolColor: .orange
                )
                calModel.transactionToCopy = nil
                calModel.transactionIdToCopy = nil
                return true
            }
                                    
            
            print("Transaction id to copy: \(trans.id) - \(String(describing: trans.uuid)) - \(trans.serverID)")
            
            calModel.transactionToCopy = trans
            calModel.transactionIdToCopy = trans.id
            showDropActions = true
        }
        
        return true
    }
    
    
    func handleDayIsDragTargeted(_ isTargeted: Bool) {
        if isTargeted {
            withAnimation { calModel.dragTarget = day }
        } else {
            withAnimation { calModel.dragTarget = nil }
        }
    }
    
    
    func handleDayWasTapped() {
        if phoneLineItemDisplayItem != .both {
            withAnimation {
                
                if AppState.shared.isIphone {
                    calProps.overviewDay = day
                    /// Set `selectedDay` to the same day as the overview day that way any transactions or transfers initiated via the bottom panel will have the date of the bottom panel.
                    /// (Since `TransactionEditView` and `TransferSheet` use `selectedDate` as their default date.)
                    calProps.selectedDay = day
                    calProps.bottomPanelContent = .overviewDay
                } else {
                    calProps.overviewDay = day
                    calProps.selectedDay = day
                    /// Inspector is in ``RootViewPad``.
                    calProps.inspectorContent = .overviewDay
                    calProps.showInspector = true
                }
                
                
                
            }
        }
    }
}



#endif
