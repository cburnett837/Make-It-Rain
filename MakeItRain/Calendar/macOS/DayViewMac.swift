//
//  DayView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/18/24.
//

import SwiftUI
#if os(macOS)
struct DayViewMac: View {
    @Local(\.alignWeekdayNamesLeft) var alignWeekdayNamesLeft
    
    @Environment(CalendarModel.self) private var calModel
    @Environment(CalendarProps.self) private var calProps
    @Environment(PayMethodModel.self) private var payModel
    @Environment(CategoryModel.self) private var catModel
    @Environment(KeywordModel.self) private var keyModel
    
    var day: CBDay
    var cellHeight: CGFloat?
    @FocusState var focusedField: Int?

    @State private var showTransferSheet = false
    
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
        AppState.shared.todayDay == (day.dateComponents?.day ?? 0)
        && AppState.shared.todayMonth == calModel.sMonth.actualNum
        && AppState.shared.todayYear == calModel.sMonth.year
    }
    
    var filteredTrans: [CBTransaction] {
        calModel.filteredTrans(day: day)
    }
    
    var body: some View {
        //let _ = Self._printChanges()
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
                                LineItemView(trans: trans, day: day)
                            }
                        }
                    }
                                                        
                    //Spacer()
                    HStack {
                        Spacer()
                        //eodView(eodAmount: day.eodTotal)                                                                        
                                                
                        Text(day.eodTotal.currencyWithDecimals())
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
                    calProps.selectedDay = day
                    calProps.transEditID = UUID().uuidString
                    //calModel.transEditID = 0
                }
                .onTapGesture {
                    /// Used for hilighting
                    //calModel.hilightTrans = nil
                    focusedField = nil
                    print("OnTapGesture \(#file)")
                }
                                                
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
                calProps.selectedDay = day
                calProps.transEditID = UUID().uuidString
            }
            
            Button("New Transfer / Payment") {
                calProps.selectedDay = day
                calProps.showTransferSheet = true
            }
            
            Button {
                if let transactionToPaste = calModel.getCopyOfTransaction() {
                    transactionToPaste.date = day.date!
                                                    
//                    if !calModel.isUnifiedPayMethod {
//                        transactionToPaste.payMethod = calModel.sPayMethod!
//                    }
                    
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
                return "Credit available out of limit of \(calModel.sPayMethod?.limit?.currencyWithDecimals() ?? "-")"
            case .remainingBalance:
                return "Remaining balance before hitting $0.00"
            }
            
        } else if calModel.sPayMethod?.accountType == .unifiedCredit {
            switch creditEodView {
            case .availableCredit:
                
                let cumulativeLimits = payModel
                    .paymentMethods
                    .filter { $0.accountType == .credit  || $0.accountType == .loan }
                    .map { $0.limit ?? 0.0 }
                    .reduce(0.0, +)
                
                
                return "Credit available out of limit of \(cumulativeLimits.currencyWithDecimals())"
            case .remainingBalance:
                return "Remaining balance before hitting $0.00"
            }
            
        } else {
            return "Remaining balance before hitting $0.00"
        }
    }
}



#endif
