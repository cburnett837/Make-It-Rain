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
    case overviewDay, fitTransactions, smartTransactionsWithIssues, categoryAnalysis
}


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
            
    @Environment(FuncModel.self) var funcModel
    @Environment(CalendarModel.self) private var calModel
    @Environment(PayMethodModel.self) private var payModel
    @Environment(CategoryModel.self) private var catModel
    @Environment(KeywordModel.self) private var keyModel
    @Environment(EventModel.self) private var eventModel
    
    let enumID: NavDestination
    
    #warning("NOTE BINDINGS ARE NOT ALLOWED TO BE PASSED TO THE CALENDAR VIEW")
    
    @FocusState private var focusedField: Int?
        
    let touchAndHoldPlusButtonTip = TouchAndHoldPlusButtonTip()
    let touchAndHoldMonthToFilterCategoriesTip = TouchAndHoldMonthToFilterCategoriesTip()
    let swipeToChangeMonthsTip = SwipeToChangeMonthsTip()
    
    let sevenColumnGrid = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    @State private var showSearchBar = false
    @State private var selectedDay: CBDay?
    @State private var transEditID: String?
    @State private var editTrans: CBTransaction?
    
    @State private var overviewDay: CBDay?
    @State private var scrollHeight: CGFloat = 0
    @State private var bottomPanelHeight: CGFloat = 300
    @State private var scrollContentMargins: CGFloat = 300
    
    @State private var showTransferSheet = false
    @State private var showPaymentMethodSheet = false
    @State private var showCategorySheet = false
    @State private var showBudgetSheet = false
    @State private var showCalendarOptionsSheet = false
    @State private var showStartingAmountsSheet = false
    @State private var showAnalysisSheet = false
    @State private var showPhotosPicker = false
    @State private var showCamera = false
    @State private var showSideBar = false
    
    @State private var bottomPanelContent: BottomPanelContent?
                
    @State private var findTransactionWhere = WhereToLookForTransaction.normalList
    
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
            .standardBackground()
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            
            .if(AppState.shared.isIpad) { $0.toolbar(.hidden) }
            .if(!AppState.shared.isIpad) { $0.toolbar { calendarToolbar() } }
            //.toolbar { calendarToolbar() }
                        
            /// Using this instead of a task because the iPad doesn't reload `CalendarView`. It just changes the data source.
            .onChange(of: enumID, initial: true, onChangeOfMonthEnumID)
            
            .onShake { resetMonthState() }
            
            /// This exists in 2 place - purely for visual effect. See ``LineItemView``
            /// This is needed (passing the ID instead of the trans) because you can close the popover without actually clicking the close button. So I need somewhere to do cleanup.
//            .onChange(of: transEditID) { transEditIdChanged(oldValue: $0, newValue: $1) }
//            .sensoryFeedback(.selection, trigger: transEditID) { $1 != nil }
//            .sheet(item: $editTrans) { trans in
//                TransactionEditView(trans: trans, transEditID: $transEditID, day: selectedDay!, isTemp: false)
//                    /// This is needed for the drag to dismiss.
//                    .onDisappear {
//                        print("ONDisappear \(transEditID)")
//                        transEditID = nil
//                    }
//            }
            
            
            
            .onChange(of: transEditID) { transEditIdChanged(oldValue: $0, newValue: $1) }
            .sensoryFeedback(.selection, trigger: transEditID) { $1 != nil }
            .sheet(item: $editTrans, onDismiss: {
                transEditIdChanged(oldValue: $0, newValue: $1)
            }) { trans in
                TransactionEditView(trans: trans, transEditID: $transEditID, day: selectedDay!, isTemp: false)
                    /// This is needed for the drag to dismiss.
                    .onDisappear {
                        print("ONDisappear \(transEditID)")
                        transEditID = nil
                    }
            }
            
            
            
            
            
            
            
            .if(!AppState.shared.isIpad) {
                $0.sheet(isPresented: $showAnalysisSheet) {
                    AnalysisSheet(showAnalysisSheet: $showAnalysisSheet)
                }
            }
            .sheet(isPresented: $showCalendarOptionsSheet) {
                CalendarOptionsSheet(selectedDay: $selectedDay)
            }
            .sheet(isPresented: $showPaymentMethodSheet) {
                TouchAndHoldMonthToFilterCategoriesTip.didTouchMonthName.sendDonation()
            } content: {
                PaymentMethodSheet(payMethod: $calModel.sPayMethod, whichPaymentMethods: .all)
            }
            .sheet(isPresented: $showCategorySheet) {
                MultiCategorySheet(categories: $calModel.sCategories)
            }
            .sheet(isPresented: $showTransferSheet) {
                TransferSheet2(date: selectedDay?.date ?? Date())
            }
            .fullScreenCover(isPresented: $showBudgetSheet) {
                BudgetTable(maxHeaderHeight: .constant(50))
            }
            .sheet(isPresented: $showStartingAmountsSheet, onDismiss: startingAmountSheetDismissed) {
                StartingAmountSheet()
            }
            
//            #if os(iOS)
//            .photosPicker(isPresented: $showPhotosPicker, selection: $calModel.imagesFromLibrary, maxSelectionCount: 1, matching: .images, photoLibrary: .shared())
//            .onChange(of: showPhotosPicker) { oldValue, newValue in
//                if !newValue {
//                    if calModel.imagesFromLibrary.isEmpty {
//                        calModel.isUploadingSmartTransactionPicture = false
//                        calModel.smartTransactionDate = nil
//                    } else {
//                        calModel.uploadPictures()
//                    }
//                }
//            }
//            
//            .fullScreenCover(isPresented: $showCamera) {
//                AccessCameraView(selectedImage: $calModel.imageFromCamera)
//                    .background(.black)
//            }
//            .onChange(of: showCamera) { oldValue, newValue in
//                if !newValue {
//                    Task {
//                        if let imageFromCamera = calModel.imageFromCamera, let imageData = PhotoModel.prepareDataFromUIImage(image: imageFromCamera) {
//                            await calModel.uploadPicture(with: imageData)
//                        } else {
//                            calModel.isUploadingSmartTransactionPicture = false
//                            calModel.smartTransactionDate = nil
//                        }
//                    }
//                }
//            }
//            #endif
            
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
                    let month = calModel.months.filter { $0.num == AppState.shared.todayMonth && $0.year == AppState.shared.todayYear }.first
                    if let month {
                        let day = month.days.filter { $0.dateComponents?.day == AppState.shared.todayDay }.first
                        if let day {
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
        /// 1. It will lag when resizing due to the scroll content margins changing. (This will only work if you do the passThrough window thing to the calendar view.)
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
                                FitTransactionOverlay(bottomPanelContent: $bottomPanelContent, bottomPanelHeight: $bottomPanelHeight, scrollContentMargins: $scrollContentMargins)
                                
                            case .smartTransactionsWithIssues:
                                SmartTransactionsWithIssuesOverlay(
                                    bottomPanelContent: $bottomPanelContent,
                                    transEditID: $transEditID,
                                    findTransactionWhere: $findTransactionWhere,
                                    bottomPanelHeight: $bottomPanelHeight,
                                    scrollContentMargins: $scrollContentMargins
                                )
                            case .categoryAnalysis:
                                EmptyView()
                            }
                        }
                    }
                }
            }
            /// Reset the overviewDay if change from a day overview to another overlay.
            .onChange(of: bottomPanelContent) { oldValue, newValue in
                if oldValue == .overviewDay && newValue != nil {
                    overviewDay = nil
                    let targetDay = calModel.sMonth.days.filter { $0.dateComponents?.day == (calModel.sMonth.num == AppState.shared.todayMonth ? AppState.shared.todayDay : 1) }.first
                    selectedDay = targetDay
                }
            }
        }
    }
    
    
    
    
    // MARK: - Calendar Views
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
        .overlay(Rectangle().frame(width: nil, height: 2, alignment: .bottom).foregroundColor(Color(.tertiarySystemFill)), alignment: .bottom)
    }
        
    
    var calendarGrid: some View {
        @Bindable var calModel = calModel
        /// The geometry reader is needed for the keyboard avoidance
        return GeometryReader { geo in
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
                                    showPhotosPicker: $showPhotosPicker,
                                    showCamera: $showCamera,
                                    overviewDay: $overviewDay,
                                    bottomPanelContent: $bottomPanelContent
                                )
                                .id(day.dateComponents?.day ?? 0)
                                /// This is the dividing line
                                .overlay(
                                    Rectangle()
                                        .frame(width: nil, height: 2, alignment: .bottom)
                                        .foregroundColor(Color(.tertiarySystemFill)),
                                    alignment: .bottom
                                )
                                .frame(minHeight: scrollHeight / divideBy, alignment: .center)
                            }
                        }
                    }
                }
                //.contentMargins(.bottom, (overviewDay == nil && !showFitTransactions) ? 0 : scrollContentMargins, for: .scrollContent)
                //.contentMargins(.bottom, (overviewDay == nil && !showFitTransactions) ? 0 : (AppState.shared.isLandscape ? AppState.shared.isIpad ? 300 : 150 : AppState.shared.isIpad ? 500 : 300), for: .scrollContent)
                
                .contentMargins(.bottom, (bottomPanelContent == nil || AppState.shared.isIpad) ? 0 : scrollContentMargins, for: .scrollContent)
                
                .frame(height: scrollHeight)
                .scrollIndicators(.hidden)
                .onScrollPhaseChange { oldPhase, newPhase in
                    if newPhase == .interacting {
                        withAnimation { calModel.hilightTrans = nil }
                    }
                }
                
                .onChange(of: overviewDay) {
                    if let day = $1 {
                        withAnimation { scroll.scrollTo(day.date?.day) }
                    }
                }
            }
        }
        /// Only for the pref key
        .viewHeightObserver()
        .onPreferenceChange(ViewHeightKey.self) {
            print("Setting scroll height to \($0)")
            scrollHeight = $0
        }
//        .sheet(isPresented: $showFitTransactions) {
//            BottomPanelSheetContainerView($scrollContentMargins) {
//                FitTransactionOverlay(showFitTransactions: $showFitTransactions)
//            }
//        }
//        .sheet(isPresented: $showSmartTransactionsWithIssues) {
//            BottomPanelSheetContainerView($scrollContentMargins) {
//                SmartTransactionsWithIssuesOverlay(
//                    showSmartTransaction: $showSmartTransactionsWithIssues,
//                    transEditID: $transEditID,
//                    findTransactionWhere: $findTransactionWhere
//                )
//            }
//        }
//        .sheet(item: $overviewDay) { overviewDay in
//            BottomPanelSheetContainerView($scrollContentMargins) {
//                DayOverviewView(
//                    day: $overviewDay,
//                    selectedDay: $selectedDay,
//                    transEditID: $transEditID,
//                    showTransferSheet: $showTransferSheet,
//                    showCamera: $showCamera,
//                    showPhotosPicker: $showPhotosPicker
//                )
//            }
//        }
        
//        .overlay {
//            if !AppState.shared.isIpad {
//                if overviewDay != nil {                                        
//                    BottomPanelContainerView($customSheetHeight) {
//                        DayOverviewView(
//                            day: $overviewDay,
//                            selectedDay: $selectedDay,
//                            transEditID: $transEditID,
//                            showTransferSheet: $showTransferSheet,
//                            showCamera: $showCamera,
//                            showPhotosPicker: $showPhotosPicker,
//                            sheetHeight: $customSheetHeight
//                        )
//                    }
//                }
//                                
//                if showFitTransactions {
//                    BottomPanelContainerView($customSheetHeight) {
//                        FitTransactionOverlay(showFitTransactions: $showFitTransactions, sheetHeight: $customSheetHeight)
//                    }
//                }
//                
//                if showSmartTransactionsWithIssues {
//                    BottomPanelContainerView($customSheetHeight) {
//                        SmartTransactionsWithIssuesOverlay(
//                            showSmartTransaction: $showSmartTransactionsWithIssues,
//                            transEditID: $transEditID,
//                            findTransactionWhere: $findTransactionWhere,
//                            sheetHeight: $customSheetHeight
//                        )
//                    }
//                }
//            }
//        }
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
                    showPaymentMethodSheetButton
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
                        fitTransactionButton
                            .font(.title2)
                        
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
                                .font(.title2)
                                .contentShape(Rectangle())
                        }
                        
                        searchButton
                            .font(.title2)
                        
                        Menu {
                            Section("Create") {
                                newTransactionButton
                                newTransferButton
                            }
                            
                            Section("Smart Receipts") {
                                takePhotoButton
                                selectPhotoButton
                            }
                        } label: {
                            Image(systemName: "plus")
                                .font(.title2)
                                .contentShape(Rectangle())
                        } primaryAction: {
                            transEditID = UUID().uuidString
                        }
                        .popoverTip(touchAndHoldPlusButtonTip)
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
                    fitTransactionButton
                    
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
                        
                        Section("Smart Receipts") {
                            takePhotoButton
                            selectPhotoButton
                        }
                    } label: {
                        Image(systemName: "plus")
                    } primaryAction: {
                        transEditID = UUID().uuidString
                    }
                    .popoverTip(touchAndHoldPlusButtonTip)
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
    
    
    var smartTransactionWithIssuesButton: some View {
        Group {
            if !calModel.tempTransactions.filter({$0.isSmartTransaction ?? false}).isEmpty {
                Button {
                    withAnimation {
                        bottomPanelContent = .smartTransactionsWithIssues
                        //showSmartTransactionsWithIssues = true
                    }
                } label: {
                    Image(systemName: "brain")
                        .foregroundStyle(Color.fromName(appColorTheme) == .orange ? .red : .orange)
                }
            }
        }
    }
    
    
    var fitTransactionButton: some View {
        Group {
            if !calModel.fitTrans.filter({ !$0.isAcknowledged }).isEmpty {
                if AppState.shared.user?.id == 1 {
                    Button {
                        withAnimation {
                            //showFitTransactions = true
                            bottomPanelContent = .fitTransactions
                        }
                    } label: {
                        Image(systemName: "clock.badge.exclamationmark")
                            .foregroundStyle(Color.fromName(appColorTheme) == .orange ? .red : .orange)
                            .contentShape(Rectangle())
                    }
                }
            }
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
    
    
    var showPaymentMethodSheetButton: some View {
        Button {
            showPaymentMethodSheet = true
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
            withAnimation {
                showAnalysisSheet = true
                if AppState.shared.isIpad {
                    bottomPanelContent = .categoryAnalysis
                }
            }
        } label: {
            Label {
                Text("Analyze Categories")
            } icon: {
                Image(systemName: "chart.bar.doc.horizontal")
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
                .tint(calModel.searchText.isEmpty ? Color.fromName(appColorTheme) : Color.fromName(appColorTheme) == .orange ? .red : .orange)
                .scaleEffect(!calModel.searchText.isEmpty ? 1.2 : 1)
                .animation(!calModel.searchText.isEmpty ? .easeInOut(duration: 1).repeatForever(autoreverses: true) : .default, value: calModel.searchText.isEmpty )
                .contentShape(Rectangle())
        }
        
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
            //let newID = UUID().uuidString
            //calModel.pendingSmartTransaction = CBTransaction(uuid: newID)
            //calModel.pictureTransactionID = newID
            calModel.isUploadingSmartTransactionPicture = true
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
            //let newID = UUID().uuidString
            //calModel.pendingSmartTransaction = CBTransaction(uuid: newID)
            //calModel.pictureTransactionID = newID
            calModel.isUploadingSmartTransactionPicture = true
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
                        .onChange(of: showAnalysisSheet) { oldValue, newValue in
                            if newValue == false {
                                withAnimation {
                                    bottomPanelContent = nil
                                }
                            }
                        }
                }
            }
        }
    }
    
    
    
    // MARK: - Functions
    
    func startingAmountSheetDismissed() {
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
    }
    
    func transEditIdChanged(oldValue: String?, newValue: String?) {
        print(".onChange(of: transEditID) -- \(newValue)")
        /// When `newValue` is false, save to the server. We have to use this because `.popover(isPresented:)` has no onDismiss option.
        if oldValue != nil && newValue == nil {
            
            /// Present tip after trying to add 3 new transactions.
            let trans = calModel.getTransaction(by: oldValue!, from: findTransactionWhere)
            
            if trans.action == .add {
                TouchAndHoldPlusButtonTip.didTouchPlusButton.sendDonation()
            }
                                
            calModel.saveTransaction(id: oldValue!, day: selectedDay!, location: findTransactionWhere, eventModel: eventModel)
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
            //calModel.pictureTransactionID = nil
            PhotoModel.shared.pictureParent = nil
            
            /// Force this to `.normalList` since smart transactions will change the variable to look in the temp list.
            findTransactionWhere = .normalList
                                                            
        } else if newValue != nil {
            editTrans = calModel.getTransaction(by: newValue!, from: findTransactionWhere)
        }
    }
    
    func resetMonthState() {
        Helpers.buzzPhone(.success)
        withAnimation {
            calModel.sCategories = []
            calModel.searchText = ""
            showSearchBar = false
            calModel.sPayMethod = payModel.paymentMethods.first(where: { $0.isDefault })
        }
    }
    
    func onChangeOfMonthEnumID() {
        print(".onChange(of: enumID, initial: true)")
        Task {
            calModel.setSelectedMonthFromNavigation(navID: enumID, prepareStartAmount: true)
            let month = calModel.months.filter {$0.enumID == enumID}.first!
            let targetDay = month.days.filter { $0.dateComponents?.day == (month.actualNum == AppState.shared.todayMonth ? AppState.shared.todayDay : 1) }.first
            selectedDay = targetDay
        }
    }
}

#endif
