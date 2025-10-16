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
    @Local(\.colorTheme) var colorTheme
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
        @Bindable var photoModel = PhotoModel.shared
        
        NavigationStack {
            
            ScrollViewReader { scrollProxy in
                List {
                    transactionList
                }
                /// Scroll to today when the view loads (if applicable)
                .onAppear { scrollToTodayOnAppearOfScrollView(scrollProxy) }
            }
            
            
//            StandardContainerWithToolbar(.list) {
//                transactionList
//            }
            
            .searchable(text: $searchText, prompt: Text("Search"))
            .navigationTitle("\(calModel.sMonth.name) \(String(calModel.sYear))")
            .navigationSubtitle(calModel.sPayMethod?.title ?? "N/A")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NewTransactionMenuButton(transEditID: $transEditID, showTransferSheet: $showTransferSheet, showPhotosPicker: $showPhotosPicker, showCamera: $showCamera)
                }
                                
//                ToolbarItem(placement: .topBarTrailing) { paymentMethodButton }
//                    .matchedTransitionSource(id: "myButton", in: paymentMethodMenuButtonNamespace)
//                ToolbarSpacer(.fixed, placement: .topBarTrailing)
                ToolbarItem(placement: .topBarTrailing) { closeButton }
            }
            #endif
        }
        
        
        
        
        
//        StandardContainer(AppState.shared.isIpad ? .sidebarList : .list) {
//            transactionList
//        } header: {
//            if AppState.shared.isIpad {
//                SidebarHeader(
//                    title: sheetTitle,
//                    close: {
//                        #if os(iOS)
//                        withAnimation { showTransactionListSheet = false }
//                        #else
//                        dismiss()
//                        #endif
//                    }, view1: {
//                        NewTransactionMenuButton(transEditID: $transEditID, showTransferSheet: $showTransferSheet, showPhotosPicker: $showPhotosPicker, showCamera: $showCamera)
//                    }
//                )
//            } else {
//                SheetHeader(
//                    title: sheetTitle,
//                    close: {
//                        #if os(iOS)
//                        withAnimation { showTransactionListSheet = false }
//                        #else
//                        dismiss()
//                        #endif
//                    }, view1: {
//                        NewTransactionMenuButton(transEditID: $transEditID, showTransferSheet: $showTransferSheet, showPhotosPicker: $showPhotosPicker, showCamera: $showCamera)
//                    }
//                )
//            }
//        }
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
        .sheet(isPresented: $showPaymentMethodSheet) {
            
        } content: {
            PayMethodSheet(payMethod: $calModel.sPayMethod, whichPaymentMethods: .all, showStartingAmountOption: false)
                .navigationTransition(.zoom(sourceID: "myButton", in: paymentMethodMenuButtonNamespace))
        }

    }
    
    
    var paymentMethodButton: some View {
        Button {
            showPaymentMethodSheet = true
        } label: {
            Image(systemName: "creditcard")
                .foregroundStyle(colorScheme == .dark ? .white : .black)
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
                .foregroundStyle(colorScheme == .dark ? .white : .black)
        }
    }
    
    
    
    var transactionList: some View {
        ForEach(calModel.sMonth.days.filter { $0.date != nil }) { day in
            let filteredTrans = getTransactions(for: day)
            
            let doesHaveTransactions = filteredTrans
                .filter { $0.dateComponents?.day == day.date?.day }
                .count > 0
            
            let dailyTotal = transactions
                .filter { $0.dateComponents?.day == day.date?.day }
                .map { ($0.payMethod?.isCreditOrLoan ?? false) ? $0.amount * -1 : $0.amount }
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
                    if searchText.isEmpty {
                        Text("No Transactions")
                            .foregroundStyle(.gray)
                    }
                    
                }
            } header: {
                if let date = day.date, date.isToday {
                    HStack {
                        Text("TODAY")
                            .foregroundStyle(Color.fromName(colorTheme))
                        VStack {
                            Divider()
                                .overlay(Color.fromName(colorTheme))
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
        transactions
            .filter { searchText.isEmpty ? true : $0.title.localizedStandardContains(searchText) }
            .filter { $0.dateComponents?.day == day.date?.day }
            .filter { ($0.payMethod?.isAllowedToBeViewedByThisUser ?? true) }
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
                        let methods: Array<String> = payModel.paymentMethods
                            .filter { $0.isAllowedToBeViewedByThisUser }
                            .filter { !$0.isHidden }
                            .filter { $0.isDebit }
                            .map { $0.id }
                        return methods.contains(trans.payMethod?.id ?? "")

                    } else if sMethod.isUnifiedCredit {
                        let methods: Array<String> = payModel.paymentMethods
                            .filter { $0.isAllowedToBeViewedByThisUser }
                            .filter { !$0.isHidden }
                            .filter { $0.isCredit }
                            .map { $0.id }
                        return methods.contains(trans.payMethod?.id ?? "")

                    } else {
                        return trans.payMethod?.id == sMethod.id && (trans.payMethod?.isAllowedToBeViewedByThisUser ?? true) && !(trans.payMethod?.isHidden ?? false)
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
