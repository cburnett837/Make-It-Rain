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
    
    @AppStorage("appColorTheme") var appColorTheme: String = Color.green.description
    @AppStorage("lineItemIndicator") var lineItemIndicator: LineItemIndicator = .emoji
    @AppStorage("updatedByOtherUserDisplayMode") var updatedByOtherUserDisplayMode = UpdatedByOtherUserDisplayMode.full
    @AppStorage("viewMode") var viewMode = CalendarViewMode.scrollable
    @AppStorage("useWholeNumbers") var useWholeNumbers = false
    @AppStorage("threshold") var threshold = "500.0"
    @AppStorage("phoneLineItemDisplayItem") var phoneLineItemDisplayItem: PhoneLineItemDisplayItem = .both
    

    //@Environment(RootViewModelPhone.self) var vm
    @Environment(FuncModel.self) var funcModel
    @Environment(CalendarModel.self) private var calModel
    @Environment(PayMethodModel.self) private var payModel
    @Environment(CategoryModel.self) private var catModel
    @Environment(KeywordModel.self) private var keyModel
    
    //@State private var transEditID: Int?
    //@State private var transPreviewID: Int?
    @Binding var showSearchBar: Bool
    @Binding var selectedDay: CBDay?
    var focusedField: FocusState<Int?>.Binding
    var searchFocus: FocusState<Int?>.Binding
    
    let touchAndHoldPlusButtonTip = TouchAndHoldPlusButtonTip()
    let touchAndHoldMonthToFilterCategoriesTip = TouchAndHoldMonthToFilterCategoriesTip()
    let swipeToChangeMonthsTip = SwipeToChangeMonthsTip()
    
    @State private var transEditID: String?
    
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

    /// This is the same as using `.maxLabelWidthObserver()`. But I did it this way to I could understand better when looking at this.
    ///
    @State private var overlayX: CGFloat?
    @State private var overlayY: CGFloat?
    
    
    @State private var overviewDay: CBDay?
    
    @State private var putBackToBottomPanelViewOnRotate = false

    
    var body: some View {
        let _ = Self._printChanges()
        @Bindable var navManager = NavigationManager.shared
        //@Bindable var vm = vm
        @Bindable var calModel = calModel
        
        /// The geomerty reader is needed for the keyboard avoidance
        
        Group {
            calendarView
        }
        .onChange(of: AppState.shared.orientation, { oldValue, newValue in
            if [.faceDown, .faceUp].contains(newValue) {
                return
            }
            
            if viewMode == .bottomPanel || putBackToBottomPanelViewOnRotate {
                if [.landscapeLeft, .landscapeRight].contains(newValue) {
                    putBackToBottomPanelViewOnRotate = true
                    viewMode = .scrollable
                } else {
                    viewMode = .bottomPanel
                    putBackToBottomPanelViewOnRotate = false
                }
            }
        })
        
        //.overlay { Color.red.opacity(0.1) }
        .if(viewMode == .scrollable) {
            $0.onPreferenceChange(MaxSizePreferenceKey.self) { maxDayHeight = $0 }
        }
//        .onChange(of: maxDayHeight, initial: true) { oldValue, newValue in
//            print("HEIGHT: \(newValue)")
//        }
        
        //.safeAreaPadding(.bottom)
        //.padding(.bottom, 40)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        //.ignoresSafeArea(.all, edges: .bottom)
        .standardBackground()
        
        .task {
            let targetDay = calModel.sMonth.days.filter { $0.dateComponents?.day == (calModel.sMonth.num == AppState.shared.todayMonth ? AppState.shared.todayDay : 1) }.first
            selectedDay = targetDay
        }
        .sensoryFeedback(.selection, trigger: transEditID) { oldValue, newValue in
            newValue != nil
        }
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
//        .refreshable {
//            Task {
//                calModel.prepareForRefresh()
//                await funcModel.downloadEverything(setDefaultPayMethod: false, createNewStructs: true, refreshTechnique: .viaButton)
//            }
//        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            calendarToolbar()
        }
        
        /// This exists in 2 place - purely for visual effect. See ``LineItemView``
        /// This is needed because you can close the popover without actually clicking the close button. So I need somewhere to do cleanup.
        .onChange(of: transEditID, { oldValue, newValue in
            print(".onChange(of: transEditID)")
            /// When `newValue` is false, save to the server. We have to use this because `.popover(isPresented:)` has no onDismiss option.
            if oldValue != nil && newValue == nil {
                calModel.saveTransaction(id: oldValue!, day: selectedDay!)
                /// When adding a transaction via a day's context menu, the selectedDay gets changed to the contexts day. So when closing the transaction, put the selected day back to today so the normal plus button works and the gray box goes back to today.
                /// Gotta have a selectedDay for the editing of a transaction. Since one is not always used in details view, set to the current day if in the current month, otherwise set to the first of the month.
                if viewMode == .scrollable {
                    let targetDay = calModel.sMonth.days.filter { $0.dateComponents?.day == (calModel.sMonth.num == AppState.shared.todayMonth ? AppState.shared.todayDay : 1) }.first
                    selectedDay = targetDay
                }
            }
        })
        .sheet(item: $transEditID) { id in
            TransactionEditView(transEditID: id, day: selectedDay!, isTemp: false)
                .onDisappear {
                    /// Present tip after trying to add 3 new transactions.
                    let trans = calModel.getTransaction(by: id, from: .normalList)
                    if trans.action == .add {
                        TouchAndHoldPlusButtonTip.didTouchPlusButton.sendDonation()
                    }
                }
        }
        
        .sheet(isPresented: $showAnalysisSheet) {
            AnalysisSheet2(showAnalysisSheet: $showAnalysisSheet)
        }
        .sheet(isPresented: $showCalendarOptionsSheet) {
            CalendarOptionsSheet(selectedDay: $selectedDay)
        }        
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
        .sheet(isPresented: $calModel.showSmartTransactionPaymentMethodSheet) {
            //PaymentMethodSheet(payMethod: Binding($calModel.pendingSmartTransaction)!.payMethod, trans: calModel.pendingSmartTransaction, calcAndSaveOnChange: true, whichPaymentMethods: .allExceptUnified, isPendingSmartTransaction: true)
            PaymentMethodSheet(
                payMethod: Binding(get: { CBPaymentMethod() }, set: { calModel.pendingSmartTransaction!.payMethod = $0 }),
                trans: calModel.pendingSmartTransaction,
                calcAndSaveOnChange: true,
                whichPaymentMethods: .allExceptUnified,
                isPendingSmartTransaction: true
            )
            
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
        .sheet(isPresented: $calModel.showSmartTransactionDatePickerSheet, onDismiss: {
            if calModel.pendingSmartTransaction!.date == nil {
                calModel.pendingSmartTransaction!.date = Date()
            }
            
            calModel.saveTransaction(id: calModel.pendingSmartTransaction!.id, isPendingSmartTransaction: true)
            calModel.tempTransactions.removeAll()
            calModel.pendingSmartTransaction = nil
        }, content: {
            GeometryReader { geo in
                ScrollView {
                    VStack {
                        SheetHeader(title: "Select Receipt Date", subtitle: calModel.pendingSmartTransaction!.title) {
                            calModel.showSmartTransactionDatePickerSheet = false
                        }
                        
                        Divider()                        
                        
                        DatePicker(selection: Binding($calModel.pendingSmartTransaction)!.date ?? Date(), displayedComponents: [.date]) {
                            EmptyView()
                        }
                        .datePickerStyle(.graphical)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .labelsHidden()
                       
                        Spacer()
                        Button("Done") {
                            calModel.showSmartTransactionDatePickerSheet = false
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.bottom, 12)
                    }
                    .frame(minHeight: geo.size.height)
                }
                .padding([.top, .horizontal])
            }
            
            //.presentationDetents([.medium])
                                                            
        })
    }
    
    
    
    var calendarView: some View {
        Group {
            @Bindable var calModel = calModel
            VStack(spacing: 0) {
                if !AppState.shared.isLandscape {
                    //TipView(swipeToChangeMonthsTip, arrowEdge: .bottom)
                    fakeNavHeader
                        .popoverTip(swipeToChangeMonthsTip)
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
                                            DayViewPhone(transEditID: $transEditID, day: $day, selectedDay: $selectedDay, showTransferSheet: $showTransferSheet, outerGeo: geo, overlayX: $overlayX, overlayY: $overlayY, putBackToBottomPanelViewOnRotate: $putBackToBottomPanelViewOnRotate, overviewDay: $overviewDay)
                                                .id(day.dateComponents?.day)
                                            
                                                /// This is the dividing line
                                                .overlay(Rectangle().frame(width: nil, height: 2, alignment: .bottom).foregroundColor(Color(.tertiarySystemFill)), alignment: .bottom)
                                            
                                                .if(viewMode == .scrollable) {
                                                    $0.frame(minHeight: (geo.size.height) / divideBy, alignment: .center)
                                                }
                                                .if(viewMode == .bottomPanel) {
                                                    $0.frame(height: (geo.size.height) / divideBy, alignment: .center)
                                                }
                                        }
                                    }
                                }
                            }
                            .scrollIndicators(.hidden)
                            //.transaction { $0.animation = nil }
//                            .transaction {
//                                if geo.frame(in: .global).minX == 0 {
//                                    $0.animation = .default
//                                } else {
//                                    $0.animation = .none
//                                }
//                            }
                            .frame(minHeight: geo.size.height)
                            .if(viewMode == .bottomPanel) {
                                $0.scrollDisabled(true)
                            }
                            .coordinateSpace(name: "Custom")
                            .overlay {
                                if let innerX = overlayX, let innerY = overlayY, let transPreviewID = calModel.transPreviewID {
                                    TransactionPreview(transPreviewID: transPreviewID, transEditID: $transEditID, overlayX: $overlayX, overlayY: $overlayY)
                                        .padding()
                                        .background {
                                            GeometryReader { overlayGeo in
                                                //let trans = calModel.getTransaction(by: transPreviewID)
                                                let overlayFrame = overlayGeo.frame(in: .named("Custom"))
                                                
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(.ultraThickMaterial)
                                                    .onChange(of: overlayFrame) { oldValue, newValue in
                                                        let outerGlobal = geo.frame(in: .global)
                                                        
                                                        /// Keep from overflowing left
                                                        if overlayFrame.minX < outerGlobal.minX { overlayX! -= overlayFrame.minX }
                                                        /// Keep from overflowing right
                                                        if overlayFrame.maxX > outerGlobal.maxX { overlayX! -= overlayFrame.maxX - outerGlobal.maxX }
                                                        /// Keep from overflowing top
                                                        if overlayFrame.minY < outerGlobal.minY { overlayY! -= overlayFrame.minY - outerGlobal.minY }
                                                        /// Keep from overflowing bottom
                                                        if overlayFrame.maxY > outerGlobal.maxY { overlayY! -= overlayFrame.maxY - outerGlobal.maxY }
                                                    }
                                            }
                                        }
                                        .position(x: innerX, y: innerY)
                                        .transition(.asymmetric(insertion: .scale, removal: .opacity)) // top
                                    //.transition(.asymmetric(insertion: .offset(y: 100), removal: .move(edge: .leading))) // bottom
                                }
                            }
                            .onScrollPhaseChange { oldPhase, newPhase in
                                if newPhase == .interacting {
                                    withAnimation {
                                        overlayX = nil
                                        overlayY = nil
                                        calModel.transPreviewID = nil
                                        calModel.hilightTrans = nil
                                    }
                                }
                            }
                            .onChange(of: AppState.shared.orientation) { oldValue, newValue in
                                if [.faceDown, .faceUp].contains(newValue) { return }
                                if [.faceDown, .faceUp].contains(oldValue) { return }
                                if calModel.sMonth.actualNum != AppState.shared.todayMonth || calModel.sYear != AppState.shared.todayYear { return }
                                scroll.scrollTo(AppState.shared.todayDay, anchor: .top)
                            }
                            .onAppear {
                                if calModel.sMonth.actualNum != AppState.shared.todayMonth || calModel.sYear != AppState.shared.todayYear { return }
                                scroll.scrollTo(AppState.shared.todayDay, anchor: .top)
                            }
                        }
                    }
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
                
                if viewMode == .bottomPanel {
                    bottomPanel
                }
                
                if viewMode == .scrollable {
                    if overviewDay != nil {
                        DayOverviewView(day: $overviewDay, transEditID: $transEditID)
                            .frame(height: 300)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            //.edgesIgnoringSafeArea(.bottom)
                    }
                }
            }
        }
    }
    
    
    
    @ToolbarContentBuilder
    func calendarToolbar() -> some ToolbarContent {
        if AppState.shared.isLandscape {
            ToolbarItemGroup(placement: .principal) {
                Text(calModel.sMonth.name)
            }
        }
        
        ToolbarItem(placement: .topBarLeading) {
            backButton
        }
        
        ToolbarItemGroup(placement: .topBarTrailing) {
            @Bindable var calModel = calModel
            HStack(spacing: 20) {
                if calModel.showLoadingSpinner {
                    ProgressView()
                        .tint(.none)
                }
                
                if AppState.shared.longPollFailed {
                    longPollToolbarButton
                }
                
                if AppState.shared.isLandscape {
                    showPaymentMethodSheetButton
                }

                Menu {
                    Section("Display Options") {
                        Picker("Calendar", selection: $viewMode) {
                            condensedViewButton
                                .tag(CalendarViewMode.bottomPanel)
                            fullViewButton
                                .tag(CalendarViewMode.scrollable)
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                    }
                    
                    Section("Analytics") {
                        budgetSheetButton
                        analysisSheetButton
                    }
                    
                    Section("Starting Amounts") {
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
                
                .photosPicker(isPresented: $showPhotosPicker, selection: $calModel.imageSelection, matching: .images, photoLibrary: .shared())
                .opacity(calModel.chatGptIsThinking ? 0 : 1)
                .overlay {
                    ProgressView()
                        .opacity(calModel.chatGptIsThinking ? 1 : 0)
                        .tint(.none)
                }
                #if os(iOS)
                .fullScreenCover(isPresented: $showCamera) {
                    AccessCameraView(selectedImage: $calModel.selectedImage)
                        .background(.black)
                }
                #endif
            }
        }
    }
    
    var backButton: some View {
        Group {
            @Bindable var navManager = NavigationManager.shared
            Button {
                navManager.navPath.removeLast()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text(String(calModel.sYear))
                }
            }
        }
    }
    
    var longPollToolbarButton: some View {
        Button {
            AppState.shared.showAlert("Attempting to resubscribe to multi-device updates. \nIf this keeps failing please contact the developer.")
            Task {
                AppState.shared.longPollFailed = false
                await funcModel.downloadEverything(setDefaultPayMethod: true, createNewStructs: false, refreshTechnique: .viaButton)
                //funcModel.longPollServerForChanges()
            }
        } label: {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .foregroundStyle(.red)
        }
    }
    
    var showPaymentMethodSheetButton: some View {
        Button {
            showPaymentMethodSheet = true
        } label: {
            Text("\(calModel.sPayMethod?.title ?? "")")
        }
    }
    
    var condensedViewButton: some View {
        Button {
            //withAnimation {
                viewMode = .bottomPanel
                calModel.transPreviewID = nil
            //}
        } label: {
            Label {
                Text("Condensed")
            } icon: {
                //Image(systemName: viewMode == .bottomPanel ? "checkmark" : "list.bullet.below.rectangle")
                Image(systemName: "list.bullet.below.rectangle")
                    //.foregroundStyle(viewMode == .bottomPanel ? Color.accentColor : .primary, .secondary, .secondary)
            }
        }
    }
    
    var fullViewButton: some View {
        Button {
            //withAnimation {
                viewMode = .scrollable
                /// Put back the selection box since if you're in .bottomPanel mode it could change. Selection box is not able to move in .details mode.
                let targetDay = calModel.sMonth.days.filter { $0.dateComponents?.day == AppState.shared.todayDay }.first
                selectedDay = targetDay
            //}
        } label: {
            HStack {
                Label {
                    Text("Full")
                } icon: {
                    //Image(systemName: viewMode == .scrollable ? "checkmark" : "calendar")
                    Image(systemName: "calendar")
                        //.foregroundStyle(viewMode == .details ? Color.accentColor : .primary, .secondary, .secondary)
                }
            }
        }
    }
    
    var budgetSheetButton: some View {
        Button {
            //viewMode = .budget
            showBudgetSheet = true
        } label: {
            HStack {
                Label {
                    Text("Budget")
                } icon: {
                    Image(systemName: viewMode == .budget ? "checkmark" : "chart.pie")
                        //.foregroundStyle(viewMode == .details ? Color.accentColor : .primary, .secondary, .secondary)
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
                Text("Show All")
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
                searchFocus.wrappedValue = 0 /// 0 is the searchFields focusID
                focusedField.wrappedValue = 0 /// 0 is the searchFields focusID
                //focusedField.wrappedValue = .search
            }
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
        .disabled(viewMode == .budget)
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
                Image(systemName: "arrow.forward")
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
        
            /// Clear preview trans when switching payment method or category filter
            .onChange(of: calModel.sPayMethod) { oldValue, newValue in
                calModel.transPreviewID = nil
            }
            .onChange(of: calModel.sCategory) { oldValue, newValue in
                calModel.transPreviewID = nil
            }
            
            
            
            
//            HStack {
//                Text("")
//                Spacer()
//            }
//            .contentShape(Rectangle())
//            .onTapGesture {
//                if viewMode == .details || viewMode == .scrollable {
////                    calModel.transPreviewID = nil
////                    calModel.hilightTrans = nil
//                    withAnimation {
//                        overlayX = nil
//                        overlayY = nil
//                        calModel.transPreviewID = nil
//                        calModel.hilightTrans = nil
//                    }
//                }
//            }
        
            
//            if phoneLineItemDisplayItem != PhoneLineItemDisplayItem.both {
//                if let transPreviewID = calModel.transPreviewID {
//                    TransactionPreview(transPreviewID: transPreviewID)
//                }
//            }
        }
        //.background(.ultraThinMaterial)
        .padding(.bottom, 10)
        .contentShape(Rectangle())
        
        
        .gesture(DragGesture()
            .onEnded { value in
                let dragAmount = value.translation.width
                if dragAmount < -200 {
                    var next: NavDestination? {
                        switch calModel.sMonth.enumID {
                        case .lastDecember: return .january
                        case .january:      return .february
                        case .february:     return .march
                        case .march:        return .april
                        case .april:        return .may
                        case .may:          return .june
                        case .june:         return .july
                        case .july:         return .august
                        case .august:       return .september
                        case .september:    return .october
                        case .october:      return .november
                        case .november:     return .december
                        case .december:     return .nextJanuary
                        case .nextJanuary:  return nil
                        default:            return nil
                        }
                    }
                    
                    if let next = next {
                        NavigationManager.shared.navPath = [next]
                        SwipeToChangeMonthsTip.didChangeViaSwipe = true
                        swipeToChangeMonthsTip.invalidate(reason: .actionPerformed)
                    }
                                        
                } else if dragAmount > 200 {
                    var prev: NavDestination? {
                        switch calModel.sMonth.enumID {
                        case .lastDecember: return nil
                        case .january:      return .lastDecember
                        case .february:     return .january
                        case .march:        return .february
                        case .april:        return .march
                        case .may:          return .april
                        case .june:         return .may
                        case .july:         return .june
                        case .august:       return .july
                        case .september:    return .august
                        case .october:      return .september
                        case .november:     return .october
                        case .december:     return .november
                        case .nextJanuary:  return .december
                        default:            return nil
                        }
                    }
                    
                    if let prev = prev {
                        NavigationManager.shared.navPath = [prev]
                        SwipeToChangeMonthsTip.didChangeViaSwipe = true
                        swipeToChangeMonthsTip.invalidate(reason: .actionPerformed)
                    }
                }
            }
        )
    }
        
    var bottomPanel: some View {
        ScrollView {
            /// Preview Panel
            if let selectedDay = selectedDay {
                var filteredTrans: Array<CBTransaction> {
                    calModel.filteredTrans(day: selectedDay)
                }
                
                VStack(spacing: 0) {
                    Divider()
                    
                    if filteredTrans.isEmpty {
                        ContentUnavailableView("No Transactions", systemImage: "bag.fill.badge.questionmark", description: Text(" \(selectedDay.displayDate)"))
                        Button("Add") {
                            transEditID = UUID().uuidString
                        }
                    } else {
                        VStack(spacing: 0) {
                            //List {
                            #warning("Using the same filter approach I use for the mac causes the sheet to die")
                            ForEach(filteredTrans) { trans in
                                VStack(spacing: 0) {
                                    LineItemView(trans: trans, day: selectedDay)
                                        //.padding(.vertical, 4)
                                    //LineItemViewPhone(trans: trans, day: selectedDay)
                                    Divider()
                                }
                                .listRowInsets(EdgeInsets())
                            }
                            //}
                            //.listStyle(.plain)
                            
                        }
                    }
                }
            } else {
                VStack {
                    Spacer()
                    Text("Please select a day to view transactions.")
                    Spacer()
                }
            }
        }
        .padding(.top, 10)
    }
    
    
    
    
    struct TransactionPreview: View {
        @AppStorage("appColorTheme") var appColorTheme: String = Color.green.description
        @AppStorage("lineItemIndicator") var lineItemIndicator: LineItemIndicator = .emoji
        @AppStorage("updatedByOtherUserDisplayMode") var updatedByOtherUserDisplayMode = UpdatedByOtherUserDisplayMode.full
        @AppStorage("viewMode") var viewMode = CalendarViewMode.scrollable
        @AppStorage("useWholeNumbers") var useWholeNumbers = false
        @AppStorage("threshold") var threshold = "500.0"
        
        @Environment(CalendarModel.self) private var calModel
        
        let transPreviewID: String
        @Binding var transEditID: String?
        @Binding var overlayX: CGFloat?
        @Binding var overlayY: CGFloat?
        
        
        var body: some View {
            let trans = calModel.getTransaction(by: transPreviewID, from: .normalList)
            let isNew = trans.title.isEmpty && trans.action == .add
            let wasUpdatedByAnotherUser = trans.updatedBy.id != AppState.shared.user?.id
            
            if !isNew {
                var amountColor: Color {
                    if trans.payMethod?.accountType == .credit {
                        trans.amount < 0 ? .blue : .gray
                    } else {
                        trans.amount > 0 ? .blue : .gray
                    }
                }
                
                VStack(alignment: .customHorizontalAlignment, spacing: 0) {
                    VStack(alignment: .trailing) {
                        
                        Button {
                            withAnimation {
                                overlayX = nil
                                overlayY = nil
                                calModel.transPreviewID = nil
                                calModel.hilightTrans = nil
                            }
                        } label: {
                            Image(systemName: "xmark")
                        }
                        .buttonStyle(.plain)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.gray)
                        .imageScale(.small)
                        .frame(width: 20, height: 20)
                        .foregroundStyle(.gray)
                        //.background(isPressed ? Color(.darkGray) : buttonColor)
                        .background(Color(.darkGray))
                        .clipShape(Circle())
                        
                        //Button("Close") {}
                    }
                    
                    .alignmentGuide(.customHorizontalAlignment, computeValue: { $0[HorizontalAlignment.leading] })
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: lineItemIndicator == .dot ? 0 : 4) {
                            if calModel.isUnifiedPayMethod /* && showAccountOnUnifiedView */ {
                                CircleDot(color: trans.payMethod?.color ?? .primary, width: 5)
                                    .padding(.leading, 1)
                            }
                                                                                                                
                            if lineItemIndicator == .dot {
                                CircleDot(color: trans.category?.color ?? .primary, width: 5)
                                    .padding(.leading, 1)

                            } else {
                                if let emoji = trans.category?.emoji {
                                    
                                    Image(systemName: emoji)
                                        .foregroundStyle( trans.category?.color ?? .primary)
                                        //.foregroundStyle( trans.category?.color ?? .primary, .primary, .secondary)
                                        .font(.caption2)
                                    
                                    //Text(emoji).frame(width: 20)
                                } else {
                                    CircleDot(color: .primary, width: 5)
                                        .padding(.leading, 1)
                                }
                            }
                            
                            Text(trans.title)
                                .foregroundStyle(trans.color)
                                .if(wasUpdatedByAnotherUser && updatedByOtherUserDisplayMode == .concise) {
                                    $0.italic(true).bold(true)
                                }
                                .lineLimit(1)
                                
                            Spacer()
                                .frame(maxWidth: 10)
                                
                            
                            Text(trans.amount.currencyWithDecimals(useWholeNumbers ? 2 : 0))
                                .foregroundStyle(amountColor)
                                .font(.callout)
                        }
                        //.frame(maxWidth: .infinity)
                        
//                        Divider()
//                            .frame(maxWidth: .infinity)
//                            
                        
                        VStack(alignment: .leading, spacing: 0) {
                            if trans.notifyOnDueDate {
                                HStack(spacing: 2) {
                                    Image(systemName: "bell")
                                    let text = trans.notificationOffset == 0 ? "On day of" : (trans.notificationOffset == 1 ? "The day before" : "2 days before")
                                    Text(text)
                                }
                                .foregroundStyle(.gray)
                                .font(.caption2)
                            }
                            
                            if wasUpdatedByAnotherUser && updatedByOtherUserDisplayMode == .full {
                                HStack(spacing: 2) {
                                    Image(systemName: "person")
                                    Text("\(trans.updatedBy.initials)")
                                }
                                .foregroundStyle(.gray)
                                .font(.caption2)
                            }
                        }
                        //.frame(maxWidth: .infinity)
                    }
                    //.fixedSize(horizontal: true, vertical: false)
                    .alignmentGuide(.customHorizontalAlignment, computeValue: { $0[HorizontalAlignment.leading] })
                    .onTapGesture(count: 2) {
                        transEditID = calModel.transPreviewID
                    }
                    .onTapGesture(count: 1) {
                        withAnimation {
                            calModel.transPreviewID = nil
                            calModel.hilightTrans = nil
                        }
                    }
                }
            }
        }
    }
    
    
    struct DayOverviewView: View {
        @Environment(CalendarModel.self) private var calModel
        @Binding var day: CBDay?
        @Binding var transEditID: String?
        
        @Environment(\.dismiss) var dismiss
        
        var moreButton: some View {
            Button {
                
            } label: {
                Image(systemName: "ellipsis")
            }
        }
        
        var body: some View {
            if let day {
                VStack {
                    SheetHeader(
                        title: day.displayDate,
                        close: { withAnimation { self.day = nil } },
                        view1: { moreButton }
                    )
                    .padding()
                                                    
                    ScrollView {
                        /// Preview Panel
                        
                        var filteredTrans: Array<CBTransaction> {
                            calModel.filteredTrans(day: day)
                        }
                        
                        VStack(spacing: 0) {
                            Divider()
                            
                            if filteredTrans.isEmpty {
                                ContentUnavailableView("No Transactions", systemImage: "bag.fill.badge.questionmark")
                                Button("Add") {
                                    transEditID = UUID().uuidString
                                }
                            } else {
                                VStack(spacing: 0) {
                                    //List {
                                    #warning("Using the same filter approach I use for the mac causes the sheet to die")
                                    ForEach(filteredTrans) { trans in
                                        VStack(spacing: 0) {
                                            LineItemView(trans: trans, day: day)
                                                //.padding(.vertical, 4)
                                            //LineItemViewPhone(trans: trans, day: selectedDay)
                                            Divider()
                                        }
                                        .listRowInsets(EdgeInsets())
                                    }
                                    //}
                                    //.listStyle(.plain)
                                    
                                }
                            }
                        }
                    }
                }
                .background { Color.darkGray.ignoresSafeArea(edges: .bottom) }
            }
            
        }
    }
    
}
#endif
