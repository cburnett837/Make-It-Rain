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


//var todayDay = Calendar.current.component(.day, from: Date())
//var todayMonth = Calendar.current.component(.month, from: Date())
//var todayYear = Calendar.current.component(.year, from: Date())
//
//func updateTodayVariables() {
//    todayDay = Calendar.current.component(.day, from: Date())
//    todayMonth = Calendar.current.component(.month, from: Date())
//    todayYear = Calendar.current.component(.year, from: Date())
//}
//
//let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
//
//let numberFormatter = NumberFormatter()
//let colorMenuOptions: Array<Color> = [.pink, .red, .orange, .yellow, .green, .mint, .cyan, .blue, .indigo, .purple]

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
    @AppStorage("preferDarkMode") var preferDarkMode: Bool = true
    @AppStorage("appScreenWidth") var screenWidth: Double = 0
    @AppStorage("appScreenHeight") var screenHeight: Double = 0
    @AppStorage("useBiometrics") var useBiometrics = false
    @AppStorage("startInFullScreen") var startInFullScreen = false
    
    @State private var appState = AppState.shared
    @State private var authState = AuthState.shared
    @State private var funcModel: FuncModel
    @State private var calModel: CalendarModel
    @State private var payModel: PayMethodModel
    @State private var catModel: CategoryModel
    @State private var keyModel: KeywordModel
    @State private var repModel: RepeatingTransactionModel
    //@State private var tagModel = TagModel()
    
    let keychainManager = KeychainManager()
    @State private var isUnlocked = false
    
    
    init() {
        let calModel = CalendarModel()
        let payModel = PayMethodModel()
        let catModel = CategoryModel()
        let keyModel = KeywordModel()
        let repModel = RepeatingTransactionModel()
        
        self.calModel = calModel
        self.payModel = payModel
        self.catModel = catModel
        self.keyModel = keyModel
        self.repModel = repModel
        
        self.funcModel = .init(calModel: calModel, payModel: payModel, catModel: catModel, keyModel: keyModel, repModel: repModel)
        
        do {
            try setupTips()
        } catch {
            print("Error initializing tips: \(error)")
        }
    }
        
    var body: some Scene {
        WindowGroup {
            @Bindable var appState = AppState.shared
            Group {
                /// `AuthState.shared.isThinking` is always true when app launches from fresh state.
                /// `AppState.shared.appIsReadyToHideSplashScreen` is set in `downloadEverything()` when the current month completes.
                if AuthState.shared.isThinking || !AppState.shared.appIsReadyToHideSplashScreen/* || AppState.shared.holdSplash */{
                    loadingScreen
                } else {
                    if AuthState.shared.isLoggedIn {
                        if AppState.shared.hasBadConnection {
                            TempTransactionList()
                        } else {
                            rootView
                        }
                    } else {
                        if AppState.shared.hasBadConnection {
                            TempTransactionList()
                        } else {
                            Login()
                                .transition(.opacity)
                        }
                    }
                }
            }
            .environment(funcModel)
            .environment(calModel)
            .environment(payModel)
            .environment(catModel)
            .environment(keyModel)
            .environment(repModel)
            .environment(\.colorScheme, preferDarkMode ? .dark : .light)
            .preferredColorScheme(preferDarkMode ? .dark : .light)
//            .onReceive(AppState.shared.splashTimer) { input in
//                AppState.shared.splashTimer.upstream.connect().cancel()
//                withAnimation(.easeOut(duration: 1)) {
//                    AppState.shared.holdSplash = false
//                }
//            }
            
            #if os(iOS)
            .onAppear {
                let or = UIDevice.current.orientation
                AppState.shared.orientation = or
                if [.landscapeLeft, .landscapeRight].contains(or) || ([.faceUp, .faceDown].contains(or) && AppState.shared.isLandscape) {
                    AppState.shared.isLandscape = true
                } else {
                    AppState.shared.isLandscape = false
                }
            }
            .onRotate {
                AppState.shared.orientation = $0
                if [.landscapeLeft, .landscapeRight].contains($0) || ([.faceUp, .faceDown].contains($0) && AppState.shared.isLandscape) {
                    AppState.shared.isLandscape = true
                } else {
                    AppState.shared.isLandscape = false
                }
            }
            #endif
        
            /// Create the app delegate for Mac
            #if os(macOS)
            .background {
                HostingWindowFinder { window in
                    guard let window else { return }
                    window.delegate = appDelegate
                }
            }
        
            /// Set fullscreen if the app preferences call for it
            .onAppear {
                if startInFullScreen {
                    Task {
                        await MainActor.run {
                            AppState.shared.isInFullScreen = true
                            if let window = NSApplication.shared.windows.last {
                                window.toggleFullScreen(nil)
                            }
                        }
                    }
                }
            }
            #endif
        
            /// Univseral alert
            .alert(AppState.shared.alertText, isPresented: $appState.showAlert) {
                if let function = AppState.shared.alertFunction {
                    Button(AppState.shared.alertButtonText) {
                        function()
                    }
                }
                
                if let function = AppState.shared.alertFunction2 {
                    Button(AppState.shared.alertButtonText2) {
                        function()
                    }
                } else {
                    Button("Close") {}
                }                
            }
        }
        .defaultSize(width: 1000, height: 600)
        
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .newItem, addition: { })
            SidebarCommands()
            TextFormattingCommands()
            ToolbarCommands()
        }
        #endif
        
        #if os(macOS)
        Settings {
            SettingsView(showSettings: .constant(false))
                .frame(maxWidth: 400, minHeight: 600)
                .environment(funcModel)
                .environment(calModel)
                .environment(payModel)
                .environment(catModel)
                .environment(keyModel)
                .environment(repModel)
                //.environment(tagModel)
        }
        #endif
    }
    
    var loadingScreen: some View {
        Group {
            @Bindable var navManager = NavigationManager.shared
            SplashScreen()
                .transition(.opacity)
                .task {
                    funcModel.setDeviceUUID()
                    await funcModel.checkForCredentials()
                    if AuthState.shared.isLoggedIn {
                        print("TASK")
                        /// Add the current month to the NavPath
                        /// Using this task, and `init()` of ``CalendarModel``, the app will start on the current month and year.
                        /// ``todayMonth`` is in ``MakeItRainApp``
                        
                        /// When the user logs in, if they have no payment methods, make the payment method table the only view available.
                        if !AppState.shared.methsExist {
                            LoadingManager.shared.showInitiallyLoadingSpinner = false
                            LoadingManager.shared.showLoadingBar = false
                            navManager.selection = .paymentMethods
                        
                            /// Fetch the unified payment methods (standard with every account).
                            await payModel.fetchPaymentMethods(calModel: calModel)
                            
                        } else {
                            /// This isn't used on the iPhone, but it needed to be set since the funcModel uses it to determine what to download first.
                            /// This is used on the Mac.
                            navManager.selection = NavDestination.getMonthFromInt(AppState.shared.todayMonth)
                            
                            navManager.navPath.append(NavDestination.getMonthFromInt(AppState.shared.todayMonth)!)
                            LoadingManager.shared.showInitiallyLoadingSpinner = true
                            //printPersistentMethods()
                                        
                            funcModel.refreshTask = Task {
                                calModel.prepareMonths()
                                if let selection = navManager.selection {
                                    calModel.setSelectedMonthFromNavigation(navID: selection, prepareStartAmount: false)
                                    await funcModel.downloadEverything(setDefaultPayMethod: true, createNewStructs: true, refreshTechnique: .viaInitial)
                                }
                            }
                        }
                        funcModel.longPollServerForChanges()
                        NotificationManager.shared.registerForPushNotifications()
                    }
                }
        }
    }
    
    var rootView: some View {
        RootView()
            .frame(idealWidth: screenWidth, idealHeight: screenHeight)
            .onPreferenceChange(SizePreferenceKey.self) { value in
                screenWidth = value.width
                screenHeight = value.height
            }
            //.environment(tagModel)
            //.toolbar(.hidden, for: .windowToolbar)
    }
    
    
    private func setupTips() throws {
        // Show all defined tips in the app.
        // Tips.showAllTipsForTesting()

        // Show some tips, but not all.
        // Tips.showTipsForTesting([tip1, tip2, tip3])

        // Hide all tips defined in the app.
        // Tips.hideAllTipsForTesting()

        // Purge all TipKit-related data.
        try Tips.resetDatastore()

        // Configure and load all tips in the app.
        try Tips.configure()
        
    }
}
















//@main
//struct MakeItRainApp: App {
//    #if os(macOS)
//    @NSApplicationDelegateAdaptor(AppDelegateMac.self) var appDelegate
//    //@State private var windowDelegate = MyWindowDelegate()
//    #else
//    @UIApplicationDelegateAdaptor(AppDelegatePhone.self) var appDelegate
//    @Environment(\.scenePhase) var scenePhase
//    #endif
//    
//    @Environment(\.colorScheme) var colorScheme
//    @AppStorage("preferDarkMode") var preferDarkMode: Bool = true
//    @AppStorage("appScreenWidth") var screenWidth: Double = 0
//    @AppStorage("appScreenHeight") var screenHeight: Double = 0
//    @AppStorage("useBiometrics") var useBiometrics = false
//    @AppStorage("startInFullScreen") var startInFullScreen = false
//    
//    @State private var appState = AppState.shared
//    @State private var authState = AuthState.shared
//    @State private var funcModel: FuncModel
//    @State private var calModel: CalendarModel
//    @State private var payModel: PayMethodModel
//    @State private var catModel: CategoryModel
//    @State private var keyModel: KeywordModel
//    @State private var repModel: RepeatingTransactionModel
//    //@State private var tagModel = TagModel()
//    
//    let keychainManager = KeychainManager()
//    @State private var isUnlocked = false
//    
//    
//    init() {
//        let calModel = CalendarModel()
//        let payModel = PayMethodModel()
//        let catModel = CategoryModel()
//        let keyModel = KeywordModel()
//        let repModel = RepeatingTransactionModel()
//        
//        self.calModel = calModel
//        self.payModel = payModel
//        self.catModel = catModel
//        self.keyModel = keyModel
//        self.repModel = repModel
//        
//        self.funcModel = .init(calModel: calModel, payModel: payModel, catModel: catModel, keyModel: keyModel, repModel: repModel)
//    }
//        
//    var body: some Scene {
//        WindowGroup {
//            @Bindable var appState = AppState.shared
//            Group {
////                if useBiometrics && !AuthState.shared.isBioAuthed {
////                    Text("")
////                        .task {
////                            //AppState.shared.setDateToYesterday()
////                            funcModel.setDeviceUUID()
////                            funcModel.authenticate()
////                        }
////                } else {
//                    Group {
//                        if AuthState.shared.isThinking { /// always true when app launches from fresh state.
//                            loadingScreen
//                        } else {
//                            if AuthState.shared.isLoggedIn {
//                                rootView
//                            } else {
//                                if AppState.shared.hasBadConnection {
//                                    tempTransList
//                                } else {
//                                    Login()
//                                }
//                            }
//                        }
//                    }
//                //}
//            }
//            .environment(funcModel)
//            .environment(calModel)
//            .environment(payModel)
//            .environment(catModel)
//            .environment(keyModel)
//            .environment(repModel)
//            .environment(\.colorScheme, preferDarkMode ? .dark : .light)
//            .preferredColorScheme(preferDarkMode ? .dark : .light)
//            
//            #if os(iOS)
//            .onAppear {
//                let or = UIDevice.current.orientation
//                AppState.shared.orientation = or
//                if [.landscapeLeft, .landscapeRight].contains(or) || ([.faceUp, .faceDown].contains(or) && AppState.shared.isLandscape) {
//                    AppState.shared.isLandscape = true
//                } else {
//                    AppState.shared.isLandscape = false
//                }
//            }
//            .onRotate {
//                AppState.shared.orientation = $0
//                if [.landscapeLeft, .landscapeRight].contains($0) || ([.faceUp, .faceDown].contains($0) && AppState.shared.isLandscape) {
//                    AppState.shared.isLandscape = true
//                } else {
//                    AppState.shared.isLandscape = false
//                }
//            }
//            #endif
//        
//            /// Create the app delegate for Mac
//            #if os(macOS)
//            .background {
//                HostingWindowFinder { window in
//                    guard let window else { return }
//                    window.delegate = appDelegate
//                }
//            }
//        
//            /// Set fullscreen if the app preferences call for it
//            .onAppear {
//                if startInFullScreen {
//                    Task {
//                        await MainActor.run {
//                            AppState.shared.isInFullScreen = true
//                            if let window = NSApplication.shared.windows.last {
//                                window.toggleFullScreen(nil)
//                            }
//                        }
//                    }
//                }
//            }
//            #endif
//        
//            /// Univseral alert
//            .alert(AppState.shared.alertText, isPresented: $appState.showAlert) {
//                if let function = AppState.shared.alertFunction {
//                    Button(AppState.shared.alertButtonText) {
//                        function()
//                    }
//                }
//                
//                Button("Close") {}
//            }
//        }
//        .defaultSize(width: 1000, height: 600)
//        
//        #if os(macOS)
//        .windowStyle(.hiddenTitleBar)
//        .windowToolbarStyle(.unified)
//        .commands {
//            CommandGroup(replacing: .newItem, addition: { })
//            SidebarCommands()
//            TextFormattingCommands()
//            ToolbarCommands()
//        }
//        #endif
//        
//        #if os(macOS)
//        Settings {
//            SettingsView(showSettings: .constant(false))
//                .frame(maxWidth: 400, minHeight: 600)
//                .environment(funcModel)
//                .environment(calModel)
//                .environment(payModel)
//                .environment(catModel)
//                .environment(keyModel)
//                .environment(repModel)
//                //.environment(tagModel)
//        }
//        #endif
//        
//    }
//    
//    var loadingScreen: some View {
//        VStack {
//            ProgressView()
//                .tint(.none)
//            //Text("Authenticating…")
//            Text("Loading…")
//        }
//        #if os(iOS)
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
//        .standardBackground()
//        #endif
//        .task {
//            funcModel.setDeviceUUID()
//            await funcModel.checkForCredentials()
////            do {
////                AuthState.shared.logout()
////                try keychainManager.removeFromKeychain()
////            } catch {
////                print(error.localizedDescription)
////            }
//        }
//        //ProgressView()
//    }
//    
//    var rootView: some View {
//        RootView()
//            .frame(idealWidth: screenWidth, idealHeight: screenHeight)
//        //.environment(tagModel)
//        //.toolbar(.hidden, for: .windowToolbar)
//            .onPreferenceChange(SizePreferenceKey.self) { value in
//                screenWidth = value.width
//                screenHeight = value.height
//            }
//    }
//    
//    var tempTransList: some View {
//        TempTransactionList()
//            #if os(iOS)
//            .onChange(of: scenePhase) { oldPhrase, newPhase in
//                if newPhase == .inactive {
//                    print("scenePhase: Inactive")
//                } else if newPhase == .active {
//                    print("scenePhase: Active")
//                    Task {
//                        //authState.isThinking = true
//                        await funcModel.checkForCredentials()
//                    }
//                } else if newPhase == .background {
//                    print("scenePhase: Background")
//                }
//            }
//            #else
//            // MARK: - Handling Lifecycles (Mac)
//            .onChange(of: AppState.shared.macWokeUp) { oldValue, newValue in
//                if newValue { Task { await funcModel.checkForCredentials() } }
//            }
//            .onChange(of: AppState.shared.macSlept) { oldValue, newValue in
//                if newValue { Task { await funcModel.checkForCredentials() } }
//            }
//            .onChange(of: AppState.shared.macWindowDidBecomeMain) { oldValue, newValue in
//                if newValue { Task { await funcModel.checkForCredentials() } }
//            }
//            #endif
//    }
//    
//}
