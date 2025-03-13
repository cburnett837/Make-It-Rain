//
//  CalendarViewPhone.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/16/24.
//

import SwiftUI
import PhotosUI
import Charts
import TipKit
#if os(iOS)


struct CalendarViewPhone: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    @AppStorage("appColorTheme") var appColorTheme: String = Color.blue.description
    @AppStorage("lineItemIndicator") var lineItemIndicator: LineItemIndicator = .emoji
    @AppStorage("updatedByOtherUserDisplayMode") var updatedByOtherUserDisplayMode = UpdatedByOtherUserDisplayMode.full
    @AppStorage("useWholeNumbers") var useWholeNumbers = false
    @AppStorage("threshold") var threshold = "500.0"
    @AppStorage("phoneLineItemDisplayItem") var phoneLineItemDisplayItem: PhoneLineItemDisplayItem = .both
    
    @State private var currentPhoneLineItemDisplayItem = PhoneLineItemDisplayItem.both
    
        
    @Environment(FuncModel.self) var funcModel
    @Environment(CalendarModel.self) private var calModel
    @Environment(PayMethodModel.self) private var payModel
    @Environment(CategoryModel.self) private var catModel
    @Environment(KeywordModel.self) private var keyModel
    @Environment(EventModel.self) private var eventModel
    
    //@State private var transEditID: Int?
    let enumID: NavDestination
    @State private var showSearchBar = false
    @Binding var selectedDay: CBDay?
    //var focusedField: FocusState<Int?>.Binding
    //var searchFocus: FocusState<Int?>.Binding
    
    @FocusState private var focusedField: Int?
    
    let touchAndHoldPlusButtonTip = TouchAndHoldPlusButtonTip()
    let touchAndHoldMonthToFilterCategoriesTip = TouchAndHoldMonthToFilterCategoriesTip()
    let swipeToChangeMonthsTip = SwipeToChangeMonthsTip()
    
    @State private var transEditID: String?
    @State private var editTrans: CBTransaction?
    
    //var isShowingLoadingSpinnner: Bool
    
    var divideBy: CGFloat {
        let cellCount = calModel.sMonth.firstWeekdayOfMonth - 1 + calModel.sMonth.dayCount
        if cellCount > 35 {
            return 6
        } else if cellCount <= 35 && cellCount > 28 {
            return 5
        } else {
            return 4
        }
    }
    
    var eodColor: Color {
        if selectedDay?.eodTotal ?? 0.00 > Double(threshold) ?? 500 {
            return .gray
        } else if selectedDay?.eodTotal ?? 0.00 < 0 {
            return .red
        } else {
            return .orange
        }
    }
    
    let sevenColumnGrid = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    @State private var showTransferSheet = false
    @State private var showPaymentMethodSheet = false
    @State private var showCategorySheet = false
    @State private var showBudgetSheet = false
    @State private var showCalendarOptionsSheet = false
    @State private var showStartingAmountsSheet = false
    @State private var showAnalysisSheet = false
    @State private var showPhotosPicker = false
    @State private var showCamera = false
    
    @State private var maxDayHeight: CGFloat = 20.0
    
    @State private var overviewDay: CBDay?
    
    //@State private var putBackToBottomPanelViewOnRotate = false
    
    @State private var scrollHeight: CGFloat = 0
    @State private var transHeight: CGFloat = 0
    
    @State private var showFitTransactions = false
    
    @State private var visibleDays: Array<Int> = []
    
    @State private var scrollToComplete = false

    
    var body: some View {
        //let _ = Self._printChanges()
        @Bindable var navManager = NavigationManager.shared
        //@Bindable var vm = vm
        @Bindable var calModel = calModel
        
        /// The geometry reader is needed for the keyboard avoidance
        NavigationStack {
            Group {
                if calModel.sMonth.enumID == enumID {
                    calendarView
                    //Text("Calendar")
                } else {
                    ProgressView()
                    //Text("HEY")
                        .transition(.opacity)
                        .tint(.none)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
//                calendarView
//                    .opacity(calModel.sMonth.enumID == enumID ? 1 : 0)
//                    .overlay(
//                        ProgressView()
//                            .transition(.opacity)
//                            .tint(.none)
//                            .opacity(calModel.sMonth.enumID == enumID ? 0 : 1)
//                    )
                    
            }
            .onChange(of: AppState.shared.orientation, { oldValue, newValue in
                if [.faceDown, .faceUp].contains(newValue) {
                    return
                }
                
                if [.landscapeRight, .landscapeLeft].contains(newValue) {
                    recalculateTransHeight()
                }
                
                if [.portrait, .portraitUpsideDown].contains(newValue)
                && [.landscapeRight, .landscapeLeft].contains(oldValue) {
                    recalculateTransHeight()
                }
            })
                    
            .onPreferenceChange(MaxSizePreferenceKey.self) { maxDayHeight = $0 }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .standardBackground()
//            .task {
//                calModel.setSelectedMonthFromNavigation(navID: enumID, prepareStartAmount: true)
//                let month = calModel.months.filter {$0.enumID == enumID}.first!
//                let targetDay = month.days.filter { $0.dateComponents?.day == (month.actualNum == AppState.shared.todayMonth ? AppState.shared.todayDay : 1) }.first
//                selectedDay = targetDay
//            }
            /// Using this instead of a task because the iPad doesn't reload `CalendarView`. It just changes the data source.
            .onChange(of: enumID, initial: true) {
                Task {
                    calModel.setSelectedMonthFromNavigation(navID: enumID, prepareStartAmount: true)
                    let month = calModel.months.filter {$0.enumID == enumID}.first!
                    let targetDay = month.days.filter { $0.dateComponents?.day == (month.actualNum == AppState.shared.todayMonth ? AppState.shared.todayDay : 1) }.first
                    selectedDay = targetDay
                }
                
            }
            .sensoryFeedback(.selection, trigger: transEditID) { $1 != nil }
            .onShake {
                Helpers.buzzPhone(.success)
                withAnimation {
                    //calModel.sCategory = nil
                    calModel.sCategories = []
                    calModel.searchText = ""
                    showSearchBar = false
                    calModel.sPayMethod = payModel.paymentMethods.first(where: { $0.isDefault })
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            //.interactiveDismissDisabled(true)
            .toolbar {
                calendarToolbar()
            }
            
            /// This exists in 2 place - purely for visual effect. See ``LineItemView``
            /// This is needed (passing the ID instead of the trans) because you can close the popover without actually clicking the close button. So I need somewhere to do cleanup.
            .onChange(of: transEditID, { oldValue, newValue in
                print(".onChange(of: transEditID)")
                /// When `newValue` is false, save to the server. We have to use this because `.popover(isPresented:)` has no onDismiss option.
                if oldValue != nil && newValue == nil {
                    
                    /// Present tip after trying to add 3 new transactions.
                    let trans = calModel.getTransaction(by: oldValue!, from: .normalList)
                    if trans.action == .add {
                        TouchAndHoldPlusButtonTip.didTouchPlusButton.sendDonation()
                    }
                                        
                    calModel.saveTransaction(id: oldValue!, day: selectedDay!, eventModel: eventModel)
                    /// - When adding a transaction via a day's context menu, `selectedDay` gets changed to the contexts day.
                    ///   So when closing the transaction, put `selectedDay`back to today so the normal plus button works and the gray box goes back to today.
                    /// - Gotta have a `selectedDay` for the editing of a transaction and transfer sheet.
                    ///   Since one is not always used in details view, set to the current day if in the current month, otherwise set to the first of the month.
                    /// - If you're viewing the bottom panel, reset `selectedDay` to `overviewDay` so any transactions that are added via the bottom panel have the date of the bottom panel.
                    if overviewDay != nil {
                        selectedDay = overviewDay
                    } else {
                        let targetDay = calModel.sMonth.days.filter { $0.dateComponents?.day == (calModel.sMonth.num == AppState.shared.todayMonth ? AppState.shared.todayDay : 1) }.first
                        selectedDay = targetDay
                    }
                    /// Keep the model clean, and show alert for a photo that may be taking a long time to upload.
                    calModel.pictureTransactionID = nil
                                                                    
                } else {
                    editTrans = calModel.getTransaction(by: transEditID!, from: .normalList)
                }
            })
            .sheet(item: $editTrans) { trans in
                TransactionEditView(trans: trans, transEditID: $transEditID, day: selectedDay!, isTemp: false)
                    /// This is needed for the drag to dismiss.
                    .onDisappear { transEditID = nil }
            }
            
            
            
            
            
    //        .sheet(item: $editPaymentMethod, onDismiss: {
    //            paymentMethodEditID = nil
    //            payModel.determineIfUserIsRequiredToAddPaymentMethod()
    //        }, content: { meth in
    //            PayMethodView(payMethod: meth, payModel: payModel, editID: $paymentMethodEditID)
    //            #if os(iOS)
    //            //.presentationDetents([.medium, .large])
    //            #endif
    //        })
    //        .onChange(of: paymentMethodEditID) { oldValue, newValue in
    //            if let newValue {
    //                let payMethod = payModel.getPaymentMethod(by: newValue)
    //
    //                if payMethod.accountType == .unifiedChecking || payMethod.accountType == .unifiedCredit {
    //                    paymentMethodEditID = nil
    //                    AppState.shared.showAlert("Combined payment methods cannot be edited.")
    //                } else {
    //                    editPaymentMethod = payMethod
    //                }
    //            } else {
    //                payModel.savePaymentMethod(id: oldValue!, calModel: calModel)
    //                payModel.determineIfUserIsRequiredToAddPaymentMethod()
    //            }
    //        }
            
            
            
            
            .sheet(isPresented: $showAnalysisSheet) {
                AnalysisSheet(showAnalysisSheet: $showAnalysisSheet)
            }
            .sheet(isPresented: $showCalendarOptionsSheet, onDismiss: {
                if currentPhoneLineItemDisplayItem != phoneLineItemDisplayItem {
                    currentPhoneLineItemDisplayItem = phoneLineItemDisplayItem
                    recalculateTransHeight()
                }
            }, content: {
                CalendarOptionsSheet(selectedDay: $selectedDay)
            })
            .sheet(isPresented: $showPaymentMethodSheet, onDismiss: {
                TouchAndHoldMonthToFilterCategoriesTip.didTouchMonthName.sendDonation()
            }, content: {
                PaymentMethodSheet(payMethod: $calModel.sPayMethod, whichPaymentMethods: .all)
            })
            .sheet(isPresented: $showCategorySheet) {
                MultiCategorySheet(categories: $calModel.sCategories)
            }
            .sheet(isPresented: $showTransferSheet) {
                TransferSheet2(date: selectedDay?.date ?? Date())
            }
            .fullScreenCover(isPresented: $showBudgetSheet) {
                BudgetTable(maxHeaderHeight: .constant(50))
            }
            .sheet(isPresented: $showStartingAmountsSheet) {
                calModel.calculateTotalForMonth(month: calModel.sMonth)
                Task {
                    await withTaskGroup(of: Void.self) { group in
                        let starts = calModel.sMonth.startingAmounts.filter { !$0.payMethod.isUnified }
                        for start in starts {
                            group.addTask {
                                await calModel.submit(start)
                            }
                        }
                    }
                }
            } content: {
                StartingAmountSheet()
            }
            
            #if os(iOS)
            .photosPicker(isPresented: $showPhotosPicker, selection: $calModel.imagesFromLibrary, maxSelectionCount: 1, matching: .images, photoLibrary: .shared())
            .onChange(of: showPhotosPicker) { oldValue, newValue in
                if !newValue { calModel.uploadPictures() }
            }
            .fullScreenCover(isPresented: $showCamera) {
                AccessCameraView(selectedImage: $calModel.imageFromCamera)
                    .background(.black)
            }
            #endif
        }
        
        .overlay {
            if (!AppState.shared.isIpad) {
                searchBarOverlay
            }
            
        }
        
    }
    
    
    func recalculateTransHeight() {
        print("-- \(#function)")
        withAnimation {
            transHeight = 0
        }
    }
    
    
    var calendarView: some View {
        Group {
            @Bindable var calModel = calModel
            VStack(spacing: 0) {
                if !AppState.shared.isLandscape {
                    //TipView(swipeToChangeMonthsTip, arrowEdge: .bottom)
                    fakeNavHeader
                        .popoverTip(swipeToChangeMonthsTip)
                        .dropDestination(for: CBTransaction.self) { droppedTrans, location in
                            calModel.dragTarget = nil
                            return true
                        }
                }
                
                Group {
                    LazyVGrid(columns: sevenColumnGrid, spacing: 0) {
                        ForEach(days, id: \.self) { name in
                            Text(name)
                                .frame(maxWidth: .infinity)
                                .font(.subheadline)
                                .foregroundStyle(.gray)
                        }
                    }
                    .padding(.bottom, 4)
                    .overlay(Rectangle().frame(width: nil, height: 2, alignment: .bottom).foregroundColor(Color(.tertiarySystemFill)), alignment: .bottom)
                    
                    GeometryReader { geo in
                        ScrollViewReader { scroll in
                            ScrollView {
                                LazyVGrid(columns: sevenColumnGrid, spacing: 0) {
                                    ForEach($calModel.sMonth.days) { $day in
                                        VStack(spacing: 0) {
                                            DayViewPhone(
                                                transEditID: $transEditID,
                                                day: $day,
                                                selectedDay: $selectedDay,
                                                showTransferSheet: $showTransferSheet,
                                                //putBackToBottomPanelViewOnRotate: $putBackToBottomPanelViewOnRotate,
                                                showPhotosPicker: $showPhotosPicker,
                                                showCamera: $showCamera,
                                                overviewDay: $overviewDay,
                                                transHeight: $transHeight
                                            )
                                            .id(day.dateComponents?.day ?? 0)
                                            .onAppear {
                                                visibleDays.append(day.dateComponents?.day ?? 0)
                                            }
                                            
                                            /// This is the dividing line
//                                            .if(AppState.shared.isIpad && day.date != nil) {
//                                                $0.border(Color(.tertiarySystemFill), width: 2)                                                
//                                            }
                                            
                                            //.if(!AppState.shared.isIpad) {
                                            //    $0.
                                            .overlay(
                                                    Rectangle()
                                                        .frame(width: nil, height: 2, alignment: .bottom)
                                                        .foregroundColor(
                                                            Color(.tertiarySystemFill)
                                                        ), alignment: .bottom
                                                )
                                           // }
//                                            .if(AppState.shared.isIpad) {
//                                                $0
//                                                .overlay(
//                                                    Rectangle()
//                                                        .frame(width: 2, height: nil, alignment: .leading)
//                                                        .foregroundColor(
//                                                            Color(.tertiarySystemFill)
//                                                        ), alignment: .leading
//                                                )
//                                                .overlay(
//                                                    Rectangle()
//                                                        .frame(width: 2, height: nil, alignment: .trailing)
//                                                        .foregroundColor(
//                                                            Color(.tertiarySystemFill)
//                                                        ), alignment: .trailing
//                                                )
//                                            }
                                            
                                            
                                            //.frame(minHeight: geo.size.height / divideBy, alignment: .center)
                                            .frame(minHeight: scrollHeight / divideBy, alignment: .center)
                                            
                                        }
                                    }
                                }
                                
                                /// This is for when the target scrollTo day is not visible. We first scroll to this so the scroll views goes to the bottom, and then we scroll to the targetDay.
//                                Spacer()
//                                    .frame(height: 1)
//                                    .id(100000)
                            }
                            .contentMargins(.bottom, (overviewDay == nil && !showFitTransactions) ? 0 : (scrollHeight) - (AppState.shared.isLandscape ? AppState.shared.isIpad ? 300 : 150 : AppState.shared.isIpad ? 500 : 300), for: .scrollContent)
                            .frame(height: scrollHeight)
                            //.frame(height: (overviewDay == nil && !showFitTransactions) ? scrollHeight : (scrollHeight) - (AppState.shared.isLandscape ? AppState.shared.isIpad ? 300 : 150 : AppState.shared.isIpad ? 500 : 300))
                            .scrollIndicators(.hidden)
                            //.transaction { $0.animation = nil }
                            //.frame(minHeight: geo.size.height)
                            .onScrollPhaseChange { oldPhase, newPhase in
                                if newPhase == .interacting {
                                    withAnimation { calModel.hilightTrans = nil }
                                }
                            }
//                            .onChange(of: AppState.shared.orientation) { oldValue, newValue in
//                                if [.faceDown, .faceUp].contains(newValue) { return }
//                                if [.faceDown, .faceUp].contains(oldValue) { return }
//                                if calModel.sMonth.actualNum != AppState.shared.todayMonth || calModel.sYear != AppState.shared.todayYear { return }
//                                scroll.scrollTo(AppState.shared.todayDay, anchor: .top)
//                            }
//                            .onChange(of: overviewDay) { oldValue, newValue in
//                                if phoneLineItemDisplayItem != .both {
//                                    withAnimation {
//                                        scroll.scrollTo(newValue?.dateComponents?.day, anchor: .bottom)
//                                    }
//                                }
//                            }
//                            .onAppear {
//                                /// Need the task due to the fade-in animation.
//                                Task {
//                                    //try? await Task.sleep(nanoseconds: UInt64(1 * Double(NSEC_PER_SEC)))
//                                    if calModel.sMonth.actualNum != AppState.shared.todayMonth || calModel.sYear != AppState.shared.todayYear {
//                                        print("NOT TO TODAY \(calModel.sMonth.actualNum) - \(AppState.shared.todayMonth) - \(calModel.sYear) - \(AppState.shared.todayYear)")
//                                        scrollToComplete = true
//                                        return
//                                    }
//                                    
//                                    print("SCROLLING TO TODAY")
//                                    /// This is for when the target scrollTo day is not visible. We first scroll to this so the scroll view goes to the bottom, and then we scroll to the targetDay.
//                                    if !visibleDays.contains(AppState.shared.todayDay) {
//                                        scroll.scrollTo(100000, anchor: .top)
//                                    }
//                                    //scroll.scrollTo(AppState.shared.todayDay, anchor: .top)
//                                    try? await Task.sleep(nanoseconds: UInt64(0.3 * Double(NSEC_PER_SEC)))
//                                    scrollToComplete = true
//                                }
//                            }
                        }
                        
                        
                        
                    }
                    /// Only for the pref key
                    .background {
                        GeometryReader { geo in
                            Color.clear.preference(key: ViewHeightKey.self, value: geo.size.height)
                        }
                    }
                    .onPreferenceChange(ViewHeightKey.self) {
                        scrollHeight = $0
                        //if scrollHeight == 0 { scrollHeight = $0 }
                    }
                    
                    .overlay {
                        if overviewDay != nil {
                            DayOverviewView(
                                day: $overviewDay,
                                selectedDay: $selectedDay,
                                transEditID: $transEditID,
                                showTransferSheet: $showTransferSheet,
                                showCamera: $showCamera,
                                showPhotosPicker: $showPhotosPicker
                            )
                            .frame(height: AppState.shared.isLandscape ? AppState.shared.isIpad ? 300 : 150 : AppState.shared.isIpad ? 500 : 300)
                            .frame(maxHeight: .infinity, alignment: .bottom)
                            .transition(.move(edge: .bottom))
                        }
                        
                        
                        if showFitTransactions {
                            FitTransactionOverlay(showFitTransactions: $showFitTransactions)
                                .frame(height: AppState.shared.isLandscape ? AppState.shared.isIpad ? 300 : 150 : AppState.shared.isIpad ? 500 : 300)
                                .frame(maxHeight: .infinity, alignment: .bottom)
                                .transition(.move(edge: .bottom))
                        }
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation {
                        calModel.hilightTrans = nil
                    }
                }
                                
                
            }
        }
        /// This is set via ``LineItemMiniView``.
        .onPreferenceChange(TransMaxSizePreferenceKey.self) { newSize in
            //DispatchQueue.main.async {
                //print("\(newSize)")
                transHeight = max(transHeight, newSize)
            //}
        }
    }
    
    @ToolbarContentBuilder
    func calendarToolbar() -> some ToolbarContent {
        if AppState.shared.isLandscape {
            ToolbarItemGroup(placement: .principal) {
                Text(enumID.displayName)
            }
        }
        
        ToolbarItem(placement: .topBarLeading) {
            if !AppState.shared.isIpad {
                backButton
            } else {
                if AppState.shared.isLandscape {
                    HStack(spacing: 10) {
                        showPaymentMethodSheetButton
                        
                        Button {
                            showCategorySheet = true
                            TouchAndHoldMonthToFilterCategoriesTip.didSelectCategoryFilter = true
                            touchAndHoldMonthToFilterCategoriesTip.invalidate(reason: .actionPerformed)
                        } label: {
                            HStack(spacing: 2) {
                                if !calModel.sCategories.isEmpty {
                                    var categoryFilterTitle: String {
                                        let cats = calModel.sCategories
                                        if cats.isEmpty {
                                            return ""
                                            
                                        } else if cats.count == 1 {
                                            return cats.first!.title
                                            
                                        } else if cats.count == 2 {
                                            return "\(cats[0].title), \(cats[1].title)"
                                            
                                        } else {
                                            return "\(cats[0].title), \(cats[1].title), \(cats.count - 2)+"
                                        }
                                    }
                                    
                                    Text("(\(categoryFilterTitle))")
                                        .italic()
                                } else {
                                    Text("Categories")
                                }
                            }
                            //.font(.callout)
                            //.foregroundStyle(.gray)
                            .contentShape(Rectangle())
                        }
                    
                        
                        
                        
                    }
                }
            }
        }
        
        
        ToolbarItemGroup(placement: .topBarTrailing) {
            @Bindable var calModel = calModel
            HStack(spacing: 20) {
                
                if (!showSearchBar && AppState.shared.isIpad) || !AppState.shared.isIpad{
                    if calModel.showLoadingSpinner {
                        ProgressView()
                            .tint(.none)
                    }
                    
                    if AppState.shared.longPollFailed {
                        longPollToolbarButton
                    }
                    
                    if !calModel.fitTrans.filter({ !$0.isAcknowledged }).isEmpty {
                        if AppState.shared.user?.id == 1 {
                            Button {
                                withAnimation {
                                    showFitTransactions = true
                                }
                            } label: {
                                Image(systemName: "clock.badge.exclamationmark")
                                    .foregroundStyle(Color.fromName(appColorTheme) == .orange ? .red : .orange)
                            }
                        }
                    }
                    
                    Menu {
                        Section("Analytics") {
                            budgetSheetButton
                            analysisSheetButton
                        }
                        
                        Section {
                            startingAmountSheetButton
                        }
                        
                        Section {
                            refreshButton
                            settingsSheetButton
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(Color.accentColor)
                    }
                    
                    searchButton
                    
                    Menu {
                        Section("Create") {
                            newTransactionButton
                            newTransferButton
                        }
                        
                        Section("Receipts") {
                            takePhotoButton
                            selectPhotoButton
                        }
                    } label: {
                        Image(systemName: "plus")
                    } primaryAction: {
                        transEditID = UUID().uuidString
                    }
                    .popoverTip(touchAndHoldPlusButtonTip)
                    .opacity(calModel.chatGptIsThinking ? 0 : 1)
                    .overlay {
                        ProgressView()
                            .opacity(calModel.chatGptIsThinking ? 1 : 0)
                            .tint(.none)
                    }
                }
                
                
                if showSearchBar && AppState.shared.isIpad {
                    HStack(spacing: 0) {
                        @Bindable var calModel = calModel
                        
                        Picker("", selection: $calModel.searchWhat) {
                            Text("Title")
                                .tag(CalendarSearchWhat.titles)
                            Text("Tag")
                                .tag(CalendarSearchWhat.tags)
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        
                        StandardTextField(
                            "Search \(calModel.searchWhat == .titles ? "Transaction Titles" : "Transaction Tags")",
                            text: $calModel.searchText,
                            isSearchField: true,
                            alwaysShowCancelButton: true,
                            focusedField: $focusedField,
                            focusValue: 0,
                            onSubmit: { withAnimation { showSearchBar = false } },
                            onCancel: { withAnimation { showSearchBar = false } }
                        )
                    }
                    .offset(x: showSearchBar ? 0 : -200)
                    //.opacity(showSearchBar ? 1 : 0)
                    .transition(.move(edge: .trailing))
                    .frame(maxWidth: showSearchBar ? .infinity : 0)
                }
                
                
                
                
            
            }
//            .frame(maxWidth: .infinity)
//            .opacity(showSearchBar ? 0 : 1)
//            .overlay {
//                
//            }
        }
    }
    
    var backButton: some View {
        Group {
            //@Bindable var navManager = NavigationManager.shared
            Button {
                //navManager.navPath.removeLast()
                dismiss()
                //NavigationManager.shared.monthSelection = nil
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text(String(calModel.sYear))
                }
            }
        }
//        .onDisappear {
//            NavigationManager.shared.selection = nil
//        }
    }
    
    var longPollToolbarButton: some View {
        Button {
            let config = AlertConfig(
                title: "Attempting to resubscribe to multi-device updates",
                subtitle: "If this keeps failing please contact the developer.",
                symbol: .init(name: "ipad.and.iphone", color: .green)
            )
            AppState.shared.showAlert(config: config)
            
            Task {
                AppState.shared.longPollFailed = false
                await funcModel.downloadEverything(setDefaultPayMethod: true, createNewStructs: false, refreshTechnique: .viaButton)
                //funcModel.longPollServerForChanges()
            }
        } label: {
            Image(systemName: "ipad.and.iphone.slash")
                .foregroundStyle(Color.fromName(appColorTheme) == .red ? .orange : .red)
        }
    }
    
    var showPaymentMethodSheetButton: some View {
        Button {
            showPaymentMethodSheet = true
        } label: {
            Text("\(calModel.sPayMethod?.title ?? "")")
        }
    }
    
    var budgetSheetButton: some View {
        Button {
            showBudgetSheet = true
        } label: {
            HStack {
                Label {
                    Text("Budget")
                } icon: {
                    Image(systemName: "chart.pie")
                }
            }
        }
    }
    
    var startingAmountSheetButton: some View {
        Button {
            for meth in payModel.paymentMethods.filter({ !$0.isUnified }) {
                calModel.prepareStartingAmount(for: meth)
            }
            showStartingAmountsSheet = true
        } label: {
            Label {
                Text("B.O.M. Balances")
            } icon: {
                Image(systemName: "dollarsign.circle")
            }
        }
    }
    
    var refreshButton: some View {
        Button {
            funcModel.refreshTask?.cancel()
            funcModel.refreshTask = Task {
                calModel.prepareForRefresh()
                let targetDay = calModel.sMonth.days.filter { $0.dateComponents?.day == AppState.shared.todayDay }.first
                selectedDay = targetDay
                                
                await funcModel.downloadEverything(setDefaultPayMethod: false, createNewStructs: true, refreshTechnique: .viaButton)
            }
        } label: {
            Label {
                Text("Refresh")
            } icon: {
                Image(systemName: "arrow.triangle.2.circlepath")
            }
        }
    }
    
    var analysisSheetButton: some View {
        Button {
            showAnalysisSheet = true
        } label: {
            Label {
                Text("Analyze Categories")
            } icon: {
                Image(systemName: "brain")
            }
        }
    }
    
    var settingsSheetButton: some View {
        Button {
            //showInfo()
            currentPhoneLineItemDisplayItem = phoneLineItemDisplayItem
            showCalendarOptionsSheet = true
        } label: {
            Label {
                Text("Settings")
            } icon: {
                Image(systemName: "gear")
                //Image(systemName: "sidebar.right")
            }
        }
    }
    
    var searchButton: some View {
        Button {
            withAnimation {
                showSearchBar.toggle()
                //searchFocus.wrappedValue = 0 /// 0 is the searchFields focusID
                
                if AppState.shared.isIpad {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                        focusedField = 0 /// 0 is the searchFields focusID
                    })
                } else {
                    focusedField = 0 /// 0 is the searchFields focusID
                }
                        
                //focusedField.wrappedValue = .search
            }
//            completion: {
//                focusedField = 0 /// 0 is the searchFields focusID
//            }
        } label: {
            Label {
                Text("Search")
            } icon: {
                Image(systemName: "magnifyingglass")
            }
        }
        .tint(calModel.searchText.isEmpty ? Color.fromName(appColorTheme) : Color.fromName(appColorTheme) == .orange ? .red : .orange)
        .scaleEffect(!calModel.searchText.isEmpty ? 1.2 : 1)
        .animation(!calModel.searchText.isEmpty ? .easeInOut(duration: 1).repeatForever(autoreverses: true) : .default, value: calModel.searchText.isEmpty )
    }
    
    var newTransactionButton: some View {
        Button {
            transEditID = UUID().uuidString
            TouchAndHoldPlusButtonTip.didSelectSmartReceiptOrTransferOption = true
            touchAndHoldPlusButtonTip.invalidate(reason: .actionPerformed)
        } label: {
            Label {
                Text("New Transaction")
            } icon: {
                Image(systemName: "plus")
            }
        }
    }
    
    var newTransferButton: some View {
        Button {
            showTransferSheet = true
            TouchAndHoldPlusButtonTip.didSelectSmartReceiptOrTransferOption = true
            touchAndHoldPlusButtonTip.invalidate(reason: .actionPerformed)
        } label: {
            Label {
                Text("New Transfer")
            } icon: {
                Image(systemName: "arrowshape.turn.up.forward.fill")
            }
        }
    }
    
    var takePhotoButton: some View {
        Button {
            let newID = UUID().uuidString
            calModel.pendingSmartTransaction = CBTransaction(uuid: newID)
            calModel.pictureTransactionID = newID
            showCamera = true
            TouchAndHoldPlusButtonTip.didSelectSmartReceiptOrTransferOption = true
            touchAndHoldPlusButtonTip.invalidate(reason: .actionPerformed)
        } label: {
            Label {
                Text("Take Photo")
            } icon: {
                Image(systemName: "camera")
            }
        }
    }
    
    var selectPhotoButton: some View {
        Button {
            let newID = UUID().uuidString
            calModel.pendingSmartTransaction = CBTransaction(uuid: newID)
            calModel.pictureTransactionID = newID
            showPhotosPicker = true
            TouchAndHoldPlusButtonTip.didSelectSmartReceiptOrTransferOption = true
            touchAndHoldPlusButtonTip.invalidate(reason: .actionPerformed)
        } label: {
            Label {
                Text("Photo Library")
            } icon: {
                Image(systemName: "photo.badge.plus")
            }
        }
    }
                
    var fakeNavHeader: some View {
        HStack {
            @Bindable var calModel = calModel
            Menu {
                Section("Payment Methods") {
                    Button(calModel.sPayMethod?.title ?? "Select Payment Method") {
                        showPaymentMethodSheet = true
                    }
                }
                
                Section("Optional Filter By Categories") {
                    Button(calModel.sCategory?.title ?? "Select Categories") {
                        showCategorySheet = true
                        TouchAndHoldMonthToFilterCategoriesTip.didSelectCategoryFilter = true
                        touchAndHoldMonthToFilterCategoriesTip.invalidate(reason: .actionPerformed)
                    }
                    
                    if !calModel.sCategories.isEmpty {
                        Button("Reset", role: .destructive) {
                            calModel.sCategories.removeAll()
                        }
                    }
                }
            } label: {
                VStack(alignment: .leading, spacing: 0) {
                    Text("\(calModel.sMonth.name)\(calModel.sMonth.year == calModel.sYear ? "" : " \(calModel.sMonth.year)")")
                        .font(.largeTitle)
                        .bold()
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                        .lineLimit(1)
                    
                    HStack(spacing: 2) {
                        Text("\(calModel.sPayMethod?.title ?? "")")
                        
                        if !calModel.sCategories.isEmpty {
                            var categoryFilterTitle: String {
                                let cats = calModel.sCategories
                                if cats.isEmpty {
                                    return ""
                                    
                                } else if cats.count == 1 {
                                    return cats.first!.title
                                    
                                } else if cats.count == 2 {
                                    return "\(cats[0].title), \(cats[1].title)"
                                    
                                } else {
                                    return "\(cats[0].title), \(cats[1].title), \(cats.count - 2)+"
                                }
                            }
                            
                            Text("(\(categoryFilterTitle))")
                                .italic()
                        }
                                                
                        Image(systemName: "chevron.right")
                    }
                    .font(.callout)
                    .foregroundStyle(.gray)
                    .contentShape(Rectangle())
                }
                .popoverTip(touchAndHoldMonthToFilterCategoriesTip)
                
            } primaryAction: {
                showPaymentMethodSheet = true
            }
            .layoutPriority(1)
            .padding(.leading, 16)
            .padding(.bottom, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
            
//            HStack(spacing: 15) {
//                Button {
//                    var prev: NavDestination? {
//                        switch calModel.sMonth.enumID {
//                        case .lastDecember: return nil
//                        case .january:      return .lastDecember
//                        case .february:     return .january
//                        case .march:        return .february
//                        case .april:        return .march
//                        case .may:          return .april
//                        case .june:         return .may
//                        case .july:         return .june
//                        case .august:       return .july
//                        case .september:    return .august
//                        case .october:      return .september
//                        case .november:     return .october
//                        case .december:     return .november
//                        case .nextJanuary:  return .december
//                        default:            return nil
//                        }
//                    }
//                    
//                    if let prev = prev {
//                        //NavigationManager.shared.navPath = [prev]
//                        NavigationManager.shared.monthSelection = prev
//                        SwipeToChangeMonthsTip.didChangeViaSwipe = true
//                        swipeToChangeMonthsTip.invalidate(reason: .actionPerformed)
//                    }
//                } label: {
//                    Image(systemName: "chevron.left")
//                }
//                
//                Button {
//                    var next: NavDestination? {
//                        switch calModel.sMonth.enumID {
//                        case .lastDecember: return .january
//                        case .january:      return .february
//                        case .february:     return .march
//                        case .march:        return .april
//                        case .april:        return .may
//                        case .may:          return .june
//                        case .june:         return .july
//                        case .july:         return .august
//                        case .august:       return .september
//                        case .september:    return .october
//                        case .october:      return .november
//                        case .november:     return .december
//                        case .december:     return .nextJanuary
//                        case .nextJanuary:  return nil
//                        default:            return nil
//                        }
//                    }
//                    
//                    if let next = next {
//                        //NavigationManager.shared.navPath = [next]
//                        NavigationManager.shared.monthSelection = next
//                        SwipeToChangeMonthsTip.didChangeViaSwipe = true
//                        swipeToChangeMonthsTip.invalidate(reason: .actionPerformed)
//                    }
//                } label: {
//                    Image(systemName: "chevron.right")
//                }
//            }
//            .padding(.trailing, 16)
//            .padding(.bottom, 4)
            
            

            
        }
        //.background(.ultraThinMaterial)
        .padding(.bottom, 10)
        .contentShape(Rectangle())
        
        
//        .gesture(DragGesture()
//            .onEnded { value in
//                let dragAmount = value.translation.width
//                if dragAmount < -200 {
//                    var next: NavDestination? {
//                        switch calModel.sMonth.enumID {
//                        case .lastDecember: return .january
//                        case .january:      return .february
//                        case .february:     return .march
//                        case .march:        return .april
//                        case .april:        return .may
//                        case .may:          return .june
//                        case .june:         return .july
//                        case .july:         return .august
//                        case .august:       return .september
//                        case .september:    return .october
//                        case .october:      return .november
//                        case .november:     return .december
//                        case .december:     return .nextJanuary
//                        case .nextJanuary:  return nil
//                        default:            return nil
//                        }
//                    }
//                    
//                    if let next = next {
//                        NavigationManager.shared.monthSelection = next
//                        //NavigationManager.shared.navPath = [next]
//                        SwipeToChangeMonthsTip.didChangeViaSwipe = true
//                        swipeToChangeMonthsTip.invalidate(reason: .actionPerformed)
//                    }
//                                        
//                } else if dragAmount > 200 {
//                    var prev: NavDestination? {
//                        switch calModel.sMonth.enumID {
//                        case .lastDecember: return nil
//                        case .january:      return .lastDecember
//                        case .february:     return .january
//                        case .march:        return .february
//                        case .april:        return .march
//                        case .may:          return .april
//                        case .june:         return .may
//                        case .july:         return .june
//                        case .august:       return .july
//                        case .september:    return .august
//                        case .october:      return .september
//                        case .november:     return .october
//                        case .december:     return .november
//                        case .nextJanuary:  return .december
//                        default:            return nil
//                        }
//                    }
//                    
//                    if let prev = prev {
//                        NavigationManager.shared.monthSelection = prev
//                        //NavigationManager.shared.navPath = [prev]
//                        SwipeToChangeMonthsTip.didChangeViaSwipe = true
//                        swipeToChangeMonthsTip.invalidate(reason: .actionPerformed)
//                    }
//                }
//            }
//        )
    }
    
    var searchBarOverlay: some View {
        VStack {
            @Bindable var calModel = calModel
            VStack {
                /// Opting for this since using ``StandardUITextField`` won't close the keyboard when clicking the return button.
                /// I also don't need the toolbar for this textField.
                StandardTextField(
                    "Search \(calModel.searchWhat == .titles ? "Transaction Titles" : "Transaction Tags")",
                    text: $calModel.searchText,
                    isSearchField: true,
                    alwaysShowCancelButton: true,
                    focusedField: $focusedField,
                    focusValue: 0,
                    onSubmit: { withAnimation { showSearchBar = false } },
                    onCancel: { withAnimation { showSearchBar = false } }
                )
                Picker("", selection: $calModel.searchWhat) {
                    Text("Title")
                        .tag(CalendarSearchWhat.titles)
                    Text("Tag")
                        .tag(CalendarSearchWhat.tags)
                }
                .labelsHidden()
                .pickerStyle(.segmented)
            }            
            .padding(.horizontal, 10)
            .padding(.bottom, 10)
            //.focused($focusedField, equals: .search)
            .background(.ultraThickMaterial)
            
            Spacer()
        }
        //.animation(.easeOut, value: showSearchBar)
        
        //.opacity(showSearchBar ? 1 : 0)
        .offset(y: showSearchBar ? 0 : -200)
        .transition(.move(edge: .top))

    }
}

#endif
