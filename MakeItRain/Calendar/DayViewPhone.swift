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
    
    @State private var showDailyActions = false
    @State private var showPhotosPicker = false
    @State private var showCamera = false
    
    @Binding var overviewDay: CBDay?
    
    
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
                    withAnimation {
                        calModel.hilightTrans = nil
                    }
                }
            } else {
                VStack(spacing: 5) {
                    dayNumber
                    dailyTransactionList
                    eodText
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation {
                        overviewDay = day
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
                        .fill(overviewDay == day ? Color(.tertiarySystemFill) : Color.clear)
                        .padding(.bottom, 2) /// This is here to offset the overlay divider line in `CalendarViewPhone` that separates the weeks.
                )
                .padding(.vertical, 2)
                .background(calModel.dragTarget == day ? .gray.opacity(0.5) : .clear)
                .dropDestination(for: CBTransaction.self) { droppedTrans, location in
                    let trans = droppedTrans.first
                    if let trans {
                        withAnimation {
                            let originalMonth = trans.dateComponents?.month!
                            let monthObj = calModel.months.filter { $0.num == originalMonth }.first
                            if let monthObj {
                                monthObj.days.forEach { $0.transactions.removeAll(where: { $0.id == trans.id }) }
                            }
                                                        
                            trans.log(field: .date, old: trans.date?.string(to: .monthDayShortYear), new: day.date?.string(to: .monthDayShortYear))
                            
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
                    if $0 {
                        withAnimation { calModel.dragTarget = day }
                    }
                }
                .confirmationDialog("\(day.weekday), the \((day.dateComponents?.day ?? 0).withOrdinal())", isPresented: $showDailyActions) {
                    Button {
                        transEditID = UUID().uuidString
                        selectedDay = day
                    } label: {
                        Label {
                            Text("New Transaction")
                        } icon: {
                            Image(systemName: "plus.square.fill")
                        }
                    }
                    
                    Button("New Transfer") {
                        selectedDay = day
                        showTransferSheet = true
                    }
                
                    Button {
                        let newID = UUID().uuidString
                        let trans = CBTransaction(uuid: newID)
                        trans.date = day.date!
                        calModel.pendingSmartTransaction = trans
                        calModel.pictureTransactionID = newID
                        showCamera = true
                    } label: {
                        Label {
                            Text("Capture Receipt")
                        } icon: {
                            Image(systemName: "camera.fill")
                        }
                    }
                    
                    Button {
                        let newID = UUID().uuidString
                        let trans = CBTransaction(uuid: newID)
                        trans.date = day.date!
                        calModel.pendingSmartTransaction = trans
                        calModel.pictureTransactionID = newID
                        showPhotosPicker = true
                    } label: {
                        Label {
                            Text("Select Receipt")
                        } icon: {
                            Image(systemName: "photo.badge.plus")
                        }
                    }                    
                                                            
                    Button {
                        if let transactionToPaste = calModel.getCopyOfTransaction() {
                            transactionToPaste.date = day.date!
                                                            
                            if !calModel.isUnifiedPayMethod {
                                transactionToPaste.payMethod = calModel.sPayMethod!
                            }
                            
                            day.upsert(transactionToPaste)
                            calModel.saveTransaction(id: transactionToPaste.id, day: day)
                        }
                    } label: {
                        Text("Paste")
                    }
                } message: {
                    Text("\(day.weekday), the \((day.dateComponents?.day ?? 0).withOrdinal())")
                }
                .photosPicker(isPresented: $showPhotosPicker, selection: $calModel.imageSelection, matching: .images, photoLibrary: .shared())
                #if os(iOS)
                .fullScreenCover(isPresented: $showCamera) {
                    AccessCameraView(selectedImage: $calModel.selectedImage)
                        .background(.black)
                }
                #endif
            }
        }
    }
    
   
        
    var dayNumber: some View {
        Text("\(day.dateComponents?.day ?? 0)")
            .frame(maxWidth: .infinity)
            .foregroundColor(.primary)
            .contentShape(Rectangle())
            //.padding(.bottom, 5)
//            .onTapGesture {
//                withAnimation {
//                    overviewDay = day
//                }
//                
//            }
            .if(isToday) {
                $0
                .bold()
                .background {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.fromName(appColorTheme))
                        .frame(maxWidth: .infinity)
                }
            }
    }
    
    var dailyTransactionList: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(filteredTrans) { trans in
                LineItemMiniView(transEditID: $transEditID, trans: trans, day: day, putBackToBottomPanelViewOnRotate: $putBackToBottomPanelViewOnRotate)
                    .padding(.vertical, 0)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
    }
    
    var transactionDotRow: some View {
        HStack(spacing: 1) {
            if filteredTrans.count == 0 {
                Circle()
                    .fill(.clear)
                    .frame(width: 6, height: 6)
                    .padding(.vertical, 3.5)
                
            } else if filteredTrans.count > 6 {
                Circle()
                    .fill(day.transactions[0].category?.color ?? .primary)
                    .frame(width: 6, height: 6)
                Circle()
                    .fill(day.transactions[1].category?.color ?? .primary)
                    .frame(width: 6, height: 6)
                
                Text("+\(filteredTrans.count - 2)")
                    .foregroundStyle(.primary)
                    .font(.caption2)
                
            } else {
                ForEach(filteredTrans) { trans in
                    Circle()
                        .fill(trans.category?.color ?? .primary)
                        .frame(width: 6, height: 6)
                        .padding(.vertical, 3.5)
                }
            }
        }
    }
    
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
