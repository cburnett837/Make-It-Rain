//
//  RootView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/18/24.
//

import SwiftUI

//@Observable
//class RootViewModelPhone {
//    //var selectedDay: CBDay?
//    //var showMenu: Bool = false
//    //var showInfo: Bool = false
//    //var didRespondToDrag = false
//    //var offset: CGFloat = 0
//    //var showSearchBar: Bool = false
//}

struct RootView: View {
    @AppStorage("appColorTheme") var appColorTheme: String = Color.green.description
    
    @Environment(\.scenePhase) var scenePhase

    @Environment(FuncModel.self) var funcModel
    @Environment(CalendarModel.self) var calModel
    @Environment(PayMethodModel.self) var payModel
    @Environment(CategoryModel.self) var catModel
    @Environment(KeywordModel.self) var keyModel
    @Environment(RepeatingTransactionModel.self) var repModel
    //@Environment(TagModel.self) var tagModel
    
    #if os(iOS)
    @State private var selectedDay: CBDay?
    #endif
            
    var body: some View {
        @Bindable var navManager = NavigationManager.shared
        @Bindable var calModel = calModel
        @Bindable var funcModel = funcModel
        //@Bindable var appState = AppState.shared
        
        VStack {
            #if os(macOS)
            RootViewMac()
            #else
            RootViewPhone2(selectedDay: $selectedDay)
                //.environment(iPhoneVm)
                
            #endif
        }
        .tint(Color.fromName(appColorTheme))
//        #if os(macOS)
//        .interactiveToasts($appState.toasts)
//        #endif
        
        /// This is here in case you want to cancel the dragging transaction - this will unhilight the last hilighted day.
        .dropDestination(for: CBTransaction.self) { droppedTrans, location in
            calModel.dragTarget = nil
            return true
        }
        
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
        
        #if os(macOS)
        /// Set ``sMonth`` in ``CalendarModel`` so the model is aware
        .onChange(of: navManager.selection, { oldValue, newValue in
            print("onChange(of: navManager.selection)")
            
            calModel.transPreviewID = nil
            //calModel.transEditID = nil
            calModel.hilightTrans = nil
            
            if let selection = navManager.selection {
                if NavDestination.justMonths.contains(selection) {
                    calModel.setSelectedMonthFromNavigation(navID: selection, prepareStartAmount: true)
                }
            }
        })
        #endif
        
        #if os(iOS)
        /// Set ``sMonth`` in ``CalendarModel`` so the model is aware
        .onChange(of: navManager.navPath) { old, new in
            print("onChange(of: navManager.navPath.count)")
            
            print(navManager.navPath)
            
            if let newPath = navManager.navPath.last {
                
                /// I had this commented out, but put it back on 1/2/25 - I think it's needed for visuals only on iOS.
                navManager.selection = newPath
                
                print("NEW PATH \(newPath)")
                if new.count > old.count || new.count == old.count {
                    //navTitle = String(calModel.sYear)
                    calModel.transPreviewID = nil
                   // calModel.transEditID = nil
                    calModel.hilightTrans = nil
                    
                    /// Gotta have a selectedDay for the editing of a transaction. Since one is not always used in details view, set to the current day if in the current month, otherwise set to the first of the month.
                    
                    
                    if NavDestination.justMonths.contains(newPath) {
                        if new.count > old.count {
                            /// Only show the swipe month tip after the month has been changes via navigation 3 times.
                            SwipeToChangeMonthsTip.didChangeMonthViaNavList.sendDonation()
                        }
                        
                        calModel.setSelectedMonthFromNavigation(navID: newPath, prepareStartAmount: true)
                        
                        let targetDay = calModel.sMonth.days.filter { $0.dateComponents?.day == (calModel.sMonth.num == AppState.shared.todayMonth ? AppState.shared.todayDay : 1) }.first
                        selectedDay = targetDay
                        
                        
                    }
                } else {
                    
                }
            } else {
                navManager.selection = nil
            }
        }
        #endif
        
        /// If you add your first payment method, download all the content on save.
        /// `AppState.shared.methsExist` will get set by either `determineIfUserIsRequiredToAddPaymentMethod()` in the ``PayMethodModel``, or by `AuthState.attemptLogin`
        .onChange(of: AppState.shared.methsExist, { oldValue, newValue in
            if newValue && !oldValue {
                funcModel.refreshTask = Task {
                    calModel.prepareMonths()
                    await funcModel.downloadEverything(setDefaultPayMethod: true, createNewStructs: true, refreshTechnique: .viaButton)
                }
                funcModel.longPollServerForChanges()
            }
        })
        
        .onChange(of: calModel.sYear, { oldValue, newValue in
            LoadingManager.shared.showInitiallyLoadingSpinner = true
            AppState.shared.downloadedData.removeAll()
            
            funcModel.refreshTask?.cancel()
            funcModel.refreshTask = Task {
                calModel.months.forEach { month in
                    month.days.removeAll()
                    month.startingAmounts.removeAll()
                    
                    if month.enumID == .lastDecember {
                        month.year = newValue - 1
                    } else if month.enumID == .nextJanuary {
                        month.year = newValue + 1
                    } else {
                        month.year = newValue
                    }
                }
                
                calModel.prepareMonths()
                /// This is not needed because `.onChange(of: navManager.selection)` handles it (even when switching years)
                //calModel.prepareStartingAmount()
                await funcModel.downloadEverything(setDefaultPayMethod: true, createNewStructs: true, refreshTechnique: .viaButton)
            }
        })
        
        // MARK: - Handling Lifecycles (iPhone)
        .onChange(of: scenePhase) { oldPhrase, newPhase in
            if newPhase == .inactive {
                print("scenePhase: Inactive")
                
            } else if newPhase == .active {
                print("scenePhase: Active")
                if funcModel.refreshTask == nil {
                    funcModel.refreshTask = Task {
                        AppState.shared.startNewNowTimer()
                        await funcModel.downloadEverything(setDefaultPayMethod: false, createNewStructs: false, refreshTechnique: .viaSceneChange)
                    }
                }
                
            } else if newPhase == .background {
                AppState.shared.cancelNowTimer()
                funcModel.longPollTask?.cancel()
                funcModel.longPollTask = nil
                print("scenePhase: Background")
            }
        }
        
        // MARK: - Handling Lifecycles (Mac)
        .onChange(of: AppState.shared.macWokeUp) { oldValue, newValue in
            if newValue {
                if funcModel.refreshTask == nil {
                    funcModel.refreshTask = Task {
                        AppState.shared.startNewNowTimer()
                        await funcModel.downloadEverything(setDefaultPayMethod: false, createNewStructs: false, refreshTechnique: .viaSceneChange)
                    }
                }
            }
        }
        
        .onChange(of: AppState.shared.macSlept) { oldValue, newValue in
            if newValue {
                AppState.shared.cancelNowTimer()
                funcModel.longPollTask?.cancel()
                funcModel.longPollTask = nil
            }
        }
        
        .onChange(of: AppState.shared.macWindowDidBecomeMain) { oldValue, newValue in
            if newValue {
                funcModel.longPollServerForChanges()
            }
        }
        
        //.backgroundStyle(.background)
        //.background(Color.totalDarkGray)
    }
}
