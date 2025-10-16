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

#if os(iOS)
struct CalendarViewPhone: View {
    @AppStorage("lineItemIndicator") var lineItemIndicator: LineItemIndicator = .emoji
    @AppStorage("updatedByOtherUserDisplayMode") var updatedByOtherUserDisplayMode = UpdatedByOtherUserDisplayMode.full
    @AppStorage("phoneLineItemDisplayItem") var phoneLineItemDisplayItem: PhoneLineItemDisplayItem = .both
    
    @Local(\.colorTheme) var colorTheme
    @Local(\.useWholeNumbers) var useWholeNumbers
    @Local(\.threshold) var threshold
            
    //@Environment(\.colorScheme) var colorScheme
    //@Environment(\.dismiss) var dismiss
    @Environment(FuncModel.self) var funcModel
    @Environment(CalendarProps.self) var calProps
    @Environment(CalendarModel.self) private var calModel
    @Environment(PayMethodModel.self) private var payModel
    @Environment(CategoryModel.self) private var catModel
    @Environment(KeywordModel.self) private var keyModel
    @Environment(EventModel.self) private var eventModel
    @Environment(PlaidModel.self) private var plaidModel
    
    #warning("NOTE BINDINGS ARE NOT ALLOWED TO BE PASSED TO THE CALENDAR VIEW")
    let enumID: NavDestination
    let sevenColumnGrid = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    @FocusState private var focusedField: Int?
    //@State private var calProps = CalendarProps()
    @State private var lastBalanceUpdateTimer: Timer?
  
    var body: some View {
        @Bindable var calProps = calProps
        //let _ = Self._printChanges()
        @Bindable var navManager = NavigationManager.shared
        @Bindable var calModel = calModel
        @Bindable var photoModel = PhotoModel.shared
        
        NavigationStack {
            Group {
                if calModel.sMonth.enumID == enumID {
                    VStack(spacing: 0) {
                        calendarView
                        bottomPanelViews
                    }
                    //.background(calendarBackground)
                } else {
                    ProgressView()
                        .transition(.opacity)
                        .tint(.none)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .searchable(text: $calModel.searchText, prompt: Text("Search"))
            .searchPresentationToolbarBehavior(.avoidHidingContent)
            .toolbar {
                DefaultToolbarItem(kind: .search, placement: .bottomBar)
                ToolbarSpacer(.flexible, placement: .bottomBar)
                ToolbarItem(placement: .bottomBar) {
                    NewTransactionMenuButton(
                        transEditID: $calProps.transEditID,
                        showTransferSheet: $calProps.showTransferSheet,
                        showPhotosPicker: $calProps.showPhotosPicker,
                        showCamera: $calProps.showCamera
                    )
                    //.matchedTransitionSource(id: "myButton", in: newTransactionMenuButtonNamespace)
                }
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar { CalendarToolbar() }
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
                transEditID: $calProps.transEditID,
                editTrans: $calProps.editTrans,
                selectedDay: $calProps.selectedDay,
                overviewDay: $calProps.overviewDay,
                findTransactionWhere: $calProps.findTransactionWhere,
                presentTip: true,
                resetSelectedDayOnClose: true,
                //newTransactionMenuButtonNamespace: newTransactionMenuButtonNamespace
            )
            .sheet(isPresented: $calProps.showTransferSheet) {
                TransferSheet(date: calProps.selectedDay?.date ?? Date())
            }
            /// Only allow 1 photo since this is happening only for smart transactions.
            .photosPicker(isPresented: $calProps.showPhotosPicker, selection: $photoModel.imagesFromLibrary, maxSelectionCount: 1, matching: .images, photoLibrary: .shared())
            /// Upload the picture from the selectedt photos when the photo picker sheet closes.
            .onChange(of: calProps.showPhotosPicker) { oldValue, newValue in
                if !newValue {
                    if PhotoModel.shared.imagesFromLibrary.isEmpty {
                        calModel.cleanUpPhotoVariables()
                    } else {
                        PhotoModel.shared.uploadPicturesFromLibrary(delegate: calModel, photoType: XrefModel.getItem(from: .photoTypes, byEnumID: .transaction))
                    }
                }
            }
            #if os(iOS)
            .fullScreenCover(isPresented: $calProps.showCamera) {
                AccessCameraView(selectedImage: $photoModel.imageFromCamera)
                    .background(.black)
            }
            /// Upload the picture from the camera when the camera sheet closes.
            .onChange(of: calProps.showCamera) { oldValue, newValue in
                if !newValue {
                    PhotoModel.shared.uploadPictureFromCamera(delegate: calModel, photoType: XrefModel.getItem(from: .photoTypes, byEnumID: .transaction))
                }
            }
            #endif
            
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
                    //calProps.timeSinceLastBalanceUpdate = Date().timeSince(balance.lastTimeICheckedPlaidSyncedDate)
                    //calProps.timeSinceLastBalanceUpdate = Date().timeSince(balance.lastTimePlaidSyncedWithInstitutionDate)
                    calProps.timeSinceLastBalanceUpdate = Date().timeSince(balance.enteredDate)
                }
                setCurrentBalanceTimer()
            }
            .onDisappear { lastBalanceUpdateTimer?.invalidate() }
            /// END CURRENT BALANCE TIMER STUFF
            
            
            
//            .inspector(isPresented: $calProps.showAnalysisInspector) {
//                //Text("hey")
//                TransactionListView(showTransactionListSheet: $calProps.showTransactionListSheet)
//                //AnalysisSheet(showAnalysisSheet: $calProps.showAnalysisSheet)
//            }
            
        }
        //.environment(calProps)
        .disableZoomeInteractiveDismiss()
    }
    
    
    // MARK: - Calendar Views
    var calendarView: some View {
        Group {
            VStack(spacing: 0) {
                if AppState.shared.isIphone {
                    CalendarFakeNavHeader()
                        .dropDestination(for: CBTransaction.self) { droppedTrans, location in
                            calModel.dragTarget = nil
                            return true
                        }
                }
                Group {
                    weekdayNameGrid
                    CalendarGridPhone(enumID: enumID)
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
                    .frame(maxWidth: .infinity, alignment: .center)
                    //.frame(maxWidth: .infinity)
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                    .padding(.leading, 0)
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
                    DayOverviewView(day: $calProps.overviewDay)
                    
                case .plaidTransactions:
                    PlaidTransactionOverlay(showInspector: .constant(false)) /// Inspector is only used on iPad. Bottom panel is only used on iPhone/
                    
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
            .frame(height: 250)
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
            calModel.isInMultiSelectMode = false
            let month = calModel.months.filter {$0.enumID == enumID}.first!
            
            funcModel.prepareStartingAmounts(for: month)
            calModel.setSelectedMonthFromNavigation(navID: enumID, prepareStartAmount: true)
            
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
