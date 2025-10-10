//
//  RootView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/18/24.
//

import SwiftUI

struct RootView: View {
    @Local(\.colorTheme) var colorTheme
    
    @Environment(\.scenePhase) var scenePhase
    @Environment(FuncModel.self) var funcModel
    @Environment(CalendarModel.self) var calModel
    @Environment(PayMethodModel.self) var payModel
    @Environment(CategoryModel.self) var catModel
    @Environment(KeywordModel.self) var keyModel
    @Environment(RepeatingTransactionModel.self) var repModel
    @Environment(EventModel.self) var eventModel
    
    let monthNavigationNamespace: Namespace.ID
        
    var body: some View {
        @Bindable var navManager = NavigationManager.shared
        @Bindable var funcModel = funcModel
        //@Bindable var appState = AppState.shared
        
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
        .task {
            /// set the calendar model to use the current month (ignore starting amounts and calculations)
//            if let selectedMonth = navManager.selectedMonth {
//                calViewModel.setSelectedMonthFromNavigation(navID: selectedMonth, prepareStartAmount: false)
//            }
            #if os(iOS)
            if !AppState.shared.isIpad {
                if !AppState.shared.showPaymentMethodNeededSheet {
                    calModel.showMonth = true
                }
                
            }
            #endif
        }
        //.tint(Color.fromName(colorTheme))
        
        /// This is here in case you want to cancel the dragging transaction - this will unhilight the last hilighted day.
        .dropDestination(for: CBTransaction.self) { droppedTrans, location in
            calModel.dragTarget = nil
            return true
        }
        
        #if os(macOS)
        /// Set ``sMonth`` in ``CalendarModel`` so the model is aware.
        .onChange(of: navManager.selection) { oldValue, newValue in
            print("onChange(of: navManager.selection)")
            calModel.sMonth = CBMonth(num: 100000)
            calModel.hilightTrans = nil
            
            if let selection = navManager.selection {
                if NavDestination.justMonths.contains(selection) {
                    Task {
                        let targetMonth = calModel.months.filter{ $0.enumID == selection }.first
                        if let targetMonth {
                            funcModel.prepareStartingAmounts(for: targetMonth)
                            calModel.setSelectedMonthFromNavigation(navID: selection, prepareStartAmount: true)
                        } else {
                            fatalError("Incorrect month")
                        }
                    }
                }
            }
        }
        #endif
        
        #if os(iOS)
        
        /// The NavLink for a month view is technically a button that sets `NavigationManager.selection`, and then sets `showMonth = true` , which opens a fullScreenCover.
        /// When the fullScreenCover is closed, set `NavigationManager.selection` to nil.
        .onChange(of: calModel.showMonth) { oldValue, newValue in
            //print("onChange(of: showMonth) -- \(newValue)")
            if !newValue {
                navManager.selectedMonth = nil
            }
        }
        
        /// This is ONLY here to hilight open the accessorials on iPhone. It serves no other function.
//        .onChange(of: navManager.navPath) { oldValue, newValue in
//            //print("onChange(of: navManager.navPath) -- \(newValue)")
//            if let newPath = newValue.last {
//                navManager.selection = newPath
//            } else {
//                navManager.selection = nil
//            }
//        }
        
        /// Clear out `calModel.sMonth` when `NavigationManager.selection` is set to nil, which will happen when closing the months fullScreenCover.
        /// This will also happen when leaving a accessorial list, but that is less significant - and more of a "keep the app's state clean" thing.
//        .onChange(of: navManager.selection, initial: true) { oldValue, newValue in
//            //print("onChange(of: navManager.selection) -- \(String(describing: newValue))")
//            calModel.hilightTrans = nil
//            if newValue == nil {
//                Task {
//                    try? await Task.sleep(nanoseconds: UInt64(0.1 * Double(NSEC_PER_SEC)))
//                    calModel.sMonth = CBMonth(num: 100000)
//                }
//            }
//        }
        
        /// Clear out `calModel.sMonth` when `NavigationManager.selectedMonth` is set to nil, which will happen when closing the months fullScreenCover.
        .onChange(of: navManager.selectedMonth, initial: true) { oldValue, newValue in
            //print("onChange(of: navManager.selection) -- \(String(describing: newValue))")
            calModel.hilightTrans = nil
            if newValue == nil {
                Task {
                    try? await Task.sleep(nanoseconds: UInt64(0.1 * Double(NSEC_PER_SEC)))
                    calModel.sMonth = CBMonth(num: 100000)
                }
            }
        }
        #endif
        
        /// If you add your first payment method, download all the content on save.
        /// `AppState.shared.methsExist` will get set by either `determineIfUserIsRequiredToAddPaymentMethod()` in the ``PayMethodModel``, or by `AuthState.attemptLogin`.
        .onChange(of: AppState.shared.methsExist) { oldValue, newValue in
            if newValue && !oldValue {
                funcModel.refreshTask = Task {
                    calModel.prepareMonths()
                    await funcModel.downloadEverything(setDefaultPayMethod: true, createNewStructs: true, refreshTechnique: .viaButton)
                }
                funcModel.longPollServerForChanges()
            }
        }
        
        .onChange(of: calModel.sYear) { oldValue, newValue in
            LoadingManager.shared.showInitiallyLoadingSpinner = true
            AppState.shared.downloadedData.removeAll()
            
            funcModel.refreshTask?.cancel()
            funcModel.refreshTask = Task {
                calModel.months.forEach { month in
                    month.days.removeAll()
                    month.startingAmounts.removeAll()
                    month.budgets.removeAll()
                    
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
        }
        
        // MARK: - Handling Lifecycles (iPhone)
        #if os(iOS)
        .onChange(of: scenePhase) { oldPhrase, newPhase in
            if newPhase == .inactive {
                print("scenePhase: Inactive")
                
            } else if newPhase == .active {
                print("scenePhase: Active")
                
                AppState.shared.startNewNowTimer()
                
                if funcModel.refreshTask == nil {
                    print("funcModel.refreshTask does not exist")
                    funcModel.refreshTask = Task {
                        
                        let shouldDownload = await AppState.shared.checkIfDownloadingDataIsNeeded()
                        if shouldDownload {
                            print("🎃YES NEW DATA TO DOWNLOAD")
                            await funcModel.downloadEverything(setDefaultPayMethod: false, createNewStructs: false, refreshTechnique: .viaSceneChange)
                        } else {
                            print("🎃NO NEW DATA TO DOWNLOAD")
                            funcModel.longPollServerForChanges()
                            
                            Task {
                                await OpenRecordManager.shared.fetchOpenOrClosed()
                            }                                                        
                        }
                    }
                } else {
                    print("funcModel.refreshTask already exists")
                }
                
                
                Task {
                    let _ = await OpenRecordManager.shared.batchMark(.open)
                }
                
                
            } else if newPhase == .background {
                print("scenePhase: Background")
                AppState.shared.cancelNowTimer()
                funcModel.longPollTask?.cancel()
                funcModel.longPollTask = nil
                funcModel.refreshTask?.cancel()
                funcModel.refreshTask = nil
                
                Task {
                    let _ = await OpenRecordManager.shared.batchMark(.closed)
                }
            }
        }
        #endif
        
        
        #if os(macOS)
        // MARK: - Handling Lifecycles (Mac)
        .onChange(of: AppState.shared.macWokeUp) { oldValue, newValue in
            if newValue {
                AppState.shared.startNewNowTimer()
                
                if funcModel.refreshTask == nil {
                    funcModel.refreshTask = Task {
                        let shouldDownload = await AppState.shared.checkIfDownloadingDataIsNeeded()
                        if shouldDownload {
                            print("🎃YES NEW DATA TO DOWNLOAD")
                            await funcModel.downloadEverything(setDefaultPayMethod: false, createNewStructs: false, refreshTechnique: .viaSceneChange)
                        } else {
                            print("🎃NO NEW DATA TO DOWNLOAD")
                            funcModel.longPollServerForChanges()
                        }
                    }
                }
            }
        }
        
        .onChange(of: AppState.shared.macSlept) { oldValue, newValue in
            if newValue {
                AppState.shared.cancelNowTimer()
                funcModel.longPollTask?.cancel()
                funcModel.longPollTask = nil
                funcModel.refreshTask?.cancel()
                funcModel.refreshTask = nil
            }
        }
        
        .onChange(of: AppState.shared.macWindowDidBecomeMain) { oldValue, newValue in
            if newValue {
                AppState.shared.startNewNowTimer()
                
                if funcModel.refreshTask == nil {
                    funcModel.refreshTask = Task {
                        let shouldDownload = await AppState.shared.checkIfDownloadingDataIsNeeded()
                        if shouldDownload {
                            print("🎃YES NEW DATA TO DOWNLOAD")
                            await funcModel.downloadEverything(setDefaultPayMethod: false, createNewStructs: false, refreshTechnique: .viaSceneChange)
                        } else {
                            print("🎃NO NEW DATA TO DOWNLOAD")
                            funcModel.longPollServerForChanges()
                        }
                    }
                }
            }
        }
        
        //.backgroundStyle(.background)
        //.background(Color.totalDarkGray)
        #endif
    }
}
