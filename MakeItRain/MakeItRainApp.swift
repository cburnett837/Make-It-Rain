//
//  MakeItRainApp.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/18/24.
//

import SwiftUI
import Observation
import LocalAuthentication
import TipKit
#if os(iOS)
import UIKit
#endif

@main
struct MakeItRainApp: App {
    #if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegateMac.self) var appDelegate
    //@State private var windowDelegate = MyWindowDelegate()
    #else
    @UIApplicationDelegateAdaptor(AppDelegatePhone.self) var appDelegate
    @Environment(\.scenePhase) var scenePhase
    #endif
    
    @Environment(\.colorScheme) var colorScheme
    @Local(\.colorTheme) var colorTheme
    @AppStorage("appScreenWidth") var screenWidth: Double = 0
    @AppStorage("appScreenHeight") var screenHeight: Double = 0
    @AppStorage("useBiometrics") var useBiometrics = false
    @AppStorage("startInFullScreen") var startInFullScreen = false
    @AppStorage("userColorScheme") var userColorScheme: UserPreferedColorScheme = .userSystem
    
    @State private var appState = AppState.shared
    @State private var authState = AuthState.shared
    @State private var undoManager = UndodoManager.shared
    @State private var openRecordManager = OpenRecordManager.shared
    
    @State private var funcModel: FuncModel
    @State private var calModel: CalendarModel
    @State private var payModel: PayMethodModel
    @State private var catModel: CategoryModel
    @State private var keyModel: KeywordModel
    @State private var repModel: RepeatingTransactionModel
    @State private var eventModel: EventModel
    
    @State private var photoModel = PhotoModel.shared
    @State private var locationManager = LocationManager.shared
    @State private var mapModel = MapModel()
    
    @State private var isUnlocked = false
    
    @Namespace private var monthNavigationNamespace
    
    init() {
        let calModel = CalendarModel.shared
                
        /// This is now a singleton because the creditLimits are needed inside the calModel. 2/21/25
        /// However, views still access this via the environment.
        let payModel = PayMethodModel.shared
        //let payModel = PayMethodModel()
        
        /// All singletons because of experimenting with single window groups on iPad os.
        /// Should be find to leave them as such.
        let catModel = CategoryModel.shared
        let keyModel = KeywordModel.shared
        let repModel = RepeatingTransactionModel.shared
        let eventModel = EventModel.shared
        
        self.calModel = calModel
        self.payModel = payModel
        self.catModel = catModel
        self.keyModel = keyModel
        self.repModel = repModel
        self.eventModel = eventModel
        
        self.funcModel = .init(calModel: calModel, payModel: payModel, catModel: catModel, keyModel: keyModel, repModel: repModel, eventModel: eventModel)
        
        do {
            try setupTips()
        } catch {
            print("Error initializing tips: \(error)")
        }
    }
        
    var body: some Scene {
        WindowGroup {
            RootViewWrapper {
                CalendarSheetLayerWrapper(monthNavigationNamespace: monthNavigationNamespace) {
                    @Bindable var appState = AppState.shared
                    Group {
                        /// `AuthState.shared.isThinking` is always true when app launches from fresh state.
                        /// `AppState.shared.appShouldShowSplashScreen` is set to false in `downloadEverything()` when the current month completes.
                        /// `AppState.shared.splashTextAnimationIsFinished` is set to false in when the animation on the splash screen finishes.
                        if AuthState.shared.isThinking || AppState.shared.appShouldShowSplashScreen || !AppState.shared.splashTextAnimationIsFinished/* || AppState.shared.holdSplash */{
                            /// Always the first view to be shown.
                            /// Starts the login process.
                            splashScreen
                        } else {
                            if AuthState.shared.isLoggedIn {
                                rootView                                    
                            } else {
                                loginView
                            }
                        }
                    }
                    #if os(iOS)
                    .onAppear {
                        setDeviceOrientation(UIDevice.current.orientation)
                        setDefaultColorScheme(.green)
                    }
                    .onRotate { setDeviceOrientation($0) }
                    #endif
                    
                    /// Create the app delegate for Mac.
                    #if os(macOS)
                    .background {
                        HostingWindowFinder { window in
                            guard let window else { return }
                            window.delegate = appDelegate
                        }
                    }
                    
                    /// Set fullscreen if the app preferences call for it.
                    .onAppear {
                        if startInFullScreen { startMacInFullScreen() }
                        setDefaultColorScheme(.blue)
                    }
                    #endif
                }
            }
            #if os(macOS)
            .toolbar(.visible, for: .windowToolbar)
            #endif
            .environment(funcModel)
            .environment(calModel)
            .environment(payModel)
            .environment(catModel)
            .environment(keyModel)
            .environment(repModel)
            .environment(eventModel)
            //.preferredColorScheme(colorScheme)
        }
        .defaultSize(width: 1000, height: 600)
        
        #if os(macOS)
        //.defaultLaunchBehavior(.presented) --> Not using because we terminate the app when the last window closes.
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .newItem, addition: { })
            SidebarCommands()
            //TextFormattingCommands()
            //ToolbarCommands()
        }
        #endif
        
        #if os(macOS)
        Window("Budget", id: "budgetWindow") {
            BudgetTable()
                .frame(minWidth: 300, minHeight: 200)
                .environment(calModel)
                .environment(payModel)
                .environment(catModel)
                .environment(keyModel)
                .environment(repModel)
                .environment(eventModel)
        }
        .auxilaryWindow()
        
        Window("Pending Fit Transactions", id: "pendingFitTransactions") {
            FitTransactionOverlay(bottomPanelContent: .constant(.fitTransactions), bottomPanelHeight: .constant(0), scrollContentMargins: .constant(0))
                .frame(minWidth: 300, minHeight: 200)
                .environment(calModel)
                .environment(payModel)
        }
        .auxilaryWindow()
        
        Window("Category Analysis", id: "analysisSheet") {
            AnalysisSheet(showAnalysisSheet: .constant(true))
                .frame(minWidth: 300, minHeight: 500)
                .environment(funcModel)
                .environment(calModel)
                .environment(payModel)
                .environment(catModel)
                .environment(keyModel)
                .environment(repModel)
                .environment(eventModel)
                //.environment(mapModel)
        }
        .auxilaryWindow()
                        
        Window("Multi-Select", id: "multiSelectSheet") {
            MultiSelectTransactionOptionsSheet(
                bottomPanelContent: .constant(.multiSelectOptions),
                bottomPanelHeight: .constant(0),
                scrollContentMargins: .constant(0),
                showAnalysisSheet: .constant(false)
            )
            .frame(minHeight: 500)
            .frame(width: 250)
            .environment(funcModel)
            .environment(calModel)
            .environment(payModel)
            .environment(catModel)
            .environment(keyModel)
            .environment(repModel)
            .environment(eventModel)
//            .onDisappear {
//                calModel.isInMultiSelectMode = false
//            }
        }
        .auxilaryWindow()
            
        WindowGroup("MonthlyWindowPlaceHolder", id: "monthlyWindow", for: NavDestination?.self) { dest in
            let width = ((NSScreen.main?.visibleFrame.width ?? 500) / 3) * 2
            let height = ((NSScreen.main?.visibleFrame.height ?? 500) / 4) * 3
                        
            if let dest = dest.wrappedValue {
                CalendarViewMac(enumID: dest!, isInWindow: true)
                    /// Frame is required to prevent the window from entering full screen if the main window is full screen
                    .frame(
                        minWidth: width,
                        maxWidth: (NSScreen.main?.visibleFrame.width ?? 500) - 1,
                        minHeight: height,
                        maxHeight: (NSScreen.main?.visibleFrame.height ?? 500) - 1
                    )
                    .environment(funcModel)
                    .environment(calModel)
                    .environment(payModel)
                    .environment(catModel)
                    .environment(keyModel)
                    .environment(repModel)
                    .environment(eventModel)
                    //.environment(mapModel)
                    .onAppear {
                        if let window = NSApp.windows.first(where: {$0.title.contains("MonthlyWindowPlaceHolder")}) {
                            window.title = AppState.shared.monthlySheetWindowTitle
                        }
                    }
                    .onDisappear {
                        calModel.windowMonth = nil
                    }                
            }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.expanded)
        .auxilaryWindow(openIn: .center)
        
        Settings {
            SettingsView(showSettings: .constant(false))
                .frame(maxWidth: 400, minHeight: 600)
                .environment(funcModel)
                .environment(calModel)
                .environment(payModel)
                .environment(catModel)
                .environment(keyModel)
                .environment(repModel)
                .environment(eventModel)
                //.environment(mapModel)
        }
        #endif
    }        
    
    
    private var splashScreen: some View {
        @Bindable var navManager = NavigationManager.shared
        return SplashScreen()
            .transition(.opacity)
            .task {
                print("FLIPPED TO SPLASH SCREEN")
                funcModel.setDeviceUUID()
                await AuthState.shared.loginViaKeychain(funcModel: funcModel)
            }
    }
    
    
    private var loginView: some View {
        LoginView()
            .transition(.opacity)
            .onAppear {
                if AuthState.shared.serverRevoked {
                    Task {
                        await funcModel.logout()
                        AuthState.shared.serverRevoked = false
                    }
                }
            }
    }
    
    
    private var rootView: some View {
        RootView(monthNavigationNamespace: monthNavigationNamespace)
            .tint(Color.fromName(colorTheme))
            .frame(idealWidth: screenWidth, idealHeight: screenHeight)
            .onPreferenceChange(SizePreferenceKey.self) { value in
                screenWidth = value.width
                screenHeight = value.height
            }
    }
    
    
    #if os(iOS)
    private func setDeviceOrientation(_ new: UIDeviceOrientation) {
        AppState.shared.orientation = new
        if [.landscapeLeft, .landscapeRight].contains(new) || ([.faceUp, .faceDown].contains(new) && AppState.shared.isLandscape) {
            AppState.shared.isLandscape = true
        } else {
            AppState.shared.isLandscape = false
        }
    }
    #endif
    
    
    #if os(macOS)
    private func startMacInFullScreen() {
        Task {
            await MainActor.run {
                if let window = NSApplication.shared.windows.last {
                    AppState.shared.isInFullScreen = true
                    window.toggleFullScreen(nil)
                }
            }
        }
    }
    #endif
    
    
    private func setupTips() throws {
        // Show all defined tips in the app.
        // Tips.showAllTipsForTesting()

        // Show some tips, but not all.
        // Tips.showTipsForTesting([tip1, tip2, tip3])

        // Hide all tips defined in the app.
        // Tips.hideAllTipsForTesting()

        // Purge all TipKit-related data.
        //try Tips.resetDatastore()

        // Configure and load all tips in the app.
        try Tips.configure()
        
    }
    
    
    private func setDefaultColorScheme(_ color: Color) {
        /// Set a default color scheme
        
        if UserDefaults.standard.data(forKey: "colorTheme") == nil {
            let data = try? JSONEncoder().encode(color.description)
            UserDefaults.standard.set(data, forKey: "colorTheme")
        }
    }
}
