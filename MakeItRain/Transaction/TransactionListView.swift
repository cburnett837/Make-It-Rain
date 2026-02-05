//
//  TransactionListView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 6/2/25.
//

import SwiftUI

fileprivate struct TransListCumTotal {
    var day: Int
    var total: Double
}


enum WhichTransactionsToShow {
    case selectedMonth, onlyWithReceipts
}

struct TransactionListView: View {
    #if os(macOS)
    @Environment(\.dismiss) var dismiss
    #endif
    
    //@Local(\.colorTheme) var colorTheme
    @Environment(\.colorScheme) private var colorScheme
    @Environment(CalendarProps.self) private var calProps    
    @Environment(CalendarModel.self) private var calModel
    @Environment(PayMethodModel.self) private var payModel
    

    //@State private var transactions: [CBTransaction] = []
    @State private var totalSpent: Double = 0.0
    @State private var searchText = ""

    @State private var transEditID: String?
    @State private var editTrans: CBTransaction?
    @State private var transDay: CBDay?
    
    @State private var cumTotals: [TransListCumTotal] = []
    
    @Binding var showTransactionListSheet: Bool
    
    @State private var showTransferSheet = false
    @State private var showPhotosPicker = false
    @State private var showCamera = false
    @State private var showPaymentMethodSheet = false
    
    @Namespace var paymentMethodMenuButtonNamespace
    
//    var sheetTitle: String {
//        "\(calModel.sPayMethod?.title ?? "N/A") \(calModel.sMonth.name) \(String(calModel.sYear))"
//    }
    
    var body: some View {
        if AppState.shared.isIphone {
            content
        } else {
            NavigationStack {
                content
            }
        }
    }
    
    @ViewBuilder
    var content: some View {
        @Bindable var calModel = calModel
        @Bindable var photoModel = FileModel.shared
        
        ScrollViewReader { scrollProxy in
            List {
                ForEach(calModel.sMonth.days.filter { $0.date != nil }) { day in
                    DayChunk(
                        day: day,
                        //transactions: transactions,
                        searchText: searchText,
                        cumTotals: cumTotals,
                        transDay: $transDay,
                        transEditID: $transEditID
                    )
                }
            }
            /// Scroll to today when the view loads (if applicable)
            //.onAppear { scrollToTodayOnAppearOfScrollView(scrollProxy) }
        }
        .searchable(text: $searchText, prompt: Text("Search"))
        .searchPresentationToolbarBehavior(.avoidHidingContent)
        .navigationTitle("\(calModel.sMonth.name) \(String(calModel.sMonth.year))")
        .navigationSubtitle(calModel.sPayMethod?.title ?? "N/A")
        //.background(Color(.systemBackground)) // force matching
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            DefaultToolbarItem(kind: .search, placement: .bottomBar)
            ToolbarSpacer(.flexible, placement: .bottomBar)
            ToolbarItem(placement: .bottomBar) {
                NewTransactionMenuButton(transEditID: $transEditID, showTransferSheet: $showTransferSheet, showPhotosPicker: $showPhotosPicker, showCamera: $showCamera)
            }
            if AppState.shared.isIpad {
                ToolbarItem(placement: .topBarTrailing) { paymentMethodButton }
                ToolbarSpacer(.flexible, placement: .topBarTrailing)
                ToolbarItem(placement: .topBarTrailing) { closeButton }
            } else {
                ToolbarItem(placement: .topBarTrailing) {
                    paymentMethodButton
                        //.matchedTransitionSource(id: "myButton", in: paymentMethodMenuButtonNamespace)
                }
            }
        }
        #endif
        .task {
            setSelectedDay()
            //prepareData()
        }
        .sheet(isPresented: $showTransferSheet) {
            TransferSheet(defaultDate: transDay?.date ?? Date())
        }
        #if os(iOS)
        .photoPickerAndCameraSheet(
            fileUploadCompletedDelegate: calModel,
            parentType: .transaction,
            allowMultiSelection: false,
            showPhotosPicker: $showPhotosPicker,
            showCamera: $showCamera
        )
        #endif
        .transactionEditSheetAndLogic(transEditID: $transEditID, selectedDay: $transDay)
        .sheet(isPresented: $showPaymentMethodSheet) {
            calModel.startingAmountSheetDismissed()
        } content: {
            PayMethodSheet(payMethod: $calModel.sPayMethod, whichPaymentMethods: .all, showStartingAmountOption: true, showNoneOption: true)
                //#if os(iOS)
                //.navigationTransition(.zoom(sourceID: "myButton", in: paymentMethodMenuButtonNamespace))
                //#endif
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
    
    
    func scrollToTodayOnAppearOfScrollView(_ proxy: ScrollViewProxy) {
        if calModel.sMonth.actualNum == AppState.shared.todayMonth {
            /// Give the list time to open before scrolling
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                withAnimation {
                    proxy.scrollTo(AppState.shared.todayDay, anchor: .top)
                }
            }
        }
    }
    
    
//    func getTransactions(for day: CBDay) -> Array<CBTransaction> {
//        return transactions
//            .filter { searchText.isEmpty ? true : $0.title.localizedCaseInsensitiveContains(searchText) }
//            .filter { $0.dateComponents?.day == day.date?.day }
//            .filter { ($0.payMethod?.isPermitted ?? true) }
//            //.filter { !($0.payMethod?.isHidden ?? false) && $0.payMethod?.id == calModel.sPayMethod?.id }
//            //.filter { $0.payMethod?.id == calModel.sPayMethod?.id }
//            .sorted {
//                if transactionSortMode == .title {
//                    return $0.title < $1.title
//                    
//                } else if transactionSortMode == .enteredDate {
//                    return $0.enteredDate < $1.enteredDate
//                    
//                } else {
//                    if categorySortMode == .title {
//                        return ($0.category?.title ?? "").lowercased() < ($1.category?.title ?? "").lowercased()
//                    } else {
//                        return $0.category?.listOrder ?? 0 < $1.category?.listOrder ?? 0
//                    }
//                }
//            }
//    }
    
    
    func setSelectedDay() {
        transDay = calModel.sMonth.days.filter { $0.dateComponents?.day == (calModel.sMonth.actualNum == AppState.shared.todayMonth ? AppState.shared.todayDay : 1) }.first
    }
    
//    func prepareData() {
//        transactions = calModel.justTransactions
//            .filter { calModel.isInMultiSelectMode ? calModel.multiSelectTransactions.map({ $0.id }).contains($0.id) : true }
//            //.filter { $0.payMethod?.id == calModel.sPayMethod?.id }
//            .filter { trans in
//                if let sMethod = calModel.sPayMethod {
//                    if sMethod.isUnifiedDebit {
//                        let methods: Array<String> = payModel.paymentMethods
//                            .filter { $0.isPermitted }
//                            .filter { !$0.isHidden }
//                            .filter { $0.isDebit }
//                            .map { $0.id }
//                        return methods.contains(trans.payMethod?.id ?? "")
//
//                    } else if sMethod.isUnifiedCredit {
//                        let methods: Array<String> = payModel.paymentMethods
//                            .filter { $0.isPermitted }
//                            .filter { !$0.isHidden }
//                            .filter { $0.isCredit }
//                            .map { $0.id }
//                        return methods.contains(trans.payMethod?.id ?? "")
//
//                    } else {
//                        return trans.payMethod?.id == sMethod.id && (trans.payMethod?.isPermitted ?? true) && !(trans.payMethod?.isHidden ?? false)
//                    }
//                } else {
//                    return false
//                }
//            }
//            .filter { $0.dateComponents?.month == calModel.sMonth.actualNum }
//            .filter { $0.dateComponents?.year == calModel.sMonth.year }
//            .sorted { $0.dateComponents?.day ?? 0 < $1.dateComponents?.day ?? 0 }
//        
//
////        totalSpent = transactions
////            .map { $0.payMethod?.accountType == .credit ? $0.amount * -1 : $0.amount }
////            .reduce(0.0, +)
//            
//        
////        /// Analyze Data
////        cumTotals.removeAll()
////        
////        var total: Double = 0.0
////        calModel.sMonth.days.forEach { day in
////            let doesHaveTransactions = !transactions.filter { $0.dateComponents?.day == day.date?.day }.isEmpty
////            let dailyTotal = transactions
////                .filter { $0.dateComponents?.day == day.date?.day }
////                .map { $0.payMethod?.accountType == .credit ? $0.amount * -1 : $0.amount }
////                .reduce(0.0, +)
////            
////            
////            if doesHaveTransactions {
////                total += dailyTotal
////                cumTotals.append(TransListCumTotal(day: day.date!.day, total: total))
////            }
////
////        }
//    }
}


fileprivate struct DayChunk: View {
    @Environment(CalendarModel.self) private var calModel

    var day: CBDay
    //var transactions: Array<CBTransaction>
    var searchText: String
    var cumTotals: [TransListCumTotal]
    @Binding var transDay: CBDay?
    @Binding var transEditID: String?
    
    @State private var filteredTrans: [CBTransaction] = []
    @State private var doesHaveTransactions: Bool = false
    @State private var dailyTotal: Double = 0.0
    @State private var dailyCount: Int = 0
    
    var eodColor: Color {
//        if day.eodTotal > AppSettings.shared.lowBalanceThreshold {
//            return .gray
//        } else if day.eodTotal < 0 {
//            return .red
//        } else {
//            return .orange
//        }
        
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
    
    var body: some View {
        Group {
            if doesHaveTransactions {
                theSection {
                    transLoop
                }
            } else if searchText.isEmpty {
                theSection {
                    Text("No Transactions")
                        .foregroundStyle(.gray)
                }
            }
        }
        .id(day.id)
        .onChange(of: searchText, initial: true) { prepareTransactions(searchText: $1) }
        .onChange(of: calModel.sPayMethod) { prepareTransactions(searchText: searchText) }
    }
    
    
    @ViewBuilder
    func theSection<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        Section {
            content()
        } header: {
            sectionHeader
        } footer: {
            sectionFooter
        }
    }
    
    
    @ViewBuilder
    var transLoop: some View {
        ForEach(filteredTrans) { trans in
            TransactionListLine(trans: trans, onTap: {
                self.transDay = day
                self.transEditID = trans.id
            })                
        }
    }
    
    
    @ViewBuilder
    var sectionHeader: some View {
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
    }
    
    
    @ViewBuilder
    var sectionFooter: some View {
        HStack {
            Text("\(calModel.sPayMethod == nil ? "Spending:" : "EOD:") \(day.eodTotal.currencyWithDecimals())")
                .foregroundStyle(eodColor)
            
            Spacer()
            if dailyCount > 1 {
                Text(dailyTotal.currencyWithDecimals())
            }
        }
    }
    
    
    func prepareTransactions(searchText: String) {
        self.filteredTrans = calModel.getTransactions(day: day.id, meth: calModel.sPayMethod)
            .filter { searchText.isEmpty ? true : $0.title.localizedCaseInsensitiveContains(searchText) }
        
        self.doesHaveTransactions = filteredTrans
            .filter { $0.dateComponents?.day == day.date?.day }
            .count > 0
        
        self.dailyTotal = filteredTrans
            .filter { $0.dateComponents?.day == day.date?.day }
            .filter { $0.factorInCalculations }
            .map { ($0.payMethod?.isCreditOrLoan ?? false) ? $0.amount * -1 : $0.amount }
            .reduce(0.0, +)
        
        self.dailyCount = filteredTrans
            .filter { $0.dateComponents?.day == day.date?.day }
            .count
    }
}
