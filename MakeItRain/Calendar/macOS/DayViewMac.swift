//
//  DayView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/18/24.
//

import SwiftUI

struct DayViewMac: View {
    @Local(\.useWholeNumbers) var useWholeNumbers
    @Local(\.threshold) var threshold
    @Local(\.alignWeekdayNamesLeft) var alignWeekdayNamesLeft
    
    @Environment(CalendarModel.self) private var calModel
    
    @Environment(PayMethodModel.self) private var payModel
    @Environment(CategoryModel.self) private var catModel
    @Environment(KeywordModel.self) private var keyModel
    @Environment(EventModel.self) private var eventModel
    
    //@State private var transEditID: String?
    @Binding var transEditID: String?
    @Binding var editTrans: CBTransaction?
    @Binding var selectedDay: CBDay?
    ///@State private var editTrans: CBTransaction?
    
    
    @State private var localEditTrans: CBTransaction?
    
    @Binding var day: CBDay
    var cellHeight: CGFloat?
    //var searchText: String
    //var searchWhat: CalendarSearchWhat
//    var focusedField: FocusState<FocusedField?>.Binding
    @FocusState var focusedField: Int?

    @State private var showTransferSheet = false
    
    var eodColor: Color {
        if day.eodTotal > threshold {
            return .gray
        } else if day.eodTotal < 0 {
            return .red
        } else {
            return .orange
        }
    }
    
    private var isToday: Bool {
        AppState.shared.todayDay == (day.dateComponents?.day ?? 0)
        && AppState.shared.todayMonth == calModel.sMonth.actualNum
        && AppState.shared.todayYear == calModel.sMonth.year
    }
    
    var filteredTrans: [CBTransaction] {
        calModel.filteredTrans(day: day)
    }
    
    var body: some View {
        Group {
            if day.date == nil {
                Text("")
            } else {
                VStack(spacing: 0) {
                    HStack {
                        if !alignWeekdayNamesLeft {
                            Spacer()
                        }
                        if isToday {
                            todayNumber
                        } else {
                            notTodayNumber
                        }
                        if alignWeekdayNamesLeft {
                            Spacer()
                        }
                    }
                    
                    ScrollView(showsIndicators: true) {
                        VStack(spacing: 0) {
                            ForEach(filteredTrans) { trans in
                                LineItemView(trans: trans, day: day, focusedField: _focusedField)
                            }
                        }
                    }
                                                        
                    //Spacer()
                    HStack {
                        Spacer()
                        //eodView(eodAmount: day.eodTotal)                                                                        
                                                
                        Text(day.eodTotal.currencyWithDecimals(useWholeNumbers ? 0 : 2))
                            .font(.title3)
                            .foregroundColor(eodColor)
                            .padding(.trailing, 2)
                            .help(createEodHelpDescription())
                            //.questionCursor()
                    }
                }
                .contentShape(Rectangle())
                .background(calModel.dragTarget == day ? .gray.opacity(0.5) : .clear)
                .contextMenu { contextMenu }
                                
                .onTapGesture(count: 2) {
                    selectedDay = day
                    transEditID = UUID().uuidString
                    //calModel.transEditID = 0
                }
                .onTapGesture {
                    /// Used for hilighting
                    //calModel.hilightTrans = nil
                    focusedField = nil
                    print("OnTapGesture \(#file)")
                }
                                
                /// This `.popover(item: $transEditID) & .onChange(of: transEditID)` are used for adding new transactions. They also exists in ``LineItemViewMac``, which are used to edit existing transactions.
                .popover(item: $localEditTrans) { trans in
                    TransactionEditView(trans: trans, transEditID: $transEditID, day: day, isTemp: false)
                        .frame(minWidth: 320)
                }
//                .transactionEditSheetAndLogic(
//                    calModel: calModel,
//                    transEditID: $transEditID,
//                    editTrans: $editTrans,
//                    selectedDay: .constant(nil),
//                    findTransactionWhere: .normalList
//                )
                
                /// When the edit trans is set, set a local copy to trigger the popover.
                /// Have to use the "global & local" idea otherwise a popover for every day will try and open when you create a new transactions.
                .onChange(of: editTrans) {
                    if $1 != nil && selectedDay?.date == day.date {
                        localEditTrans = $1
                    }
                }
                
                /// When the popover closes, clear the global variables, which will trigger the saving and cleanup of the trans.
                .onChange(of: localEditTrans) {
                    if $1 == nil {
                        editTrans = nil
                        transEditID = nil
                    }
                }
                
                
                
                
//                .onChange(of: transEditID) { oldValue, newValue in
//                    print(".onChange(of: transEditID)")
//                    /// When `newValue` is false, save to the server. We have to use this because `.popover(isPresented:)` has no onDismiss option.
//                    if oldValue != nil && newValue == nil {
////                        calModel.saveTransaction(id: oldValue!, day: day, eventModel: eventModel)
////                        
////                        /// Keep the model clean, and show alert for a photo that may be taking a long time to upload.
////                        calModel.pictureTransactionID = nil
//                    } else {
//                        editTrans = calModel.getTransaction(by: transEditID!, from: .normalList)
//                    }
//                }
//                           
//                /// This onChange is needed because you can close the popover without actually clicking the close button.
//                /// `popover()` has no `onDismiss()` optiion, so I need somewhere to do cleanup.
//                .onChange(of: editTrans) { oldValue, newValue in
//                    print(".onChange(of: editTrans)")
//                    if oldValue == nil && newValue != nil {
//                        focusedField = nil
//                    }
//                    
//                    if oldValue != nil && newValue == nil {
//                        let id = oldValue!.id
//                        calModel.saveTransaction(id: id, day: day)
////                        calModel.pictureTransactionID = nil
//                        FileModel.shared.fileParent = nil
//                    }
//                }

                .dropDestination(for: CBTransaction.self) { droppedTrans, location in
                    let trans = droppedTrans.first
                    if let trans {
                        
                        if trans.date == day.date {
                            calModel.dragTarget = nil
                            AppState.shared.showToast(title: "Operation Cancelled", subtitle: "Can't copy or move to the original day", body: "Please try again", symbol: "hand.raised.fill", symbolColor: .orange)
                            return true
                        }
                        
                        withAnimation {
                            let originalMonth = trans.dateComponents?.month!
                            let monthObj = calModel.months.filter { $0.num == originalMonth }.first
                            if let monthObj {
                                monthObj.days.forEach { $0.transactions.removeAll(where: { $0.id == trans.id }) }
                            }
                        
                            trans.log(field: .date, old: trans.date?.string(to: .monthDayShortYear), new: day.date?.string(to: .monthDayShortYear), groupID: UUID().uuidString)
                            
                            trans.date = day.date!
                            calModel.sMonth.days.forEach { $0.transactions.removeAll(where: { $0.id == trans.id }) }
                            
                            let combinedTrans = day.transactions + droppedTrans
                            day.transactions = Array(combinedTrans.uniqued())
                            
                            calModel.dragTarget = nil
                        }
                        
                        Task {
                            await calModel.saveTransaction(id: trans.id)
                        }
                    }
                    
                    return true
                    
                } isTargeted: {
                    if $0 { withAnimation { calModel.dragTarget = day } }
                }
                
                .sheet(isPresented: $showTransferSheet) {
                    TransferSheet(defaultDate: day.date!)
                        #if os(iOS)
                        .presentationSizing(.page)
                        #else
                        .frame(minWidth: 500, minHeight: 700)
                        .presentationSizing(.fitted)
                        #endif
                    //TransferSheet(defaultDate: $day)
                    //TransferSheet(defaultDate: Binding(get: { }, set: { }))
                }
            }
        }
        .frame(height: cellHeight, alignment: .center)
    }
    
    var contextMenu: some View {
        VStack {
            Button("New Transaction") {
                transEditID = UUID().uuidString
                selectedDay = day
            }
            
            Button("New Transfer / Payment") {
                showTransferSheet = true
            }
            
            Button {
                if let transactionToPaste = calModel.getCopyOfTransaction() {
                    transactionToPaste.date = day.date!
                                                    
                    if !calModel.isUnifiedPayMethod {
                        transactionToPaste.payMethod = calModel.sPayMethod!
                    }
                    
                    day.upsert(transactionToPaste)
                    Task {
                        await calModel.saveTransaction(id: transactionToPaste.id/*, day: day*/)
                    }
                    
                } else {
                    print("nothing to paste")
                }
            } label: {
                Text("Paste")
            }
        }
    }
    
    
    var todayNumber: some View {
        Text("\(day.dateComponents?.day ?? 0)")
            .bold()
            .font(.title2)
            //.foregroundColor(Color(.darkGray))
            .padding(.bottom, 6)
            .padding(.top, 8)
            .padding(6)
            .background(Circle().fill(Color(.green)))
            .padding(.horizontal, 8)
            .padding(.bottom, 0)
            .padding(.top, -4)
    }
    
    var notTodayNumber: some View {
        Text("\(day.dateComponents?.day ?? 0)")
            .font(.title2)
            //.foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.bottom, 10)
            .padding(.top, 10)
    }
    
    
    func createEodHelpDescription() -> String {
        //let creditEodView = CreditEodView.fromString(UserDefaults.standard.string(forKey: "creditEodView") ?? "")
        let creditEodView = LocalStorage.shared.creditEodView
        
        if calModel.sPayMethod?.accountType == .credit || calModel.sPayMethod?.accountType == .loan {
            switch creditEodView {
            case .availableCredit:
                return "Credit available out of limit of \(calModel.sPayMethod?.limit?.currencyWithDecimals(useWholeNumbers ? 0 : 2) ?? "-")"
            case .remainingBalance:
                return "Remaining balance before hitting $0.00"
            }
            
        } else if calModel.sPayMethod?.accountType == .unifiedCredit {
            switch creditEodView {
            case .availableCredit:
                
                let cumulativeLimits = PayMethodModel.shared
                    .paymentMethods
                    .filter { $0.accountType == .credit  || $0.accountType == .loan }
                    .map { $0.limit ?? 0.0 }
                    .reduce(0.0, +)
                
                
                return "Credit available out of limit of \(cumulativeLimits.currencyWithDecimals(useWholeNumbers ? 0 : 2))"
            case .remainingBalance:
                return "Remaining balance before hitting $0.00"
            }
            
        } else {
            return "Remaining balance before hitting $0.00"
        }
    }
}



