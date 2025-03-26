//
//  DayView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/18/24.
//

import SwiftUI

struct DayViewMac: View {
    @AppStorage("useWholeNumbers") var useWholeNumbers = false
    @AppStorage("threshold") var threshold = "500.0"
    @AppStorage("alignWeekdayNamesLeft") var alignWeekdayNamesLeft = true
    
    @Environment(CalendarModel.self) private var calModel
    
    @Environment(PayMethodModel.self) private var payModel
    @Environment(CategoryModel.self) private var catModel
    @Environment(KeywordModel.self) private var keyModel
    @Environment(EventModel.self) private var eventModel
    
    @State private var transEditID: String?
    @State private var editTrans: CBTransaction?
    
    @Binding var day: CBDay
    var cellHeight: CGFloat?
    //var searchText: String
    //var searchWhat: CalendarSearchWhat
//    var focusedField: FocusState<FocusedField?>.Binding
    @FocusState var focusedField: Int?

    @State private var showTransferSheet = false
    
    var eodColor: Color {
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
                
                .contextMenu {
                    VStack {
                        Button("New Transaction") {
                            transEditID = UUID().uuidString
                        }
                        
                        Button("New Transfer") {
                            showTransferSheet = true
                        }
                        
                        Button {
                            if let transactionToPaste = calModel.getCopyOfTransaction() {
                                transactionToPaste.date = day.date!
                                                                
                                if !calModel.isUnifiedPayMethod {
                                    transactionToPaste.payMethod = calModel.sPayMethod!
                                }
                                
                                day.upsert(transactionToPaste)
                                calModel.saveTransaction(id: transactionToPaste.id, day: day)
                            } else {
                                print("nothing to paste")
                            }
                        } label: {
                            Text("Paste")
                        }
                    }
                }
                                
                .onTapGesture(count: 2) {
                    transEditID = UUID().uuidString
                    //calModel.transEditID = 0
                }
                .onTapGesture {
                    /// Used for hilighting
                    calModel.hilightTrans = nil
                    focusedField = nil
                    print("OnTapGesture \(#file)")
                }
                                
                /// This `.popover(item: $transEditID) & .onChange(of: transEditID)` are used for adding new transactions. They also exists in ``LineItemViewMac``, which are used to edit existing transactions.
                .popover(item: $editTrans, content: { trans in
                    TransactionEditView(trans: trans, transEditID: $transEditID, day: day, isTemp: false)
                        .frame(minWidth: 320)
                })
                
                
                
                .onChange(of: transEditID, { oldValue, newValue in
                    print(".onChange(of: transEditID)")
                    /// When `newValue` is false, save to the server. We have to use this because `.popover(isPresented:)` has no onDismiss option.
                    if oldValue != nil && newValue == nil {
                        calModel.saveTransaction(id: oldValue!, day: day, eventModel: eventModel)
                        
                        /// Keep the model clean, and show alert for a photo that may be taking a long time to upload.
                        calModel.pictureTransactionID = nil
                    } else {
                        editTrans = calModel.getTransaction(by: transEditID!, from: .normalList)
                    }
                })

                
                
                
                
                
                                                
                /// This onChange is needed because you can close the popover without actually clicking the close button.
                /// `popover()` has no `onDismiss()` optiion, so I need somewhere to do cleanup.
                .onChange(of: transEditID, { oldValue, newValue in
                    if oldValue == nil && newValue != nil {
                        focusedField = nil
                    }
                    
                    if oldValue != nil && newValue == nil {
                        calModel.saveTransaction(id: oldValue!, day: day)
                    }
                })

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
                        
                        calModel.saveTransaction(id: trans.id)
                    }
                    
                    return true
                    
                } isTargeted: {
                    if $0 { withAnimation { calModel.dragTarget = day } }
                }
                
                .sheet(isPresented: $showTransferSheet) {
                    TransferSheet2(date: day.date!)
                    //TransferSheet(day: $day)
                    //TransferSheet(day: Binding(get: { }, set: { }))
                }
            }
        }
        .frame(height: cellHeight, alignment: .center)
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
        let creditEodView = CreditEodView.fromString(UserDefaults.standard.string(forKey: "creditEodView") ?? "")
        
        if calModel.sPayMethod?.accountType == .credit {
            
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
                    .filter { $0.accountType == .credit }
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



