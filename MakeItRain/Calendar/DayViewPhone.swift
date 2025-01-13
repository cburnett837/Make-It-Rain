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
    @AppStorage("viewMode") var viewMode = CalendarViewMode.scrollable
    @AppStorage("updatedByOtherUserDisplayMode") var updatedByOtherUserDisplayMode = UpdatedByOtherUserDisplayMode.full
    @AppStorage("useWholeNumbers") var useWholeNumbers = false
    @AppStorage("tightenUpEodTotals") var tightenUpEodTotals = true
    @AppStorage("threshold") var threshold = "500.0"
    @AppStorage("lineItemIndicator") var lineItemIndicator: LineItemIndicator = .emoji
    
    
    @AppStorage("phoneLineItemDisplayItem") var phoneLineItemDisplayItem: PhoneLineItemDisplayItem = .both
    
    
    //@Environment(RootViewModelPhone.self) var vm
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
    let outerGeo: GeometryProxy
    @Binding var overlayX: CGFloat?
    @Binding var overlayY: CGFloat?
    @Binding var putBackToBottomPanelViewOnRotate: Bool
    //var cellHeight: CGFloat?
    //var maxDayHeight: CGFloat = 20
    //@Binding var transEditID: Int?
    //@Binding var transPreviewID: Int?
    
    
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
                    if viewMode == .scrollable {
                        withAnimation {
                            overlayX = nil
                            overlayY = nil
                            calModel.transPreviewID = nil
                            calModel.hilightTrans = nil
                        }
                    }
                }
                //.padding(.horizontal, categoryIndicator == .background ? 1 : 0)
            } else {
                VStack(spacing: viewMode == .scrollable ? 5 : 0) {
                    dayNumber
                    
                    if viewMode == .scrollable {
                        dailyTransactionList
                    } else {
                        transactionDotRow
                    }
                    
                    eodText
                }
                //.padding(.horizontal, categoryIndicator == .background ? 1 : 0)
                .contentShape(Rectangle())
                .onTapGesture {
                    if viewMode == .scrollable {
                        withAnimation {
                            overviewDay = day
                        }
                    } else {
                        if viewMode == .bottomPanel {
                            selectedDay = day
                        } else {
                            withAnimation {
                                overlayX = nil
                                overlayY = nil
                                calModel.transPreviewID = nil
                                calModel.hilightTrans = nil
                            }
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
                        //.fill(selectedDay == day ? Color(.tertiarySystemFill) : Color.clear)
                    
                    /// The selectedDay is required because the list view of the calendar required a selected day to view the transaction list, and thus the `TransactionEditView` also requires it, but the selected day doesn't make sense in details view. So when in details view, only show the selected day view if it is the actual day. If in list view, show the selected day depending on what day was tapped.
                    
                        /// `BEGIN NOTE 1.1` Use this to  hilight the selected day in bottomPanel view, and the current day in details view.
//                        .fill((viewMode == .details ? selectedDay == day
//                               && day.dateComponents?.month == AppState.shared.todayMonth
//                               && day.dateComponents?.year == AppState.shared.todayYear
//                               && day.dateComponents?.day == AppState.shared.todayDay : selectedDay == day)
//                              ? Color(.tertiarySystemFill) : Color.clear)
                        /// `END NOTE 1.1`
                        /// `BEGIN NOTE 1.1` Use this to only hilight the selected day in bottomPanel view.
                        .fill((viewMode == .bottomPanel && selectedDay == day) ? Color(.tertiarySystemFill) : Color.clear)
                        .fill((viewMode == .scrollable && overviewDay == day) ? Color(.tertiarySystemFill) : Color.clear)
                        /// `END NOTE 1.1`
                    
                    
                        .padding(.bottom, 2) /// This is here to offset the overlay divider line in `CalendarViewPhone` that separates the weeks.
                
                )
                .padding(.vertical, 2)
                .background(calModel.dragTarget == day ? .gray.opacity(0.5) : .clear)
                //.onTapGesture { calModel.hilightTrans = nil }
                //.frame(height: maxEodSize)
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
                        
//                        Task {
//                            calModel.calculateTotalForMonth(month: calModel.sMonth)
//                            let _ = await calModel.submit(trans)
//                        }
                        calModel.saveTransaction(id: trans.id)
                    }
                    
                    return true
                    
                } isTargeted: { isTargeted in
                    if isTargeted {
                        withAnimation {
                            calModel.dragTarget = day
                        }
                    }
                }
//                .sheet(item: $overviewDay) { day in
//                    DayOverviewView(day: day, transEditID: $transEditID)
//                        .presentationDetents([.height(300), .medium, .large])
//                        .presentationBackgroundInteraction(.enabled(upThrough: .medium))
//                }
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
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(filteredTrans) { trans in
                    LineItemMiniView(transEditID: $transEditID, trans: trans, day: day, outerGeo: outerGeo, overlayX: $overlayX, overlayY: $overlayY, putBackToBottomPanelViewOnRotate: $putBackToBottomPanelViewOnRotate)
                        .padding(.vertical, 0)
                }
                if (viewMode == .scrollable) {
                    Spacer()
                }
            }
        }
        .if(viewMode == .scrollable) {
            $0.scrollDisabled(true)
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
        .if(viewMode == .bottomPanel) { $0.frame(maxHeight: .infinity, alignment: .center) }
        .frame(maxWidth: .infinity, alignment: .center) /// This causes each day to be the same size
        .minimumScaleFactor(0.5)
        .lineLimit(1)
    }
            
}


#endif
