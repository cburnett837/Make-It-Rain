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

enum BottomPanelContent {
    case overviewDay, fitTransactions, smartTransactionsWithIssues, categoryAnalysis, multiSelectOptions, plaidTransactions, transactionList
}

#if os(iOS)
struct CalendarViewPhone: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    @Local(\.colorTheme) var colorTheme
    @Local(\.useWholeNumbers) var useWholeNumbers
    @Local(\.threshold) var threshold
    
    @AppStorage("lineItemIndicator") var lineItemIndicator: LineItemIndicator = .emoji
    @AppStorage("updatedByOtherUserDisplayMode") var updatedByOtherUserDisplayMode = UpdatedByOtherUserDisplayMode.full
    @AppStorage("phoneLineItemDisplayItem") var phoneLineItemDisplayItem: PhoneLineItemDisplayItem = .both
            
    @Environment(FuncModel.self) var funcModel
    @Environment(CalendarModel.self) private var calModel
    @Environment(PayMethodModel.self) private var payModel
    @Environment(CategoryModel.self) private var catModel
    @Environment(KeywordModel.self) private var keyModel
    @Environment(EventModel.self) private var eventModel
    @Environment(PlaidModel.self) private var plaidModel
    
    let enumID: NavDestination
    
    #warning("NOTE BINDINGS ARE NOT ALLOWED TO BE PASSED TO THE CALENDAR VIEW")
    let touchAndHoldPlusButtonTip = TouchAndHoldPlusButtonTip()
    let touchAndHoldMonthToFilterCategoriesTip = TouchAndHoldMonthToFilterCategoriesTip()
    
    let sevenColumnGrid = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    @FocusState private var focusedField: Int?
    
    @State private var showSearchBar = false
    @State private var selectedDay: CBDay?
    @State private var transEditID: String?
    @State private var editTrans: CBTransaction?
    
    @State private var overviewDay: CBDay?
    @State private var scrollHeight: CGFloat = 0
    @State private var bottomPanelHeight: CGFloat = 300
    @State private var scrollContentMargins: CGFloat = 300
    //@State private var scrollPosition = ScrollPosition(idType: CBDay.ID.self)
    
    @State private var showTransferSheet = false
    @State private var showPayMethodSheet = false
    @State private var showCategorySheet = false
    @State private var showBudgetSheet = false
    @State private var showCalendarOptionsSheet = false
    //@State private var showStartingAmountsSheet = false
    @State private var showAnalysisSheet = false
    @State private var showTransactionListSheet = false
    @State private var showPhotosPicker = false
    @State private var showCamera = false
    @State private var showSideBar = false
    //@State private var showMultiSelectSummarySheet = false
    
    @State private var bottomPanelContent: BottomPanelContent?
                
    @State private var findTransactionWhere = WhereToLookForTransaction.normalList
    
    @State private var editLock = false
    
    @State private var timeSinceLastBalanceUpdate: String = ""
    @State private var lastBalanceUpdateTimer: Timer?
    
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
    
    var calendarBackground: some View {
        AppState.shared.isIpad && (showAnalysisSheet || bottomPanelContent != nil)
        ? colorScheme == .dark
        ? Color.darkGray3.ignoresSafeArea(.all)
        : Color(UIColor.systemGray6).ignoresSafeArea(.all)
        : colorScheme == .dark ? Color.black.ignoresSafeArea(.all) : Color.white.ignoresSafeArea(.all)
    }
    
    var calculatedScrollContentMargins: CGFloat {
        return (bottomPanelContent == nil || AppState.shared.isIpad) ? 0 : scrollContentMargins
    }
    
    var monthText: String {
        "\(calModel.sMonth.name)\(calModel.sMonth.year == calModel.sYear ? "" : " \(calModel.sMonth.year)")"
    }
    
    var paymentMethodText: String {
        //"\(calModel.sPayMethod?.title ?? "") (\(calModel.sMonth.startingAmounts.filter {$0.payMethod.id == calModel.sPayMethod?.id}.first?.amountString ?? ""))"
        "\(calModel.sPayMethod?.title ?? "") "
    }
            
    var body: some View {
        //let _ = Self._printChanges()
        @Bindable var navManager = NavigationManager.shared
        @Bindable var calModel = calModel
        @Bindable var photoModel = PhotoModel.shared
        
        NavigationStack {
            Group {
                if calModel.sMonth.enumID == enumID {
                    HStack(spacing: 0) {
                        VStack {
                            if AppState.shared.isIpad {
                                fakeToolbar
                            }
                            calendarView
                        }
                        .background(calendarBackground)
                        
                        if AppState.shared.isIpad {
                            iPadSideBar
                        }
                    }
                } else {
                    ProgressView()
                        .transition(.opacity)
                        .tint(.none)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            
            .if(AppState.shared.isIpad) { $0.toolbar(.hidden) }
            .if(!AppState.shared.isIpad) { $0.toolbar { calendarToolbar() } }
            //.toolbar { calendarToolbar() }
            .onChange(of: calModel.sPayMethod, initial: true) { oldValue, newValue in
                if let balance = plaidModel.balances.filter({ $0.payMethodID == newValue?.id }).first {
                    //timeSinceLastBalanceUpdate = Date().timeSince(balance.lastTimeICheckedPlaidSyncedDate)
                    timeSinceLastBalanceUpdate = Date().timeSince(balance.lastTimePlaidSyncedWithInstitutionDate)
                }
                
                /// Keep the displayed time ago up to date.
                self.lastBalanceUpdateTimer?.invalidate()
                self.lastBalanceUpdateTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
                    Task { @MainActor in
                        if let balance = plaidModel.balances.filter({ $0.payMethodID == calModel.sPayMethod?.id }).first {
                            //timeSinceLastBalanceUpdate = Date().timeSince(balance.lastTimeICheckedPlaidSyncedDate)
                            timeSinceLastBalanceUpdate = Date().timeSince(balance.lastTimePlaidSyncedWithInstitutionDate)
                        }
                    }
                }
            }
            .onDisappear {
                lastBalanceUpdateTimer?.invalidate()
            }
                        
            /// Using this instead of a task because the iPad doesn't reload `CalendarView`. It just changes the data source.
            .onChange(of: enumID, initial: true, onChangeOfMonthEnumID)
            
            .onShake {
                /// Prevent shake to reset from happening when viewing the month via the analytic page.
                if !calModel.categoryFilterWasSetByCategoryPage {
                    resetMonthState()
                }
            }
            
            /// This exists in 2 place - purely for visual effect. See ``LineItemView``
            /// This is needed (passing the ID instead of the trans) because you can close the popover without actually clicking the close button. So I need somewhere to do cleanup.
            
            .transactionEditSheetAndLogic(
                calModel: calModel,
                transEditID: $transEditID,
                editTrans: $editTrans,
                selectedDay: $selectedDay,
                overviewDay: $overviewDay,
                findTransactionWhere: $findTransactionWhere,
                presentTip: true,
                resetSelectedDayOnClose: true
            )
//            .onChange(of: transEditID) { transEditIdChanged(oldValue: $0, newValue: $1) }
//            .sensoryFeedback(.selection, trigger: transEditID) { $1 != nil }
//            .sheet(item: $editTrans) { trans in
//                TransactionEditView(trans: trans, transEditID: $transEditID, day: selectedDay!, isTemp: false)
//                    /// needed to prevent the view from being incorrect.
//                    .id(trans.id)
//                    /// This is needed for the drag to dismiss.
//                    .onDisappear {
//                        transEditID = nil
//                    }
//                    //.presentationSizing(.page)
//            }
            .if(!AppState.shared.isIpad) {
                $0
                .sheet(isPresented: $showAnalysisSheet) {
                    AnalysisSheet(showAnalysisSheet: $showAnalysisSheet)
                }
                .sheet(isPresented: $showTransactionListSheet) {
                    TransactionListView(showTransactionListSheet: $showTransactionListSheet)
                }
            }
            .sheet(isPresented: $showCalendarOptionsSheet) {
                CalendarOptionsSheet(selectedDay: $selectedDay)
            }
            .sheet(isPresented: $showPayMethodSheet) {
                TouchAndHoldMonthToFilterCategoriesTip.didTouchMonthName.sendDonation()
                startingAmountSheetDismissed()
            } content: {
                PayMethodSheet(payMethod: $calModel.sPayMethod, whichPaymentMethods: .all, showStartingAmountOption: true)
            }
            .sheet(isPresented: $showCategorySheet) {
                MultiCategorySheet(categories: $calModel.sCategories)
            }
            .sheet(isPresented: $showTransferSheet) {
                TransferSheet(date: selectedDay?.date ?? Date())
            }
            .sheet(isPresented: $showBudgetSheet) {
                BudgetTable()
                    //.presentationSizing(.page)
            }
//            .sheet(isPresented: $showStartingAmountsSheet, onDismiss: startingAmountSheetDismissed) {
//                StartingAmountSheet()
//            }
            /// Only allow 1 photo since this is happening only for smart transactions.
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
                                    
            .onReceive(AppState.shared.currentDateTimer) { input in
                let isDayChange = AppState.shared.setNow()
                #if os(iOS)
                /// If on iPhone, and the day changes, change the selected day as well otherwise it will be blank on day change and cause a crash.
                if isDayChange {
                    if let month = calModel.months.filter({ $0.num == AppState.shared.todayMonth && $0.year == AppState.shared.todayYear }).first {
                        if let day = month.days.filter({ $0.dateComponents?.day == AppState.shared.todayDay }).first {
                            selectedDay = day
                        }
                    }
                }
                #endif
            }
        }
        .disableZoomeInteractiveDismiss()
        .overlay {
            if (!AppState.shared.isIpad) {
                searchBarOverlay
            }
        }
        /// This can't be a sheet because...
        /// 1. It will lag when resizing due to the scroll content margins changing. ---> (This will only work if you do the passThrough window thing to the calendar view.)
        /// 2. It will dismiss when other sheets open (payMethod, settings, etc).
        .overlay {
            Group {
                if !AppState.shared.isIpad {
                    if let content = bottomPanelContent {
                        BottomPanelContainerView($bottomPanelHeight) {
                            switch content {
                            case .overviewDay:
                                DayOverviewView(
                                    day: $overviewDay,
                                    selectedDay: $selectedDay,
                                    transEditID: $transEditID,
                                    showTransferSheet: $showTransferSheet,
                                    showCamera: $showCamera,
                                    showPhotosPicker: $showPhotosPicker,
                                    bottomPanelHeight: $bottomPanelHeight,
                                    scrollContentMargins: $scrollContentMargins,
                                    bottomPanelContent: $bottomPanelContent
                                )
                                
                            case .fitTransactions:
                                FitTransactionOverlay(
                                    bottomPanelContent: $bottomPanelContent,
                                    bottomPanelHeight: $bottomPanelHeight,
                                    scrollContentMargins: $scrollContentMargins
                                )
                                
                            case .plaidTransactions:
                                PlaidTransactionOverlay(
                                    bottomPanelContent: $bottomPanelContent,
                                    bottomPanelHeight: $bottomPanelHeight,
                                    scrollContentMargins: $scrollContentMargins
                                )
                                
                            case .smartTransactionsWithIssues:
                                SmartTransactionsWithIssuesOverlay(
                                    bottomPanelContent: $bottomPanelContent,
                                    transEditID: $transEditID,
                                    findTransactionWhere: $findTransactionWhere,
                                    bottomPanelHeight: $bottomPanelHeight,
                                    scrollContentMargins: $scrollContentMargins
                                )
                            case .multiSelectOptions:
                                MultiSelectTransactionOptionsSheet(
                                    bottomPanelContent: $bottomPanelContent,
                                    bottomPanelHeight: $bottomPanelHeight,
                                    scrollContentMargins: $scrollContentMargins,
                                    showAnalysisSheet: $showAnalysisSheet
                                )
                            
                            case .transactionList:
                                EmptyView()
                            
                            case .categoryAnalysis:
                                EmptyView()
                            }
                        }
                    }
                }
            }
        }
//        /// Reset the overviewDay if change from a day overview to another overlay.
//        .onChange(of: bottomPanelContent) { oldValue, newValue in
//            if oldValue == .overviewDay && newValue != nil {
//                overviewDay = nil
//                let targetDay = calModel.sMonth.days.filter { $0.dateComponents?.day == (calModel.sMonth.num == AppState.shared.todayMonth ? AppState.shared.todayDay : 1) }.first
//                selectedDay = targetDay
//            }
//            
//            if newValue == nil {
//                scrollContentMargins = 300
//            }
//        }
    }
    
    
    
    
    // MARK: - Calendar Views
    var calendarView: some View {
        Group {
            VStack(spacing: 0) {
                if !AppState.shared.isLandscape {
                    fakeNavHeader
                        .dropDestination(for: CBTransaction.self) { droppedTrans, location in
                            calModel.dragTarget = nil
                            return true
                        }
                }
                
                Group {
                    weekdayNameGrid
                    calendarGrid
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation {
                        calModel.hilightTrans = nil
                    }
                }
            }
        }
    }
    
    
    var weekdayNameGrid: some View {
        LazyVGrid(columns: sevenColumnGrid, spacing: 0) {
            ForEach(days, id: \.self) { name in
                Text(name)
                    .frame(maxWidth: .infinity, alignment: AppState.shared.isIpad ? .leading : .center)
                    //.frame(maxWidth: .infinity)
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                    .padding(.leading, AppState.shared.isIpad ? 6 : 0)
            }
        }
        .padding(.bottom, 4)
        .overlay(dividingLine, alignment: .bottom)
    }
    
    
    var dividingLine: some View {
        Rectangle()
            .frame(width: nil, height: 2, alignment: .bottom)
            .foregroundColor(Color(.tertiarySystemFill))
    }
    
    
    var calendarGrid: some View {
        @Bindable var calModel = calModel
        
        /// Use geometry reader instead of a preference key to avoid the fakeNavHeader from being pushed up when the dayOverView sheet gets dragged to the top.
        return GeometryReader { geo in
            /// DO NOT USE the new scrollView apis.
            /// The new .scrollPosition($scrollPosition) causes big lagging issues when scrolling. --->I think it's because it has to constantly report its position.
            ScrollViewReader { scrollProxy in
                ScrollView {
                    LazyVGrid(columns: sevenColumnGrid, spacing: 0) {
                        ForEach($calModel.sMonth.days) { $day in
                            DayViewPhone(
                                transEditID: $transEditID,
                                day: $day,
                                selectedDay: $selectedDay,
                                showTransferSheet: $showTransferSheet,
                                showPhotosPicker: $showPhotosPicker,
                                showCamera: $showCamera,
                                overviewDay: $overviewDay,
                                bottomPanelContent: $bottomPanelContent
                            )
                            .overlay(dividingLine, alignment: .bottom)
                            .frame(minHeight: geo.size.height / divideBy, alignment: .center)
                            .id(day.id)
                        }
                    }
                }
                .contentMargins(.bottom, calculatedScrollContentMargins, for: .scrollContent)
                .frame(height: geo.size.height)
                .scrollIndicators(.hidden)
                .onScrollPhaseChange { if $1 == .interacting { withAnimation { calModel.hilightTrans = nil } } }
                /// Scroll to today when the view loads (if applicable)
                .onAppear { scrollToTodayOnAppearOfScrollView(scrollProxy) }
                /// Focus on the overviewDay when selecting, or changing.
                .onChange(of: overviewDay) { scrollToOverViewDay(scrollProxy, $0, $1) }
                /// Focus on the overview day when resizing the bottom panel.
                .onChange(of: calculatedScrollContentMargins) {
                    if let day = overviewDay {
                        print(".onChange(of: calculatedScrollContentMargins) - adjusting scroll to day \(day.id)")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation { scrollProxy.scrollTo(day.id, anchor: .bottom) }
                        }
                    } else {
                        print(".onChange(of: calculatedScrollContentMargins) - ignoring")
                    }
                }
                .onChange(of: bottomPanelContent) { oldValue, newValue in
                    if oldValue == .overviewDay && newValue != nil {
                        overviewDay = nil
                        let targetDay = calModel.sMonth.days.filter { $0.dateComponents?.day == (calModel.sMonth.num == AppState.shared.todayMonth ? AppState.shared.todayDay : 1) }.first
                        selectedDay = targetDay
                    }
                    
                    if newValue == nil {
                        scrollContentMargins = 300
                        //scrollProxy.scrollTo(calModel.sMonth.days.last?.id ?? 0, anchor: .bottom)
                        
                        if calModel.isInMultiSelectMode {
                            bottomPanelContent = .multiSelectOptions
                        }
                    }
                }
            }
        }
//        .viewHeightObserver()
//        .onPreferenceChange(ViewHeightKey.self) { print("Setting scrollview \($0)"); scrollHeight = $0 }
    }
    
    
    func scrollToTodayOnAppearOfScrollView(_ proxy: ScrollViewProxy) {
        if enumID.monthNum == AppState.shared.todayMonth {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    proxy.scrollTo(AppState.shared.todayDay, anchor: .bottom)
                }
            }
        }
    }
    
    func scrollToOverViewDay(_ proxy: ScrollViewProxy, _ oldValue: CBDay?, _ newValue: CBDay?) {
        print("-- \(#function)")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if let day = newValue {
                print("\(#function) -- new overView day is set")
                /// Block this from running since .onChange(of: calculatedScrollContentMargins) will also run when opening the day for the first time.
                if oldValue != nil {
                    print("\(#function) -- adjusting day to \(day.id)")
                    withAnimation {
                        proxy.scrollTo(day.id, anchor: .bottom)
                    }
                } else {
                    print("\(#function) -- ignoring because oldValue is nil")
                }
                
            } else if let oldViewDay = oldValue {
                print("\(#function) -- old overView say is set - adjusting day to \(oldViewDay.id)")
                withAnimation { proxy.scrollTo(oldViewDay.id, anchor: .bottom) }
            } else {
                print("\(#function) -- Can't find overview day")
            }
        }
    }
    
    
    // MARK: - Toolbar Views
    var fakeToolbar: some View {
        HStack {
            HStack(spacing: 20) {
                /// Show back button if is iPhone, or is iPad being showing in a sheet. (LIke when accessing the calendar from the category view)
                if (!AppState.shared.isIpad) || (AppState.shared.isIpad && calModel.isShowingFullScreenCoverOnIpad){
                    backButton
                } else {
                    if (AppState.shared.isIpad && !calModel.isShowingFullScreenCoverOnIpad && NavigationManager.shared.columnVisibility != .all) {
                        sidebarButtonIpad
                    }
                }
                
                /// Show payment method and category buttons when is iPad in landscape mode.
                if AppState.shared.isIpad && AppState.shared.isLandscape {
                    showPayMethodSheetButton
                        .contentShape(Rectangle())
                    categorySheetButtonIpad
                        .contentShape(Rectangle())
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            monthName
            
            HStack(spacing: 27) {
                if showSearchBar && AppState.shared.isIpad {
                    searchBarOverlayIpad
                } else {
                    if (!showSearchBar && AppState.shared.isIpad) || !AppState.shared.isIpad {
                        if calModel.showLoadingSpinner {
                            ProgressView()
                                .tint(.none)
                        }
                                                               
                        smartTransactionWithIssuesButton
                            .font(.title2)
                        ToolbarLongPollButton()
                            .font(.title2)
                        plaidTransactionButton
                            .font(.title2)
                                                                                                                        
                        moreMenu
                        
                        searchButton
                            .font(.title2)
                        
                        
                        
                        NewTransactionMenuButton(transEditID: $transEditID, showTransferSheet: $showTransferSheet, showPhotosPicker: $showPhotosPicker, showCamera: $showCamera)
                        
//                        Menu {
//                            Section("Create") {
//                                newTransactionButton
//                                newTransferButton
//                            }
//                            
//                            Section("Smart Receipts") {
//                                takePhotoButton
//                                selectPhotoButton
//                            }
//                        } label: {
//                            Image(systemName: "plus")
//                                .font(.title2)
//                                .contentShape(Rectangle())
//                        } primaryAction: {
//                            transEditID = UUID().uuidString
//                        }
//                        .popoverTip(touchAndHoldPlusButtonTip)
//                        .opacity(calModel.chatGptIsThinking ? 0 : 1)
//                        .overlay {
//                            ProgressView()
//                                .opacity(calModel.chatGptIsThinking ? 1 : 0)
//                                .tint(.none)
//                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 20)
        /// The buttons in the trailing edge don't seem to be touchable without this background...
        //.background(colorScheme == .dark ? Color.black : Color.white)
        //.background(Color.red.ignoresSafeArea(.all))
    }
         
    
    @ToolbarContentBuilder
    func calendarToolbar() -> some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            HStack(spacing: 10) {
                /// Show back button if is iPhone, or is iPad being showing in a sheet. (LIke when accessing the calendar from the category view)
                if (!AppState.shared.isIpad) || (AppState.shared.isIpad && calModel.isShowingFullScreenCoverOnIpad) {
                    backButton
                } else {
//                    if (AppState.shared.isIpad && !calModel.isShowingFullScreenCoverOnIpad) {
//                        Button {
//                            withAnimation {
//                                NavigationManager.shared.columnVisibility = NavigationManager.shared.columnVisibility == .all ? .detailOnly : .all
//                            }
//                        } label: {
//                            Image(systemName: "sidebar.left")
//                        }
//                    }
                }
                
                /// Show payment method and category buttons when is iPad in landscape mode.
                if AppState.shared.isIpad && AppState.shared.isLandscape {
                    
                    showPayMethodSheetButton
                    
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
                        .contentShape(Rectangle())
                    }
                }
            }
        }
        
        if AppState.shared.isLandscape {
            ToolbarItemGroup(placement: .principal) {
                monthName
            }
        }
        
        ToolbarItemGroup(placement: .topBarTrailing) {
            @Bindable var calModel = calModel
            HStack(spacing: 20) {
                if (!showSearchBar && AppState.shared.isIpad) || !AppState.shared.isIpad {
                    if calModel.showLoadingSpinner {
                        ProgressView()
                            .tint(.none)
                    }
                    
                    ToolbarLongPollButton()
                    smartTransactionWithIssuesButton
                    plaidTransactionButton
                    
                    moreMenu
                    
                    searchButton
                    
                    NewTransactionMenuButton(transEditID: $transEditID, showTransferSheet: $showTransferSheet, showPhotosPicker: $showPhotosPicker, showCamera: $showCamera)
                    
                    //newTransactionMenu
//                    .opacity(calModel.chatGptIsThinking ? 0 : 1)
//                    .overlay {
//                        ProgressView()
//                            .opacity(calModel.chatGptIsThinking ? 1 : 0)
//                            .tint(.none)
//                    }
                    
//                    Button {
//                        withAnimation {
//                            showSideBar.toggle()
//                        }
//                    } label: {
//                        Image(systemName: "sidebar.right")
//                    }
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
//            .frame(maxWidth: .infinity)z
//            .opacity(showSearchBar ? 0 : 1)
//            .overlay {
//                
//            }
        }
    }
    
    
    var moreMenu: some View {
        Menu {
            Section("Analytics") {
                budgetSheetButton
                analysisSheetButton
            }            
//                        Section {
//                            startingAmountSheetButton
//                        }
            
            Section {
                transactionListSheetButton
                multiSelectButton
            }
            
            Section {
                refreshButton
                settingsSheetButton
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .foregroundStyle(Color.accentColor)
                .if(AppState.shared.isIpad) {
                    $0
                        .font(.title2)
                        .contentShape(Rectangle())
                }
        }
    }
    
//    var newTransactionMenu: some View {
//        Menu {
//            Section("Create") {
//                newTransactionButton
//                newTransferButton
//            }
//            
//            Section("Smart Receipts") {
//                takePhotoButton
//                selectPhotoButton
//            }
//        } label: {
//            Image(systemName: "plus")
//        } primaryAction: {
//            transEditID = UUID().uuidString
//        }
//        .popoverTip(touchAndHoldPlusButtonTip)
//    }
    
    
    var multiSelectButton: some View {
        Button {
            withAnimation {
                calModel.isInMultiSelectMode.toggle()
                bottomPanelContent = .multiSelectOptions
            }
        } label: {
            Label {
                Text("Multi-Select")
            } icon: {
                Image(systemName: "rectangle.and.hand.point.up.left.filled")
            }
        }
    }
    
    
    var smartTransactionWithIssuesButton: some View {
        Group {
            if !calModel.tempTransactions.filter({ $0.isSmartTransaction ?? false }).isEmpty {
                Button {
                    withAnimation {
                        bottomPanelContent = .smartTransactionsWithIssues
                        //showSmartTransactionsWithIssues = true
                    }
                } label: {
                    Image(systemName: "brain")
                        .foregroundStyle(Color.fromName(colorTheme) == .orange ? .red : .orange)
                }
            }
        }
    }
    
    
//    var fitTransactionButton: some View {
//        Group {
//            if !calModel.fitTrans.filter({ !$0.isAcknowledged }).isEmpty {
//                if AppState.shared.user?.id == 1 {
//                    Button {
//                        withAnimation {
//                            //showFitTransactions = true
//                            bottomPanelContent = .fitTransactions
//                        }
//                    } label: {
//                        Image(systemName: "clock.badge.exclamationmark")
//                            .foregroundStyle(Color.fromName(colorTheme) == .orange ? .red : .orange)
//                            .contentShape(Rectangle())
//                    }
//                }
//            }
//        }
//    }
    
    @ViewBuilder
    var plaidTransactionButton: some View {
//        Group {
//            if !plaidModel.trans.filter({ !$0.isAcknowledged }).isEmpty {
//                if AppState.shared.user?.id == 1 {
//                    Button {
//                        withAnimation {
//                            //showFitTransactions = true
//                            bottomPanelContent = .plaidTransactions
//                        }
//                    } label: {
//                        Image(systemName: "clock.badge.exclamationmark")
//                            .foregroundStyle(Color.fromName(colorTheme) == .orange ? .red : .orange)
//                            .contentShape(Rectangle())
//                    }
//                }
//            }
//        }
        
        var color: Color {
            plaidModel.trans.filter({ !$0.isAcknowledged }).isEmpty
            ? Color.secondary
            : Color.fromName(colorTheme) == .orange ? .red : .orange
        }
        
        Button {
            withAnimation {
                //showFitTransactions = true
                bottomPanelContent = .plaidTransactions
            }
        } label: {
            Image(systemName: "creditcard")
                .foregroundStyle(color)
                .contentShape(Rectangle())
        }
        
        
    }
    
    
    var monthName: some View {
        if calModel.sMonth.year != AppState.shared.todayYear {
            Text("\(enumID.displayName) \(String(calModel.sMonth.year))")
                .bold()
        } else {
            Text(enumID.displayName)
                .bold()
        }
    }
    
    
    var backButton: some View {
        Group {
            //@Bindable var navManager = NavigationManager.shared
            Button {
                //navManager.navPath.removeLast()
                calModel.isShowingFullScreenCoverOnIpad = false
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
    
    
    var showPayMethodSheetButton: some View {
        Button {
            showPayMethodSheet = true
        } label: {
            Text("\(calModel.sPayMethod?.title ?? "")")
        }
    }
    
    
    var categorySheetButtonIpad: some View {
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
            .contentShape(Rectangle())
        }
    }
    
    
    var budgetSheetButton: some View {
        Button {
            showBudgetSheet = true
        } label: {
            HStack {
                Label {
                    Text("Dashboard")
                } icon: {
                    Image(systemName: "chart.pie")
                }
            }
        }
    }
    
    
//    var startingAmountSheetButton: some View {
//        Button {
//            for meth in payModel.paymentMethods.filter({ !$0.isUnified }) {
//                calModel.prepareStartingAmount(for: meth)
//            }
//            showStartingAmountsSheet = true
//        } label: {
//            Label {
//                Text("B.O.M. Balances")
//            } icon: {
//                Image(systemName: "dollarsign.circle")
//            }
//        }
//    }
    
    
    var refreshButton: some View {
        Button {
            funcModel.isLoading = true
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
                    .symbolEffect(.rotate, options: SymbolEffectOptions.repeat(.continuous).speed(3), isActive: funcModel.isLoading)
            }
        }
        .disabled(funcModel.isLoading)
    }
    
    
    var analysisSheetButton: some View {
        Button {
            withAnimation {
                showAnalysisSheet = true
                if AppState.shared.isIpad {
                    bottomPanelContent = .categoryAnalysis
                }
            }
        } label: {
            Label {
                Text("Insights")
            } icon: {
                Image(systemName: "chart.bar.doc.horizontal")
            }
        }
    }
    
    
    var transactionListSheetButton: some View {
        Button {
            withAnimation {
                showTransactionListSheet = true
                if AppState.shared.isIpad {
                    bottomPanelContent = .transactionList
                }
            }
        } label: {
            Label {
                Text("Transaction List")
            } icon: {
                Image(systemName: "list.bullet")
            }
        }
    }
    
    
    var settingsSheetButton: some View {
        Button {
            showCalendarOptionsSheet = true
        } label: {
            Label {
                Text("Settings")
            } icon: {
                Image(systemName: "gear")
            }
        }
    }
    
    
    var searchButton: some View {
        Button {
            withAnimation {
                showSearchBar.toggle()
                //searchFocus.wrappedValue = 0 /// 0 is the searchFields focusID
                
                if AppState.shared.isIpad {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
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
            Image(systemName: "magnifyingglass")
                .tint(calModel.searchText.isEmpty ? Color.fromName(colorTheme) : Color.fromName(colorTheme) == .orange ? .red : .orange)
                .scaleEffect(!calModel.searchText.isEmpty ? 1.2 : 1)
                .animation(!calModel.searchText.isEmpty ? .easeInOut(duration: 1).repeatForever(autoreverses: true) : .default, value: calModel.searchText.isEmpty )
                .contentShape(Rectangle())
        }
    }
    
    
//    var newTransactionButton: some View {
//        Button {
//            transEditID = UUID().uuidString
//            TouchAndHoldPlusButtonTip.didSelectSmartReceiptOrTransferOption = true
//            touchAndHoldPlusButtonTip.invalidate(reason: .actionPerformed)
//        } label: {
//            Label {
//                Text("New Transaction")
//            } icon: {
//                Image(systemName: "plus")
//            }
//        }
//    }
//    
//    
//    var newTransferButton: some View {
//        Button {
//            showTransferSheet = true
//            TouchAndHoldPlusButtonTip.didSelectSmartReceiptOrTransferOption = true
//            touchAndHoldPlusButtonTip.invalidate(reason: .actionPerformed)
//        } label: {
//            Label {
//                Text("New Transfer / Payment")
//            } icon: {
//                Image(systemName: "arrowshape.turn.up.forward.fill")
//            }
//        }
//    }
//    
//    
//    var takePhotoButton: some View {
//        Button {
//            //let newID = UUID().uuidString
//            //calModel.pendingSmartTransaction = CBTransaction(uuid: newID)
//            //calModel.pictureTransactionID = newID
//            calModel.isUploadingSmartTransactionPicture = true
//            showCamera = true
//            TouchAndHoldPlusButtonTip.didSelectSmartReceiptOrTransferOption = true
//            touchAndHoldPlusButtonTip.invalidate(reason: .actionPerformed)
//        } label: {
//            Label {
//                Text("Take Photo")
//            } icon: {
//                Image(systemName: "camera")
//            }
//        }
//    }
//    
//    
//    var selectPhotoButton: some View {
//        Button {
//            //let newID = UUID().uuidString
//            //calModel.pendingSmartTransaction = CBTransaction(uuid: newID)
//            //calModel.pictureTransactionID = newID
//            calModel.isUploadingSmartTransactionPicture = true
//            showPhotosPicker = true
//            TouchAndHoldPlusButtonTip.didSelectSmartReceiptOrTransferOption = true
//            touchAndHoldPlusButtonTip.invalidate(reason: .actionPerformed)
//        } label: {
//            Label {
//                Text("Photo Library")
//            } icon: {
//                Image(systemName: "photo.badge.plus")
//            }
//        }
//    }
          
    
    var fakeNavHeader: some View {
        HStack {
            @Bindable var calModel = calModel
            Menu {
                Section("Accounts") {
                    Button(calModel.sPayMethod?.title ?? "Select Account") {
                        showPayMethodSheet = true
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
                monthTitleAndPayMethodMenuLabel
            } primaryAction: {
                showPayMethodSheet = true
            }
            .layoutPriority(1)
            .padding(.leading, 16)
            .padding(.bottom, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            
//            currentBalanceLabel
//                .padding(.trailing, 16)
//                .padding(.bottom, 4)
//                .frame(maxWidth: .infinity, alignment: .trailing)
            
            
//            ScrollView(.horizontal, showsIndicators: false) {
//                HStack {
//                    ForEach(calModel.sMonth.startingAmounts) { amount in
//                        
//                        HStack(alignment: .circleAndTitle, spacing: 0) {
//                            CircleDot(color: amount.payMethod.color)
//                                .alignmentGuide(.circleAndTitle) { $0[VerticalAlignment.center] }
//                                                        
//                            VStack(alignment: .leading) {
//                                Text(amount.payMethod.title)
//                                    .font(.caption)
//                                    .alignmentGuide(.circleAndTitle) { $0[VerticalAlignment.center] }
//                                
//                                Text(amount.amount.currencyWithDecimals(useWholeNumbers ? 0 : 2))
//                                    .font(.caption)
//                            }
//                        }
//                    }
//                }
//            }
            
        }
        .padding(.bottom, 10)
        .contentShape(Rectangle())
    }
    
    @ViewBuilder
    var monthTitleAndPayMethodMenuLabel: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(monthText)
                .font(.largeTitle)
                .bold()
                .foregroundStyle(colorScheme == .dark ? .white : .black)
                .lineLimit(1)
            
            HStack(spacing: 2) {
                Text(paymentMethodText)
                    .padding(.leading, -2)
                
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
            
            
            
            if let meth = calModel.sPayMethod {
                if meth.isUnified {
                    if meth.isDebit {
                        let debitIDs = payModel.paymentMethods.filter { $0.isDebit }.map { $0.id }
                        let sum = plaidModel.balances.filter { debitIDs.contains($0.payMethodID) }.map { $0.amount }.reduce(0.0, +)
                        Text("\(sum.currencyWithDecimals(useWholeNumbers ? 0 : 2))")
                            .font(.callout)
                            .foregroundStyle(.gray)
                            .lineLimit(1)
                    } else {
                        let creditIDs = payModel.paymentMethods.filter { $0.isCredit }.map { $0.id }
                        let sum = plaidModel.balances.filter { creditIDs.contains($0.payMethodID) }.map { $0.amount }.reduce(0.0, +)
                        Text("\(sum.currencyWithDecimals(useWholeNumbers ? 0 : 2))")
                            .font(.callout)
                            .foregroundStyle(.gray)
                            .lineLimit(1)
                    }
                    
                } else {
//                    if let balance = plaidModel.balances.filter({ $0.payMethodID == calModel.sPayMethod?.id }).first {
//                        Text("\(balance.amount.currencyWithDecimals(useWholeNumbers ? 0 : 2)), \(balance.lastTimeICheckedPlaidSyncedDate?.string(to: .monthDayHrMinAmPm) ?? "N/A")")
//                            .font(.callout)
//                            .foregroundStyle(.gray)
//                            .lineLimit(1)
//                    }
                    
                    
                    if let balance = plaidModel.balances.filter({ $0.payMethodID == calModel.sPayMethod?.id }).first {
                        Text("\(balance.amount.currencyWithDecimals(useWholeNumbers ? 0 : 2)) (\(timeSinceLastBalanceUpdate))")
                            .font(.callout)
                            .foregroundStyle(.gray)
                            .lineLimit(1)
                    }
                }
            }
        }
        .popoverTip(touchAndHoldMonthToFilterCategoriesTip)
    }
    
//    @ViewBuilder
//    var currentBalanceLabel: some View {
//        if let balance = plaidModel.balances.filter({ $0.payMethodID == calModel.sPayMethod?.id }).first {
//            VStack(alignment: .trailing, spacing: 0) {
//                Text("Balance")
//                    .font(.largeTitle)
//                    .bold()
//                    .foregroundStyle(colorScheme == .dark ? .white : .black)
//                    .lineLimit(1)
//                                
//                Text("\(balance.amountString) as of \(balance.lastTimeICheckedPlaidSyncedDate?.string(to: .monthDayYearHrMinAmPm) ?? "N/A")")
//                    .font(.callout)
//                    .foregroundStyle(.gray)
//                    .lineLimit(1)
//            }
//        }
//    }
    
    
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
            //.background(.ultraThickMaterial)
            
            .background {
                Color(.secondarySystemBackground)
                    .clipShape(
                        .rect(
                            topLeadingRadius: 0,
                            bottomLeadingRadius: 15,
                            bottomTrailingRadius: 15,
                            topTrailingRadius: 0
                        )
                    )
                    .ignoresSafeArea(edges: .all)
            }
            
            Spacer()
        }
        //.animation(.easeOut, value: showSearchBar)
        
        //.opacity(showSearchBar ? 1 : 0)
        .offset(y: showSearchBar ? 0 : -200)
        .transition(.move(edge: .top))

    }
    
    
    var searchBarOverlayIpad: some View {
        HStack(spacing: 0) {
            @Bindable var calModel = calModel
            
            Spacer()
                .frame(width: 10)
            
            Picker("", selection: $calModel.searchWhat) {
                Text("Title")
                    .tag(CalendarSearchWhat.titles)
                Text("Tag")
                    .tag(CalendarSearchWhat.tags)
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .background {
                Color(.tertiarySystemFill)
                    .clipShape(
                        .rect(
                            topLeadingRadius: 8,
                            bottomLeadingRadius: 8,
                            bottomTrailingRadius: 8,
                            topTrailingRadius: 8
                        )
                    )
            }
            Spacer()
                .frame(width: 4)
            
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
        //.offset(x: showSearchBar ? 0 : -200)
        .opacity(showSearchBar ? 1 : 0)
        .transition(.move(edge: .trailing).combined(with: .opacity))
        //.frame(maxWidth: showSearchBar ? .infinity : 0)
    }
    
    
    var sidebarButtonIpad: some View {
        Button {
            withAnimation {
                NavigationManager.shared.columnVisibility = NavigationManager.shared.columnVisibility == .all ? .detailOnly : .all
            }
        } label: {
            Image(systemName: "sidebar.left")
        }
        .font(.title2)
    }
    
    
    var iPadSideBar: some View {
        Group {
            if let content = bottomPanelContent {
                Divider()
                    .ignoresSafeArea(.all, edges: [.vertical])
                
                switch content {
                case .overviewDay:
                    DayOverviewView(
                        day: $overviewDay,
                        selectedDay: $selectedDay,
                        transEditID: $transEditID,
                        showTransferSheet: $showTransferSheet,
                        showCamera: $showCamera,
                        showPhotosPicker: $showPhotosPicker,
                        bottomPanelHeight: $bottomPanelHeight,
                        scrollContentMargins: $scrollContentMargins,
                        bottomPanelContent: $bottomPanelContent
                    )
                    .frame(maxWidth: getRect().width / 4)
                    
                case .fitTransactions:
                    FitTransactionOverlay(bottomPanelContent: $bottomPanelContent, bottomPanelHeight: $bottomPanelHeight, scrollContentMargins: $scrollContentMargins)
                        .frame(maxWidth: getRect().width / 3)
                    
                case .plaidTransactions:
                    PlaidTransactionOverlay(bottomPanelContent: $bottomPanelContent, bottomPanelHeight: $bottomPanelHeight, scrollContentMargins: $scrollContentMargins)
                        .frame(maxWidth: getRect().width / 3)
                    
                case .smartTransactionsWithIssues:
                    SmartTransactionsWithIssuesOverlay(
                        bottomPanelContent: $bottomPanelContent,
                        transEditID: $transEditID,
                        findTransactionWhere: $findTransactionWhere,
                        bottomPanelHeight: $bottomPanelHeight,
                        scrollContentMargins: $scrollContentMargins
                    )
                    .frame(maxWidth: getRect().width / 3)
                    
                case .categoryAnalysis:
                    AnalysisSheet(showAnalysisSheet: $showAnalysisSheet)
                        .frame(maxWidth: getRect().width / 3)
                    
                        /// This is here since AnalysisSheet is in a sheet on iPhone and is triggered by a boolean
                        .onChange(of: showAnalysisSheet) {
                            if !$1 { withAnimation { bottomPanelContent = nil } }
                        }
                    
                case .transactionList:
                    TransactionListView(showTransactionListSheet: $showTransactionListSheet)
                        .onChange(of: showTransactionListSheet) {
                            if !$1 { withAnimation { bottomPanelContent = nil } }
                        }
                    
                case .multiSelectOptions:
                    MultiSelectTransactionOptionsSheet(
                        bottomPanelContent: $bottomPanelContent,
                        bottomPanelHeight: $bottomPanelHeight,
                        scrollContentMargins: $scrollContentMargins,
                        showAnalysisSheet: $showAnalysisSheet
                    )
                    .frame(maxWidth: getRect().width / 4)
                }
            }
        }
    }
    
    
    
    // MARK: - Functions
    
    func startingAmountSheetDismissed() {
        let _ = calModel.calculateTotal(for: calModel.sMonth)
        Task {
            await withTaskGroup(of: Void.self) { group in
                let starts = calModel.sMonth.startingAmounts.filter { !$0.payMethod.isUnified }
                for start in starts {
                    
                    if start.hasChanges() {
                        group.addTask {
                            await calModel.submit(start)
                        }
                    } else {
                        print("No Starting amount Changes for \(start.payMethod.title)")
                    }
                }
            }
        }
    }
    
    
//    func transEditIdChanged(oldValue: String?, newValue: String?) {
//        print(".onChange(of: transEditID) - old: \(String(describing: oldValue)) -- new: \(String(describing: newValue))")
//        /// When `newValue` is false, save to the server. We have to use this because `.popover(isPresented:)` has no onDismiss option.
//        if oldValue != nil && newValue == nil {
//            
//            /// Present tip after trying to add 3 new transactions.
//            let trans = calModel.getTransaction(by: oldValue!, from: findTransactionWhere)
//            
//            if trans.action == .add {
//                TouchAndHoldPlusButtonTip.didTouchPlusButton.sendDonation()
//            }
//                                
//            calModel.saveTransaction(id: oldValue!, day: selectedDay!, location: findTransactionWhere)
//            /// - When adding a transaction via a day's context menu, `selectedDay` gets changed to the contexts day.
//            ///   So when closing the transaction, put `selectedDay`back to today so the normal plus button works and the gray box goes back to today.
//            /// - Gotta have a `selectedDay` for the editing of a transaction and transfer sheet.
//            ///   Since one is not always used in details view, set to the current day if in the current month, otherwise set to the first of the month.
//            /// - If you're viewing the bottom panel, reset `selectedDay` to `overviewDay` so any transactions that are added via the bottom panel have the date of the bottom panel.
//            if overviewDay != nil {
//                selectedDay = overviewDay
//            } else {
//                let targetDay = calModel.sMonth.days.filter { $0.dateComponents?.day == (calModel.sMonth.num == AppState.shared.todayMonth ? AppState.shared.todayDay : 1) }.first
//                selectedDay = targetDay
//            }
//            /// Keep the model clean, and show alert for a photo that may be taking a long time to upload.
//            //calModel.pictureTransactionID = nil
//            PhotoModel.shared.pictureParent = nil
//            
//            /// Force this to `.normalList` since smart transactions will change the variable to look in the temp list.
//            findTransactionWhere = .normalList
//            
//            /// Prevent a transaction from being opened while another one is trying to save.
//            calModel.editLock = false
//                                                            
//        } else if newValue != nil {
//            if !calModel.editLock {
//                /// Prevent a transaction from being opened while another one is trying to save.
//                calModel.editLock = true
//                editTrans = calModel.getTransaction(by: newValue!, from: findTransactionWhere)
//            }
//        }
//    }
    
    
    func resetMonthState() {
        Helpers.buzzPhone(.success)
        withAnimation {
            calModel.sCategories = []
            calModel.searchText = ""
            showSearchBar = false
            calModel.sPayMethod = payModel.paymentMethods.first(where: { $0.isViewingDefault })
        }
    }
    
    
    func onChangeOfMonthEnumID() {
        print(".onChange(of: enumID, initial: true)")
        Task {
            calModel.isInMultiSelectMode = false
            let month = calModel.months.filter {$0.enumID == enumID}.first!
            
            funcModel.prepareStartingAmounts(for: month)
            calModel.setSelectedMonthFromNavigation(navID: enumID, prepareStartAmount: true)
            
            let targetDay = month.days.filter { $0.dateComponents?.day == (month.actualNum == AppState.shared.todayMonth ? AppState.shared.todayDay : 1) }.first
            selectedDay = targetDay
        }
    }
}

#endif
