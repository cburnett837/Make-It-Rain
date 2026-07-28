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
import AppIntents
#endif


@main
struct MakeItRainApp: App {
    #if os(macOS)
    @Environment(\.openWindow) var openWindow
    @NSApplicationDelegateAdaptor(AppDelegateMac.self) var appDelegate
    #else
    @UIApplicationDelegateAdaptor(AppDelegatePhone.self) var appDelegate
    @Environment(\.scenePhase) var scenePhase
    #endif
    
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("appScreenWidth") var screenWidth: Double = 0
    @AppStorage("appScreenHeight") var screenHeight: Double = 0
    @AppStorage("useBiometrics") var useBiometrics = false
    @Local(\.startInFullScreen) var startInFullScreen
    @Local(\.userColorScheme) var userColorScheme
    
    @State var store = AppStore()
    @State private var appState = AppState.shared
    @State private var authState = AuthState.shared
    @State private var undoManager = UndodoManager.shared
    @State private var openRecordManager = OpenRecordManager.shared
    
    @State var webSocketManager: WebSocketManager
    @State var funcModel: FuncModel
    @State var calModel: CalendarModel
    @State var payModel: PayMethodModel
    @State var catModel: CategoryModel
    @State var keyModel: KeywordModel
    @State var repModel: RepeatingTransactionModel
    @State var plaidModel: PlaidModel
    @State var dashboardModel: DashboardModel
    @State var budgetModel: BudgetModel
    @State var tagModel: TagModel
    
    @State private var fileModel = FileModel.shared
    @State private var locationManager = LocationManager.shared
    @State var dataChangeTriggers = DataChangeTriggers.shared
    //@State private var mapModel = MapModel()
    
//    #if os(macOS)
//    @State var categoryAnalysisModel = CivViewModel()
//    #endif
    
    @State private var userIdentity = Cody.shared
    
    @State var calProps = CalendarProps()
    
    @State private var showCamera = false
    
    //@State private var isUnlocked = false
        
    init() {
        let isStressTest = ProcessInfo.processInfo.arguments.contains("--ui-stress-test")
        if isStressTest {
            print("Running in UI stress test mode")
        }
        
        #if os(iOS)
        PhoneWatchSync.shared.start()
        #endif
        
        let store = AppStore()
        let calModel = CalendarModel(store: store)
        let payModel = PayMethodModel(store: store)
        let catModel = CategoryModel(store: store)
        let keyModel = KeywordModel(store: store)
        let repModel = RepeatingTransactionModel(store: store)
        let plaidModel = PlaidModel(store: store)
        let dashboardModel = DashboardModel(store: store, isForSelectedMonth: false)
        let budgetModel = BudgetModel(store: store)
        let tagModel = TagModel(store: store)
        
        let webSocketManager = WebSocketManager(
            store: store,
            calModel: calModel,
            payModel: payModel,
            catModel: catModel,
            keyModel: keyModel,
            repModel: repModel,
            plaidModel: plaidModel,
            budgetModel: budgetModel,
            tagModel: tagModel,
            dashboardModel: dashboardModel
        )

        let funcModel = FuncModel(
            store: store,
            calModel: calModel,
            payModel: payModel,
            catModel: catModel,
            keyModel: keyModel,
            repModel: repModel,
            plaidModel: plaidModel,
            webSocketManager: webSocketManager,
            dashboardModel: dashboardModel,
            budgetModel: budgetModel,
            tagModel: tagModel
        )

        _store = State(initialValue: store)
        _calModel = State(initialValue: calModel)
        _payModel = State(initialValue: payModel)
        _catModel = State(initialValue: catModel)
        _keyModel = State(initialValue: keyModel)
        _repModel = State(initialValue: repModel)
        _plaidModel = State(initialValue: plaidModel)
        _dashboardModel = State(initialValue: dashboardModel)
        _webSocketManager = State(initialValue: webSocketManager)
        _funcModel = State(initialValue: funcModel)
        _budgetModel = State(initialValue: budgetModel)
        _tagModel = State(initialValue: tagModel)
        
        
//        let webSocketManager = WebSocketManager(
//            calModel: calModel,
//            payModel: payModel,
//            catModel: catModel,
//            keyModel: keyModel,
//            repModel: repModel,
//            plaidModel: plaidModel
//        )
//        
//        let funcModel = FuncModel(
//            calModel: calModel,
//            payModel: payModel,
//            catModel: catModel,
//            keyModel: keyModel,
//            repModel: repModel,
//            plaidModel: plaidModel,
//            webSocketManager: webSocketManager,
//            dashboardModel: dashboardModel
//        )
//        
//        self.funcModel = funcModel
//        self.webSocketManager = webSocketManager
        
        do {
            try setupTips()
        } catch {
            print("Error initializing tips: \(error)")
        }
    }
    
    
    @State private var plaidWouldLikeToShow = false
    var isReadyToShowPlaidSheet: Bool {
        if let targetMonth = calModel.months.get(by: (AppState.shared.todayMonth, AppState.shared.todayYear)) {
            return plaidWouldLikeToShow
            && !AppState.shared.shouldShowSplash
            && !AuthState.shared.isThinking
            && !AppState.shared.splashIsAnimating
            && AuthState.shared.isLoggedIn
            && targetMonth.hasBeenLoadedFromServer
        } else {
            return false
        }
    }
    
    
        
    var body: some Scene {
        WindowGroup {
            /// Allow for universal sheets. Such as payment method sheet when first downloading the app, universal alerts, universal camera, etc.
            /// Views shown in this layer will be at the top-most part of the UI - Allowing for content on top of both sheets, and allowing the universal calendar sheet.
            RootViewWrapper(showCamera: $showCamera) {
                /// Allow for a universal calendar view.
                CalendarSheetLayerWrapper() {
                    Group {
                        /// `AuthState.shared.isThinking` is true when launching from a fresh state.
                        /// `AppState.shared.shouldShowSplash`is true when launching from a fresh state, and is set to false in either `downloadEverything()` when the current month completes, or in ``AuthState`` if login fails.
                        /// `AppState.shared.splashIsAnimating`is true when launching from a fresh state, and is set to false when the animation on the splash screen finishes.
                        /// *Once the 3 conditions above are met, the view will flip to the `rootView` or the `loginView` (depending on the apps overall state).*
                        if AuthState.shared.isThinking || AppState.shared.shouldShowSplash || AppState.shared.splashIsAnimating {
                            /// Always the first view to be shown.
                            /// Starts the login process.
                            /// Login flow descriptions are written in the `splashScreen` and `loginScreen` views below.
                            splashScreen
                        } else {
                            if AuthState.shared.isLoggedIn {
                                rootView                                    
                            } else {
                                /// Login flow descriptions are written in the `splashScreen` and `loginScreen` views below.
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
            .task {
                webSocketManager.funcModelRefreshFunction = refreshMiddleManForWebSocketManager
            }
            .onOpenURL { handleOpeningUrl($0) }
            #if os(macOS)
            .background(
                WindowAccessor { window in
                    window?.identifier = NSUserInterfaceItemIdentifier("mainWindow")
                }
            )
            .toolbar(.visible, for: .windowToolbar)
            .onAppear {
                // to make sure the UtilityWindowView is created
                // so that the next time we actually need to use it, we can configure it before opening
                //
                // if we don't call openWindow(id: UtilityWindowView.id) for at least once,
                // NSApplication.shared.windows will not contains the window instance.
                //
                // That is before the following call,  NSApplication.shared.windows.map(\.identifier?.rawValue) will not contain UtilityWindowView.id
                //
                // Also, configure the window within the Button closure right after calling openWindow(id: FullScreenOverlay.id) or within FullScreenOverlay.onAppear will not work completely either
                // Some of the properties will not be reflected.
                guard NSApplication.shared.windows.first(where: {$0.identifier?.rawValue == MacAlertAndToastOverlay.id}) == nil else {
                    // already created and configured
                    return
                }
                openWindow(id: MacAlertAndToastOverlay.id)
            }
            #endif
            .environment(funcModel)
            .environment(calModel)
            .environment(payModel)
            .environment(catModel)
            .environment(keyModel)
            .environment(repModel)
            .environment(plaidModel)
            .environment(dashboardModel)
            .environment(calProps)
            .environment(dataChangeTriggers)
            .environment(webSocketManager)
            .environment(store)
            .environment(budgetModel)
            .environment(tagModel)
            //.preferredColorScheme(colorScheme)
            .onChange(of: isReadyToShowPlaidSheet, initial: true) { _, isReady in
                guard isReady else { return }
                
                if let targetMonth = calModel.months.get(by: (AppState.shared.todayMonth, AppState.shared.todayYear)) {
                    Task { @MainActor in
                        if calModel.showMonth == false {
                            NavigationManager.shared.selectedMonth = targetMonth.enumID
                            NavigationManager.shared.selection = nil
                            calModel.showMonth = true
                        }
                        
                        withAnimation { calProps.bottomPanelContent = .plaidTransactions }
                        plaidWouldLikeToShow = false
                    }
                }
            }
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
            CalendarCommands(calModel: calModel)
        }
        #endif
        
        #if os(macOS)
        //dashboardWindow
        plaidWindow
        //insightsWindow
        //multiSelectWindow
        monthlyPlaceholderWindow
        settingsWindow
        macAlertAndToastOverlayWindow
        #endif
    }
    
    
    func refreshMiddleManForWebSocketManager() async {
        await funcModel.downloadEverything(setDefaultPayMethod: false, createNewStructs: false, refreshTechnique: .viaLongPoll)
    }
    
    
    @ViewBuilder
    private var splashScreen: some View {
        /// -----Login flow for splash screen-----
        /// The splash screen is the first view to show.
        /// It will check the keychain for an API key and call `AuthState.loginViaKeychain()`.
        
        /// If `AuthState.attemptLogin()` is successful, it will ...
            /// 1. Return true to this task, which will run `FuncModel.downloadInitial()`.
            /// Once...
            ///     1. We are logged in…
            ///     2. Splash animation has finished…
            ///     3. First month has downloaded…
            /// ... the splash screen will show the calendar full screen cover, and a split seocnd later switch the app from ``SplashScreen`` to ``RootView``.
        
        /// If `AuthState.attemptLogin()` fails, it will ...
            /// 1. Set `AuthState.isLoggedIn = false`
            /// 2. Set `AuthState.isThinking = false`.
            /// 3. Set `AppState.shouldShowSplash = false`.
            /// 4. Clear login state. (AKA the api key from the keychain if it exists.)
            /// The combo of variable settings above will cause the app to be redirected to the login screen.
                
        @Bindable var navManager = NavigationManager.shared
        SplashScreen()
            .transition(.opacity)
            .task {
                funcModel.setDeviceUUID()
                
                /// Download data when coming to the splash screen via the login screen.
                if AuthState.shared.isLoggedIn {
                    funcModel.downloadInitial()
                } else {
                    /// Perform login when cold launching.
                    if await AuthState.shared.loginViaKeychain() {
                        funcModel.downloadInitial()
                    }
                }
            }
    }
    
    
    private var loginView: some View {
        /// -----Login flow for login screen-----
        /// You enter your email and password on the login page, and tap the login button, which calls `AuthState.attemptLogin()`.
        
        /// If `AuthState.attemptLogin()` is successful, it will set ...
            /// 1. `AuthState.isLoggedIn = true`
            /// 2. `AuthState.isThinking = false`.
            /// 3. `AppState.shared.splashIsAnimating = true`.
            /// 4. `AppState.shouldShowSplash = true`.
            /// --- This will trigger the splash screen to show, which will run ``FuncModel.downloadInitial()`` and do further app logic.
            /// --- See description in `private var splashScreen` for further information.
        
        /// If `AuthState.attemptLogin()`fails, it will...
            /// 1. Set `AuthState.isLoggedIn = false`
            /// 2. Set `AuthState.isThinking = false`.
            /// 3. Set `AppState.shouldShowSplash = false`.
            /// 4. Set an error in ``AuthState`` that will show an alert on the login screen.
            /// 5. Clear login state. (AKA the api key from the keychain if it exists.)
        LoginView()
            .transition(.opacity)
            .onAppear {
                if AuthState.shared.serverRevoked {
                    funcModel.logout()
                    AuthState.shared.serverRevoked = false
                }
            }
    }
    
    
    @ViewBuilder
    private var rootView: some View {
        //let _ = print("RootView Render")
        RootView()
            .tint(Color.theme)
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
    
    
    
    //@State private var waitToGoToMainViewTask: Task<Void, Never>? = nil
    private func handleOpeningUrl(_ url: URL) {
        //print(url.absoluteString)
        
        if url.host == "plaid_transactions" {
            plaidWouldLikeToShow = true
//            self.waitToGoToMainViewTask = Task { @MainActor in
//                if let targetMonth = calModel.months.filter({ $0.actualNum == AppState.shared.todayMonth }).first {
//                    var attempts = 0
//                    let maxAttempts = 300
//                    /// Wait for up to a minute for the login to succeed.
//                    while attempts < maxAttempts {
//                        attempts += 1
//                        
//                        if let task = waitToGoToMainViewTask, task.isCancelled { return }
//                        
//                        print(
//                            "Should be all 'true'",
//                            !AppState.shared.shouldShowSplash,
//                            !AuthState.shared.isThinking,
//                            !AppState.shared.splashIsAnimating,
//                            targetMonth.hasBeenLoadedFromServer,
//                            (AuthState.shared.isLoggedIn || !AuthState.shared.keychainCredentialsExist)
//                        )
//                        
//                        if !AppState.shared.shouldShowSplash
//                            && !AuthState.shared.isThinking
//                            && !AppState.shared.splashIsAnimating
//                            && targetMonth.hasBeenLoadedFromServer
//                            && (AuthState.shared.isLoggedIn || !AuthState.shared.keychainCredentialsExist)
//                        {
//                            break
//                        }
//                        
//                        try? await Task.sleep(for: .milliseconds(100))
//                    }
//                    
//                    let success = attempts < maxAttempts
//                    
//                    if success {
//                        #if os(iOS)
//                        if AppState.shared.isIphone,
//                           AuthState.shared.isLoggedIn,
//                           !AppState.shared.showPaymentMethodNeededSheet,
//                           !AppState.shared.splashIsAnimating,
//                           targetMonth.hasBeenLoadedFromServer {
//                            
//                            if calModel.showMonth == false {
//                                NavigationManager.shared.selectedMonth = targetMonth.enumID
//                                NavigationManager.shared.selection = nil
//                                calModel.showMonth = true
//                            }
//                            
//                            withAnimation { calProps.bottomPanelContent = .plaidTransactions }
//                            
//                            
//                        }
//                        #endif
//                    }
//                }
//            }
                                               
            return
        }
        
        if url.host == "take_photo" {
            calModel.isUploadingSmartTransactionFile = true
            showCamera = true
            return
        }
        
        if let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
        let queryItems = urlComponents.queryItems {
            for item in queryItems {
                //print("Key: \(item.name), Value: \(item.value ?? "nil")")
                
                if item.name == "action" {
                    if item.value == "take_photo" {
                        //print("should open camera")
                        calModel.isUploadingSmartTransactionFile = true
                        showCamera = true
                    }
                }
            }
        }
    }
    
    
//    private func handleOpeningUrl(_ url: URL) {
//        print("opened url:", url.absoluteString)
//
//        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
//            return
//        }
//
//        let action = components.queryItems?
//            .first(where: { $0.name == "action" })?
//            .value
//
//        guard action == "take_photo" else { return }
//
//        print("should open camera")
//        calModel.isUploadingSmartTransactionFile = true
//        showCamera = true
//    }
}

#if os(macOS)

struct CalendarCommands: Commands {
    @Local(\.showHashTagsOnLineItems) var showHashTagsOnLineItems
    var calModel: CalendarModel
    
    @State private var showPopulateAlert = false
    @State private var showPopulateOptionsSheet = false
    
    var body: some Commands {
        CommandMenu("Calendar") { // "Custom Actions" is the new menu title
            if NavDest.justMonths.contains(NavigationManager.shared.selection ?? .placeholderMonth) {
                populateButton
                    .disabled(!NavDest.justMonths.contains(NavigationManager.shared.selection ?? .placeholderMonth))
                resetButton
                    .disabled(!NavDest.justMonths.contains(NavigationManager.shared.selection ?? .placeholderMonth))
            }
            
            Divider()
            
            ToolbarNowButton()
                .environment(calModel)
            PlaygroundButton()
                .environment(calModel)
            
            Divider()
            
            Menu("Line Items") {
                Toggle("Show Tags", isOn: $showHashTagsOnLineItems)
                //Button("Option 1") {}
                //Button("Option 2") {}
            }
        }
    }
    
    var populateButton: some View {
        Button {
            if calModel.sMonth.hasBeenPopulated {
                ToolbarAndCommandsCoordinator.shared.showPopulateAlert = true
            } else {
                ToolbarAndCommandsCoordinator.shared.showPopulateOptionsSheet = true
            }
        } label: {
            Text("Populate \(calModel.sMonth.name) \(String(calModel.sMonth.year))…")
        }
    }
    
    var resetButton: some View {
        Button {
            ToolbarAndCommandsCoordinator.shared.showResetMonthAlert = true
        } label: {
            Text("Reset \(calModel.sMonth.name) \(String(calModel.sMonth.year))…")
        }
    }
    
}
#endif
