//
//  RootView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/18/24.
//

import SwiftUI

struct RootView: View {
    //@Local(\.colorTheme) var colorTheme
    
    @Environment(\.scenePhase) var scenePhase
    @Environment(FuncModel.self) var funcModel
    @Environment(CalendarModel.self) var calModel
    @Environment(PayMethodModel.self) var payModel
    @Environment(CategoryModel.self) var catModel
    @Environment(KeywordModel.self) var keyModel
    @Environment(RepeatingTransactionModel.self) var repModel
    
    //@State private var warmUpTransactionView = false
    
    let monthNavigationNamespace: Namespace.ID
        
    var body: some View {
        //let _ = Self._printChanges()
        @Bindable var navManager = NavigationManager.shared
        @Bindable var funcModel = funcModel
        
        content
//            .onAppear {
//                warmUpTransactionView = true
//            }
            /// We have to "Warm Up" the transaction view since it's expensive to compute.
            /// This way the layout will get cached and future transactions will open quickly.
//            .background {
//                TransactionEditView(
//                    trans: CBTransaction(),
//                    transEditID: .constant("0"),
//                    day: CBDay(date: Date()),
//                    isTemp: false,
//                    transLocation: .searchResultList,
//                    isWarmUp: true
//                )
//                .opacity(0)
//                .allowsHitTesting(false)
//            }
            //.task { prepareView() }
            /// This is here in case you want to cancel the dragging transaction - this will unhilight the last hilighted day.
            .dropDestination(for: CBTransaction.self) { _, _ in
                calModel.dragTarget = nil
                return true
            }

            // MARK: - Handle Global State Changes
            #if os(macOS)
            .onChange(of: navManager.selection) { peformNavigationOnMac($0, $1) }
            #else
            .onChange(of: calModel.showMonth) { setNavToNilWhenMonthSheetCloses($0, $1) }
            .onChange(of: navManager.selectedMonth, initial: true) { clearMonthWhenNavSetToNil($0, $1) }
            #endif
            .onChange(of: AppState.shared.methsExist) { downloadAllContentOnSaveOfFirstPaymentMethod($0, $1) }
            .onChange(of: calModel.sYear) { downloadContentOnYearChange($0, $1) }
            .onChange(of: payModel.paymentMethods.filter { !$0.isHidden && !$0.isPrivate }.count) {
                recalcTotalsWhenAPaymentMethodChangesHiddenStatus($0, $1)
            }
                                        
            // MARK: - Handling Lifecycles
            #if os(iOS)
            .onChange(of: scenePhase) {
                switch $1 {
                case .background:   sceneBecameBackground()
                case .inactive:     break
                case .active:       sceneBecameActive()
                @unknown default:   fatalError("Unknown scene type")
                }
            }
            #else
            .onChange(of: AppState.shared.macWokeUp) { if $1 { sceneBecameActive() } }
            .onChange(of: AppState.shared.macSlept) { if $1 { sceneBecameBackground() } }
            .onChange(of: AppState.shared.macWindowDidBecomeMain) { if $1 { sceneBecameActive() } }
            #endif
    }
    
    var content: some View {
        VStack {
            #if os(macOS)
            RootViewMac()
            #else
            if AppState.shared.isIpad {
                RootViewPad(monthNavigationNamespace: monthNavigationNamespace)
            } else {
                RootViewPhone(monthNavigationNamespace: monthNavigationNamespace)
            }
            #endif
        }
    }
    
    func prepareView() {
        #if os(iOS)
        if AppState.shared.isIphone {
            if !AppState.shared.showPaymentMethodNeededSheet {
                calModel.showMonth = true
            }
        }
        #endif
    }
    
    
    // MARK: - OnChange Functions
    
    #if os(macOS)
    func peformNavigationOnMac(_ old: NavDestination?, _ new: NavDestination?) {
        /// Set ``sMonth`` in ``CalendarModel`` so the model is aware.
        
        calModel.sMonth = CBMonth(num: 100000)
        //calModel.hilightTrans = nil
        
        if let selection = NavigationManager.shared.selection {
            if NavDestination.justMonths.contains(selection) {
                Task {
                    let targetMonth = calModel.months.filter { $0.enumID == selection }.first
                    if let targetMonth {
                        funcModel.prepareStartingAmounts(for: targetMonth)
                        calModel.setSelectedMonthFromNavigation(navID: selection, calculateStartingAndEod: true)
                    } else {
                        fatalError("Incorrect month")
                    }
                }
            }
        }
    }
    
    
    #else
    func setNavToNilWhenMonthSheetCloses(_ old: Bool, _ new: Bool) {
        /// The NavLink for a month view is technically a button that sets `NavigationManager.selection`, and then sets `showMonth = true` , which opens a fullScreenCover.
        /// When the fullScreenCover is closed, set `NavigationManager.selection` to nil.
        
        if !new { NavigationManager.shared.selectedMonth = nil }
    }
           
    
    func clearMonthWhenNavSetToNil(_ old: NavDestination?, _ new: NavDestination?) {
        /// Clear out `calModel.sMonth` when `NavigationManager.selectedMonth` is set to nil, which will happen when closing the months fullScreenCover.
        
        //calModel.hilightTrans = nil
        if new == nil {
            calModel.sMonth = CBMonth(num: 100000)
        }
    }
    #endif
        
    func downloadAllContentOnSaveOfFirstPaymentMethod(_ old: Bool, _ new: Bool) {
        // If you add your first payment method, download all the content on save.
        /// `AppState.shared.methsExist` will get set by either `determineIfUserIsRequiredToAddPaymentMethod()` in the ``PayMethodModel``, or by `AuthState.attemptLogin`.
        
        if new && !old {
            funcModel.refreshTask = Task {
                calModel.prepareMonths()
                await funcModel.downloadEverything(
                    setDefaultPayMethod: true,
                    createNewStructs: true,
                    refreshTechnique: .viaButton
                )
            }
            funcModel.longPollServerForChanges()
        }
    }
        
    
    func downloadContentOnYearChange(_ old: Int, _ new: Int) {
        /// Kick off the download task when the year changes.
        funcModel.refreshTask?.cancel()
        funcModel.refreshTask = Task {
            calModel.months.forEach { month in
                month.days.removeAll()
                month.startingAmounts.removeAll()
                month.budgets.removeAll()
                
                if month.enumID == .lastDecember {
                    month.year = new - 1
                } else if month.enumID == .nextJanuary {
                    month.year = new + 1
                } else {
                    month.year = new
                }
            }
            
            calModel.prepareMonths()
            /// This is not needed because `.onChange(of: navManager.selection)` handles it (even when switching years)
            //calModel.prepareStartingAmount()
            await funcModel.downloadEverything(setDefaultPayMethod: true, createNewStructs: true, refreshTechnique: .viaButton)
        }
    }
        
    
    func recalcTotalsWhenAPaymentMethodChangesHiddenStatus(_ old: Int, _ new: Int) {
        /// If you are viewing transactions from a payment method and that method gets hidden or marked private by another device, recalculate the totals.
        
        print("\(old) -> \(new)")
        if new < old {
            let allowMeths = payModel.paymentMethods.filter { !$0.isHidden && !$0.isPrivate }.map { $0.id }
            
            if !allowMeths.contains(calModel.sPayMethod?.id ?? "0") {
                calModel.sPayMethod = nil
                calModel.sPayMethod = payModel.paymentMethods.filter { $0.isUnifiedDebit }.first
            }
                            
            calModel.sMonth.startingAmounts.removeAll(where: { !allowMeths.contains($0.payMethod.id) })
            let _ = calModel.calculateTotal(for: calModel.sMonth)
        }
    }
    
    
    // MARK: - LifeCycle Functions
    
    func sceneBecameActive() {
        #if os(iOS)
        AppState.shared.scenePhase = .active
        #endif
        AppState.shared.startNewNowTimer()
        
        if funcModel.refreshTask == nil {
            funcModel.refreshTask = Task {
                if await AppState.shared.checkIfDownloadingDataIsNeeded() {
                    print("🎃There is new data to download.")
                    await funcModel.downloadEverything(setDefaultPayMethod: false, createNewStructs: false, refreshTechnique: .viaSceneChange)
                } else {
                    print("🎃There is no new data to download.")
                    funcModel.longPollServerForChanges()
                }
            }
        }
    }
    
    func sceneBecameBackground() {
        #if os(iOS)
        AppState.shared.scenePhase = .background
        #endif
        AppState.shared.cancelNowTimer()
        funcModel.longPollTask?.cancel()
        funcModel.longPollTask = nil
        funcModel.refreshTask?.cancel()
        funcModel.refreshTask = nil
    }

    
//    #if os(iOS)
//    func handleIosSceneChange(_ old: ScenePhase, _ new: ScenePhase) {
//        print("-- \(#function) -- \(new)")
//        switch new {
//        case .background:  sceneBecameBackground()
//        case .inactive: break
//        case .active: sceneBecameActive()
//        @unknown default: fatalError("Unknown scene type")
//        }
//    }
//    #endif
//    
//    
//    #if os(macOS)
//    func handleMacWokeUp(_ old: Bool, _ new: Bool) {
//        print("-- \(#function)")
//        if new { sceneBecameActive() }
//    }
//    
//    
//    func handleMacSlept(_ old: Bool, _ new: Bool) {
//        print("-- \(#function)")
//        if new { sceneBecameBackground() }
//    }
//    
//    
//    func handleMacWindowDidBecomeMain(_ old: Bool, _ new: Bool) {
//        print("-- \(#function)")
//        if new { sceneBecameActive() }
//    }
//    #endif
}



//
//struct RootViewOG: View {
//    //@Local(\.colorTheme) var colorTheme
//    
//    @Environment(\.scenePhase) var scenePhase
//    @Environment(FuncModel.self) var funcModel
//    @Environment(CalendarModel.self) var calModel
//    @Environment(PayMethodModel.self) var payModel
//    @Environment(CategoryModel.self) var catModel
//    @Environment(KeywordModel.self) var keyModel
//    @Environment(RepeatingTransactionModel.self) var repModel
//    
//    
//    let monthNavigationNamespace: Namespace.ID
//        
//    var body: some View {
//        @Bindable var navManager = NavigationManager.shared
//        @Bindable var funcModel = funcModel
//        //@Bindable var appState = AppState.shared
//        
//        VStack {
//            #if os(macOS)
//            RootViewMac()
//            #else
//            if AppState.shared.isIpad {
//                RootViewPad(monthNavigationNamespace: monthNavigationNamespace)
//            } else {
//                RootViewPhone(monthNavigationNamespace: monthNavigationNamespace)
//            }
//            #endif
//        }
//        .task {
//            /// set the calendar model to use the current month (ignore starting amounts and calculations)
////            if let selectedMonth = navManager.selectedMonth {
////                calViewModel.setSelectedMonthFromNavigation(navID: selectedMonth, calculateStartingAndEod: false)
////            }
//            #if os(iOS)
//            if AppState.shared.isIphone {
//                if !AppState.shared.showPaymentMethodNeededSheet {
//                    calModel.showMonth = true
//                }
//                
//            }
//            #endif
//        }
//        //.tint(Color.theme)
//        
//        /// This is here in case you want to cancel the dragging transaction - this will unhilight the last hilighted day.
//        .dropDestination(for: CBTransaction.self) { droppedTrans, location in
//            calModel.dragTarget = nil
//            return true
//        }
//        
//        #if os(macOS)
//        /// Set ``sMonth`` in ``CalendarModel`` so the model is aware.
//        .onChange(of: navManager.selection) { oldValue, newValue in
//            //print("onChange(of: navManager.selection)")
//            calModel.sMonth = CBMonth(num: 100000)
//            calModel.hilightTrans = nil
//            
//            if let selection = navManager.selection {
//                if NavDestination.justMonths.contains(selection) {
//                    Task {
//                        let targetMonth = calModel.months.filter{ $0.enumID == selection }.first
//                        if let targetMonth {
//                            funcModel.prepareStartingAmounts(for: targetMonth)
//                            calModel.setSelectedMonthFromNavigation(navID: selection, calculateStartingAndEod: true)
//                        } else {
//                            fatalError("Incorrect month")
//                        }
//                    }
//                }
//            }
//        }
//        #endif
//        
//        #if os(iOS)
//        
//        /// The NavLink for a month view is technically a button that sets `NavigationManager.selection`, and then sets `showMonth = true` , which opens a fullScreenCover.
//        /// When the fullScreenCover is closed, set `NavigationManager.selection` to nil.
//        .onChange(of: calModel.showMonth) { oldValue, newValue in
//            //print("onChange(of: showMonth) -- \(newValue)")
//            if !newValue {
//                //print("calModel.showMonth is now false")
//                navManager.selectedMonth = nil
//            }
//        }
//        
//        /// This is ONLY here to hilight open the accessorials on iPhone. It serves no other function.
////        .onChange(of: navManager.navPath) { oldValue, newValue in
////            //print("onChange(of: navManager.navPath) -- \(newValue)")
////            if let newPath = newValue.last {
////                navManager.selection = newPath
////            } else {
////                navManager.selection = nil
////            }
////        }
//        
//        /// Clear out `calModel.sMonth` when `NavigationManager.selection` is set to nil, which will happen when closing the months fullScreenCover.
//        /// This will also happen when leaving a accessorial list, but that is less significant - and more of a "keep the app's state clean" thing.
////        .onChange(of: navManager.selection, initial: true) { oldValue, newValue in
////            //print("onChange(of: navManager.selection) -- \(String(describing: newValue))")
////            calModel.hilightTrans = nil
////            if newValue == nil {
////                Task {
////                    try? await Task.sleep(nanoseconds: UInt64(0.1 * Double(NSEC_PER_SEC)))
////                    calModel.sMonth = CBMonth(num: 100000)
////                }
////            }
////        }
//        
//        /// Clear out `calModel.sMonth` when `NavigationManager.selectedMonth` is set to nil, which will happen when closing the months fullScreenCover.
//        .onChange(of: navManager.selectedMonth, initial: true) { oldValue, newValue in
//            //print("onChange(of: navManager.selection) -- \(String(describing: newValue))")
//            calModel.hilightTrans = nil
//            if newValue == nil {
//                //print("Clearing calModel.sMonth")
//                calModel.sMonth = CBMonth(num: 100000)
////                Task {
////                    try? await Task.sleep(nanoseconds: UInt64(0.1 * Double(NSEC_PER_SEC)))
////                    print("Clearing calModel.sMonth")
////                    calModel.sMonth = CBMonth(num: 100000)
////                }
//            }
//        }
//        #endif
//        
//        /// If you add your first payment method, download all the content on save.
//        /// `AppState.shared.methsExist` will get set by either `determineIfUserIsRequiredToAddPaymentMethod()` in the ``PayMethodModel``, or by `AuthState.attemptLogin`.
//        .onChange(of: AppState.shared.methsExist) { oldValue, newValue in
//            if newValue && !oldValue {
//                funcModel.refreshTask = Task {
//                    calModel.prepareMonths()
//                    await funcModel.downloadEverything(setDefaultPayMethod: true, createNewStructs: true, refreshTechnique: .viaButton)
//                }
//                funcModel.longPollServerForChanges()
//            }
//        }
//        
//        /// Kick off the download task then the year changes.
//        .onChange(of: calModel.sYear) { oldValue, newValue in
//            LoadingManager.shared.showInitiallyLoadingSpinner = true
//            AppState.shared.downloadedData.removeAll()
//            
//            funcModel.refreshTask?.cancel()
//            funcModel.refreshTask = Task {
//                calModel.months.forEach { month in
//                    month.days.removeAll()
//                    month.startingAmounts.removeAll()
//                    month.budgets.removeAll()
//                    
//                    if month.enumID == .lastDecember {
//                        month.year = newValue - 1
//                    } else if month.enumID == .nextJanuary {
//                        month.year = newValue + 1
//                    } else {
//                        month.year = newValue
//                    }
//                }
//                
//                calModel.prepareMonths()
//                /// This is not needed because `.onChange(of: navManager.selection)` handles it (even when switching years)
//                //calModel.prepareStartingAmount()
//                await funcModel.downloadEverything(setDefaultPayMethod: true, createNewStructs: true, refreshTechnique: .viaButton)
//            }
//        }
//        
//        /// If you are viewing transactions from a payment method and that method gets hidden or marked private by another device, recalculate the totals.
//        .onChange(of: payModel.paymentMethods.filter { !$0.isHidden && !$0.isPrivate }.count) { oldValue, newValue in
//            print("\(oldValue) -> \(newValue)")
//            if newValue < oldValue {
//                let allowMeths = payModel.paymentMethods.filter { !$0.isHidden && !$0.isPrivate }.map { $0.id }
//                
//                if !allowMeths.contains(calModel.sPayMethod?.id ?? "0") {
//                    calModel.sPayMethod = nil
//                    calModel.sPayMethod = payModel.paymentMethods.filter { $0.isUnifiedDebit }.first
//                }
//                                
//                calModel.sMonth.startingAmounts.removeAll(where: { !allowMeths.contains($0.payMethod.id) })
//                let _ = calModel.calculateTotal(for: calModel.sMonth)
//            }
//        }
//        
//        // MARK: - Handling Lifecycles (iPhone/iPad)
//        #if os(iOS)
//        .onChange(of: scenePhase) { oldPhrase, newPhase in
//            if newPhase == .inactive {
//                print("scenePhase: Inactive")
//                
//            } else if newPhase == .active {
//                print("scenePhase: Active")
//                
//                AppState.shared.startNewNowTimer()
//                
//                if funcModel.refreshTask == nil {
//                    print("funcModel.refreshTask does not exist")
//                    funcModel.refreshTask = Task {
//                        
//                        let shouldDownload = await AppState.shared.checkIfDownloadingDataIsNeeded()
//                        if shouldDownload {
//                            print("🎃YES NEW DATA TO DOWNLOAD")
//                            await funcModel.downloadEverything(setDefaultPayMethod: false, createNewStructs: false, refreshTechnique: .viaSceneChange)
//                        } else {
//                            print("🎃NO NEW DATA TO DOWNLOAD")
//                            funcModel.longPollServerForChanges()
//                            
//                            Task {
//                                await OpenRecordManager.shared.fetchOpenOrClosed()
//                            }
//                        }
//                    }
//                } else {
//                    print("funcModel.refreshTask already exists")
//                }
//                
//                
//                Task {
//                    let _ = await OpenRecordManager.shared.batchMark(.open)
//                }
//                
//                
//            } else if newPhase == .background {
//                print("scenePhase: Background")
//                AppState.shared.cancelNowTimer()
//                funcModel.longPollTask?.cancel()
//                funcModel.longPollTask = nil
//                funcModel.refreshTask?.cancel()
//                funcModel.refreshTask = nil
//                
//                Task {
//                    let _ = await OpenRecordManager.shared.batchMark(.closed)
//                }
//            }
//        }
//        #endif
//        
//        
//        #if os(macOS)
//        // MARK: - Handling Lifecycles (Mac)
//        .onChange(of: AppState.shared.macWokeUp) { oldValue, newValue in
//            if newValue {
//                AppState.shared.startNewNowTimer()
//                
//                if funcModel.refreshTask == nil {
//                    funcModel.refreshTask = Task {
//                        let shouldDownload = await AppState.shared.checkIfDownloadingDataIsNeeded()
//                        if shouldDownload {
//                            print("🎃YES NEW DATA TO DOWNLOAD")
//                            await funcModel.downloadEverything(setDefaultPayMethod: false, createNewStructs: false, refreshTechnique: .viaSceneChange)
//                        } else {
//                            print("🎃NO NEW DATA TO DOWNLOAD")
//                            funcModel.longPollServerForChanges()
//                        }
//                    }
//                }
//            }
//        }
//        
//        .onChange(of: AppState.shared.macSlept) { oldValue, newValue in
//            if newValue {
//                AppState.shared.cancelNowTimer()
//                funcModel.longPollTask?.cancel()
//                funcModel.longPollTask = nil
//                funcModel.refreshTask?.cancel()
//                funcModel.refreshTask = nil
//            }
//        }
//        
//        .onChange(of: AppState.shared.macWindowDidBecomeMain) { oldValue, newValue in
//            if newValue {
//                AppState.shared.startNewNowTimer()
//                
//                if funcModel.refreshTask == nil {
//                    funcModel.refreshTask = Task {
//                        let shouldDownload = await AppState.shared.checkIfDownloadingDataIsNeeded()
//                        if shouldDownload {
//                            print("🎃YES NEW DATA TO DOWNLOAD")
//                            await funcModel.downloadEverything(setDefaultPayMethod: false, createNewStructs: false, refreshTechnique: .viaSceneChange)
//                        } else {
//                            print("🎃NO NEW DATA TO DOWNLOAD")
//                            funcModel.longPollServerForChanges()
//                        }
//                    }
//                }
//            }
//        }
//        
//        //.backgroundStyle(.background)
//        //.background(Color.totalDarkGray)
//        #endif
//    }
//}
