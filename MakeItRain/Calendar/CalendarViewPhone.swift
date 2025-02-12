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
    @AppStorage("useWholeNumbers") var useWholeNumbers = false
    @AppStorage("threshold") var threshold = "500.0"
    @AppStorage("phoneLineItemDisplayItem") var phoneLineItemDisplayItem: PhoneLineItemDisplayItem = .both
    
        
    @Environment(FuncModel.self) var funcModel
    @Environment(CalendarModel.self) private var calModel
    @Environment(PayMethodModel.self) private var payModel
    @Environment(CategoryModel.self) private var catModel
    @Environment(KeywordModel.self) private var keyModel
    @Environment(EventModel.self) private var eventModel
    
    //@State private var transEditID: Int?
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
    
    @State private var overviewDay: CBDay?
    
    @State private var putBackToBottomPanelViewOnRotate = false
    
    @State private var scrollHeight: CGFloat = 0
    @State private var transHeight: CGFloat = 0

    
    var body: some View {
        //let _ = Self._printChanges()
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
        .task {
            let targetDay = calModel.sMonth.days.filter { $0.dateComponents?.day == (calModel.sMonth.num == AppState.shared.todayMonth ? AppState.shared.todayDay : 1) }.first
            selectedDay = targetDay
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
        /// This is needed (passing the ID instead of the trans) because you can close the popover without actually clicking the close button. So I need somewhere to do cleanup.
        .onChange(of: transEditID, { oldValue, newValue in
            print(".onChange(of: transEditID)")
            /// When `newValue` is false, save to the server. We have to use this because `.popover(isPresented:)` has no onDismiss option.
            if oldValue != nil && newValue == nil {
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
        .sheet(isPresented: $showCalendarOptionsSheet, onDismiss: {
            recalculateTransHeight()
            
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
                                                putBackToBottomPanelViewOnRotate: $putBackToBottomPanelViewOnRotate,
                                                showPhotosPicker: $showPhotosPicker,
                                                showCamera: $showCamera,
                                                overviewDay: $overviewDay,
                                                transHeight: $transHeight
                                            )
                                            .id(day.dateComponents?.day)
                                            /// This is the dividing line
                                            .overlay(Rectangle().frame(width: nil, height: 2, alignment: .bottom).foregroundColor(Color(.tertiarySystemFill)), alignment: .bottom)
                                            
                                            //.frame(minHeight: geo.size.height / divideBy, alignment: .center)
                                            .frame(minHeight: scrollHeight / divideBy, alignment: .center)
                                        }
                                    }
                                }
                            }
                            .scrollIndicators(.hidden)
                            //.transaction { $0.animation = nil }
                            //.frame(minHeight: geo.size.height)
                            .frame(height: overviewDay == nil ? scrollHeight : (scrollHeight) - (AppState.shared.isLandscape ? 150 : 300))
                            .onScrollPhaseChange { oldPhase, newPhase in
                                if newPhase == .interacting {
                                    withAnimation { calModel.hilightTrans = nil }
                                }
                            }
                            .onChange(of: AppState.shared.orientation) { oldValue, newValue in
                                if [.faceDown, .faceUp].contains(newValue) { return }
                                if [.faceDown, .faceUp].contains(oldValue) { return }
                                if calModel.sMonth.actualNum != AppState.shared.todayMonth || calModel.sYear != AppState.shared.todayYear { return }
                                scroll.scrollTo(AppState.shared.todayDay, anchor: .top)
                            }
//                            .onChange(of: overviewDay) { oldValue, newValue in
//                                if phoneLineItemDisplayItem != .both {
//                                    withAnimation {
//                                        scroll.scrollTo(newValue?.dateComponents?.day, anchor: .bottom)
//                                    }
//                                }
//                            }
                            .onAppear {
                                if calModel.sMonth.actualNum != AppState.shared.todayMonth || calModel.sYear != AppState.shared.todayYear { return }
                                scroll.scrollTo(AppState.shared.todayDay, anchor: .top)
                            }
                        }
                        
                        if overviewDay != nil {
                            DayOverviewView(
                                day: $overviewDay,
                                selectedDay: $selectedDay,
                                transEditID: $transEditID,
                                showTransferSheet: $showTransferSheet,
                                showCamera: $showCamera,
                                showPhotosPicker: $showPhotosPicker
                            )
                            .frame(height: AppState.shared.isLandscape ? 150 : 300)
                            .frame(maxHeight: .infinity, alignment: .bottom)
                            .transition(.move(edge: .bottom))
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
                .opacity(calModel.chatGptIsThinking ? 0 : 1)
                .overlay {
                    ProgressView()
                        .opacity(calModel.chatGptIsThinking ? 1 : 0)
                        .tint(.none)
                }
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
//                        NavigationManager.shared.navPath = [prev]
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
//                        NavigationManager.shared.navPath = [next]
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
    
            
    struct DayOverviewView: View {
        @Environment(\.dismiss) var dismiss
        @Environment(CalendarModel.self) private var calModel
        @Environment(EventModel.self) private var eventModel
        
        @Binding var day: CBDay?
        /// The transaction Sheet and the transfer sheet use the selected day - so keep it up to date with the day being displayed in the bottom panel
        @Binding var selectedDay: CBDay?
        @Binding var transEditID: String?
        @Binding var showTransferSheet: Bool
        @Binding var showCamera: Bool
        @Binding var showPhotosPicker: Bool
        
        @State private var showDropActions = false
        @State private var showDailyActions = false
        
        var body: some View {
            if let day {
                var filteredTrans: Array<CBTransaction> {
                    calModel.filteredTrans(day: day)
                }
                VStack {
                    if !AppState.shared.isLandscape { header }
                    ScrollView {
                        if AppState.shared.isLandscape { header }
                        
                        VStack(spacing: 0) {
                            Divider()
                            
                            if filteredTrans.isEmpty {
                                ContentUnavailableView("No Transactions", systemImage: "bag.fill.badge.questionmark")
                                Button("Add") {
                                    transEditID = UUID().uuidString
                                }
                            } else {
                                VStack(spacing: 0) {
                                    ForEach(filteredTrans) { trans in
                                        VStack(spacing: 0) {
                                            LineItemView(trans: trans, day: day)
                                            Divider()
                                        }
                                        .listRowInsets(EdgeInsets())
                                    }
                                }
                            }
                        }
                    }
                }
                .background {
                    //Color.darkGray.ignoresSafeArea(edges: .bottom)
                    Color(.secondarySystemBackground).ignoresSafeArea(edges: .bottom)
                }
                .dropDestination(for: CBTransaction.self) { droppedTrans, location in
                    let trans = droppedTrans.first
                    if let trans {
                        if trans.date == day.date {
                            calModel.dragTarget = nil
                            AppState.shared.showToast(title: "Operation Cancelled", subtitle: "Can't copy or move to the original day", body: "Please try again", symbol: "hand.raised.fill", symbolColor: .orange)
                            return true
                        }
                                                
                        calModel.transactionToCopy = trans
                        showDropActions = true
                    }
                    
                    return true
                    
                } isTargeted: {
                    if $0 { withAnimation { calModel.dragTarget = day } }
                }
                
                .confirmationDialog("\(day.weekday), the \((day.dateComponents?.day ?? 0).withOrdinal())\n\(calModel.transactionToCopy?.title ?? "N/A")", isPresented: $showDropActions) {
                    moveButton
                    copyAndPasteButton
                    Button("Cancel", role: .cancel) {
                        calModel.dragTarget = nil
                    }
                } message: {
                    Text("\(calModel.transactionToCopy?.title ?? "N/A")\nDropped on \(day.weekday), the \((day.dateComponents?.day ?? 0).withOrdinal())")
                }
                
                .confirmationDialog("\(day.weekday), the \((day.dateComponents?.day ?? 0).withOrdinal())", isPresented: $showDailyActions) {
                    DayContextMenu(
                        day: day,
                        selectedDay: $day,
                        transEditID: $transEditID,
                        showTransferSheet: $showTransferSheet,
                        showCamera: $showCamera,
                        showPhotosPicker: $showPhotosPicker
                    )
                } message: {
                    Text("\(day.weekday), the \((day.dateComponents?.day ?? 0).withOrdinal())")
                }
            }
        }
        
        
        var header: some View {
            SheetHeader(
                title: day!.displayDate,
                close: {
                    /// When closing, set the selected day back to today or the first of the month if not viewing the current month (which would be the default)
                    withAnimation { self.day = nil }
                    let targetDay = calModel.sMonth.days.filter { $0.dateComponents?.day == (calModel.sMonth.num == AppState.shared.todayMonth ? AppState.shared.todayDay : 1) }.first
                    selectedDay = targetDay
                },
                view1: { moreButton }
            )
            .padding()
        }
        
        
        var moreButton: some View {
//            Button {
//                showDailyActions = true
//            } label: {
//                Image(systemName: "ellipsis")
//            }
                        
            Menu {
                DayContextMenu(
                    day: day!,
                    selectedDay: $day,
                    transEditID: $transEditID,
                    showTransferSheet: $showTransferSheet,
                    showCamera: $showCamera,
                    showPhotosPicker: $showPhotosPicker
                )
            } label: {
                Image(systemName: "ellipsis")
            }
        }
        
        var moveButton: some View {
            Button("Move") {
                withAnimation {
                    if let trans = calModel.transactionToCopy {
                        let originalMonth = trans.dateComponents?.month!
                        let monthObj = calModel.months.filter { $0.num == originalMonth }.first
                        if let monthObj {
                            monthObj.days.forEach { $0.transactions.removeAll(where: { $0.id == trans.id }) }
                        }
                        
                        trans.log(field: .date, old: trans.date?.string(to: .monthDayShortYear), new: day?.date?.string(to: .monthDayShortYear))
                        
                        trans.date = day?.date!
                        calModel.sMonth.days.forEach { $0.transactions.removeAll(where: { $0.id == trans.id }) }
                                                        
                        day?.transactions.append(trans)
                        calModel.dragTarget = nil
                        calModel.saveTransaction(id: trans.id, eventModel: eventModel)
                    }
                }
            }
        }
        
        var copyAndPasteButton: some View {
            Button {
                withAnimation {
                    if let trans = calModel.getCopyOfTransaction() {
                        trans.date = day?.date!
                                                        
                        if !calModel.isUnifiedPayMethod {
                            trans.payMethod = calModel.sPayMethod!
                        }
                        
                        day?.upsert(trans)
                        calModel.dragTarget = nil
                        calModel.saveTransaction(id: trans.id, day: day)
                    }
                }
            } label: {
                Text("Copy & Paste")
            }
        }
            
    }
}
#endif
