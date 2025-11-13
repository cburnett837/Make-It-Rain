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
    @AppStorage("categorySortMode") var categorySortMode: SortMode = .title
    @Local(\.useWholeNumbers) var useWholeNumbers
    //@Local(\.colorTheme) var colorTheme
    @Environment(\.colorScheme) private var colorScheme

    @Environment(CalendarModel.self) private var calModel
    @Environment(PayMethodModel.self) private var payModel
    @Environment(EventModel.self) private var eventModel

    @State private var transactions: [CBTransaction] = []
    @State private var totalSpent: Double = 0.0
    @State private var searchText = ""

    @State private var transEditID: String?
    @State private var editTrans: CBTransaction?
    @State private var transDay: CBDay?
    
    @State private var cumTotals: [CumTotal] = []
    
    @Binding var showTransactionListSheet: Bool
    
    @State private var showTransferSheet = false
    @State private var showPhotosPicker = false
    @State private var showCamera = false
    @State private var showPaymentMethodSheet = false
    
    @Namespace var paymentMethodMenuButtonNamespace

    

    struct CumTotal {
        var day: Int
        var total: Double
    }
    
//    var sheetTitle: String {
//        "\(calModel.sPayMethod?.title ?? "N/A") \(calModel.sMonth.name) \(String(calModel.sYear))"
//    }
    
    var body: some View {
        @Bindable var calModel = calModel
        @Bindable var photoModel = FileModel.shared
        NavigationStack {
            ScrollViewReader { scrollProxy in
                List {
                    transactionList
                }
                /// Scroll to today when the view loads (if applicable)
                .onAppear { scrollToTodayOnAppearOfScrollView(scrollProxy) }
            }
            .searchable(text: $searchText, prompt: Text("Search"))
            .navigationTitle("\(calModel.sMonth.name) \(String(calModel.sYear))")
            .navigationSubtitle(calModel.sPayMethod?.title ?? "N/A")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                DefaultToolbarItem(kind: .search, placement: .bottomBar)
                ToolbarSpacer(.flexible, placement: .bottomBar)
                ToolbarItem(placement: .bottomBar) {
                    NewTransactionMenuButton(transEditID: $transEditID, showTransferSheet: $showTransferSheet, showPhotosPicker: $showPhotosPicker, showCamera: $showCamera)
                }
                ToolbarItem(placement: .topBarTrailing) { closeButton }
            }
            #endif
        }
        .task {
            setSelectedDay()
            prepareData()
        }
        .sheet(isPresented: $showTransferSheet) {
            TransferSheet(date: transDay?.date ?? Date())
        }
        .photoPickerAndCameraSheet(
            fileUploadCompletedDelegate: calModel,
            parentType: .transaction,
            allowMultiSelection: false,
            showPhotosPicker: $showPhotosPicker,
            showCamera: $showCamera
        )
        .transactionEditSheetAndLogic(transEditID: $transEditID, selectedDay: $transDay)
        .sheet(isPresented: $showPaymentMethodSheet) {
            
        } content: {
            PayMethodSheet(payMethod: $calModel.sPayMethod, whichPaymentMethods: .all, showStartingAmountOption: false)
                #if os(iOS)
                .navigationTransition(.zoom(sourceID: "myButton", in: paymentMethodMenuButtonNamespace))
                #endif
        }
    }
    
    
    var paymentMethodButton: some View {
        Button {
            showPaymentMethodSheet = true
        } label: {
            Image(systemName: "creditcard")
                .schemeBasedForegroundStyle()
        }
    }
    
    
    var closeButton: some View {
        Button {
            #if os(iOS)
            withAnimation { showTransactionListSheet = false }
            #else
            dismiss()
            #endif
        } label: {
            Image(systemName: "xmark")
                .schemeBasedForegroundStyle()
        }
    }
    
    
    
    var transactionList: some View {
        ForEach(calModel.sMonth.days.filter { $0.date != nil }) { day in
            let filteredTrans = calModel.getTransactions(day: day.id)
            
            let doesHaveTransactions = filteredTrans
                .filter { $0.dateComponents?.day == day.date?.day }
                .count > 0
            
            let dailyTotal = transactions
                .filter { $0.dateComponents?.day == day.date?.day }
                .filter { $0.factorInCalculations }
                .map { ($0.payMethod?.isCreditOrLoan ?? false) ? $0.amount * -1 : $0.amount }
                .reduce(0.0, +)
            
            let dailyCount = transactions
                .filter { $0.dateComponents?.day == day.date?.day }
                .count
                                                
            Section {
                if doesHaveTransactions {
                    ForEach(filteredTrans) { trans in
                    //ForEach(getTransactions(for: day)) { trans in
                        TransactionListLine(trans: trans)
                            .onTapGesture {
                                self.transDay = day
                                self.transEditID = trans.id
                            }
                    }
                } else {
                    if searchText.isEmpty {
                        Text("No Transactions")
                            .foregroundStyle(.gray)
                    }
                    
                }
            } header: {
                if let date = day.date, date.isToday {
                    HStack {
                        Text("TODAY")
                            .foregroundStyle(Color.theme)
                        VStack {
                            Divider()
                                .overlay(Color.theme)
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
            .id(day.id)
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
    
    
    func scrollToTodayOnAppearOfScrollView(_ proxy: ScrollViewProxy) {
        if calModel.sMonth.actualNum == AppState.shared.todayMonth {
            //DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                //withAnimation {
                    proxy.scrollTo(AppState.shared.todayDay, anchor: .top)
                //}
            //}
        }
    }
    
    
    func getTransactions(for day: CBDay) -> Array<CBTransaction> {
        return transactions
            .filter { searchText.isEmpty ? true : $0.title.localizedCaseInsensitiveContains(searchText) }
            .filter { $0.dateComponents?.day == day.date?.day }
            .filter { ($0.payMethod?.isPermitted ?? true) }
            //.filter { !($0.payMethod?.isHidden ?? false) && $0.payMethod?.id == calModel.sPayMethod?.id }
            //.filter { $0.payMethod?.id == calModel.sPayMethod?.id }
            .sorted {
                if transactionSortMode == .title {
                    return $0.title < $1.title
                    
                } else if transactionSortMode == .enteredDate {
                    return $0.enteredDate < $1.enteredDate
                    
                } else {
                    if categorySortMode == .title {
                        return ($0.category?.title ?? "").lowercased() < ($1.category?.title ?? "").lowercased()
                    } else {
                        return $0.category?.listOrder ?? 0 < $1.category?.listOrder ?? 0
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
//            FileModel.shared.fileParent = nil
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
                        let methods: Array<String> = payModel.paymentMethods
                            .filter { $0.isPermitted }
                            .filter { !$0.isHidden }
                            .filter { $0.isDebit }
                            .map { $0.id }
                        return methods.contains(trans.payMethod?.id ?? "")

                    } else if sMethod.isUnifiedCredit {
                        let methods: Array<String> = payModel.paymentMethods
                            .filter { $0.isPermitted }
                            .filter { !$0.isHidden }
                            .filter { $0.isCredit }
                            .map { $0.id }
                        return methods.contains(trans.payMethod?.id ?? "")

                    } else {
                        return trans.payMethod?.id == sMethod.id && (trans.payMethod?.isPermitted ?? true) && !(trans.payMethod?.isHidden ?? false)
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
