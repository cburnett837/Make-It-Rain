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
    case overviewDay, smartTransactionsWithIssues, categoryAnalysis, multiSelectOptions, plaidTransactions, transactionList
}

fileprivate let BOTTOM_PANEL_HEIGHT: CGFloat = 260


enum CalendarNavDest {
    case categoryInsights, plaidRejectPage, budgets, dashboard, transactionList
}


#if os(iOS)
struct CalendarViewPhone: View {
    @Local(\.updatedByOtherUserDisplayMode) var updatedByOtherUserDisplayMode
    @Local(\.phoneLineItemDisplayItem) var phoneLineItemDisplayItem
    @Local(\.lineItemIndicator) var lineItemIndicator
    @Local(\.useWholeNumbers) var useWholeNumbers
    @Local(\.threshold) var threshold
    
    //@Environment(\.safeAreaInsets) var safeAreaInsets
    @Environment(FuncModel.self) var funcModel
    @Environment(CalendarProps.self) var calProps
    @Environment(CalendarModel.self) private var calModel
    @Environment(PayMethodModel.self) private var payModel
    @Environment(CategoryModel.self) private var catModel
    @Environment(KeywordModel.self) private var keyModel
    @Environment(PlaidModel.self) private var plaidModel
    
    #warning("NOTE BINDINGS ARE NOT ALLOWED TO BE PASSED TO THE CALENDAR VIEW")
    let enumID: NavDestination
    
    @FocusState private var searchFocused: Int?
    @State private var lastBalanceUpdateTimer: Timer?
    @State private var showDemoSheet = false
    /// Used to navigate to additional pages in the bottom panel. (I.E. Plaid transactions reject all before date)
    @State private var navPath = NavigationPath()
    //@State private var showSearchBar = true
    
    /// Retain this here so we don't lose the data when we leave the sheet
    @State private var categoryAnalysisModel = CategoryInsightsModel()
    @State private var selectedPlaidFilterMeth: CBPaymentMethod?

    
    var searchPrompt: String {
        searchFocused == 0 ? "Search by transaction name or #" : "Search"
    }
    
    @State private var safeAreaInsets: EdgeInsets = EdgeInsets()
    
    var body: some View {
        //let _ = Self._printChanges()
        @Bindable var calProps = calProps
        @Bindable var navManager = NavigationManager.shared
        @Bindable var calModel = calModel
        @Bindable var photoModel = FileModel.shared
        
        //Text("Multi \(calModel.isInMultiSelectMode)")
        
        /// Wrap in a geoReader so I can get the safe area insets and adjust the calendar accordingly.
        GeometryReader { geo in
            NavigationStack(path: $calProps.navPath) {
                VStack {
                    if calModel.sMonth.enumID == enumID {
                        if AppState.shared.isIphone {
                            calChunkIphone
                        } else {
                            calendarView
                        }
                    }
//                    else {
//                        ProgressView()
//                            .transition(.opacity)
//                            .tint(.none)
//                            .frame(maxWidth: .infinity, maxHeight: .infinity)
//                    }
                }
                .navigationDestination(for: CalendarNavDest.self) { dest in
                    switch dest {
                    case .categoryInsights:
                        CategoryInsightsSheet(
                            navPath: $calProps.navPath,
                            showAnalysisSheet: $calProps.showAnalysisSheet,
                            model: categoryAnalysisModel
                        )
                        
                    case .plaidRejectPage:
                        ClearPlaidBeforeDateView(
                            selectedMeth: $selectedPlaidFilterMeth,
                            navPath: $calProps.navPath
                        )
                        
                    case .budgets:
                        BudgetTable()
                        
                    case .dashboard:
                        CalendarDashboard()
                        
                    case .transactionList:
                        TransactionListView(
                            showTransactionListSheet: $calProps.showTransactionListSheet
                        )
                    }
                }
                .searchable(text: $calModel.searchText, prompt: searchPrompt)
                .searchFocused($searchFocused, equals: 0)
                .searchPresentationToolbarBehavior(.avoidHidingContent)
                /// Prevent accidentally closing the calendar sheet when deeper in its nav path. (Like when on the insight page or the insights children pages)
                .interactiveDismissDisabled(!calProps.navPath.isEmpty)
                //.navigationBarTitleDisplayMode(.inline)
                //.navigationBarBackButtonHidden(true)
                //.navigationTitle("Calendar")
                .toolbar { CalendarToolbar() }
                /// Using this instead of a task because the iPad doesn't reload `CalendarView`. It just changes the data source.
                .onChange(of: enumID, initial: true, onChangeOfMonthEnumID)
                .onShake {
                    /// Prevent "shake to reset" from happening when viewing the month via the analytic page.
                    if !calModel.categoryFilterWasSetByCategoryPage {
                        /// Prevent resetting when shaking to undo on a transaction.
                        if calProps.transEditID == nil {
                            resetMonthState()
                        }
                    }
                }
                .transactionEditSheetAndLogic( 
                    transEditID: $calProps.transEditID,
                    selectedDay: $calProps.selectedDay,
                    overviewDay: $calProps.overviewDay,
                    findTransactionWhere: $calProps.findTransactionWhere,
                    presentTip: true,
                    resetSelectedDayOnClose: true,
                )
                .photoPickerAndCameraSheet(
                    fileUploadCompletedDelegate: calModel,
                    parentType: .transaction,
                    allowMultiSelection: false,
                    showPhotosPicker: $calProps.showPhotosPicker,
                    showCamera: $calProps.showCamera
                )
                //.sheet(isPresented: $showDemoSheet) { Text("Hitch performance test sheet") }
                .sheet(isPresented: $calProps.showTransferSheet) {
                    TransferSheet(defaultDate: calProps.selectedDay?.date ?? Date())
                }
                /// Keep the current date indicator up to date.
                .onReceive(AppState.shared.currentDateTimer) { input in
                    let isDayChange = AppState.shared.setNow()
                    #if os(iOS)
                    /// If on iPhone, and the day changes, change the selected day as well otherwise it will be blank on day change and cause a crash.
                    if isDayChange {
                        if let month = calModel.months.filter({ $0.num == AppState.shared.todayMonth && $0.year == AppState.shared.todayYear }).first {
                            if let day = month.days.filter({ $0.dateComponents?.day == AppState.shared.todayDay }).first {
                                calProps.selectedDay = day
                            }
                        }
                    }
                    #endif
                }
                
                /// BEGIN CURRENT BALANCE TIMER STUFF
                .onChange(of: plaidModel.balances, setCurrentBalanceTimer)
                .onChange(of: calModel.sPayMethod, initial: true) { oldValue, newValue in
                    if let balance = plaidModel.balances.filter({ $0.payMethodID == newValue?.id }).first {
                        calProps.timeSinceLastBalanceUpdate = Date().timeSince(balance.enteredDate)
                    }
                    setCurrentBalanceTimer()
                }
                .onDisappear { lastBalanceUpdateTimer?.invalidate() }
            }
            .disableZoomInteractiveDismiss()
            /// Track the safe area insets, so we can adjust the bottom of the calendar accordingly.
            /// But, block the insets from updating when in a calendar sheet. The recalc of this view causes the keyboard toolbar to lag inside the transaction edit view.
            .onChange(of: geo.safeAreaInsets, initial: true) {
                if calProps.transEditID == nil {
                    //print("Setting safe area insets to \($1.bottom)")
                    safeAreaInsets = $1
                }
            }
        }
    }
    
    
    // MARK: - Calendar Views
    @ViewBuilder
    var calChunkIphone: some View {
        //let _ = Self._printChanges()
        //let _ = print("The new safe area insets are \(safeAreaInsets.bottom)")
        /// Use the GeoReader to adjust the calendar height so the bottom panel properly transitions all the way to the bottom of the screen on dismissal.
        /// Without it, the calendar/bottom panel would get clipped by the safe area, leading to the bottom panel's slide transition "poofing" at the end of it's transition.
        /// Essentially, I stretch the view into the safe area, and then apply padding to offset the stretch.
        GeometryReader { geo in
            VStack(spacing: 0) {
                calendarView
                    /// If the bottom panel is not showing, pad the bottom of the calendar by the safe area insets (since the geo reader ignores the safe area).
                    /// If the bottom panel is showing, use no padding so the bottom of the calendar will meet the top of the panel.
                    /// However, if search is focused, we read the safe area padding from the parent of `CalendarViewPhone` (``CalendarSheetLayerView``), and adjust the padding by that, minus the height of the bottom panel, so the bottom of the calendar is not clipped, and sits nicely above the search bar.
                    .padding(.bottom,
                         calProps.bottomPanelContent == nil
                         ? geo.safeAreaInsets.bottom
                         : searchFocused == 0 ? (safeAreaInsets.bottom - BOTTOM_PANEL_HEIGHT) : 0
                    )
                bottomPanelViews
                    /// Imitate a sheet dismissal behavior.
                    .transition(.move(edge: .bottom))
                    /// Sit just above the search bar.
                    .padding(.bottom, geo.safeAreaInsets.bottom)
            }
            .frame(height: geo.frame(in: .global).height + geo.safeAreaInsets.bottom)
        }
        /// If the bottom panel is not showing, ignore the edge insets so the calendar will move up when the search bar is focused.
        /// If the bottom panel is showing, ignore the safe area to protect the dismissal animation, and prevent the bottom panel from moving up when search is focused.
        .ignoresSafeArea(.keyboard, edges: calProps.bottomPanelContent == nil ? [] : .bottom)
    }
    
    
    //@GestureState private var zoom = 1.0
    var calendarView: some View {
        Group {
            VStack(spacing: 0) {
                if AppState.shared.isIphone {
                    CalendarMonthLabel()
                        .padding(.bottom, 10)
                        .scenePadding(.horizontal)
                        .dropDestination(for: CBTransaction.self) { droppedTrans, location in
                            calModel.dragTarget = nil
                            return true
                        }
                }
                weekdayNameGrid
                CalendarGridPhone(enumID: enumID)
                    .sensoryFeedback(.selection, trigger: phoneLineItemDisplayItem)
                    .contentShape(.rect)
//                    .highPriorityGesture(
//                        MagnifyGesture()
//                            .onChanged { value in
//                                if value.magnification - 1 > 1 {
//                                    guard phoneLineItemDisplayItem != .both else { return }
//                                    withAnimation { phoneLineItemDisplayItem = .both }
//                                }
//                                
//                                if value.magnification < 0.5 {
//                                    guard phoneLineItemDisplayItem != .title else { return }
//                                    withAnimation { phoneLineItemDisplayItem = .title }
//                                }
//                            }
//                            .onEnded { _ in }
//                        
//                    )
                
                
//                    .overlay {
//                        //if searchFocused == 0 {
//                            HStack {
//                                ScrollView {
//                                    VStack {
//                                        ForEach(0..<3, id: \.self) { i in
//                                            Text("Suggestion")
//                                                .padding()
//                                                //.background(Color.secondary)
//                                                //.clipShape(.capsule)
//                                                .glassEffect(.regular.interactive())
//                                        }
//                                    }
//                                }
//                                .contentMargins(20, for: .scrollContent)
//                                .defaultScrollAnchor(.bottom)
//                                .scrollIndicators(.hidden)
//                                Spacer()
//                            }
//                            //.padding(.leading, 20)
//                            .padding(.bottom, 5)
//                            .offset(x: searchFocused == 0 ? 0 : -200)
//                            //.opacity(searchFocused == 0 ? 1 : 0)
//                            .transition(.move(edge: .leading))
//                            .animation(.easeInOut(duration: 0.6), value: searchFocused)
//                        //}
//                    }
            }
        }
    }
    
    
    @ViewBuilder
    var weekdayNameGrid: some View {
        let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
                
        Grid(alignment: .top, horizontalSpacing: 0, verticalSpacing: 0) {
            GridRow {
                ForEach(days, id: \.self) { name in
                    Text(name)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                        .padding(.leading, 0)
                }
            }
            
            GridRow {
                dividingLine
                    .gridCellColumns(7)
            }
        }
        .padding(.bottom, 4)
    }
    
    
    var dividingLine: some View {
        Rectangle()
            .frame(width: nil, height: 2, alignment: .bottom)
            .foregroundColor(Color(.tertiarySystemFill))
    }
    
    
    @ViewBuilder
    var bottomPanelViews: some View {
        @Bindable var calProps = calProps
        /// This can't be a sheet because...
        /// 1. It will lag when resizing due to the scroll content margins changing. ---> (This will only work if you do the passThrough window thing to the calendar view.)
        /// 2. It will dismiss when other sheets open (payMethod, settings, etc).
        if let content = calProps.bottomPanelContent {
            BottomPanelContainerView() {
                switch content {
                case .overviewDay:
                    DayOverviewView(day: $calProps.overviewDay, showInspector: .constant(false))
                    
                case .plaidTransactions:
                    PlaidTransactionOverlay(showInspector: .constant(false), navPath: $calProps.navPath)
                    
                case .smartTransactionsWithIssues:
                    SmartTransactionsWithIssuesOverlay(showInspector: .constant(false))
                    
                case .multiSelectOptions:
                    MultiSelectTransactionOptionsSheet(showInspector: .constant(false))
                    
                case .transactionList:
                    EmptyView()
                    
                case .categoryAnalysis:
                    EmptyView()
                }
            }
            .frame(height: BOTTOM_PANEL_HEIGHT)
            //.toolbar(.hidden, for: .bottomBar)
        }
    }
    
    
    
    // MARK: - Functions
    func setCurrentBalanceTimer() {
        /// Keep the displayed time ago up to date.
        self.lastBalanceUpdateTimer?.invalidate()
        self.lastBalanceUpdateTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            Task { @MainActor in
                if let balance = plaidModel.balances.filter({ $0.payMethodID == calModel.sPayMethod?.id }).first {
                    //calProps.timeSinceLastBalanceUpdate = Date().timeSince(balance.lastTimeICheckedPlaidSyncedDate)
                    //calProps.timeSinceLastBalanceUpdate = Date().timeSince(balance.lastTimePlaidSyncedWithInstitutionDate)
                    calProps.timeSinceLastBalanceUpdate = Date().timeSince(balance.enteredDate)
                }
            }
        }
    }
    
    
    func resetMonthState() {
        Helpers.buzzPhone(.success)
        withAnimation {
            calModel.sCategories = []
            calModel.searchText = ""
            calModel.sPayMethod = payModel.paymentMethods.first(where: { $0.isViewingDefault })
        }
    }
    
    
    func onChangeOfMonthEnumID() {
        print(".onChange(of: enumID, initial: true)")
        Task {
            //calModel.isInMultiSelectMode = false
            let month = calModel.months.filter { $0.enumID == enumID }.first!
            
            funcModel.prepareStartingAmounts(for: month)
            calModel.setSelectedMonthFromNavigation(navID: enumID, calculateStartingAndEod: true)
            
            /// Set the selected day so new transactions have a default date.
            /// If in the current month, set to today.
            /// If not, set to the first of the month.
            let targetDay = month.days.filter { $0.dateComponents?.day == (month.actualNum == AppState.shared.todayMonth ? AppState.shared.todayDay : 1) }.first
            calProps.selectedDay = targetDay
            
            /// Run this when switching months.
            /// If the dashboard is open in the inspector on iPad, it won't be recalculate its data on its own.
            /// So we use the ``DataChangeTriggers`` class to send a notification to the view to tell it to recalculate.
            DataChangeTriggers.shared.viewDidChange(.calendar)
        }
    }
}

#endif
