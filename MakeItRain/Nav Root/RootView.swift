//
//  RootView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/18/24.
//

import SwiftUI

struct RootView: View {
    @Environment(\.scenePhase) var scenePhase
    @Environment(FuncModel.self) var funcModel
    @Environment(CalendarModel.self) var calModel
    @Environment(PayMethodModel.self) var payModel
    @Environment(CategoryModel.self) var catModel
    @Environment(KeywordModel.self) var keyModel
    @Environment(RepeatingTransactionModel.self) var repModel
    @Environment(WebSocketManager.self) var webSocketManager
    @Environment(AppStore.self) var store
            
    var body: some View {
        //let _ = Self._printChanges()
        @Bindable var navManager = NavigationManager.shared
        @Bindable var funcModel = funcModel
        
        VStack {
            #if os(macOS)
                RootViewMac()
            #else
            if AppState.shared.isIpad {
                RootViewPad()
            } else {
                RootViewPhone()
            }
            #endif
        }
        /// This is here in case you want to cancel the dragging transaction - this will un-highlight the last highlighted day.
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
        .onChange(of: calModel.sYear) { downloadContentOnYearChange($0, $1) }
        .onChange(of: AppState.shared.methsExist) { downloadAllContentOnSaveOfFirstPaymentMethod($0, $1) }
        .onChange(of: payModel.paymentMethods.filter { !$0.isHidden && !$0.isPrivate }.count) { recalcTotalsWhenAPaymentMethodChangesHiddenStatus($0, $1) }
                                    
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
    func peformNavigationOnMac(_ old: NavDest?, _ new: NavDest?) {
        /// Set ``sMonth`` in ``CalendarModel`` so the model is aware.
        
        calModel.sMonth = CBMonth(num: 100000)
        //calModel.hilightTrans = nil
        
        if let selection = NavigationManager.shared.selection {
            if NavDest.justMonths.contains(selection) {
                Task {
                    let targetMonth = calModel.months.filter { $0.enumID == selection }.first
                    if let targetMonth {
                        payModel.prepareStartingAmounts(for: targetMonth, calModel: calModel)
                        await calModel.setSelectedMonthFromNavigation(navID: selection, calculateStartingAndEod: true, shouldLoadDashboard: true)
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
           
    
    func clearMonthWhenNavSetToNil(_ old: NavDest?, _ new: NavDest?) {
        /// Clear out `calModel.sMonth` when `NavigationManager.selectedMonth` is set to nil, which will happen when closing the months fullScreenCover.
        
        //calModel.hilightTrans = nil
        if new == nil {
            calModel.sMonth = CBMonth(num: 100000)
        }
    }
    #endif
        
    func downloadAllContentOnSaveOfFirstPaymentMethod(_ old: Bool, _ new: Bool) {
        /// If you add your first payment method, download all the content on save.
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
            webSocketManager.startListening()
            //funcModel.longPollServerForChanges()
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
            let allowMeths: [String?] = payModel.paymentMethods.filter { !$0.isHidden && !$0.isPrivate }.map { $0.id }
            
            /// Set the view method to unified debit, which we know will exist.
            if !allowMeths.contains(calModel.sPayMethod?.id) {
                calModel.sPayMethod = nil
                calModel.sPayMethod = payModel.paymentMethods.filter { $0.isUnifiedDebit }.first
            }
                            
            /// Remove all starting amounts and recalculate totals.
            calModel.sMonth.startingAmounts.removeAll(where: { !allowMeths.contains($0.payMethod?.id) })
            let _ = CalcHelper.calculateTotal(for: calModel.sMonth, store: store)
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
                if await funcModel.checkIfDownloadingDataIsNeeded() {
                    print("🎃There is new data to download.")
                    await funcModel.downloadEverything(setDefaultPayMethod: false, createNewStructs: false, refreshTechnique: .viaSceneChange)
                } else {
                    print("🎃There is no new data to download.")
                    webSocketManager.startListening()
                    //funcModel.longPollServerForChanges()
                }
            }
        }
    }
    
    func sceneBecameBackground() {
        #if os(iOS)
        AppState.shared.scenePhase = .background
        #endif
        AppState.shared.cancelNowTimer()
        //funcModel.longPollTask?.cancel()
        //funcModel.longPollTask = nil
        webSocketManager.stopListening()
        funcModel.refreshTask?.cancel()
        funcModel.refreshTask = nil
    }
}
