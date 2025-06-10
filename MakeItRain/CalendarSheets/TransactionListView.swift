//
//  TransactionListView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 6/2/25.
//

import SwiftUI

struct TransactionListView: View {
    #if os(macOS)
    @Environment(\.dismiss) var dismiss
    #endif
    @AppStorage("transactionSortMode") var transactionSortMode: TransactionSortMode = .title
    @AppStorage("categorySortMode") var categorySortMode: CategorySortMode = .title
    @Local(\.useWholeNumbers) var useWholeNumbers
    
    @Environment(CalendarModel.self) private var calModel
    @Environment(PayMethodModel.self) private var payModel

    @Environment(EventModel.self) private var eventModel

    @State private var transactions: [CBTransaction] = []
    @State private var totalSpent: Double = 0.0

    @State private var transEditID: String?
    @State private var editTrans: CBTransaction?
    @State private var transDay: CBDay?
    
    @State private var cumTotals: [CumTotal] = []
    
    @Binding var showTransactionListSheet: Bool
    
    
    
    @State private var showTransferSheet = false
    @State private var showPhotosPicker = false
    @State private var showCamera = false
    

    struct CumTotal {
        var day: Int
        var total: Double
    }
    
    var sheetTitle: String {
        "\(calModel.sPayMethod?.title ?? "N/A") \(calModel.sMonth.name) \(String(calModel.sYear))"
    }
    
    var body: some View {
        @Bindable var calModel = calModel
        @Bindable var photoModel = PhotoModel.shared
        
        StandardContainer(AppState.shared.isIpad ? .sidebarList : .list) {
            transactionList
        } header: {
            if AppState.shared.isIpad {
                SidebarHeader(
                    title: sheetTitle,
                    close: {
                        #if os(iOS)
                        withAnimation { showTransactionListSheet = false }
                        #else
                        dismiss()
                        #endif
                    }, view1: {
                        NewTransactionMenuButton(transEditID: $transEditID, showTransferSheet: $showTransferSheet, showPhotosPicker: $showPhotosPicker, showCamera: $showCamera)
                    }
                )
            } else {
                SheetHeader(
                    title: sheetTitle,
                    close: {
                        #if os(iOS)
                        withAnimation { showTransactionListSheet = false }
                        #else
                        dismiss()
                        #endif
                    }, view1: {
                        NewTransactionMenuButton(transEditID: $transEditID, showTransferSheet: $showTransferSheet, showPhotosPicker: $showPhotosPicker, showCamera: $showCamera)
                    }
                )
            }
        }
        .task {
            setSelectedDay()
            prepareData()
        }
        .sheet(isPresented: $showTransferSheet) {
            TransferSheet(date: transDay?.date ?? Date())
        }
        .photosPicker(isPresented: $showPhotosPicker, selection: $photoModel.imagesFromLibrary, maxSelectionCount: 1, matching: .images, photoLibrary: .shared())
        .onChange(of: showPhotosPicker) { oldValue, newValue in
            if !newValue {
                if PhotoModel.shared.imagesFromLibrary.isEmpty {
                    calModel.cleanUpPhotoVariables()
                } else {
                    PhotoModel.shared.uploadPicturesFromLibrary(delegate: calModel, photoType: XrefModel.getItem(from: .photoTypes, byEnumID: .transaction))
                }
            }
        }
        #if os(iOS)
        .fullScreenCover(isPresented: $showCamera) {
            AccessCameraView(selectedImage: $photoModel.imageFromCamera)
                .background(.black)
        }
        .onChange(of: showCamera) { oldValue, newValue in
            if !newValue {
                PhotoModel.shared.uploadPictureFromCamera(delegate: calModel, photoType: XrefModel.getItem(from: .photoTypes, byEnumID: .transaction))
            }
        }
        #endif
//        .sheet(item: $editTrans) { trans in
//            TransactionEditView(trans: trans, transEditID: $transEditID, day: transDay!, isTemp: false)
//                /// This is needed for the drag to dismiss.
//                .onDisappear { transEditID = nil }
//            #warning("produces a race condition when swiping to close and opening another trans too quickly. Causes transDays to be nil and crashes the app.")
//        }
//        .onChange(of: transEditID) { transEditIdChanged(oldValue: $0, newValue: $1) }
//        .sensoryFeedback(.selection, trigger: transEditID) { $1 != nil }
        
        .transactionEditSheetAndLogic(
            calModel: calModel,
            transEditID: $transEditID,
            editTrans: $editTrans,
            selectedDay: $transDay
        )

    }
    
    
    var transactionList: some View {
        ForEach(calModel.sMonth.days) { day in
            let doesHaveTransactions = transactions
                .filter { $0.dateComponents?.day == day.date?.day }
                .count > 0
            
            let dailyTotal = transactions
                .filter { $0.dateComponents?.day == day.date?.day }
                .map { $0.payMethod?.accountType == .credit ? $0.amount * -1 : $0.amount }
                .reduce(0.0, +)
            
            let dailyCount = transactions
                .filter { $0.dateComponents?.day == day.date?.day }
                .count
                                                
            Section {
                if doesHaveTransactions {
                    ForEach(getTransactions(for: day)) { trans in
                        TransactionListLine(trans: trans)
                            .onTapGesture {
                                self.transDay = day
                                self.transEditID = trans.id
                            }
                    }
                } else {
                    Text("No Transactions")
                        .foregroundStyle(.gray)
                }
            } header: {
                if day.date?.day == AppState.shared.todayDay && day.date?.month == AppState.shared.todayMonth && day.date?.year == AppState.shared.todayYear {
                    HStack {
                        Text("TODAY")
                            .foregroundStyle(.green)
                        VStack {
                            Divider()
                                .overlay(.green)
                        }
                    }
                } else {
                    Text(day.date?.string(to: .monthDayShortYear) ?? "")
                }
                
            } footer: {
                if doesHaveTransactions {
                    SectionFooter(day: day, dailyCount: dailyCount, dailyTotal: dailyTotal, cumTotals: cumTotals)
                }
            }
        }
    }
    
    
    struct SectionFooter: View {
        @Local(\.useWholeNumbers) var useWholeNumbers
        @Local(\.threshold) var threshold

        var day: CBDay
        var dailyCount: Int
        var dailyTotal: Double
        var cumTotals: [CumTotal]
        
        private var eodColor: Color {
            if day.eodTotal > threshold {
                return .gray
            } else if day.eodTotal < 0 {
                return .red
            } else {
                return .orange
            }
        }
                
        var body: some View {
            HStack {
                Text("EOD: \(day.eodTotal.currencyWithDecimals(useWholeNumbers ? 0 : 2))")
                    .foregroundStyle(eodColor)
                
                Spacer()
                if dailyCount > 1 {
                    Text(dailyTotal.currencyWithDecimals(useWholeNumbers ? 0 : 2))
                }
            }
        }
    }
    
    
    func getTransactions(for day: CBDay) -> Array<CBTransaction> {
        transactions
            .filter { $0.dateComponents?.day == day.date?.day }
            .sorted {
                if transactionSortMode == .title {
                    return $0.title < $1.title
                    
                } else if transactionSortMode == .enteredDate {
                    return $0.enteredDate < $1.enteredDate
                    
                } else {
                    if categorySortMode == .title {
                        return ($0.category?.title ?? "").lowercased() < ($1.category?.title ?? "").lowercased()
                    } else {
                        return $0.category?.listOrder ?? 10000000000 < $1.category?.listOrder ?? 10000000000
                    }
                }
            }
    }
    
    
    func setSelectedDay() {
        transDay = calModel.sMonth.days.filter { $0.dateComponents?.day == (calModel.sMonth.actualNum == AppState.shared.todayMonth ? AppState.shared.todayDay : 1) }.first
    }
    
//    func transEditIdChanged(oldValue: String?, newValue: String?) {
//        /// When `newValue` is false, save to the server. We have to use this because `.popover(isPresented:)` has no onDismiss option.
//        if oldValue != nil && newValue == nil {
////            let theDay = transDay
////            transDay = nil
//            calModel.saveTransaction(id: oldValue!, day: transDay!, eventModel: eventModel)
//            //calModel.pictureTransactionID = nil
//            PhotoModel.shared.pictureParent = nil
//            
//            calModel.editLock = false
//            
//        } else if newValue != nil {
//            if !calModel.editLock {
//                /// Prevent a transaction from being opened while another one is trying to save.
//                calModel.editLock = true
//                editTrans = calModel.getTransaction(by: newValue!, from: .normalList)
//            }
//        }
//    }
    
    
    func prepareData() {
        transactions = calModel.justTransactions
            .filter { calModel.isInMultiSelectMode ? calModel.multiSelectTransactions.map({ $0.id }).contains($0.id) : true }
            //.filter { $0.payMethod?.id == calModel.sPayMethod?.id }
            .filter { trans in
                if let sMethod = calModel.sPayMethod {
                    if sMethod.isUnifiedDebit {
                        let methods: Array<String> = payModel.paymentMethods.filter { $0.isDebit }.map { $0.id }
                        return methods.contains(trans.payMethod?.id ?? "")

                    } else if sMethod.isUnifiedCredit {
                        let methods: Array<String> = payModel.paymentMethods.filter { $0.isCredit }.map { $0.id }
                        return methods.contains(trans.payMethod?.id ?? "")

                    } else {
                        return trans.payMethod?.id == sMethod.id
                    }
                } else {
                    return false
                }
            }
            .filter { $0.dateComponents?.month == calModel.sMonth.actualNum }
            .filter { $0.dateComponents?.year == calModel.sMonth.year }
            .sorted { $0.dateComponents?.day ?? 0 < $1.dateComponents?.day ?? 0 }
        

//        totalSpent = transactions
//            .map { $0.payMethod?.accountType == .credit ? $0.amount * -1 : $0.amount }
//            .reduce(0.0, +)
            
        
//        /// Analyze Data
//        cumTotals.removeAll()
//        
//        var total: Double = 0.0
//        calModel.sMonth.days.forEach { day in
//            let doesHaveTransactions = !transactions.filter { $0.dateComponents?.day == day.date?.day }.isEmpty
//            let dailyTotal = transactions
//                .filter { $0.dateComponents?.day == day.date?.day }
//                .map { $0.payMethod?.accountType == .credit ? $0.amount * -1 : $0.amount }
//                .reduce(0.0, +)
//            
//            
//            if doesHaveTransactions {
//                total += dailyTotal
//                cumTotals.append(CumTotal(day: day.date!.day, total: total))
//            }
//
//        }
    }
}
